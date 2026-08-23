import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:foursquare/main.dart' as app;
import 'package:foursquare/models/audio_settings.dart';
import 'package:foursquare/services/storage_service.dart';
import 'package:foursquare/ui/screens/game_page.dart';
import 'package:foursquare/ui/screens/home_page.dart';
import 'package:foursquare/ui/screens/onboarding_page.dart';
import 'package:foursquare/ui/screens/rules_page.dart';
import 'package:foursquare/ui/screens/statistics_page.dart';
import 'package:foursquare/ui/widgets/themed_board_widget.dart';

const _authorizedSmokeDevice = String.fromEnvironment(
  'ANDROID_SMOKE_DEVICE',
);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android Phase 1 main flow survives real app composition', (
    tester,
  ) async {
    expect(Platform.isAndroid, isTrue, reason: 'Android device required');
    expect(
      _authorizedSmokeDevice,
      'Foursquare_API_34_x86_64',
      reason: 'This test clears app data and only runs on the dedicated AVD',
    );
    final storage = await _prepareCleanAppData();
    addTearDown(() async {
      if (!await storage.resetAll()) {
        throw StateError('Unable to clean Android smoke-test storage');
      }
    });

    app.main();
    await _pumpUntilFound(tester, find.byType(OnboardingPage));

    expect(find.text('四子游戏'), findsOneWidget);
    expect(find.widgetWithText(TextButton, '跳过'), findsOneWidget);

    await _tapWhenVisible(
      tester,
      find.widgetWithText(TextButton, '跳过'),
    );
    await _pumpUntilFound(tester, find.byType(HomePage));

    expect(find.text('双人对战'), findsOneWidget);
    expect(find.text('人机对战'), findsOneWidget);
    expect(find.text('局域网对战'), findsOneWidget);
    expect(find.text('战绩'), findsOneWidget);
    expect(find.text('规则'), findsOneWidget);
    expect(find.text('设置'), findsOneWidget);
    expect(find.text('在线对战'), findsNothing);
    expect(find.text('冥想模式'), findsNothing);

    await _tapWhenVisible(
      tester,
      find.text('规则'),
    );
    await _pumpUntilFound(tester, find.byType(RulesPage));
    expect(find.text('对弈规则'), findsOneWidget);
    expect(find.text('精确吃子'), findsOneWidget);

    await _goBack(tester);
    await _pumpUntilFound(tester, find.byType(HomePage));
    await _tapWhenVisible(
      tester,
      find.text('战绩'),
    );
    await _pumpUntilFound(tester, find.byType(StatisticsPage));
    await _tapWhenVisible(tester, find.byTooltip('最近对局与回放'));
    await _pumpUntilFound(tester, find.text('尚无已完成对局'));

    await _goBack(tester);
    await _pumpUntilFound(tester, find.byType(StatisticsPage));
    await _goBack(tester);
    await _pumpUntilFound(tester, find.byType(HomePage));

    await _tapWhenVisible(
      tester,
      find.bySemanticsLabel(RegExp(r'^双人对战，')),
    );
    await _pumpUntilFound(tester, find.byType(GamePageView));
    await _pumpUntilFound(tester, find.byType(ThemedBoardWidget));
    await tester.pump(const Duration(seconds: 3));

    final selectablePiece = find.bySemanticsLabel(RegExp('可选棋子')).first;
    expect(selectablePiece, findsOneWidget);
    await tester.tap(selectablePiece);
    await tester.pump(const Duration(milliseconds: 300));

    final legalDestination = find.bySemanticsLabel(RegExp('可移动到此处')).first;
    expect(legalDestination, findsOneWidget);
    await tester.tap(legalDestination);
    await _pumpUntilFound(tester, find.text('移动历史（1 手）'));

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump(const Duration(milliseconds: 300));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('移动历史（1 手）'), findsOneWidget);

    await _goBack(tester);
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('continue_game_button')),
    );
    await _tapWhenVisible(
      tester,
      find.byKey(const Key('continue_game_button')),
    );
    await _pumpUntilFound(tester, find.text('移动历史（1 手）'));

    await _goBack(tester);
    await _pumpUntilFound(tester, find.byType(HomePage));

    await _tapWhenVisible(
      tester,
      find.bySemanticsLabel(RegExp(r'^人机对战，')),
    );
    await _pumpUntilFound(tester, find.byType(AlertDialog));
    await _tapWhenVisible(tester, find.text('简单'));
    await _pumpUntilFound(tester, find.byType(GamePageView));
    await _pumpUntilFound(tester, find.byType(ThemedBoardWidget));
    expect(find.byKey(const Key('game-voice-panel')), findsNothing);
    await tester.pump(const Duration(seconds: 2));
    await _goBack(tester);
    await _pumpUntilFound(tester, find.byType(HomePage));
  });
}

Future<StorageService> _prepareCleanAppData() async {
  final storage = StorageService();
  await storage.initialize();
  if (!await storage.resetAll()) {
    throw StateError('Unable to reset Android smoke-test storage');
  }

  final settingsSaved = await storage.saveSettings(
    const GameSettings(
      soundEnabled: false,
      musicEnabled: false,
      vibrationEnabled: false,
      animationEnabled: false,
      particleEnabled: false,
      performanceMonitoringEnabled: false,
      resourceWarmupEnabled: false,
      localeCode: 'zh',
    ),
  );
  if (!settingsSaved) {
    throw StateError('Unable to save Android smoke-test settings');
  }

  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(
    'audio_settings',
    jsonEncode(
      const AudioSettings(
        soundEnabled: false,
        musicEnabled: false,
        voiceEnabled: false,
        soundVolume: 0,
        musicVolume: 0,
        voiceVolume: 0,
      ).toMap(),
    ),
  );
  return storage;
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 20),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 200));
  }
  expect(finder, findsOneWidget);
}

Future<void> _tapWhenVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.tap(finder);
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _goBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pump(const Duration(milliseconds: 300));
}
