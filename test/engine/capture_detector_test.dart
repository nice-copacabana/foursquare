import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/engine/capture_detector.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/position.dart';

void main() {
  late CaptureDetector detector;

  setUp(() {
    detector = CaptureDetector();
  });

  group('完整四格吃子模式', () {
    test('四种合法横向排列均吃掉紧邻双子的对方棋子', () {
      const cases = <({
        List<PieceType> line,
        int movedIndex,
        int capturedIndex,
      })>[
        (
          line: [
            PieceType.black,
            PieceType.black,
            PieceType.white,
            PieceType.empty,
          ],
          movedIndex: 0,
          capturedIndex: 2,
        ),
        (
          line: [
            PieceType.empty,
            PieceType.black,
            PieceType.black,
            PieceType.white,
          ],
          movedIndex: 2,
          capturedIndex: 3,
        ),
        (
          line: [
            PieceType.empty,
            PieceType.white,
            PieceType.black,
            PieceType.black,
          ],
          movedIndex: 3,
          capturedIndex: 1,
        ),
        (
          line: [
            PieceType.white,
            PieceType.black,
            PieceType.black,
            PieceType.empty,
          ],
          movedIndex: 1,
          capturedIndex: 0,
        ),
      ];

      for (final testCase in cases) {
        final board = _withRow(testCase.line);

        expect(
          detector.detectCaptures(
            board,
            movedPiece: Position(testCase.movedIndex, 1),
            player: PieceType.black,
          ),
          [Position(testCase.capturedIndex, 1)],
        );
      }
    });

    test('1100、1110、0110和敌子不紧邻双子的排列均不吃子', () {
      const invalidLines = [
        [
          PieceType.black,
          PieceType.black,
          PieceType.white,
          PieceType.white,
        ],
        [
          PieceType.black,
          PieceType.black,
          PieceType.black,
          PieceType.white,
        ],
        [
          PieceType.white,
          PieceType.black,
          PieceType.black,
          PieceType.white,
        ],
        [
          PieceType.black,
          PieceType.black,
          PieceType.empty,
          PieceType.white,
        ],
        [
          PieceType.white,
          PieceType.empty,
          PieceType.black,
          PieceType.black,
        ],
      ];

      for (final line in invalidLines) {
        expect(
          detector.detectCaptures(
            _withRow(line),
            movedPiece: const Position(1, 1),
            player: PieceType.black,
          ),
          isEmpty,
        );
      }
    });

    test('移动棋子不属于相邻双子时不触发吃子', () {
      final board = _withRow(const [
        PieceType.black,
        PieceType.black,
        PieceType.white,
        PieceType.empty,
      ]);

      expect(
        detector.detectCaptures(
          board,
          movedPiece: const Position(2, 1),
          player: PieceType.black,
        ),
        isEmpty,
      );
    });

    test('同一移动横纵成立时按横向后纵向返回两个位置', () {
      final board = BoardState.initial()
          .setPiece(const Position(0, 1), PieceType.empty)
          .setPiece(const Position(1, 1), PieceType.black)
          .setPiece(const Position(2, 1), PieceType.black)
          .setPiece(const Position(3, 1), PieceType.white)
          .setPiece(const Position(1, 0), PieceType.black)
          .setPiece(const Position(1, 2), PieceType.white)
          .setPiece(const Position(1, 3), PieceType.empty);

      expect(
        detector.detectCaptures(
          board,
          movedPiece: const Position(1, 1),
          player: PieceType.black,
        ),
        const [Position(3, 1), Position(1, 2)],
      );
    });
  });

  group('输入边界', () {
    test('越界、空棋子类型和不属于移动方的落点均不吃子', () {
      final board = BoardState.initial();

      expect(
        detector.detectCaptures(
          board,
          movedPiece: const Position(-1, 0),
          player: PieceType.black,
        ),
        isEmpty,
      );
      expect(
        detector.detectCaptures(
          board,
          movedPiece: const Position(0, 0),
          player: PieceType.empty,
        ),
        isEmpty,
      );
      expect(
        detector.detectCaptures(
          board,
          movedPiece: const Position(0, 3),
          player: PieceType.black,
        ),
        isEmpty,
      );
    });
  });
}

BoardState _withRow(List<PieceType> pieces) {
  var board = BoardState.initial();
  for (var x = 0; x < pieces.length; x++) {
    board = board.setPiece(Position(x, 1), pieces[x]);
  }
  return board;
}
