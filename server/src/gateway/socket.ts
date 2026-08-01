import type { Server } from 'socket.io';

import {
    MatchmakingResult,
    RoomManager,
} from '../game/room_manager';
import { dbService } from '../services/database';
import type { GameState, Player, Room } from '../types/game';
import type {
    AuthoritativeSnapshot,
    MoveDecision,
    MoveIntent,
} from '../types/protocol';
import { PROTOCOL_VERSION } from '../types/protocol';

type GameFinishedEvent = {
    roomId: string;
    state: GameState;
};

type SocketLike = {
    id: string;
    emit: (event: string, payload: unknown) => void;
    on: (event: string, listener: (payload?: unknown) => void) => void;
    join: (roomId: string) => unknown;
};

type IoLike = {
    sockets: {
        sockets: Map<string, SocketLike>;
    };
    on: (event: string, listener: (socket: SocketLike) => void) => void;
    to: (target: string) => {
        emit: (event: string, payload: unknown) => void;
    };
};

type RoomManagerLike = {
    on: (
        event: 'game_finished',
        listener: (event: GameFinishedEvent) => void,
    ) => unknown;
    resumePlayer: (
        playerId: string,
        socketId: string,
        matchId: string,
    ) => AuthoritativeSnapshot | undefined;
    createSnapshotForSocket: (
        socketId: string,
        matchId: string,
    ) => AuthoritativeSnapshot | undefined;
    queuePlayer: (player: Player) => MatchmakingResult;
    removePlayerFromQueue: (playerId: string, socketId: string) => boolean;
    handleMove: (socketId: string, intent: MoveIntent) => MoveDecision;
    getRoomBySocketId: (socketId: string) => Room | undefined;
    removePlayer: (socketId: string) => Room | undefined;
    getDisconnectDeadline: (socketId: string) => number | undefined;
};

type PersistFinishedRoom = (room: Room) => Promise<unknown> | unknown;
type PersistenceRetryScheduler = (
    callback: () => void,
    delayMs: number,
) => unknown;

type MovePayloadParseResult =
    | { valid: true; intent: MoveIntent }
    | {
        valid: false;
        commandId: string;
        reason: 'invalid_protocol' | 'invalid_payload';
    };

type MatchRequestParseResult =
    | { valid: true; playerId: string }
    | {
        valid: false;
        reason: 'invalid_protocol' | 'invalid_payload' | 'invalid_identity';
    };

type ResumeRequestParseResult =
    | { valid: true; playerId: string; matchId: string }
    | {
        valid: false;
        matchId: string;
        reason: 'invalid_protocol' | 'invalid_payload' | 'invalid_identity';
    };

type SnapshotRequestParseResult =
    | { valid: true; matchId: string }
    | {
        valid: false;
        matchId: string;
        reason: 'invalid_protocol' | 'invalid_payload';
    };

const roomManager = new RoomManager();
const COMPLETION_RETENTION_MS = 5 * 60_000;
const MAX_PERSISTENCE_RETRY_DELAY_MS = 30_000;
const WIRE_IDENTIFIER = /^[A-Za-z0-9_-]+$/;

export const initGameServer = (io: Server): void => {
    createSocketGateway(
        io as unknown as IoLike,
        roomManager,
        persistFinishedRoom,
    );
};

/**
 * Registers the online-game transport around an authoritative room manager.
 * The narrow structural interfaces keep transport behavior unit-testable
 * without opening real sockets or adding a Socket.IO test dependency.
 */
