/// Board Widget Test - 棋盘组件测试
///
/// 测试范围：
/// - 棋盘渲染
/// - 用户交互
/// - 棋子显示
/// - 选中状态
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ui/widgets/board_widget.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/models/position.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/theme/packs/modern_eastern_theme_pack.dart';
import 'package:foursquare/ui/widgets/board_painter.dart';

void main() {
  group('BoardWidget', () {
    testWidgets('应该正确渲染初始棋盘', (WidgetTester tester) async {
      final boardState = BoardState.initial();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoardWidget(
              boardState: boardState,
              onPositionTapped: (_) {},
            ),
          ),
        ),
      );

      // 验证组件渲染
      expect(find.byType(BoardWidget), findsOneWidget);
      // BoardWidget内部使用CustomPaint绘制，可能被RepaintBoundary包装
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('点击棋盘应该触发回调', (WidgetTester tester) async {
      Position? tappedPosition;
      final boardState = BoardState.initial();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: BoardWidget(
                  boardState: boardState,
                  onPositionTapped: (pos) => tappedPosition = pos,
                ),
              ),
            ),
          ),
        ),
      );

      // 点击棋盘中心（应该在Position(2,2)附近）
      await tester.tapAt(const Offset(200, 200));
      await tester.pump();

      expect(tappedPosition, isNotNull);
    });

    testWidgets('应该显示选中的棋子', (WidgetTester tester) async {
      final boardState = BoardState.initial();
      const selectedPiece = Position(0, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoardWidget(
              boardState: boardState,
              selectedPiece: selectedPiece,
              onPositionTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(BoardWidget), findsOneWidget);
    });

    testWidgets('应该显示合法移动提示', (WidgetTester tester) async {
      final boardState = BoardState.initial();
      const validMoves = [Position(0, 1), Position(1, 0)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoardWidget(
              boardState: boardState,
              validMoves: validMoves,
              onPositionTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(BoardWidget), findsOneWidget);
    });

    testWidgets('应该显示最后移动的位置', (WidgetTester tester) async {
      final boardState = BoardState.initial();
      const lastMoveFrom = Position(0, 0);
      const lastMoveTo = Position(0, 1);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoardWidget(
              boardState: boardState,
              lastMoveFrom: lastMoveFrom,
              lastMoveTo: lastMoveTo,
              onPositionTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(BoardWidget), findsOneWidget);
    });

    testWidgets('应该正确处理空棋盘', (WidgetTester tester) async {
      // 创建一个空棋盘
      var boardState = BoardState.initial();

      // 移除所有棋子
      for (int y = 0; y < 4; y++) {
        for (int x = 0; x < 4; x++) {
          final pos = Position(x, y);
          if (boardState.getPiece(pos) != PieceType.empty) {
            boardState = boardState.removePiece(pos);
          }
        }
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoardWidget(
              boardState: boardState,
              onPositionTapped: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(BoardWidget), findsOneWidget);
    });

    testWidgets('屏幕阅读器应读出坐标、棋子和可落子状态', (WidgetTester tester) async {
      final semantics = tester.ensureSemantics();
      Position? tappedPosition;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoardWidget(
              boardState: BoardState.initial(),
              selectedPiece: const Position(0, 0),
              validMoves: const [Position(0, 1)],
              onPositionTapped: (position) => tappedPosition = position,
            ),
          ),
        ),
      );

      expect(
        find.bySemanticsLabel('第 1 行第 1 列，墨方棋子，已选中，可选择'),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel('第 2 行第 1 列，空位，可落子'),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel('第 2 行第 1 列，空位，可落子'));
      expect(tappedPosition, const Position(0, 1));
      semantics.dispose();
    });

    testWidgets('注入的主题包应到达棋盘绘制层', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BoardWidget(
              boardState: BoardState.initial(),
              themePack: modernEasternThemePack,
              onPositionTapped: (_) {},
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(BoardWidget),
          matching: find.byType(CustomPaint),
        ),
      );
      final painter = customPaint.painter! as BoardPainter;
      expect(painter.themePack, same(modernEasternThemePack));
    });
  });
}
