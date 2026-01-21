import { Player, Room } from '../types/game';
import { v4 as uuidv4 } from 'uuid';
import { GameRules } from './rules';
import { MoveData } from '../types/move';
import { EventEmitter } from 'events';

const TURN_TIMEOUT = 30000; // 30 seconds

export class RoomManager extends EventEmitter {
    private rooms: Map<string, Room> = new Map();
    private playerRoomMap: Map<string, string> = new Map(); // socketId -> roomId
    private matchmakingQueue: Player[] = [];

    constructor() {
        super();
    }

    // Add player to matchmaking queue
    public queuePlayer(player: Player): Room | null {
        // Check if player is already in queue
        if (this.matchmakingQueue.find(p => p.id === player.id)) {
            return null;
        }

        this.matchmakingQueue.push(player);

        // Try to match
        if (this.matchmakingQueue.length >= 2) {
            const p1 = this.matchmakingQueue.shift()!;
            const p2 = this.matchmakingQueue.shift()!;
            return this.createRoom(p1, p2);
        }

        return null;
    }

    public removePlayerFromQueue(playerId: string) {
        this.matchmakingQueue = this.matchmakingQueue.filter(p => p.id !== playerId);
    }

    public createRoom(p1: Player, p2: Player): Room {
        const roomId = uuidv4();
        const room: Room = {
            id: roomId,
            players: [p1, p2],
            spectators: [],
            gameState: {
                board: GameRules.getInitialBoard(), // Initialize board
                currentTurn: p1.id, // P1 starts
                status: 'playing',
                moveHistory: []
            },
            createdAt: Date.now()
        };

        this.rooms.set(roomId, room);
        this.playerRoomMap.set(p1.socketId, roomId);
        this.playerRoomMap.set(p2.socketId, roomId);

        this.resetTurnTimer(roomId);

        return room;
    }

    public getRoomBySocketId(socketId: string): Room | undefined {
        const roomId = this.playerRoomMap.get(socketId);
        if (!roomId) return undefined;
        return this.rooms.get(roomId);
    }

    public handleMove(socketId: string, moveData: MoveData): { success: boolean; room?: Room; error?: string } {
        const room = this.getRoomBySocketId(socketId);
        if (!room) return { success: false, error: 'Room not found' };

        // Validate
        const validation = new GameRules().validateMove(room.gameState, moveData);
        if (!validation.valid) {
            return { success: false, error: validation.message };
        }

        // Apply
        new GameRules().applyMove(room.gameState, moveData);

        // Switch turn
        const p1 = room.players[0];
        const p2 = room.players[1];
        room.gameState.currentTurn = room.gameState.currentTurn === p1.id ? p2.id : p1.id;

        this.resetTurnTimer(room.id);

        return { success: true, room };
    }

    private resetTurnTimer(roomId: string) {
        const room = this.rooms.get(roomId);
        if (!room || room.gameState.status !== 'playing') return;

        if (room.turnTimer) {
            clearTimeout(room.turnTimer);
        }

        room.turnTimer = setTimeout(() => {
            this.handleTimeout(roomId);
        }, TURN_TIMEOUT);
    }

    private handleTimeout(roomId: string) {
        const room = this.rooms.get(roomId);
        if (!room) return;

        // Force switch turn
        const p1 = room.players[0];
        const p2 = room.players[1];
        // Toggle turn
        room.gameState.currentTurn = room.gameState.currentTurn === p1.id ? p2.id : p1.id;

        // Emit event so socket can notify
        this.emit('turn_timeout', { roomId, currentTurn: room.gameState.currentTurn });

        // Restart timer for next player
        this.resetTurnTimer(roomId);
    }


    public removePlayer(socketId: string): Room | undefined {
        const roomId = this.playerRoomMap.get(socketId);
        if (roomId) {
            const room = this.rooms.get(roomId);
            this.playerRoomMap.delete(socketId);

            // If room exists, handle player leaving (end game?)
            // For now, if a player leaves, destroy room?
            // Or just return room so socket handler can notify opponent
            if (room) {
                // Remove room if empty or simplify logic for now
                this.rooms.delete(roomId);
                // Also remove opponent mapping
                const opponent = room.players.find(p => p.socketId !== socketId);
                if (opponent) {
                    this.playerRoomMap.delete(opponent.socketId);
                }
                return room;
            }
        }

        // Also remove from queue if present
        const queueIndex = this.matchmakingQueue.findIndex(p => p.socketId === socketId);
        if (queueIndex !== -1) {
            this.matchmakingQueue.splice(queueIndex, 1);
        }

        return undefined;
    }
}
