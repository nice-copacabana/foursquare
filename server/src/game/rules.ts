import {
    BoardState,
    GameEndReason,
    GameState,
    GameWinner,
    PieceColor,
    RecordedMove,
} from '../types/game';
import { MoveData, Position } from '../types/move';

const BOARD_SIZE = 4;
const NO_CAPTURE_DRAW_PLY = 50;

export type MoveValidation =
    | { valid: true }
    | { valid: false; message: string };

export type AppliedMove = {
    state: GameState;
    capturedPieces: Position[];
};

export class GameRules {
    public static getInitialBoard(): BoardState {
        const board: BoardState = Array.from(
            { length: BOARD_SIZE },
            () => Array<PieceColor | null>(BOARD_SIZE).fill(null),
        );
        for (let x = 0; x < BOARD_SIZE; x += 1) {
            board[0][x] = 'black';
            board[BOARD_SIZE - 1][x] = 'white';
        }
        return board;
    }

    public static validateMove(
        gameState: GameState,
        move: MoveData,
    ): MoveValidation {
        if (gameState.status !== 'playing') {
            return { valid: false, message: 'game_finished' };
        }
        if (
            gameState.noCapturePly >= NO_CAPTURE_DRAW_PLY
            || this.countPieces(gameState.board, 'black') <= 1
            || this.countPieces(gameState.board, 'white') <= 1
            || !this.hasLegalMoves(gameState.board, gameState.currentTurn)
        ) {
            return { valid: false, message: 'invalid_state' };
        }
        if (gameState.currentTurn !== move.player) {
            return { valid: false, message: 'wrong_turn' };
        }
        if (!this.isWithinBounds(move.from) || !this.isWithinBounds(move.to)) {
            return { valid: false, message: 'out_of_bounds' };
        }
        if (gameState.board[move.from.y][move.from.x] !== move.player) {
            return { valid: false, message: 'not_your_piece' };
        }
        if (gameState.board[move.to.y][move.to.x] !== null) {
            return { valid: false, message: 'target_occupied' };
        }
        const distance = Math.abs(move.from.x - move.to.x)
            + Math.abs(move.from.y - move.to.y);
        if (distance !== 1) {
            return { valid: false, message: 'not_adjacent' };
        }
        return { valid: true };
    }

    public static applyMove(gameState: GameState, move: MoveData): AppliedMove {
        const validation = this.validateMove(gameState, move);
        if (!validation.valid) {
            throw new Error(validation.message);
        }

        const board = gameState.board.map((row) => [...row]);
        board[move.from.y][move.from.x] = null;
        board[move.to.y][move.to.x] = move.player;

        const capturedPieces = this.detectCaptures(board, move.to, move.player);
        for (const captured of capturedPieces) {
            board[captured.y][captured.x] = null;
        }

        const recordedMove: RecordedMove = {
            matchId: move.matchId,
            from: { ...move.from },
            to: { ...move.to },
            player: move.player,
            capturedPieces: capturedPieces.map((position) => ({ ...position })),
        };
        const noCapturePly = capturedPieces.length > 0
            ? 0
            : gameState.noCapturePly + 1;
        const nextPlayer = this.opponent(move.player);

        let status: GameState['status'] = 'playing';
        let winner: GameWinner | undefined;
        let endReason: GameEndReason | undefined;
        let currentTurn = move.player;

        if (this.countPieces(board, nextPlayer) <= 1) {
            status = 'finished';
            winner = move.player;
            endReason = 'piece_count';
        } else if (noCapturePly >= NO_CAPTURE_DRAW_PLY) {
            status = 'finished';
            winner = 'draw';
            endReason = 'no_capture_limit';
        } else {
            currentTurn = nextPlayer;
            if (!this.hasLegalMoves(board, nextPlayer)) {
                status = 'finished';
                winner = move.player;
                endReason = 'no_legal_moves';
            }
        }

        return {
            state: {
                board,
                currentTurn,
                status,
                winner,
                endReason,
                moveHistory: [...gameState.moveHistory, recordedMove],
                noCapturePly,
                revision: gameState.revision + 1,
            },
            capturedPieces,
        };
    }

    public static detectCaptures(
        board: BoardState,
        movedPiece: Position,
        player: PieceColor,
    ): Position[] {
        if (!this.isWithinBounds(movedPiece)) return [];
        const row = Array.from(
            { length: BOARD_SIZE },
            (_, x) => ({ x, y: movedPiece.y }),
        );
        const column = Array.from(
            { length: BOARD_SIZE },
            (_, y) => ({ x: movedPiece.x, y }),
        );
        const captures: Position[] = [];
        const rowCapture = this.detectLineCapture(board, row, movedPiece, player);
        if (rowCapture) captures.push(rowCapture);
        const columnCapture = this.detectLineCapture(
            board,
            column,
            movedPiece,
            player,
        );
        if (columnCapture) captures.push(columnCapture);
        return captures;
    }

    public validateMove(gameState: GameState, move: MoveData): MoveValidation {
        return GameRules.validateMove(gameState, move);
    }

    public applyMove(
        gameState: GameState,
        move: MoveData,
    ): { newState: GameState; captured: Position[] } {
        const result = GameRules.applyMove(gameState, move);
        return { newState: result.state, captured: result.capturedPieces };
    }

    private static detectLineCapture(
        board: BoardState,
        line: Position[],
        movedPiece: Position,
        player: PieceColor,
    ): Position | undefined {
        const enemy = this.opponent(player);
        const pieces = line.map((position) => board[position.y][position.x]);
        const patterns: Array<{
            pieces: Array<PieceColor | null>;
            capturedIndex: number;
        }> = [
            { pieces: [player, player, enemy, null], capturedIndex: 2 },
            { pieces: [null, player, player, enemy], capturedIndex: 3 },
            { pieces: [null, enemy, player, player], capturedIndex: 1 },
            { pieces: [enemy, player, player, null], capturedIndex: 0 },
        ];

        for (const pattern of patterns) {
            if (pieces.every((piece, index) => piece === pattern.pieces[index])) {
                const movedIndex = line.findIndex(
                    (position) => this.samePosition(position, movedPiece),
                );
                if (movedIndex >= 0 && pattern.pieces[movedIndex] === player) {
                    return { ...line[pattern.capturedIndex] };
                }
            }
        }
        return undefined;
    }

    private static countPieces(board: BoardState, player: PieceColor): number {
        return board.reduce(
            (total, row) => total + row.filter((piece) => piece === player).length,
            0,
        );
    }

    private static hasLegalMoves(board: BoardState, player: PieceColor): boolean {
        for (let y = 0; y < BOARD_SIZE; y += 1) {
            for (let x = 0; x < BOARD_SIZE; x += 1) {
                if (board[y][x] !== player) continue;
                for (const [dx, dy] of [[1, 0], [-1, 0], [0, 1], [0, -1]]) {
                    const target = { x: x + dx, y: y + dy };
                    if (this.isWithinBounds(target)
                        && board[target.y][target.x] === null) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    private static opponent(player: PieceColor): PieceColor {
        return player === 'black' ? 'white' : 'black';
    }

    private static samePosition(left: Position, right: Position): boolean {
        return left.x === right.x && left.y === right.y;
    }

    private static isWithinBounds(position: Position): boolean {
        return position.x >= 0
            && position.x < BOARD_SIZE
            && position.y >= 0
            && position.y < BOARD_SIZE;
    }
}