export const createSocketGateway = (
    io: IoLike,
    manager: RoomManagerLike,
    persist: PersistFinishedRoom,
    schedulePersistenceRetry: PersistenceRetryScheduler = (
        callback,
        delayMs,
    ) => setTimeout(callback, delayMs),
    now: () => number = Date.now,
): void => {
    const activeRooms = new Map<string, Room>();
    const completedMatchIds = new Map<string, number>();
    const persistenceInFlight = new Set<string>();

    const registerRoom = (room: Room | undefined): void => {
        if (room) activeRooms.set(room.id, room);
    };

    const completeGame = (
        roomId: string,
        state: GameState,
        knownRoom?: Room,
    ): void => {
        const oldestRetainedCompletion = now() - COMPLETION_RETENTION_MS;
        for (const [completedId, completedAt] of completedMatchIds) {
            if (completedAt <= oldestRetainedCompletion) {
                completedMatchIds.delete(completedId);
            }
        }
        if (completedMatchIds.has(roomId)) return;
        completedMatchIds.set(roomId, now());
        io.to(roomId).emit('game_over', {
            protocolVersion: PROTOCOL_VERSION,
            matchId: roomId,
            state,
        });

        const room = knownRoom ?? activeRooms.get(roomId);
        activeRooms.delete(roomId);
        if (!room) return;
        persistWithRetry(room);
    };

    const persistWithRetry = (room: Room): void => {
        if (persistenceInFlight.has(room.id)) return;
        persistenceInFlight.add(room.id);

        const attempt = (attemptNumber: number): void => {
            let result: Promise<unknown> | unknown;
            try {
                result = persist(room);
            } catch {
                handleFailure(attemptNumber);
                return;
            }
            void Promise.resolve(result).then(
                () => persistenceInFlight.delete(room.id),
                () => handleFailure(attemptNumber),
            );
        };

        const handleFailure = (attemptNumber: number): void => {
            if (attemptNumber === 3 || attemptNumber % 10 === 0) {
                console.error('Match persistence unavailable; retrying');
            }
            schedulePersistenceRetry(
                () => attempt(attemptNumber + 1),
                Math.min(
                    attemptNumber * 1_000,
                    MAX_PERSISTENCE_RETRY_DELAY_MS,
                ),
            );
        };

        attempt(1);
    };

    manager.on('game_finished', (event) => {
        completeGame(event.roomId, event.state);
    });

    io.on('connection', (socket) => {
        handleSocketConnection(
            io,
            socket,
            manager,
            registerRoom,
            completeGame,
        );
    });
};

