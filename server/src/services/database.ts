import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export class DatabaseService {
    constructor() { }

    // Find or create a user by username (using ID as username for MVP)
    async findOrCreateUser(userId: string, username?: string) {
        // For MVP, if we don't have authentication, we rely on the client sending a consistent ID
        // or we treat the client-provided ID as the unique key.
        // However, the Schema expects a UUID for ID. If client sends non-UUID, we might need adjustments.
        // Let's assume for MVP client sends something we can use, or we just map by username.

        // Simplification: We treat the 'userId' passed from client as 'username' in DB for now
        // and let DB auto-generate the real UUID.

        let user = await prisma.user.findUnique({
            where: { username: userId },
        });

        if (!user) {
            user = await prisma.user.create({
                data: {
                    username: userId, // client provided ID as username
                },
            });
        }

        return user;
    }

    async saveMatchResult(
        player1Id: string,
        player2Id: string,
        winnerId: string | null,
        moves: any[]
    ) {
        try {
            // Ensure users exist
            const p1 = await this.findOrCreateUser(player1Id);
            const p2 = await this.findOrCreateUser(player2Id);

            // Determine winner DB ID
            let winnerDbId = null;
            if (winnerId === player1Id) winnerDbId = p1.id;
            if (winnerId === player2Id) winnerDbId = p2.id;

            const match = await prisma.match.create({
                data: {
                    player1Id: p1.id,
                    player2Id: p2.id,
                    winnerId: winnerDbId,
                    status: 'finished',
                    movesJson: JSON.stringify(moves),
                    finishedAt: new Date(),
                },
            });

            console.log(`Match saved: ${match.id}`);
            return match;
        } catch (error) {
            console.error('Failed to save match result:', error);
            return null;
        }
    }
}

export const dbService = new DatabaseService();
