import type { Position } from './move';

export type Player = {
    id: string;
    socketId: string;
    name: string;
};

export type PieceColor = 'black' | 'white';
export type GameWinner = PieceColor | 'draw';
export type GameEndReason =
    | 'piece_count'
    | 'no_capture_limit'
    | 'no_legal_moves'
    | 'timeout'
    | 'disconnect'
    | 'abandoned';

export type BoardState = (PieceColor | null)[][];

export type RecordedMove = {
    matchId: string;
    from: Position;
    to: Position;
    player: PieceColor;
    capturedPieces: Position[];
};

export type GameState = {
    board: BoardState;
    currentTurn: PieceColor;
    status: 'playing' | 'finished';
    winner?: GameWinner;
    endReason?: GameEndReason;
    moveHistory: RecordedMove[];
    noCapturePly: number;
    revision: number;
};

export type Room = {
    id: string;
    players: [Player, Player];
    spectators: Player[];
    gameState: GameState;
    colorBySocketId: Record<string, PieceColor>;
    startingPlayer: PieceColor;
    turnDeadlineEpochMs: number;
    createdAt: number;
    turnTimer?: unknown;
    cleanupTimer?: unknown;
};
