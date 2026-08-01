import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/bloc/game_event.dart';
import 'package:foursquare/bloc/game_state.dart';
import 'package:foursquare/engine/capture_detector.dart';
import 'package:foursquare/engine/game_engine.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/game_result.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';

void main() {
  group('正式吃子规则', () {
    test('完整横排 1-1-0-E 吃掉相邻对方棋子', () {
      final board = BoardState.initial()
          .setPiece(const Position(0, 1), PieceType.black)
          .setPiece(const Position(1, 1), PieceType.black)
          .setPiece(const Position(2, 1), PieceType.white)
          .setPiece(const Position(3, 1), PieceType.empty);

      final captured = CaptureDetector().detectCaptures(
        board,
        movedPiece: const Position(0, 1),
        player: PieceType.black,
      );

      expect(captured, const [Position(2, 1)]);
    });

    test('四种允许的方向排列采用同一规则', () {
      const cases = <({
        List<PieceType> row,
        int movedX,
        Position captured,
      })>[
        (
          row: [
            PieceType.black,
            PieceType.black,
            PieceType.white,
            PieceType.empty,
          ],
          movedX: 0,
          captured: Position(2, 1),
        ),
        (
          row: [
            PieceType.empty,
            PieceType.black,
            PieceType.black,
            PieceType.white,
          ],
          movedX: 1,
          captured: Position(3, 1),
        ),
        (
          row: [
            PieceType.empty,
            PieceType.white,
            PieceType.black,
            PieceType.black,
          ],
          movedX: 2,
          captured: Position(1, 1),
        ),
        (
          row: [
            PieceType.white,
            PieceType.black,
            PieceType.black,
            PieceType.empty,
          ],
          movedX: 1,
          captured: Position(0, 1),
        ),
      ];

      for (final testCase in cases) {
        final captured = CaptureDetector().detectCaptures(
          _boardWithRow(testCase.row),
          movedPiece: Position(testCase.movedX, 1),
          player: PieceType.black,
        );

        expect(captured, [testCase.captured]);
      }
    });

    test('纵向使用与横向相同的完整四格规则', () {
      var board = BoardState.initial();
      const column = [
        PieceType.black,
        PieceType.black,
        PieceType.white,
        PieceType.empty,
      ];
      for (var y = 0; y < column.length; y++) {
        board = board.setPiece(Position(1, y), column[y]);
      }

      final captured = CaptureDetector().detectCaptures(
        board,
        movedPiece: const Position(1, 0),
        player: PieceType.black,
      );

      expect(captured, const [Position(1, 2)]);
    });

    test('一次落子横纵均成立时同时移除两个对方棋子', () {
      var board = BoardState.initial()
          .setPiece(const Position(0, 1), PieceType.black)
          .setPiece(const Position(1, 1), PieceType.empty)
          .setPiece(const Position(2, 1), PieceType.black)
          .setPiece(const Position(3, 1), PieceType.white)
          .setPiece(const Position(1, 2), PieceType.white)
          .setPiece(const Position(1, 3), PieceType.empty);

      final result = GameEngine().executeMove(
        board,
        const Position(0, 1),
        const Position(1, 1),
      );

      expect(result.success, isTrue);
      expect(
        result.capturedPieces,
        const [Position(3, 1), Position(1, 2)],
      );
      expect(
        result.move!.capturedPieces,
        const [Position(3, 1), Position(1, 2)],
      );
      board = result.newBoard!;
      expect(board.getPiece(const Position(3, 1)), PieceType.empty);
      expect(board.getPiece(const Position(1, 2)), PieceType.empty);
    });

    test('AI模拟移动与正式移动使用相同的双吃规则', () {
      final board = BoardState.initial()
          .setPiece(const Position(0, 1), PieceType.black)
          .setPiece(const Position(1, 1), PieceType.empty)
          .setPiece(const Position(2, 1), PieceType.black)
          .setPiece(const Position(3, 1), PieceType.white)
          .setPiece(const Position(1, 2), PieceType.white)
          .setPiece(const Position(1, 3), PieceType.empty);

      final simulated = GameEngine().simulateMove(
        board,
        const Position(0, 1),
        const Position(1, 1),
      );

      expect(simulated, isNotNull);
      expect(simulated!.getPiece(const Position(3, 1)), PieceType.empty);
      expect(simulated.getPiece(const Position(1, 2)), PieceType.empty);
    });
  });

  group('正式终局规则', () {
    test('轮到一方时没有合法移动则该方立即判负', () {
      var board = BoardState.initial();
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          board = board.setPiece(
            Position(x, y),
            (x + y).isEven ? PieceType.black : PieceType.white,
          );
        }
      }

      final result = GameEngine().checkGameOver(board);

      expect(result, isNotNull);
      expect(result!.winner, PieceType.white);
      expect(result.endReason, GameEndReason.noLegalMoves);
      expect(result.reason, contains('无合法移动'));
    });

    test('落子后切换到对方再判断其是否有合法移动', () {
      var board = BoardState.initial();
      for (var y = 0; y < 4; y++) {
        for (var x = 0; x < 4; x++) {
          board = board.setPiece(const Position(0, 0), PieceType.black);
          board = board.setPiece(Position(x, y), PieceType.black);
        }
      }
      board = board
          .setPiece(const Position(0, 2), PieceType.white)
          .setPiece(const Position(2, 2), PieceType.white)
          .setPiece(const Position(3, 3), PieceType.white)
          .setPiece(const Position(1, 1), PieceType.empty);

      final result = GameEngine().executeMove(
        board,
        const Position(1, 0),
        const Position(1, 1),
      );

      expect(result.gameOver, isTrue);
      expect(result.gameResult!.winner, PieceType.black);
      expect(result.gameResult!.reason, contains('无合法移动'));
    });

    test('第50个连续未吃子回合判和棋', () {
      final result = GameEngine().executeMove(
        BoardState.initial(),
        const Position(0, 0),
        const Position(0, 1),
        noCapturePlyCount: 49,
      );

      expect(result.noCapturePlyCount, 50);
      expect(result.gameOver, isTrue);
      expect(result.gameResult!.status, GameStatus.draw);
      expect(result.gameResult!.reason, contains('50'));
    });
  });

  group('对局状态', () {
    test('连续未吃子计数是可持久化的显式状态', () {
      final state = GamePlaying(
        boardState: BoardState.initial(),
        mode: GameMode.pvp,
        noCapturePlyCount: 49,
      );

      final next = state.copyWith(noCapturePlyCount: 50);

      expect(next.noCapturePlyCount, 50);
    });

    test('AI模式按玩家实际执色判断是否轮到AI', () {
      final state = GamePlaying(
        boardState: BoardState.initial(currentPlayer: PieceType.black),
        mode: GameMode.pve,
        humanPlayer: PieceType.white,
      );

      expect(state.isAITurn, isTrue);
    });
  });
}

BoardState _boardWithRow(List<PieceType> row) {
  var board = BoardState.initial();
  for (var x = 0; x < row.length; x++) {
    board = board.setPiece(Position(x, 1), row[x]);
  }
  return board;
}
