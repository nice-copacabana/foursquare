import { Player, Room } from '../types/game';
import { v4 as uuidv4 } from 'uuid';

export class RoomManager {
    private rooms: Map<string, Room> = new Map();
    private playerRoomMap: Map<string, string> = new Map(); // socketId -> roomId
    private matchmakingQueue: Player[] = [];

    constructor() { }

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
                board: null, // Initial state
                currentTurn: p1.id, // P1 starts
                status: 'playing'
            },
            createdAt: Date.now()
        };

        this.rooms.set(roomId, room);
        this.playerRoomMap.set(p1.socketId, roomId);
        this.playerRoomMap.set(p2.socketId, roomId);

        return room;
    }

    public getRoomBySocketId(socketId: string): Room | undefined {
        const roomId = this.playerRoomMap.get(socketId);
        if (!roomId) return undefined;
        return this.rooms.get(roomId);
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
