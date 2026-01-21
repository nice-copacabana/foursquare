import { GameState, BoardState } from '../types/game';
import { MoveData, Position } from '../types/move';

export class GameRules {
    constructor() { }

    public static getInitialBoard(): BoardState {
        // Initialize an 8x8 empty board for now
        // In the future, this should place pieces according to Foursquare/Chess rules
        const board: BoardState = Array(8).fill(null).map(() => Array(8).fill(null));
        return board;
    }

    public validateMove(gameState: GameState, move: MoveData): { valid: boolean; message?: string } {
        // 1. Check if game is playing
        if (gameState.status !== 'playing') {
            return { valid: false, message: 'Game is not active' };
        }

        // 2. Check turn order
        if (gameState.currentTurn !== move.player) {
            return { valid: false, message: 'Not your turn' };
        }

        // 3. Bounds Check (0-7 for 8x8 board)
        if (!this.isWithinBounds(move.from) || !this.isWithinBounds(move.to)) {
            return { valid: false, message: 'Move out of bounds' };
        }

        // 4. Check if piece exists at 'from' (Basic check)
        // With current empty board init, this would fail if we strictly checked for pieces.
        // For MVP/Proto where client rules, we might skip strict piece existence check 
        // OR we rely on the client assuming the server tracks state correctly after first move.
        // For now, let's pass this if we don't have piece tracking implemented fully yet.

        // TODO: specific piece movement logic (Knight, etc.)

        return { valid: true };
    }

    public applyMove(gameState: GameState, move: MoveData): GameState {
        const newBoard = gameState.board.map(row => [...row]); // Deep copy rows

        // Move piece logic (Simplified: just clear 'from' and set 'to')
        // In a real scenario, we need to know WHAT piece moved.
        // Assuming the client logic is trusted for *what* is moving for now, or we track it.
        // Since we don't persist piece types in 'move', we might just flag the board.
        // For this improvement stage, let's rely on logging logic.

        // Swap turn
        // Ensure we switch to the OTHER player ID. 
        // But GameState only has currentTurn. Room has players array.
        // So we need to handle turn switching in RoomManager or pass players here.
        // We will just return the state object mutation here.

        // Add to history
        gameState.moveHistory.push(move);

        return gameState;
    }

    private isWithinBounds(pos: Position): boolean {
        return pos.x >= 0 && pos.x < 8 && pos.y >= 0 && pos.y < 8;
    }
}
