import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ui/screens/interactive_tutorial_page.dart';

void main() {
  testWidgets('教程要求玩家实际选择并移动棋子后才继续', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: InteractiveTutorialPage()),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('先选择左上角的墨方棋子。'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(
      find.bySemanticsLabel(RegExp('第 1 行第 1 列.*墨方棋子')),
    );
    await tester.pump();
    expect(find.textContaining('下方相邻空位'), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel(RegExp('第 2 行第 1 列.*可落子')),
    );
    await tester.pump();
    expect(find.textContaining('落子完成'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
