import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/online_protocol.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/online_authority_session.dart';

void main() {
  group('OnlineAuthoritySession', () {
    test('submitting a move does not mutate the authoritative board', () {
      final session = _session();
      final boardBefore = session.state.board;

      final intent = session.createMoveIntent(
        from: const Position(0, 0),
        to: const Position(0, 1),
      );

      expect(intent.commandId, 'command-1');
      expect(intent.expectedRevision, 0);
      expect(session.pendingCommandId, 'command-1');
      expect(session.state.revision, 0);
      expect(session.state.board, boardBefore);
      expect(session.state.board[0][0], OnlinePieceColor.black);
      expect(session.state.board[1][0], isNull);
    });

    test('matching authoritative commit applies once and clears pending', () {
      final session = _session();
      session.createMoveIntent(
        from: const Position(0, 0),
        to: const Position(0, 1),
      );

      final update = session.applyDecision(
        _committed(commandId: 'command-1', revision: 1),
      );

      expect(update, OnlineSessionUpdate.applied);
      expect(session.pendingCommandId, isNull);
      expect(session.state.revision, 1);
      expect(session.state.board[0][0], isNull);
      expect(session.state.board[1][0], OnlinePieceColor.black);

      expect(
        session.applyDecision(
          _committed(commandId: 'command-1', revision: 1),
        ),
        OnlineSessionUpdate.duplicate,
      );
      expect(session.state.revision, 1);
    });

    test('rejection leaves the board unchanged and exposes recovery need', () {
      final session = _session();
      final boardBefore = session.state.board;
      session.createMoveIntent(
        from: const Position(0, 0),
        to: const Position(0, 1),
      );

      final update = session.applyDecision(
        OnlineMoveDecision.fromJson({
          'type': 'rejected',
          'protocolVersion': 1,
          'commandId': 'command-1',
          'reason': 'stale_revision',
          'currentRevision': 2,
        }),
      );

      expect(update, OnlineSessionUpdate.requiresSnapshot);
      expect(session.pendingCommandId, isNull);
      expect(session.state.board, boardBefore);
      expect(session.state.revision, 0);
      expect(
        session.lastRejection,
        OnlineMoveRejectionReason.staleRevision,
      );
    });

    test('revision gaps require a snapshot instead of speculative replay', () {
      final session = _session();

      final update = session.applyDecision(
        _committed(commandId: 'opponent-command', revision: 2),
      );

      expect(update, OnlineSessionUpdate.requiresSnapshot);
      expect(session.state.revision, 0);

      expect(
        session.applySnapshot(_snapshot(revision: 2)),
        OnlineSessionUpdate.applied,
      );
      expect(session.state.revision, 2);
      expect(session.pendingCommandId, isNull);
    });

    test('a reconnect snapshot cannot change the assigned color', () {
      final session = _session();

      expect(
        () => session.applySnapshot(
          _snapshot(revision: 1, color: 'white'),
        ),
        throwsA(
          isA<OnlineSessionException>().having(
            (error) => error.error,
            'error',
            OnlineSessionError.colorChanged,
          ),
        ),
      );
      expect(session.color, OnlinePieceColor.black);
      expect(session.state.revision, 0);
    });

    test('server game over applies a full terminal state and clears pending',
        () {
      final session = _session();
      session.createMoveIntent(
        from: const Position(0, 0),
        to: const Position(0, 1),
      );

      final update = session.applyGameOver(
        matchId: 'match-1',
        state: OnlineGameState.fromJson({
          ..._stateJson(revision: 1, moved: false),
          'status': 'finished',
          'winner': 'white',
          'endReason': 'timeout',
        }),
      );

      expect(update, OnlineSessionUpdate.applied);
      expect(session.pendingCommandId, isNull);
      expect(session.state.status, OnlineGameStatus.finished);
      expect(session.state.winner, OnlineGameWinner.white);
      expect(session.state.endReason, OnlineGameEndReason.timeout);
    });

    test('the initial snapshot history must belong to the same match', () {
      final snapshot = OnlineStateSnapshot.fromJson({
        'protocolVersion': 1,
        'matchId': 'match-1',
        'color': 'black',
        'turnDeadlineEpochMs': 1785585720000,
        'opponentConnected': true,
        'state': {
          ..._stateJson(revision: 1, moved: true),
          'moveHistory': [
            {
              'matchId': 'different-match',
              'from': {'x': 0, 'y': 0},
              'to': {'x': 0, 'y': 1},
              'player': 'black',
              'capturedPieces': <Map<String, int>>[],
            },
          ],
        },
      });

      expect(
        () => OnlineAuthoritySession(snapshot: snapshot),
        throwsA(
          isA<OnlineSessionException>().having(
            (error) => error.error,
            'error',
            OnlineSessionError.stateMatchMismatch,
          ),
        ),
      );
    });
  });
}

OnlineAuthoritySession _session() => OnlineAuthoritySession(
      snapshot: _snapshot(revision: 0),
      commandIdGenerator: () => 'command-1',
    );

OnlineStateSnapshot _snapshot({
  required int revision,
  String color = 'black',
}) {
  return OnlineStateSnapshot.fromJson({
    'protocolVersion': 1,
    'matchId': 'match-1',
    'color': color,
    'turnDeadlineEpochMs': 1785585720000,
    'opponentConnected': true,
    'state': _stateJson(revision: revision, moved: revision > 0),
  });
}

OnlineMoveDecision _committed({
  required String commandId,
  required int revision,
}) {
  return OnlineMoveDecision.fromJson({
    'type': 'committed',
    'protocolVersion': 1,
    'commandId': commandId,
    'capturedPieces': <Map<String, int>>[],
    'turnDeadlineEpochMs': 1785585780000,
    'state': _stateJson(revision: revision, moved: true),
  });
}

Map<String, dynamic> _stateJson({
  required int revision,
  required bool moved,
}) {
  return {
    'board': [
      [moved ? null : 'black', 'black', 'black', 'black'],
      [moved ? 'black' : null, null, null, null],
      [null, null, null, null],
      ['white', 'white', 'white', 'white'],
    ],
    'currentTurn': moved ? 'white' : 'black',
    'status': 'playing',
    'moveHistory': moved
        ? [
            {
              'matchId': 'match-1',
              'from': {'x': 0, 'y': 0},
              'to': {'x': 0, 'y': 1},
              'player': 'black',
              'capturedPieces': <Map<String, int>>[],
            },
          ]
        : <Map<String, dynamic>>[],
    'noCapturePly': moved ? 1 : 0,
    'revision': revision,
  };
}
