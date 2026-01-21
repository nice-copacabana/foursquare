export type Player = {
    id: string;
    socketId: string;
    name: string;
};

export type BoardState = (string | null)[][]; // 8x8 grid, null = empty, string = pieceId/type

export type GameState = {
    board: BoardState;
    currentTurn: string; // playerId
    status: 'playing' | 'finished';
    winner?: string;
    moveHistory: any[]; // Store moves for replay/validation
};

export type Room = {
    id: string;
    players: [Player, Player]; // Fixed 2 players
    spectators: Player[];
    gameState: GameState;
    createdAt: number;
    turnTimer?: NodeJS.Timeout; // Server-side timer
};
