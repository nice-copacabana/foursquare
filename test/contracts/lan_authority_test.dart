import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/game_result.dart';
import 'package:foursquare/models/lan_protocol.dart';
import 'package:foursquare/models/move.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/lan_authority.dart';

void main() {
  late _FakeClock clock;

  setUp(() {
    clock = _FakeClock(DateTime.utc(2026, 8, 1, 12));
  });

  group('LAN host authority move decisions', () {
    test('commits a valid move with a monotonic revision and absolute deadline',
        () {
      final host = _newHost(clock);

      final response = host.handleMoveIntent(
        _intent(from: const Position(0, 0), to: const Position(0, 1)),
        sender: PieceType.black,
      );

      expect(response, isA<LanMoveCommitted>());
      final committed = response as LanMoveCommitted;
      expect(committed.revision, 1);
      expect(committed.currentPlayer, PieceType.white);
      expect(
        committed.turnDeadlineUtc,
        DateTime.utc(2026, 8, 1, 12, 1),
      );
      expect(host.revision, 1);
      expect(host.moveHistory, hasLength(1));
      expect(committed.stateHash, host.createSnapshot().stateHash);
    });

    test('returns the original response for an idempotent command retry', () {
      final host = _newHost(clock);
      final intent = _intent(
        commandId: 'same-command',
        from: const Position(0, 0),
        to: const Position(0, 1),
      );

      final first = host.handleMoveIntent(intent, sender: PieceType.black);
      final retry = host.handleMoveIntent(intent, sender: PieceType.black);

      expect(retry, same(first));
      expect(host.revision, 1);
      expect(host.moveHistory, hasLength(1));
    });

    test('rejects command id reuse with different content', () {
      final host = _newHost(clock);
      host.handleMoveIntent(
        _intent(
          commandId: 'collision',
          from: const Position(0, 0),
          to: const Position(0, 1),
        ),
        sender: PieceType.black,
      );

      final response = host.handleMoveIntent(
        _intent(
          commandId: 'collision',
          expectedRevision: 1,
          from: const Position(1, 0),
          to: const Position(1, 1),
        ),
        sender: PieceType.white,
      );

      expect(
        (response as LanMoveRejected).reason,
        LanMoveRejectionReason.unauthorized,
      );
      expect(host.revision, 1);
    });

    test('rejects stale revision, wrong side, and illegal moves', () {
      final staleHost = _newHost(clock);
      final stale = staleHost.handleMoveIntent(
        _intent(expectedRevision: 2),
        sender: PieceType.black,
      );
      expect(
        (stale as LanMoveRejected).reason,
        LanMoveRejectionReason.staleRevision,
      );

      final wrongSideHost = _newHost(clock);
      final wrongSide = wrongSideHost.handleMoveIntent(
        _intent(),
        sender: PieceType.white,
      );
      expect(
        (wrongSide as LanMoveRejected).reason,
        LanMoveRejectionReason.wrongTurn,
      );

      final illegalHost = _newHost(clock);
      final illegal = illegalHost.handleMoveIntent(
        _intent(from: const Position(0, 0), to: const Position(0, 2)),
        sender: PieceType.black,
      );
      expect(
        (illegal as LanMoveRejected).reason,
        LanMoveRejectionReason.illegalMove,
      );
      expect(illegalHost.revision, 0);
    });

    test('commits horizontal and vertical captures atomically', () {
      final host = _hostFromBoard(clock, _doubleCaptureBoard());

      final response = host.handleMoveIntent(
        _intent(from: const Position(0, 1), to: const Position(1, 1)),
        sender: PieceType.black,
      );

      final committed = response as LanMoveCommitted;
      expect(
        committed.move.capturedPieces,
        const [Position(3, 1), Position(1, 2)],
      );
      expect(
        host.boardState.getPiece(const Position(3, 1)),
        PieceType.empty,
      );
      expect(
        host.boardState.getPiece(const Position(1, 2)),
        PieceType.empty,
      );
      expect(committed.noCapturePlyCount, 0);
    });

    test('the 50th no-capture ply commits a draw', () {
      final host = _hostFromBoard(
        clock,
        BoardState.initial(),
        noCapturePlyCount: 49,
      );

      final response = host.handleMoveIntent(
        _intent(from: const Position(0, 0), to: const Position(0, 1)),
        sender: PieceType.black,
      );

      final committed = response as LanMoveCommitted;
      expect(committed.noCapturePlyCount, 50);
      expect(committed.gameResult!.status, GameStatus.draw);
      expect(committed.gameResult!.endReason, GameEndReason.noCaptureLimit);
      expect(committed.turnDeadlineUtc, isNull);
    });

    test('commits a win when the next side has no legal move', () {
      final host = _hostFromBoard(clock, _noWhiteMoveBoard());

      final response = host.handleMoveIntent(
        _intent(from: const Position(1, 0), to: const Position(1, 1)),
        sender: PieceType.black,
      );

      final committed = response as LanMoveCommitted;
      expect(committed.gameResult!.winner, PieceType.black);
      expect(committed.gameResult!.endReason, GameEndReason.noLegalMoves);
      expect(committed.turnDeadlineUtc, isNull);
    });

    test('continues revision and history metadata from a restored snapshot',
        () {
      final previousMove = Move(
        from: const Position(0, 0),
        to: const Position(0, 1),
        player: PieceType.black,
        timestamp: DateTime(2026, 8, 1, 20),
      );
      final board = BoardState.initial()
          .movePiece(previousMove.from, previousMove.to)
          .switchPlayer();
      final snapshot = LanStateSnapshot(
        gameId: 'game-1',
        revision: 4,
        boardState: board,
        startingPlayer: PieceType.black,
        moveHistory: [previousMove],
        noCapturePlyCount: 49,
        turnDeadlineUtc: clock.now.add(const Duration(seconds: 60)),
        gameResult: null,
        stateHash: 'seed',
      );
      final host = LanHostAuthority.fromSnapshot(snapshot, clock: clock.call);

      final response = host.handleMoveIntent(
        _intent(
          commandId: 'command-5',
          expectedRevision: 4,
          from: const Position(0, 3),
          to: const Position(0, 2),
        ),
        sender: PieceType.white,
      );

      final committed = response as LanMoveCommitted;
      expect(committed.revision, 5);
      expect(committed.gameResult!.status, GameStatus.draw);
      expect(committed.gameResult!.moveCount, 2);
      expect(host.moveHistory.first.timestamp.isUtc, isTrue);
    });
  });

  group('LAN host authority time and reconnect decisions', () {
    test('accepts before 60 seconds and rejects at the absolute deadline', () {
      final beforeDeadline = _newHost(clock);
      clock.advance(const Duration(seconds: 59, milliseconds: 999));
      expect(
        beforeDeadline.handleMoveIntent(
          _intent(),
          sender: PieceType.black,
        ),
        isA<LanMoveCommitted>(),
      );

      clock = _FakeClock(DateTime.utc(2026, 8, 1, 12));
      final atDeadline = _newHost(clock);
      final originalDeadline = atDeadline.turnDeadlineUtc;
      clock.advance(const Duration(seconds: 60));
      final response = atDeadline.handleMoveIntent(
        _intent(),
        sender: PieceType.black,
      );

      expect(
        (response as LanMoveRejected).reason,
        LanMoveRejectionReason.gameFinished,
      );
      expect(atDeadline.gameResult!.endReason, GameEndReason.timeout);
      expect(atDeadline.gameResult!.winner, PieceType.white);
      expect(atDeadline.moveHistory, isEmpty);
      expect(atDeadline.revision, 1);
      expect(originalDeadline, DateTime.utc(2026, 8, 1, 12, 1));
    });

    test('reconnects before 30 seconds and returns a full snapshot', () {
      final host = _newHost(clock);
      final deadline = host.markDisconnected(PieceType.white);

      clock.advance(const Duration(seconds: 29, milliseconds: 999));
      final snapshot = host.markReconnected(PieceType.white);

      expect(deadline, DateTime.utc(2026, 8, 1, 12, 0, 30));
      expect(snapshot, isNotNull);
      expect(snapshot!.gameId, host.gameId);
      expect(snapshot.revision, host.revision);
      expect(snapshot.stateHash, host.stateHash);
      expect(host.gameResult, isNull);
      expect(host.disconnectDeadlineFor(PieceType.white), isNull);
    });

    test('disconnect at 30 seconds loses while the turn clock keeps running',
        () {
      final host = _newHost(clock);
      final originalTurnDeadline = host.turnDeadlineUtc;
      host.markDisconnected(PieceType.black);

      clock.advance(const Duration(seconds: 30));
      final result = host.tick();

      expect(result!.endReason, GameEndReason.disconnect);
      expect(result.winner, PieceType.white);
      expect(host.revision, 1);
      expect(host.turnDeadlineUtc, isNull);
      expect(originalTurnDeadline, DateTime.utc(2026, 8, 1, 12, 1));
      expect(host.markReconnected(PieceType.black), isNull);
    });

    test('earlier turn deadline wins over a later disconnect deadline', () {
      final snapshot = LanStateSnapshot(
        gameId: 'game-time-priority',
        revision: 0,
        boardState: BoardState.initial(),
        startingPlayer: PieceType.black,
        moveHistory: const [],
        noCapturePlyCount: 0,
        turnDeadlineUtc: clock.now.add(const Duration(seconds: 10)),
        gameResult: null,
        stateHash: 'seed',
      );
      final host = LanHostAuthority.fromSnapshot(snapshot, clock: clock.call);
      host.markDisconnected(PieceType.black);

      clock.advance(const Duration(seconds: 10));
      host.tick();

      expect(host.gameResult!.endReason, GameEndReason.timeout);
    });
  });

  test('snapshot JSON round-trip preserves the authority state and hash', () {
    final host = _newHost(clock);
    host.handleMoveIntent(_intent(), sender: PieceType.black);

    final snapshot = host.createSnapshot();
    final restored = LanProtocol.fromJsonString(snapshot.toJsonString());

    expect(restored, snapshot);
    expect((restored as LanStateSnapshot).stateHash, host.stateHash);
    expect(restored.revision, 1);
    expect(restored.moveHistory, hasLength(1));
  });
}

