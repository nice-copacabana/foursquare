import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/l10n/app_localizations.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/ui/widgets/first_player_indicator.dart';

Widget _testApp({
  required Locale locale,
  required PieceType firstPlayer,
}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: FirstPlayerIndicator(
        firstPlayer: firstPlayer,
        duration: 10000,
      ),
    ),
  );
}

void main() {
  testWidgets('shows and announces the English first player message', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('en'),
        firstPlayer: PieceType.black,
      ),
    );

    expect(find.text('Ink moves first'), findsOneWidget);
    expect(find.text('The game is about to begin'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Ink moves first. The game is about to begin',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('游戏即将开始'), findsNothing);
    semantics.dispose();
  });

  testWidgets('shows and announces the Japanese first player message', (
    WidgetTester tester,
  ) async {
    final semantics = tester.ensureSemantics();

    await tester.pumpWidget(
      _testApp(
        locale: const Locale('ja'),
        firstPlayer: PieceType.white,
      ),
    );

    expect(find.text('玉方が先手'), findsOneWidget);
    expect(find.text('まもなく対局開始'), findsOneWidget);
    expect(
      find.bySemanticsLabel('玉方が先手。まもなく対局開始'),
      findsOneWidget,
    );
    expect(find.textContaining('游戏即将开始'), findsNothing);
    semantics.dispose();
  });
}
