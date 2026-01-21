import { GameState, BoardState } from '../types/game';
import { MoveData, Position } from '../types/move';

const BOARD_SIZE = 4;

export class GameRules {
    constructor() { }

    public static getInitialBoard(): BoardState {
        // 4x4 Grid
        // Row 0: Black
        // Row 3: White
        const board: BoardState = Array(BOARD_SIZE).fill(null).map(() => Array(BOARD_SIZE).fill(null));

        // Initialize Black pieces (Top)
        for (let x = 0; x < BOARD_SIZE; x++) {
            board[0][x] = 'black';
        }

        // Initialize White pieces (Bottom)
        for (let x = 0; x < BOARD_SIZE; x++) {
            board[BOARD_SIZE - 1][x] = 'white';
        }

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

        // 3. Check Bounds
        if (!this.isWithinBounds(move.from) || !this.isWithinBounds(move.to)) {
            return { valid: false, message: 'Move out of bounds' };
        }

        // 4. Check Ownership
        const pieceAtFrom = gameState.board[move.from.y][move.from.x];
        if (pieceAtFrom !== move.player) {
            return { valid: false, message: 'Not your piece' };
        }

        // 5. Check Target Empty
        const pieceAtTo = gameState.board[move.to.y][move.to.x];
        if (pieceAtTo !== null) {
            return { valid: false, message: 'Target position is not empty' };
        }

        // 6. Check Adjacency (Up/Down/Left/Right) - No diagonals
        const dx = Math.abs(move.from.x - move.to.x);
        const dy = Math.abs(move.from.y - move.to.y);
        if (dx + dy !== 1) {
            return { valid: false, message: 'Invalid move: Must be adjacent' };
        }

        return { valid: true };
    }

    public applyMove(gameState: GameState, move: MoveData): { newState: GameState; captured: Position[] } {
        // 1. Move the piece
        const currentPlayer = move.player; // 'black' or 'white'
        gameState.board[move.from.y][move.from.x] = null;
        gameState.board[move.to.y][move.to.x] = currentPlayer;

        // 2. Check for Captures (Self-Self-Enemy)
        const captured = this.checkCaptures(gameState.board, move.to, currentPlayer);

        // Remove captured pieces
        captured.forEach(pos => {
            gameState.board[pos.y][pos.x] = null;
        });

        // 3. Record move in history (with capture info)
        const recordedMove = { ...move, capturedPiece: captured.length > 0 ? captured[0] : undefined };
        gameState.moveHistory.push(recordedMove);

        // 4. Update Turn
        const nextPlayer = currentPlayer === 'black' ? 'white' : 'black';
        gameState.currentTurn = nextPlayer;

        // 5. Check Win Condition
        const winner = this.checkWinner(gameState.board, nextPlayer); // Check if nextPlayer is dead
        if (winner) {
            gameState.status = 'finished';
            gameState.winner = winner;
        } else if (this.checkDraw(gameState)) {
            gameState.status = 'finished';
            gameState.winner = 'draw';
        }

        return { newState: gameState, captured };
    }

    private checkCaptures(board: BoardState, pos: Position, player: string): Position[] {
        const captured: Position[] = [];
        const opponent = player === 'black' ? 'white' : 'black';
        const directions = [
            { x: 1, y: 0 },  // Right
            { x: -1, y: 0 }, // Left
            { x: 0, y: 1 },  // Down
            { x: 0, y: -1 }  // Up
        ];

        // The rule: "Self-Self-Enemy". Length = 3.
        // The newly moved piece is at 'pos'. It could be the first or second 'Self'.
        // Case A: [pos] [Self] [Enemy]
        // Case B: [Self] [pos] [Enemy]

        for (const dir of directions) {
            // Check Case A: pos -> Self -> Enemy
            const p1 = { x: pos.x + dir.x, y: pos.y + dir.y };
            const p2 = { x: pos.x + dir.x * 2, y: pos.y + dir.y * 2 };

            if (this.isWithinBounds(p1) && this.isWithinBounds(p2)) {
                if (board[p1.y][p1.x] === player && board[p2.y][p2.x] === opponent) {
                    captured.push(p2);
                    continue; // Check next direction
                }
            }

            // Check Case B: Self -> pos -> Enemy
            // Opponent is at pos + dir. Self is at pos - dir.
            const pEnemy = { x: pos.x + dir.x, y: pos.y + dir.y };
            const pSelf = { x: pos.x - dir.x, y: pos.y - dir.y };

            if (this.isWithinBounds(pEnemy) && this.isWithinBounds(pSelf)) {
                if (board[pSelf.y][pSelf.x] === player && board[pEnemy.y][pEnemy.x] === opponent) {
                    captured.push(pEnemy);
                }
            }
        }

        return captured;
    }

    private checkWinner(board: BoardState, nextPlayer: string): string | null {
        // 1. Check piece count
        let blackCount = 0;
        let whiteCount = 0;
        for (let y = 0; y < BOARD_SIZE; y++) {
            for (let x = 0; x < BOARD_SIZE; x++) {
                if (board[y][x] === 'black') blackCount++;
                if (board[y][x] === 'white') whiteCount++;
            }
        }

        if (blackCount === 0) return 'white';
        if (whiteCount === 0) return 'black';

        // 2. Check if nextPlayer has any legal moves
        if (!this.hasLegalMoves(board, nextPlayer)) {
            // Next player cannot move, so the previous player wins
            return nextPlayer === 'black' ? 'white' : 'black';
        }

        return null;
    }

    private checkDraw(gameState: GameState): boolean {
        // 50-move rule (if stored in history)
        // Simplified: just check history length for now if we don't have no-capture counters
        if (gameState.moveHistory.length > 100) return true; // Safety cap
        return false;
    }

    private hasLegalMoves(board: BoardState, player: string): boolean {
        const directions = [{ x: 1, y: 0 }, { x: -1, y: 0 }, { x: 0, y: 1 }, { x: 0, y: -1 }];

        for (let y = 0; y < BOARD_SIZE; y++) {
            for (let x = 0; x < BOARD_SIZE; x++) {
                if (board[y][x] === player) {
                    // Check if this piece can move anywhere
                    for (const dir of directions) {
                        const nx = x + dir.x;
                        const ny = y + dir.y;
                        if (this.isWithinBounds({ x: nx, y: ny }) && board[ny][nx] === null) {
                            return true;
                        }
                    }
                }
            }
        }
        return false;
    }

    private isWithinBounds(pos: Position): boolean {
        return pos.x >= 0 && pos.x < BOARD_SIZE && pos.y >= 0 && pos.y < BOARD_SIZE;
    }
}