LanHostAuthority _newHost(_FakeClock clock) {
  return LanHostAuthority.newGame(
    gameId: 'game-1',
    startingPlayer: PieceType.black,
    clock: clock.call,
  );
}

LanHostAuthority _hostFromBoard(
  _FakeClock clock,
  BoardState board, {
  int noCapturePlyCount = 0,
}) {
  final snapshot = LanStateSnapshot(
    gameId: 'game-1',
    revision: 0,
    boardState: board,
    startingPlayer: board.currentPlayer,
    moveHistory: const [],
    noCapturePlyCount: noCapturePlyCount,
    turnDeadlineUtc: clock.now.add(const Duration(seconds: 60)),
    gameResult: null,
    stateHash: 'seed',
  );
  return LanHostAuthority.fromSnapshot(snapshot, clock: clock.call);
}

LanMoveIntent _intent({
  String commandId = 'command-1',
  int expectedRevision = 0,
  Position from = const Position(0, 0),
  Position to = const Position(0, 1),
}) {
  return LanMoveIntent(
    gameId: 'game-1',
    commandId: commandId,
    expectedRevision: expectedRevision,
    from: from,
    to: to,
  );
}

BoardState _doubleCaptureBoard() {
  return BoardState.initial()
      .setPiece(const Position(0, 1), PieceType.black)
      .setPiece(const Position(1, 1), PieceType.empty)
      .setPiece(const Position(2, 1), PieceType.black)
      .setPiece(const Position(3, 1), PieceType.white)
      .setPiece(const Position(1, 2), PieceType.white)
      .setPiece(const Position(1, 3), PieceType.empty);
}

BoardState _noWhiteMoveBoard() {
  var board = BoardState.initial();
  for (var y = 0; y < 4; y++) {
    for (var x = 0; x < 4; x++) {
      board = board.setPiece(Position(x, y), PieceType.black);
    }
  }
  return board
      .setPiece(const Position(0, 2), PieceType.white)
      .setPiece(const Position(2, 2), PieceType.white)
      .setPiece(const Position(3, 3), PieceType.white)
      .setPiece(const Position(1, 1), PieceType.empty);
}

class _FakeClock {
  DateTime now;

  _FakeClock(this.now);

  DateTime call() => now;

  void advance(Duration duration) {
    now = now.add(duration);
  }
}
