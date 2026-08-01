import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/game_result.dart';
import 'package:foursquare/models/lan_protocol.dart';
import 'package:foursquare/models/move.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';

void main() {
  final deadline = DateTime.utc(2026, 8, 1, 12, 1);
  final move = Move(
    from: const Position(1, 0),
    to: const Position(1, 1),
    player: PieceType.black,
    capturedPieces: const [Position(3, 1), Position(1, 3)],
    timestamp: DateTime.utc(2026, 8, 1, 12),
  );

  group('LAN protocol JSON contracts', () {
    test('moveIntent round-trips required authority fields', () {
      final message = LanMoveIntent(
        gameId: 'game-1',
        commandId: 'command-1',
        expectedRevision: 7,
        from: const Position(0, 0),
        to: const Position(0, 1),
      );

      final json = message.toJson();
      final restored = LanProtocol.fromJson(json);

      expect(json['protocolVersion'], LanProtocol.currentVersion);
      expect(json['gameId'], 'game-1');
      expect(json['commandId'], 'command-1');
      expect(json['expectedRevision'], 7);
      expect(json.containsKey('player'), isFalse);
      expect(restored, message);
    });

    test('moveCommitted preserves both captures and ongoing turn state', () {
      final message = LanMoveCommitted(
        gameId: 'game-1',
        commandId: 'command-1',
        revision: 8,
        move: move,
        noCapturePlyCount: 0,
        currentPlayer: PieceType.white,
        turnDeadlineUtc: deadline,
        gameResult: null,
        stateHash: 'sha256:state-8',
      );

      final restored = LanProtocol.fromJsonString(message.toJsonString());

      expect(restored, message);
      expect(restored, isA<LanMoveCommitted>());
      expect(
        (restored as LanMoveCommitted).move.capturedPieces,
        const [Position(3, 1), Position(1, 3)],
      );
      expect(restored.turnDeadlineUtc, deadline);
    });

    test('terminal moveCommitted preserves GameResult and has no deadline', () {
      final result = GameResult.blackWin(
        reason: '白方仅剩一子',
        endReason: GameEndReason.pieceCount,
        moveCount: 12,
        duration: const Duration(minutes: 3),
      );
      final message = LanMoveCommitted(
        gameId: 'game-1',
        commandId: 'command-12',
        revision: 12,
        move: move,
        noCapturePlyCount: 0,
        currentPlayer: PieceType.black,
        turnDeadlineUtc: null,
        gameResult: result,
        stateHash: 'sha256:terminal',
      );

      final restored = LanProtocol.fromJson(message.toJson());

      expect(restored, message);
      expect((restored as LanMoveCommitted).gameResult, result);
    });

    test('moveRejected round-trips stable rejection reason and revision', () {
      final message = LanMoveRejected(
        gameId: 'game-1',
        commandId: 'command-stale',
        revision: 9,
        reason: LanMoveRejectionReason.staleRevision,
      );

      expect(LanProtocol.fromJson(message.toJson()), message);
    });

    test('stateSnapshot round-trips full authoritative state', () {
      final snapshotMove = Move(
        from: const Position(0, 0),
        to: const Position(0, 1),
        player: PieceType.black,
        timestamp: DateTime.utc(2026, 8, 1, 12),
      );
      final board = BoardState.initial()
          .movePiece(snapshotMove.from, snapshotMove.to)
          .switchPlayer();
      final message = LanStateSnapshot(
        gameId: 'game-1',
        revision: 3,
        boardState: board,
        startingPlayer: PieceType.black,
        moveHistory: [snapshotMove],
        noCapturePlyCount: 4,
        turnDeadlineUtc: deadline,
        gameResult: null,
        stateHash: 'sha256:snapshot-3',
      );

      final encoded = jsonEncode(message.toJson());
      final restored = LanProtocol.fromJsonString(encoded);

      expect(restored, message);
      expect((restored as LanStateSnapshot).currentPlayer, PieceType.white);
      expect(restored.moveHistory.single.captureCount, 0);
    });
  });

  group('LAN protocol rejection and validation', () {
    test('rejects payloads without protocolVersion', () {
      final json = LanMoveIntent(
        gameId: 'game-1',
        commandId: 'command-1',
        expectedRevision: 0,
        from: const Position(0, 0),
        to: const Position(0, 1),
      ).toJson()
        ..remove('protocolVersion');

      expect(
        () => LanProtocol.fromJson(json),
        throwsA(
          isA<LanProtocolException>().having(
            (error) => error.error,
            'error',
            LanProtocolError.missingProtocolVersion,
          ),
        ),
      );
    });

    test('rejects older and newer protocol versions', () {
      final valid = LanMoveIntent(
        gameId: 'game-1',
        commandId: 'command-1',
        expectedRevision: 0,
        from: const Position(0, 0),
        to: const Position(0, 1),
      ).toJson();

      for (final version in [0, LanProtocol.currentVersion + 1]) {
        expect(
          () => LanProtocol.fromJson({...valid, 'protocolVersion': version}),
          throwsA(
            isA<LanProtocolException>().having(
              (error) => error.error,
              'error',
              LanProtocolError.unsupportedProtocolVersion,
            ),
          ),
        );
      }
    });

    test('rejects negative expectedRevision and committed revision zero', () {
      expect(
        () => LanMoveIntent(
          gameId: 'game-1',
          commandId: 'command-1',
          expectedRevision: -1,
          from: const Position(0, 0),
          to: const Position(0, 1),
        ),
        throwsA(isA<LanProtocolException>()),
      );
      expect(
        () => LanMoveCommitted(
          gameId: 'game-1',
          commandId: 'command-1',
          revision: 0,
          move: move,
          noCapturePlyCount: 0,
          currentPlayer: PieceType.white,
          turnDeadlineUtc: deadline,
          gameResult: null,
          stateHash: 'hash',
        ),
        throwsA(isA<LanProtocolException>()),
      );
    });

    test('rejects blank identifiers and out-of-board move coordinates', () {
      expect(
        () => LanMoveIntent(
          gameId: ' ',
          commandId: 'command-1',
          expectedRevision: 0,
          from: const Position(0, 0),
          to: const Position(0, 1),
        ),
        throwsA(isA<LanProtocolException>()),
      );
      expect(
        () => LanMoveIntent(
          gameId: 'game-1',
          commandId: 'command-1',
          expectedRevision: 0,
          from: const Position(0, 0),
          to: const Position(0, 4),
        ),
        throwsA(isA<LanProtocolException>()),
      );
    });

    test(
        'keeps structurally valid illegal intents available for host rejection',
        () {
      final intent = LanMoveIntent(
        gameId: 'game-1',
        commandId: 'command-illegal',
        expectedRevision: 3,
        from: const Position(0, 0),
        to: const Position(0, 2),
      );

      expect(LanProtocol.fromJson(intent.toJson()), intent);
    });

    test('rejects legacy single-capture move payload', () {
      final json = LanMoveCommitted(
        gameId: 'game-1',
        commandId: 'command-1',
        revision: 1,
        move: move,
        noCapturePlyCount: 0,
        currentPlayer: PieceType.white,
        turnDeadlineUtc: deadline,
        gameResult: null,
        stateHash: 'hash',
      ).toJson();
      final moveJson = json['move'] as Map<String, dynamic>;
      moveJson
        ..remove('capturedPieces')
        ..['capturedPiece'] = {'x': 3, 'y': 1};

      expect(
        () => LanProtocol.fromJson(json),
        throwsA(
          isA<LanProtocolException>().having(
            (error) => error.error,
            'error',
            LanProtocolError.missingField,
          ),
        ),
      );
    });

    test('rejects invalid counters, players, hashes, and deadlines', () {
      final valid = LanMoveCommitted(
        gameId: 'game-1',
        commandId: 'command-1',
        revision: 1,
        move: move,
        noCapturePlyCount: 0,
        currentPlayer: PieceType.white,
        turnDeadlineUtc: deadline,
        gameResult: null,
        stateHash: 'hash',
      ).toJson();

      for (final mutation in <Map<String, dynamic>>[
        {...valid, 'noCapturePlyCount': -1},
        {...valid, 'noCapturePlyCount': 51},
        {...valid, 'noCapturePlyCount': 50},
        {...valid, 'currentPlayer': 'empty'},
        {...valid, 'stateHash': ' '},
        {...valid, 'turnDeadlineUtc': '2026-08-01T12:01:00'},
        {...valid, 'turnDeadlineUtc': null},
      ]) {
        expect(
          () => LanProtocol.fromJson(mutation),
          throwsA(isA<LanProtocolException>()),
        );
      }
    });

    test('rejects malformed stateSnapshot board and unknown type', () {
      final snapshot = LanStateSnapshot(
        gameId: 'game-1',
        revision: 0,
        boardState: BoardState.initial(),
        startingPlayer: PieceType.black,
        moveHistory: const [],
        noCapturePlyCount: 0,
        turnDeadlineUtc: deadline,
        gameResult: null,
        stateHash: 'initial',
      ).toJson();
      final boardJson = snapshot['boardState'] as Map<String, dynamic>;
      boardJson['grid'] = [
        ['black'],
      ];

      expect(
        () => LanProtocol.fromJson(snapshot),
        throwsA(isA<LanProtocolException>()),
      );
      expect(
        () => LanProtocol.fromJson({
          'protocolVersion': LanProtocol.currentVersion,
          'type': 'legacyMove',
          'gameId': 'game-1',
        }),
        throwsA(
          isA<LanProtocolException>().having(
            (error) => error.error,
            'error',
            LanProtocolError.unknownMessageType,
          ),
        ),
      );
    });

    test('rejects an ongoing snapshot when either side has at most one piece',
        () {
      final board = BoardState.initial()
          .removePiece(const Position(1, 0))
          .removePiece(const Position(2, 0))
          .removePiece(const Position(3, 0));

      expect(
        () => LanStateSnapshot(
          gameId: 'game-terminal-board',
          revision: 4,
          boardState: board,
          startingPlayer: PieceType.black,
          moveHistory: const [],
          noCapturePlyCount: 3,
          turnDeadlineUtc: deadline,
          gameResult: null,
          stateHash: 'invalid-ongoing-piece-count',
        ),
        throwsA(
          isA<LanProtocolException>().having(
            (error) => error.error,
            'error',
            LanProtocolError.invalidField,
          ),
        ),
      );
    });

    test('rejects an ongoing snapshot when the current side has no legal move',
        () {
      const board = BoardState(
        grid: [
          [
            PieceType.white,
            PieceType.black,
            PieceType.empty,
            PieceType.empty,
          ],
          [
            PieceType.black,
            PieceType.empty,
            PieceType.empty,
            PieceType.empty,
          ],
          [
            PieceType.empty,
            PieceType.empty,
            PieceType.empty,
            PieceType.black,
          ],
          [
            PieceType.empty,
            PieceType.empty,
            PieceType.black,
            PieceType.white,
          ],
        ],
        blackPieces: [
          Position(1, 0),
          Position(0, 1),
          Position(3, 2),
          Position(2, 3),
        ],
        whitePieces: [Position(0, 0), Position(3, 3)],
        currentPlayer: PieceType.white,
      );

      expect(
        () => LanStateSnapshot(
          gameId: 'game-no-moves',
          revision: 7,
          boardState: board,
          startingPlayer: PieceType.black,
          moveHistory: const [],
          noCapturePlyCount: 8,
          turnDeadlineUtc: deadline,
          gameResult: null,
          stateHash: 'invalid-ongoing-no-moves',
        ),
        throwsA(isA<LanProtocolException>()),
      );
    });
  });
}