const handleSocketConnection = (
    io: IoLike,
    socket: SocketLike,
    manager: RoomManagerLike,
    registerRoom: (room: Room | undefined) => void,
    completeGame: (
        roomId: string,
        state: GameState,
        knownRoom?: Room,
    ) => void,
): void => {
    socket.emit('message', { type: 'system', content: 'connected' });

    socket.on('resume_match', (payload) => {
        const parsed = parseResumeRequest(payload);
        if (!parsed.valid) {
            socket.emit('match_rejected', {
                protocolVersion: PROTOCOL_VERSION,
                reason: parsed.reason,
            });
            return;
        }
        const snapshot = manager.resumePlayer(
            parsed.playerId,
            socket.id,
            parsed.matchId,
        );
        if (!snapshot) {
            socket.emit('match_rejected', {
                protocolVersion: PROTOCOL_VERSION,
                reason: 'resume_not_found',
            });
            return;
        }
        socket.join(snapshot.matchId);
        socket.emit('authoritative_snapshot', snapshot);
        if (snapshot.state.status === 'playing') {
            const room = manager.getRoomBySocketId(socket.id);
            registerRoom(room);
            notifyOpponent(io, room, socket.id, 'opponent_reconnected');
        }
    });

    socket.on('request_snapshot', (payload) => {
        const parsed = parseSnapshotRequest(payload);
        if (!parsed.valid) {
            socket.emit('snapshot_rejected', {
                protocolVersion: PROTOCOL_VERSION,
                matchId: parsed.matchId,
                reason: parsed.reason,
            });
            return;
        }
        const snapshot = manager.createSnapshotForSocket(
            socket.id,
            parsed.matchId,
        );
        if (!snapshot) {
            socket.emit('snapshot_rejected', {
                protocolVersion: PROTOCOL_VERSION,
                matchId: parsed.matchId,
                reason: 'not_room_player',
            });
            return;
        }
        socket.emit('authoritative_snapshot', snapshot);
    });

    socket.on('request_match', (payload) => {
        const parsed = parseMatchRequest(payload);
        if (!parsed.valid) {
            socket.emit('match_rejected', {
                protocolVersion: PROTOCOL_VERSION,
                reason: parsed.reason,
            });
            return;
        }
        const player: Player = {
            id: parsed.playerId,
            socketId: socket.id,
            name: 'Anonymous player',
        };
        const result = manager.queuePlayer(player);
        if (result.status === 'rejected') {
            socket.emit('match_rejected', {
                protocolVersion: PROTOCOL_VERSION,
                reason: result.reason,
            });
            return;
        }
        if (result.status === 'queued') {
            socket.emit('match_queued', {
                protocolVersion: PROTOCOL_VERSION,
                status: 'searching',
            });
            return;
        }
        const room = result.room;
        registerRoom(room);

        for (const roomPlayer of room.players) {
            const playerSocket = io.sockets.sockets.get(roomPlayer.socketId);
            playerSocket?.join(room.id);
            const color = room.colorBySocketId[roomPlayer.socketId];
            if (!playerSocket || !color) continue;
            playerSocket.emit('match_found', {
                protocolVersion: PROTOCOL_VERSION,
                matchId: room.id,
                color,
                state: room.gameState,
                turnDeadlineEpochMs: room.turnDeadlineEpochMs,
                opponentConnected: true,
            });
        }
    });

    socket.on('cancel_match', (payload) => {
        const parsed = parseMatchRequest(payload);
        if (!parsed.valid) {
            socket.emit('match_rejected', {
                protocolVersion: PROTOCOL_VERSION,
                reason: parsed.reason,
            });
            return;
        }
        if (!manager.removePlayerFromQueue(parsed.playerId, socket.id)) {
            socket.emit('match_rejected', {
                protocolVersion: PROTOCOL_VERSION,
                reason: 'not_queued',
            });
            return;
        }
        socket.emit('match_cancelled', {
            protocolVersion: PROTOCOL_VERSION,
            status: 'cancelled',
        });
    });

    socket.on('submit_move', (payload) => {
        try {
            const parsed = parseMovePayload(payload);
            if (!parsed.valid) {
                emitGatewayMoveRejection(
                    socket,
                    manager,
                    parsed.commandId,
                    parsed.reason,
                );
                return;
            }

            const decision = manager.handleMove(socket.id, parsed.intent);
            if (decision.type === 'rejected') {
                socket.emit('move_rejected', decision);
                return;
            }
            const room = manager.getRoomBySocketId(socket.id);
            if (!room) {
                emitGatewayMoveRejection(
                    socket,
                    manager,
                    parsed.intent.commandId,
                    'invalid_payload',
                );
                return;
            }
            registerRoom(room);

            io.to(room.id).emit('move_committed', decision);
            if (decision.state.status === 'finished') {
                completeGame(room.id, decision.state, room);
            }
        } catch {
            emitGatewayMoveRejection(
                socket,
                manager,
                getCommandId(payload),
                'invalid_payload',
            );
        }
    });

    socket.on('disconnect', () => {
        const room = manager.removePlayer(socket.id);
        if (!room) return;
        registerRoom(room);
        const reconnectDeadlineEpochMs = manager.getDisconnectDeadline(
            socket.id,
        );
        notifyOpponent(
            io,
            room,
            socket.id,
            'opponent_disconnected',
            reconnectDeadlineEpochMs,
        );
    });
};

const parseMatchRequest = (payload: unknown): MatchRequestParseResult => {
    try {
        if (!isRecord(payload)) {
            return { valid: false, reason: 'invalid_payload' };
        }
        if (payload.protocolVersion !== PROTOCOL_VERSION) {
            return { valid: false, reason: 'invalid_protocol' };
        }
        const playerId = payload.playerId;
        if (
            typeof playerId !== 'string'
            || playerId.length < 8
            || playerId.length > 128
            || !WIRE_IDENTIFIER.test(playerId)
        ) {
            return { valid: false, reason: 'invalid_identity' };
        }
        return { valid: true, playerId };
    } catch {
        return { valid: false, reason: 'invalid_payload' };
    }
};

const parseMovePayload = (payload: unknown): MovePayloadParseResult => {
    if (!isRecord(payload)) {
        return { valid: false, commandId: '', reason: 'invalid_payload' };
    }
    const commandId = getCommandId(payload);
    if (payload.protocolVersion !== PROTOCOL_VERSION) {
        return { valid: false, commandId, reason: 'invalid_protocol' };
    }
    if (
        !isWireIdentifier(payload.matchId)
        || !isWireIdentifier(commandId)
        || !Number.isInteger(payload.expectedRevision)
        || (payload.expectedRevision as number) < 0
        || !isPosition(payload.from)
        || !isPosition(payload.to)
    ) {
        return { valid: false, commandId, reason: 'invalid_payload' };
    }

    return {
        valid: true,
        intent: {
            protocolVersion: PROTOCOL_VERSION,
            matchId: payload.matchId,
            commandId,
            expectedRevision: payload.expectedRevision as number,
            from: { x: payload.from.x, y: payload.from.y },
            to: { x: payload.to.x, y: payload.to.y },
        },
    };
};

