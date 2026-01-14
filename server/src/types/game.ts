export type Player = {
    id: string;
    socketId: string;
    name: string;
};

export type GameState = {
    board: any; // We can refine this later to match client's structure or keep it opaque
    currentTurn: string; // playerId
    status: 'playing' | 'finished';
    winner?: string;
};

export type Room = {
    id: string;
    players: [Player, Player]; // Fixed 2 players
    spectators: Player[];
    gameState: GameState;
    createdAt: number;
};
