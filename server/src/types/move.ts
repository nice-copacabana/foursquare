import type { PieceColor } from './game';

export type Position = {
    x: number;
    y: number;
};

export type MoveData = {
    matchId: string;
    from: Position;
    to: Position;
    player: PieceColor;
};
