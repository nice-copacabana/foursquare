/// Game Over Dialog Test - 游戏结束对话框测试
/// 
/// 测试范围：
/// - 对话框渲染
/// - 按钮交互
/// - 不同游戏结果显示

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ui/widgets/game_over_dialog.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/models/game_result.dart';

void main() {
  group('GameOverDialog', () {
    testWidgets('黑方获胜应该显示正确信息', (WidgetTester tester) async {
      bool restarted = false;
      bool exited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: PieceType.black,
              gameResult: GameResult.blackWin(
                reason: '白方无子可移动',
                moveCount: 10,
                duration: const Duration(minutes: 5),
              ),
              onRestart: () => restarted = true,
              onExit: () => exited = true,
            ),
          ),
        ),
      );

      // 验证标题
      expect(find.text('黑方获胜！'), findsOneWidget);
      expect(find.text('白方无子可移动'), findsOneWidget);

      // 验证按钮
      expect(find.text('退出'), findsOneWidget);
      expect(find.text('再来一局'), findsOneWidget);
    });

    testWidgets('白方获胜应该显示正确信息', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: PieceType.white,
              gameResult: GameResult.whiteWin(
                reason: '黑方无子可移动',
                moveCount: 12,
                duration: const Duration(minutes: 6),
              ),
              onRestart: () {},
              onExit: () {},
            ),
          ),
        ),
      );

      expect(find.text('白方获胜！'), findsOneWidget);
      expect(find.text('黑方无子可移动'), findsOneWidget);
    });

    testWidgets('平局应该显示正确信息', (WidgetTester tester) async {
      final gameResult = GameResult.draw(
        reason: '双方都无法移动',
        moveCount: 15,
        duration: const Duration(minutes: 7),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: null,
              gameResult: gameResult,
              onRestart: () {},
              onExit: () {},
            ),
          ),
        ),
      );

      expect(find.text('平局'), findsOneWidget);
      // 平局时不显示"平局："，只显示"平局"
      expect(find.text(gameResult.reason), findsOneWidget);
    });

    testWidgets('点击重新开始按钮应该触发回调', (WidgetTester tester) async {
      bool restarted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: PieceType.black,
              gameResult: GameResult.blackWin(
                reason: '获胜',
                moveCount: 8,
                duration: const Duration(minutes: 4),
              ),
              onRestart: () => restarted = true,
              onExit: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('再来一局'));
      await tester.pump();

      expect(restarted, true);
    });

    testWidgets('点击退出按钮应该触发回调', (WidgetTester tester) async {
      bool exited = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: PieceType.black,
              gameResult: GameResult.blackWin(
                reason: '获胜',
                moveCount: 9,
                duration: const Duration(minutes: 5),
              ),
              onRestart: () {},
              onExit: () => exited = true,
            ),
          ),
        ),
      );

      await tester.tap(find.text('退出'));
      await tester.pump();

      expect(exited, true);
    });

    testWidgets('有回放功能时应该显示查看回放按钮', (WidgetTester tester) async {
      bool replayTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: PieceType.black,
              gameResult: GameResult.blackWin(
                reason: '获胜',
                moveCount: 10,
                duration: const Duration(minutes: 5),
              ),
              onRestart: () {},
              onExit: () {},
              onReplay: () => replayTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('查看回放'), findsOneWidget);

      await tester.tap(find.text('查看回放'));
      await tester.pump();

      expect(replayTapped, true);
    });

    testWidgets('无回放功能时不应该显示查看回放按钮', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: GameOverDialog(
              winner: PieceType.black,
              gameResult: GameResult.blackWin(
                reason: '获胜',
                moveCount: 10,
                duration: const Duration(minutes: 5),
              ),
              onRestart: () {},
              onExit: () {},
            ),
          ),
        ),
      );

      expect(find.text('查看回放'), findsNothing);
    });
  });
}
