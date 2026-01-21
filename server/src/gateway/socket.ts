import { Server, Socket } from 'socket.io';
import { RoomManager } from '../game/room_manager';
import { Player } from '../types/game';
import { MoveData } from '../types/move';
import { dbService } from '../services/database';

const roomManager = new RoomManager();

export const initGameServer = (io: Server) => {
    // Global Event Listeners
    roomManager.on('turn_timeout', (data: { roomId: string; currentTurn: Player['id'] }) => {
        console.log(`Turn timeout in room ${data.roomId}, new turn: ${data.currentTurn}`);
        io.to(data.roomId).emit('turn_change', {
            currentTurn: data.currentTurn,
            reason: 'timeout'
        });
    });

    io.on('connection', (socket: Socket) => {
        handleSocketConnection(io, socket);
    });
};

const handleSocketConnection = (io: Server, socket: Socket) => {
    console.log(`User connected: ${socket.id}`);

    // Send initial welcome message
    socket.emit('message', {
        type: 'system',
        content: 'Connected to Foursquare Game Server'
    });

    // --- Matchmaking Events ---

    // Handle request match (simple: "I want to play")
    socket.on('request_match', (data: { playerId: string }) => {
        console.log(`Match requested by ${data.playerId} (${socket.id})`);

        const player: Player = {
            id: data.playerId,
            socketId: socket.id,
            name: `Player ${data.playerId.substring(0, 4)}` // Simplified name
        };

        const room = roomManager.queuePlayer(player);

        if (room) {
            // Match found! properties: room.players[0] and room.players[1]
            const p1 = room.players[0];
            const p2 = room.players[1];

            console.log(`Match found: ${room.id} (${p1.id} vs ${p2.id})`);

            // Notify Player 1
            io.to(p1.socketId).emit('match_found', {
                matchId: room.id,
                opponentId: p2.id,
                color: 'black', // P1 is black
                ownId: p1.id
            });

            // Notify Player 2
            io.to(p2.socketId).emit('match_found', {
                matchId: room.id,
                opponentId: p1.id,
                color: 'white', // P2 is white
                ownId: p2.id
            });
        } else {
            // No match yet, added to queue
            socket.emit('match_queued', { message: 'Searching for opponent...' });
        }
    });

    // Handle cancel match
    socket.on('cancel_match', (data: { playerId: string }) => {
        roomManager.removePlayerFromQueue(data.playerId);
        socket.emit('match_cancelled', { message: 'Matchmaking cancelled' });
    });

    // --- Game Events ---

    // Handle Move
    // Expected data: { matchId, from, to, player, capturedPiece? }
    socket.on('submit_move', (data: MoveData) => {
        // Use RoomManager to validate and apply move
        const result = roomManager.handleMove(socket.id, data);

        if (!result.success || !result.room) {
            console.warn(`Invalid move from ${socket.id}: ${result.error}`);
            socket.emit('move_rejected', { message: result.error || 'Invalid move' });
            return;
        }

        const room = result.room;
        console.log(`Move validated in room ${room.id}:`, data);

        // Prepare data to send to opponent
        // Inject server-validated capture info
        const serverCaptured = (result.captured && result.captured.length > 0) ? result.captured[0] : undefined;

        const moveUpdate = {
            ...data,
            capturedPiece: serverCaptured
        };

        // Find opponent
        const opponent = room.players.find(p => p.socketId !== socket.id);

        if (opponent) {
            // Forward move to opponent with validated capture info
            io.to(opponent.socketId).emit('opponent_move', moveUpdate);
        }

        // Handle Game Over
        if (result.gameEnded) {
            const p1 = room.players[0]; // Black
            const p2 = room.players[1]; // White

            let winnerId: string | null = null;
            if (result.winner === 'black') winnerId = p1.id;
            else if (result.winner === 'white') winnerId = p2.id;

            // Broadcast Game Over
            io.to(room.id).emit('game_over', {
                matchId: room.id,
                winnerId: winnerId, // Send UUID to client? Or color? Client likely wants to know 'who won'. Sending UUID is safer.
                winnerColor: result.winner,
                reason: result.winner === 'draw' ? 'draw' : 'checkmate'
            });

            console.log(`Game Over in room ${room.id}. Winner: ${result.winner} (${winnerId})`);

            // Save to DB
            dbService.saveMatchResult(
                p1.id,
                p2.id,
                winnerId,
                room.gameState.moveHistory || []
            ).catch(err => console.error('Failed to save match result:', err));
        }
    });

    // Handle Chat (Optional)
    socket.on('chat_message', (data: { content: string }) => {
        const room = roomManager.getRoomBySocketId(socket.id);
        if (room) {
            // Broadcast to everyone in room (including self? or just opponent)
            // Usually just to opponent since client shows own message locally
            const opponent = room.players.find(p => p.socketId !== socket.id);
            if (opponent) {
                io.to(opponent.socketId).emit('chat_message', {
                    senderId: socket.id,
                    content: data.content
                });
            }
        }
    });

    // --- Disconnect ---
    socket.on('disconnect', () => {
        console.log(`User disconnected: ${socket.id}`);
        const room = roomManager.removePlayer(socket.id);

        if (room) {
            // Notify the remaining player(s)
            const opponent = room.players.find(p => p.socketId !== socket.id);
            const leaver = room.players.find(p => p.socketId === socket.id);

            if (opponent && leaver) {
                io.to(opponent.socketId).emit('opponent_disconnected', {
                    matchId: room.id,
                    message: 'Opponent disconnected'
                });

                // Save match result if game was in progress
                if (room.gameState.status === 'playing') {
                    // For MVP, if someone disconnects, the other person wins
                    // We save an empty moves list for now as we don't track moves in Room yet
                    dbService.saveMatchResult(
                        leaver.id,
                        opponent.id,
                        opponent.id, // Winner is opponent
                        room.gameState.moveHistory || []
                    );
                }
            }
        }
    });
};