const parseResumeRequest = (payload: unknown): ResumeRequestParseResult => {
    try {
        const parsedPlayer = parseMatchRequest(payload);
        const matchId = getMatchId(payload);
        if (!parsedPlayer.valid) {
            return {
                valid: false,
                matchId,
                reason: parsedPlayer.reason,
            };
        }
        if (!isWireIdentifier(matchId)) {
            return {
                valid: false,
                matchId,
                reason: 'invalid_payload',
            };
        }
        return {
            valid: true,
            playerId: parsedPlayer.playerId,
            matchId,
        };
    } catch {
        return { valid: false, matchId: '', reason: 'invalid_payload' };
    }
};

const parseSnapshotRequest = (
    payload: unknown,
): SnapshotRequestParseResult => {
    try {
        if (!isRecord(payload)) {
            return { valid: false, matchId: '', reason: 'invalid_payload' };
        }
        const matchId = getMatchId(payload);
        if (payload.protocolVersion !== PROTOCOL_VERSION) {
            return { valid: false, matchId, reason: 'invalid_protocol' };
        }
        if (!isWireIdentifier(matchId)) {
            return { valid: false, matchId, reason: 'invalid_payload' };
        }
        return { valid: true, matchId };
    } catch {
        return { valid: false, matchId: '', reason: 'invalid_payload' };
    }
};

const emitGatewayMoveRejection = (
    socket: SocketLike,
    manager: RoomManagerLike,
    commandId: string,
    reason: 'invalid_protocol' | 'invalid_payload',
): void => {
    let revision = 0;
    try {
        revision = manager.getRoomBySocketId(socket.id)
            ?.gameState.revision ?? 0;
    } catch {
        // Keep malformed requests and unexpected manager failures contained.
    }
    socket.emit('move_rejected', {
        type: 'rejected',
        protocolVersion: PROTOCOL_VERSION,
        commandId,
        reason,
        currentRevision: revision,
    });
};

const getCommandId = (payload: unknown): string => {
    try {
        if (!isRecord(payload)) return '';
        return typeof payload.commandId === 'string'
            ? payload.commandId
            : '';
    } catch {
        return '';
    }
};

const getMatchId = (payload: unknown): string => {
    try {
        if (!isRecord(payload)) return '';
        return typeof payload.matchId === 'string' ? payload.matchId : '';
    } catch {
        return '';
    }
};

const isWireIdentifier = (value: unknown): value is string => {
    return typeof value === 'string'
        && value.length > 0
        && value.length <= 128
        && WIRE_IDENTIFIER.test(value);
};

const isPosition = (
    value: unknown,
): value is { x: number; y: number } => {
    return isRecord(value)
        && Number.isInteger(value.x)
        && Number.isInteger(value.y);
};

const isRecord = (value: unknown): value is Record<string, unknown> => {
    return typeof value === 'object' && value !== null && !Array.isArray(value);
};

const notifyOpponent = (
    io: IoLike,
    room: Room | undefined,
    socketId: string,
    event: 'opponent_disconnected' | 'opponent_reconnected',
    reconnectDeadlineEpochMs?: number,
): void => {
    if (!room) return;
    const opponent = room.players.find(
        (player) => player.socketId !== socketId,
    );
    if (!opponent) return;
    io.to(opponent.socketId).emit(event, {
        protocolVersion: PROTOCOL_VERSION,
        matchId: room.id,
        ...(event === 'opponent_disconnected'
            ? { reconnectDeadlineEpochMs }
            : {}),
    });
};

const persistFinishedRoom = async (room: Room): Promise<void> => {
    const { winner, endReason } = room.gameState;
    if (winner == null || endReason == null) {
        throw new Error('finished_match_result_missing');
    }
    const saved = await dbService.saveMatchResult({
        matchId: room.id,
        protocolVersion: PROTOCOL_VERSION,
        player1Id: room.players[0].id,
        player2Id: room.players[1].id,
        winner,
        startingPlayer: room.startingPlayer,
        endReason,
        revision: room.gameState.revision,
        moves: room.gameState.moveHistory,
    });
    if (!saved) throw new Error('match_persistence_failed');
};
