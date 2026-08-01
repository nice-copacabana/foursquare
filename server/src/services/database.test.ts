import assert from 'node:assert/strict';
import test from 'node:test';

import { DatabaseService } from './database';

test('finished match persistence is idempotent and maps the winner by color', async () => {
    const userCalls: unknown[] = [];
    const matchCalls: Array<{
        where: { externalId: string };
        update: Record<string, never>;
        create: Record<string, unknown>;
    }> = [];
    const client = {
        user: {
            upsert: async (args: {
                where: { username: string };
                update: Record<string, never>;
                create: { username: string };
            }) => {
                userCalls.push(args);
                return { id: `db-${args.where.username}` };
            },
        },
        match: {
            upsert: async (args: {
                where: { externalId: string };
                update: Record<string, never>;
                create: Record<string, unknown>;
            }) => {
                matchCalls.push(args);
                return { id: 'db-match-1' };
            },
        },
    };
    const service = new DatabaseService(client);
    const record = {
        matchId: 'match-persisted-1',
        protocolVersion: 1,
        player1Id: 'device-first',
        player2Id: 'device-second',
        winner: 'black' as const,
        startingPlayer: 'white' as const,
        endReason: 'piece_count' as const,
        revision: 9,
        moves: [
            {
                matchId: 'match-persisted-1',
                from: { x: 1, y: 0 },
                to: { x: 1, y: 1 },
                player: 'black' as const,
                capturedPieces: [
                    { x: 2, y: 1 },
                    { x: 1, y: 2 },
                ],
            },
        ],
    };

    await service.saveMatchResult(record);
    await service.saveMatchResult(record);

    assert.equal(userCalls.length, 4);
    assert.equal(matchCalls.length, 2);
    for (const call of matchCalls) {
        assert.deepEqual(call.where, { externalId: record.matchId });
        assert.deepEqual(call.update, {});
        assert.equal(call.create.externalId, record.matchId);
        assert.equal(call.create.player1Id, 'db-device-first');
        assert.equal(call.create.player2Id, 'db-device-second');
        assert.equal(call.create.winnerId, 'db-device-first');
        assert.equal(call.create.startingPlayer, 'white');
        assert.equal(call.create.endReason, 'piece_count');
        assert.equal(call.create.revision, 9);
        assert.deepEqual(JSON.parse(call.create.movesJson as string), record.moves);
    }
});

test('a draw persists no winner relation', async () => {
    let persisted: Record<string, unknown> | undefined;
    const service = new DatabaseService({
        user: {
            upsert: async (args) => ({ id: `db-${args.where.username}` }),
        },
        match: {
            upsert: async (args) => {
                persisted = args.create;
                return { id: 'db-draw' };
            },
        },
    });

    await service.saveMatchResult({
        matchId: 'match-draw',
        protocolVersion: 1,
        player1Id: 'device-first',
        player2Id: 'device-second',
        winner: 'draw',
        startingPlayer: 'black',
        endReason: 'no_capture_limit',
        revision: 50,
        moves: [],
    });

    assert.equal(persisted?.winnerId, null);
});
