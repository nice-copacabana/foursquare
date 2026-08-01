import assert from 'node:assert/strict';
import test from 'node:test';

import { GameRules } from './rules';
import { BoardState, GameState, PieceColor } from '../types/game';

const emptyBoard = (): BoardState =>
  Array.from({ length: 4 }, () => Array<PieceColor | null>(4).fill(null));

const playingState = (
  board: BoardState,
  overrides: Partial<GameState> = {},
): GameState => ({
  board,
  currentTurn: 'black',
  status: 'playing',
  moveHistory: [],
  noCapturePly: 0,
  revision: 0,
  ...overrides,
});

test('detects only an exact four-cell capture containing the moved piece', () => {
  const board = emptyBoard();
  board[0] = ['black', 'black', 'white', null];

  assert.deepEqual(
    GameRules.detectCaptures(board, { x: 1, y: 0 }, 'black'),
    [{ x: 2, y: 0 }],
  );
  assert.deepEqual(
    GameRules.detectCaptures(board, { x: 3, y: 3 }, 'black'),
    [],
  );

  board[0] = ['black', 'black', 'white', 'white'];
  assert.deepEqual(
    GameRules.detectCaptures(board, { x: 1, y: 0 }, 'black'),
    [],
  );
});

test('detects all four exact capture orientations', () => {
  const cases: Array<{
    line: Array<PieceColor | null>;
    movedX: number;
    capturedX: number;
  }> = [
    { line: ['black', 'black', 'white', null], movedX: 0, capturedX: 2 },
    { line: [null, 'black', 'black', 'white'], movedX: 2, capturedX: 3 },
    { line: [null, 'white', 'black', 'black'], movedX: 2, capturedX: 1 },
    { line: ['white', 'black', 'black', null], movedX: 1, capturedX: 0 },
  ];

  for (const captureCase of cases) {
    const board = emptyBoard();
    board[1] = captureCase.line;
    assert.deepEqual(
      GameRules.detectCaptures(
        board,
        { x: captureCase.movedX, y: 1 },
        'black',
      ),
      [{ x: captureCase.capturedX, y: 1 }],
    );
  }
});

test('records horizontal then vertical captures atomically', () => {
  const board = emptyBoard();
  board[1] = ['black', 'black', 'white', null];
  board[0][1] = 'black';
  board[2][1] = 'white';
  board[3][1] = null;

  assert.deepEqual(
    GameRules.detectCaptures(board, { x: 1, y: 1 }, 'black'),
    [
      { x: 2, y: 1 },
      { x: 1, y: 2 },
    ],
  );
});

test('50th no-capture ply is a draw before switching turn', () => {
  const board = GameRules.getInitialBoard();
  const result = GameRules.applyMove(
    playingState(board, { noCapturePly: 49 }),
    {
      matchId: 'match-1',
      from: { x: 0, y: 0 },
      to: { x: 0, y: 1 },
      player: 'black',
    },
  );

  assert.equal(result.state.status, 'finished');
  assert.equal(result.state.winner, 'draw');
  assert.equal(result.state.endReason, 'no_capture_limit');
  assert.equal(result.state.noCapturePly, 50);
  assert.equal(result.state.revision, 1);
});

test('opponent with one remaining piece loses immediately', () => {
  const board = emptyBoard();
  board[0] = ['black', null, 'white', null];
  board[1][1] = 'black';
  board[3][0] = 'white';

  const result = GameRules.applyMove(playingState(board), {
    matchId: 'match-2',
    from: { x: 1, y: 1 },
    to: { x: 1, y: 0 },
    player: 'black',
  });

  assert.equal(result.state.status, 'finished');
  assert.equal(result.state.winner, 'black');
  assert.equal(result.state.endReason, 'piece_count');
});

test('a capture resets the no-capture ply counter', () => {
  const board = emptyBoard();
  board[0] = ['black', null, 'white', null];
  board[1][1] = 'black';
  board[3] = ['white', 'white', 'white', null];

  const result = GameRules.applyMove(
    playingState(board, { noCapturePly: 37 }),
    {
      matchId: 'match-3',
      from: { x: 1, y: 1 },
      to: { x: 1, y: 0 },
      player: 'black',
    },
  );

  assert.deepEqual(result.capturedPieces, [{ x: 2, y: 0 }]);
  assert.equal(result.state.noCapturePly, 0);
  assert.deepEqual(result.state.moveHistory[0].capturedPieces, [
    { x: 2, y: 0 },
  ]);
});

test('a capture on the 50th candidate ply resets the counter and continues', () => {
  const board = emptyBoard();
  board[0] = ['black', null, 'white', null];
  board[1][1] = 'black';
  board[3] = ['white', 'white', 'white', null];

  const result = GameRules.applyMove(
    playingState(board, { noCapturePly: 49 }),
    {
      matchId: 'match-4',
      from: { x: 1, y: 1 },
      to: { x: 1, y: 0 },
      player: 'black',
    },
  );

  assert.equal(result.state.status, 'playing');
  assert.equal(result.state.currentTurn, 'white');
  assert.equal(result.state.noCapturePly, 0);
});

test('the next player loses when neither piece has a legal move', () => {
  const board = emptyBoard();
  board[0][0] = 'white';
  board[0][1] = 'black';
  board[1][0] = 'black';
  board[2][1] = 'black';
  board[2][3] = 'black';
  board[3][2] = 'black';
  board[3][3] = 'white';

  const result = GameRules.applyMove(playingState(board), {
    matchId: 'match-5',
    from: { x: 1, y: 2 },
    to: { x: 1, y: 1 },
    player: 'black',
  });

  assert.equal(result.state.status, 'finished');
  assert.equal(result.state.winner, 'black');
  assert.equal(result.state.endReason, 'no_legal_moves');
  assert.equal(result.state.noCapturePly, 1);
});

test('rejects a playing snapshot whose terminal invariants are already met', () => {
  const board = emptyBoard();
  board[0][0] = 'black';
  board[1][0] = 'white';
  board[3][3] = 'white';
  const state = playingState(board);

  assert.deepEqual(
    GameRules.validateMove(state, {
      matchId: 'invalid-snapshot',
      from: { x: 0, y: 0 },
      to: { x: 1, y: 0 },
      player: 'black',
    }),
    { valid: false, message: 'invalid_state' },
  );
  assert.deepEqual(
    GameRules.validateMove(
      playingState(GameRules.getInitialBoard(), { noCapturePly: 50 }),
      {
        matchId: 'invalid-draw-snapshot',
        from: { x: 0, y: 0 },
        to: { x: 0, y: 1 },
        player: 'black',
      },
    ),
    { valid: false, message: 'invalid_state' },
  );
});
