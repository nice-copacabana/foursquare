import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ui/screens/home_page.dart';

void main() {
  Widget app({required Future<bool> Function() hasSavedGame}) {
    return MaterialApp(
      home: HomePage(
        hasSavedGame: hasSavedGame,
        enableResourceWarmup: false,
      ),
    );
  }

  testWidgets('一期首页有存档时显示继续游戏且不暴露后续阶段入口', (tester) async {
    await tester.pumpWidget(app(hasSavedGame: () async => true));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('continue_game_button')), findsOneWidget);
    expect(find.text('继续游戏'), findsOneWidget);
    expect(find.text('冥想模式'), findsNothing);
    expect(find.text('在线对战'), findsNothing);
  });

  testWidgets('一期首页无存档时不显示继续游戏', (tester) async {
    await tester.pumpWidget(app(hasSavedGame: () async => false));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('continue_game_button')), findsNothing);
  });
}
