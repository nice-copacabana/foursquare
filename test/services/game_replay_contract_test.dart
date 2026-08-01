import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/move.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/services/game_replay_service.dart';

void main() {
  test('回放使用真实先手并在每一步后切换行棋方', () {
    final move = Move.now(
      from: const Position(0, 3),
      to: const Position(0, 2),
      player: PieceType.white,
    );
    final service = GameReplayService();

    final initial = service.startReplay(
      [move],
      startingPlayer: PieceType.white,
    );
    final afterMove = service.goForward();

    expect(initial.boardState.currentPlayer, PieceType.white);
    expect(afterMove.boardState.currentPlayer, PieceType.black);
  });

  test('回放严格移除记录中的全部被吃棋子', () {
    final move = Move.now(
      from: const Position(0, 0),
      to: const Position(0, 1),
      player: PieceType.black,
      capturedPieces: const [Position(0, 3), Position(1, 3)],
    );
    final service = GameReplayService()..startReplay([move]);

    final afterMove = service.goForward();

    expect(
      afterMove.boardState.getPiece(const Position(0, 3)),
      PieceType.empty,
    );
    expect(
      afterMove.boardState.getPiece(const Position(1, 3)),
      PieceType.empty,
    );
  });

  test('因棋子数终局的最后一步不会错误切换行棋方', () {
    final terminalMove = Move.now(
      from: const Position(0, 0),
      to: const Position(0, 1),
      player: PieceType.black,
      capturedPieces: const [
        Position(0, 3),
        Position(1, 3),
        Position(2, 3),
      ],
    );
    final service = GameReplayService()..startReplay([terminalMove]);

    final terminal = service.goToEnd();

    expect(terminal.boardState.currentPlayer, PieceType.black);
    expect(terminal.boardState.getPieceCount(PieceType.white), 1);
  });
}
