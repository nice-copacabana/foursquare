import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/l10n/app_localizations.dart';
import 'package:foursquare/ui/screens/interactive_tutorial_page.dart';

void main() {
  testWidgets('教程要求玩家实际选择并移动棋子后才继续', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InteractiveTutorialPage(),
      ),
    );
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('先选择左上角的墨方棋子。'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    await tester.tap(
      find.bySemanticsLabel(RegExp('第 1 行，第 1 列.*墨方')),
    );
    await tester.pump();
    expect(find.textContaining('下方相邻空位'), findsOneWidget);

    await tester.tap(
      find.bySemanticsLabel(RegExp('第 2 行，第 1 列.*可移动到此处')),
    );
    await tester.pump();
    expect(find.textContaining('落子完成'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });

  testWidgets('tutorial instructions are available in Japanese',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: InteractiveTutorialPage(),
      ),
    );
    await tester.pump();

    expect(find.text('左上の墨方の駒を選んでください。'), findsOneWidget);
  });
}
