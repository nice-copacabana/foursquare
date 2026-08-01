import type { GameState, PieceColor } from './game';
import type { Position } from './move';

export const PROTOCOL_VERSION = 1 as const;

export type MoveIntent = {
    protocolVersion: typeof PROTOCOL_VERSION;
    matchId: string;
    commandId: string;
    expectedRevision: number;
    from: Position;
    to: Position;
};

export type MoveRejectionReason =
    | 'invalid_protocol'
    | 'invalid_payload'
    | 'invalid_state'
    | 'rate_limited'
    | 'room_not_found'
    | 'not_room_player'
    | 'command_conflict'
    | 'stale_revision'
    | 'wrong_turn'
    | 'game_finished'
    | 'out_of_bounds'
    | 'not_your_piece'
    | 'target_occupied'
    | 'not_adjacent';

export type MoveCommitted = {
    type: 'committed';
    protocolVersion: typeof PROTOCOL_VERSION;
    commandId: string;
    state: GameState;
    capturedPieces: Position[];
    turnDeadlineEpochMs: number;
};

export type MoveRejected = {
    type: 'rejected';
    protocolVersion: typeof PROTOCOL_VERSION;
    commandId: string;
    reason: MoveRejectionReason;
    currentRevision: number;
};

export type MoveDecision = MoveCommitted | MoveRejected;

export type AuthoritativeSnapshot = {
    protocolVersion: typeof PROTOCOL_VERSION;
    matchId: string;
    color: PieceColor;
    state: GameState;
    turnDeadlineEpochMs: number;
    opponentConnected: boolean;
    opponentReconnectDeadlineEpochMs?: number;
};
