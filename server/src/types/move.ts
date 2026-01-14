export type Position = {
    x: number;
    y: number;
};

export type MoveData = {
    matchId: string;
    from: Position;
    to: Position;
    player: string; // 'black' | 'white' or playerId
    capturedPiece?: Position;
};
