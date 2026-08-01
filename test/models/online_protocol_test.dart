import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/online_protocol.dart';
import 'package:foursquare/models/position.dart';

void main() {
  group('online protocol contract', () {
    test('move intent contains only identity, revision and coordinates', () {
      final intent = OnlineMoveIntent(
        matchId: 'match-1',
        commandId: 'command-1',
        expectedRevision: 7,
        from: const Position(0, 0),
        to: const Position(0, 1),
      );

      expect(intent.protocolVersion, OnlineProtocol.currentVersion);
      expect(intent.toJson(), {
        'protocolVersion': OnlineProtocol.currentVersion,
        'matchId': 'match-1',
        'commandId': 'command-1',
        'expectedRevision': 7,
        'from': {'x': 0, 'y': 0},
        'to': {'x': 0, 'y': 1},
      });
      expect(intent.toJson(), isNot(contains('color')));
      expect(intent.toJson(), isNot(contains('player')));
      expect(intent.toJson(), isNot(contains('capturedPieces')));
      expect(intent.toJson(), isNot(contains('winner')));
      expect(intent.toJson(), isNot(contains('endReason')));
    });

    test('committed parses authoritative state and full capture list', () {
      final decision = OnlineMoveDecision.fromJson({
        'type': 'committed',
        'protocolVersion': 1,
        'commandId': 'command-1',
        'capturedPieces': [
          {'x': 2, 'y': 1},
          {'x': 1, 'y': 2},
        ],
        'turnDeadlineEpochMs': 1785585660000,
        'state': _finishedStateJson(),
      });

      expect(decision, isA<OnlineMoveCommitted>());
      final committed = decision as OnlineMoveCommitted;
      expect(committed.state.revision, 12);
      expect(committed.state.noCapturePly, 0);
      expect(committed.turnDeadlineEpochMs, 1785585660000);
      expect(committed.capturedPieces, const [
        Position(2, 1),
        Position(1, 2),
      ]);
      expect(committed.state.moveHistory.single.capturedPieces, const [
        Position(2, 1),
        Position(1, 2),
      ]);
      expect(committed.state.status, OnlineGameStatus.finished);
      expect(committed.state.winner, OnlineGameWinner.black);
      expect(committed.state.endReason, OnlineGameEndReason.pieceCount);
    });

    test('rejected parses stable reason and current revision', () {
      final decision = OnlineMoveDecision.fromJson({
        'type': 'rejected',
        'protocolVersion': 1,
        'commandId': 'command-2',
        'reason': 'stale_revision',
        'currentRevision': 15,
      });

      expect(decision, isA<OnlineMoveRejected>());
      final rejected = decision as OnlineMoveRejected;
      expect(rejected.reason, OnlineMoveRejectionReason.staleRevision);
      expect(rejected.currentRevision, 15);
    });

    test('gateway protocol and payload rejections use stable reasons', () {
      for (final reason in ['invalid_protocol', 'invalid_payload']) {
        final decision = OnlineMoveDecision.fromJson({
          'type': 'rejected',
          'protocolVersion': 1,
          'commandId': 'command-gateway',
          'reason': reason,
          'currentRevision': 0,
        }) as OnlineMoveRejected;

        expect(decision.reason.wireName, reason);
      }
    });

    test('snapshot parses complete authoritative recovery state', () {
      final snapshot = OnlineStateSnapshot.fromJson({
        'protocolVersion': 1,
        'matchId': 'match-1',
        'color': 'white',
        'turnDeadlineEpochMs': 1785585720000,
        'opponentConnected': false,
        'opponentReconnectDeadlineEpochMs': 1785585690000,
        'state': _playingStateJson(),
      });

      expect(snapshot.matchId, 'match-1');
      expect(snapshot.color, OnlinePieceColor.white);
      expect(snapshot.state.revision, 11);
      expect(snapshot.state.noCapturePly, 49);
      expect(snapshot.state.currentTurn, OnlinePieceColor.white);
      expect(snapshot.state.endReason, isNull);
      expect(snapshot.turnDeadlineEpochMs, 1785585720000);
      expect(snapshot.opponentConnected, isFalse);
      expect(snapshot.opponentReconnectDeadlineEpochMs, 1785585690000);
    });

    test('wire identifiers are bounded and contain only safe characters', () {
      expect(
        () => OnlineMoveIntent(
          matchId: 'm' * 129,
          commandId: 'command-1',
          expectedRevision: 0,
          from: const Position(0, 0),
          to: const Position(0, 1),
        ),
        throwsA(isA<OnlineProtocolException>()),
      );
      expect(
        () => OnlineMoveIntent(
          matchId: 'match-1',
          commandId: 'contains spaces',
          expectedRevision: 0,
          from: const Position(0, 0),
          to: const Position(0, 1),
        ),
        throwsA(isA<OnlineProtocolException>()),
      );
    });

    test('unsupported protocol version is rejected before payload parsing', () {
      expect(
        () => OnlineMoveDecision.fromJson({
          'type': 'rejected',
          'protocolVersion': 2,
          'commandId': 'command-3',
          'reason': 'wrong_turn',
          'currentRevision': 1,
        }),
        throwsA(isA<OnlineProtocolException>()),
      );
    });

    test('a finished state requires both winner and end reason', () {
      final missingWinner = Map<String, dynamic>.from(_finishedStateJson())
        ..remove('winner');

      expect(
        () => OnlineGameState.fromJson(missingWinner),
        throwsA(
          isA<OnlineProtocolException>().having(
            (error) => error.error,
            'error',
            OnlineProtocolError.missingField,
          ),
        ),
      );
    });

    test('terminal winner and end reason must be semantically consistent', () {
      final drawByTimeout = Map<String, dynamic>.from(_finishedStateJson())
        ..['winner'] = 'draw'
        ..['endReason'] = 'timeout';
      final winByNoCapture = Map<String, dynamic>.from(_finishedStateJson())
        ..['winner'] = 'black'
        ..['endReason'] = 'no_capture_limit';

      expect(
        () => OnlineGameState.fromJson(drawByTimeout),
        throwsA(isA<OnlineProtocolException>()),
      );
      expect(
        () => OnlineGameState.fromJson(winByNoCapture),
        throwsA(isA<OnlineProtocolException>()),
      );
    });
  });
}

Map<String, dynamic> _playingStateJson() => {
      'board': [
        ['black', 'black', 'black', 'black'],
        [null, null, null, null],
        [null, null, null, null],
        ['white', 'white', 'white', 'white'],
      ],
      'currentTurn': 'white',
      'status': 'playing',
      'moveHistory': <Map<String, dynamic>>[],
      'noCapturePly': 49,
      'revision': 11,
    };

Map<String, dynamic> _finishedStateJson() => {
      'board': [
        ['black', 'black', 'black', null],
        [null, 'black', null, null],
        [null, null, null, null],
        ['white', null, null, null],
      ],
      'currentTurn': 'black',
      'status': 'finished',
      'winner': 'black',
      'endReason': 'piece_count',
      'moveHistory': [
        {
          'matchId': 'match-1',
          'from': {'x': 1, 'y': 0},
          'to': {'x': 1, 'y': 1},
          'player': 'black',
          'capturedPieces': [
            {'x': 2, 'y': 1},
            {'x': 1, 'y': 2},
          ],
        },
      ],
      'noCapturePly': 0,
      'revision': 12,
    };
