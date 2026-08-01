import { PrismaClient } from '@prisma/client';
import type {
    GameEndReason,
    GameWinner,
    PieceColor,
    RecordedMove,
} from '../types/game';

type FinishedMatchRecord = {
    matchId: string;
    protocolVersion: number;
    player1Id: string;
    player2Id: string;
    winner: GameWinner;
    startingPlayer: PieceColor;
    endReason: GameEndReason;
    revision: number;
    moves: RecordedMove[];
};

const prisma = new PrismaClient();

export class DatabaseService {
    constructor() { }

    async findOrCreateUser(userId: string) {
        return prisma.user.upsert({
            where: { username: userId },
            update: {},
            create: { username: userId },
        });
    }

    async saveMatchResult(record: FinishedMatchRecord) {
        const [p1, p2] = await Promise.all([
            this.findOrCreateUser(record.player1Id),
            this.findOrCreateUser(record.player2Id),
        ]);
        const winnerDbId = record.winner === 'black'
            ? p1.id
            : record.winner === 'white'
                ? p2.id
                : null;

        return prisma.match.upsert({
            where: { externalId: record.matchId },
            update: {},
            create: {
                externalId: record.matchId,
                protocolVersion: record.protocolVersion,
                player1Id: p1.id,
                player2Id: p2.id,
                winnerId: winnerDbId,
                startingPlayer: record.startingPlayer,
                endReason: record.endReason,
                revision: record.revision,
                status: 'finished',
                movesJson: JSON.stringify(record.moves),
                finishedAt: new Date(),
            },
        });
    }
}

export const dbService = new DatabaseService();
