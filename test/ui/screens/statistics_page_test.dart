import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/l10n/app_localizations.dart';
import 'package:foursquare/models/game_record.dart';
import 'package:foursquare/models/game_result.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/services/storage_service.dart';
import 'package:foursquare/ui/screens/statistics_page.dart';

void main() {
  testWidgets('本地双人按棋色汇总且不展示误导性个人胜率', (WidgetTester tester) async {
    final records = [
      _record('pvp-black', 'pvp', GameResult.blackWin),
      _record('pvp-white', 'pvp', GameResult.whiteWin),
      _drawRecord('pvp-draw', 'pvp'),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsPage(
          loadStatistics: () async => const GameStatistics(
            totalGames: 3,
            wins: 2,
            draws: 1,
            totalMoves: 24,
            totalCaptures: 5,
          ),
          loadHistory: () async => records,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('本地双人 · 近 20 局'), findsOneWidget);
    expect(find.text('墨方胜 1'), findsOneWidget);
    expect(find.text('玉方胜 1'), findsOneWidget);
    expect(find.text('和棋 1'), findsOneWidget);
    expect(find.textContaining('不计算个人胜率'), findsOneWidget);
    expect(find.text('胜率'), findsNothing);
  });

  testWidgets('人机与局域网按本机执棋颜色汇总', (WidgetTester tester) async {
    final records = [
      _record(
        'pve-player',
        'pve',
        GameResult.whiteWin,
        humanPlayer: PieceType.white,
      ),
      _record(
        'pve-ai',
        'pve',
        GameResult.whiteWin,
        humanPlayer: PieceType.black,
      ),
      _drawRecord('pve-draw', 'pve', humanPlayer: PieceType.white),
      _record(
        'lan-local',
        'lan',
        GameResult.blackWin,
        humanPlayer: PieceType.black,
      ),
      _record(
        'lan-remote',
        'lan',
        GameResult.blackWin,
        humanPlayer: PieceType.white,
      ),
      _drawRecord('lan-draw', 'lan', humanPlayer: PieceType.black),
    ];

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsPage(
          loadStatistics: () async => const GameStatistics(totalGames: 6),
          loadHistory: () async => records,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('人机对弈 · 近 20 局'), findsOneWidget);
    expect(find.text('玩家胜 1'), findsOneWidget);
    expect(find.text('AI 胜 1'), findsOneWidget);
    expect(find.text('局域网 · 近 20 局'), findsOneWidget);
    expect(find.text('本机胜 1'), findsOneWidget);
    expect(find.text('本机负 1'), findsOneWidget);
    expect(find.text('和棋 1'), findsNWidgets(2));
  });

  testWidgets('保留最近对局入口并复用历史数据源', (WidgetTester tester) async {
    var historyLoadCount = 0;
    Future<List<GameRecord>> loadHistory() async {
      historyLoadCount++;
      return [_drawRecord('history', 'pvp')];
    }

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsPage(
          loadStatistics: () async => const GameStatistics(totalGames: 1),
          loadHistory: loadHistory,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('最近对局与回放'));
    await tester.pumpAndSettle();

    expect(find.text('最近对局'), findsOneWidget);
    expect(historyLoadCount, 2);
  });

  testWidgets('重置前明确提示累计统计与回放都会清空', (WidgetTester tester) async {
    var resetCalled = false;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsPage(
          loadStatistics: () async => const GameStatistics(totalGames: 1),
          loadHistory: () async => const [],
          resetStatistics: () async {
            resetCalled = true;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('重置统计'));
    await tester.pumpAndSettle();

    expect(find.textContaining('累计统计和最近 20 局回放'), findsOneWidget);
    await tester.tap(find.text('确认重置'));
    await tester.pumpAndSettle();

    expect(resetCalled, isTrue);
    expect(find.text('统计与最近对局已重置'), findsOneWidget);
  });

  testWidgets('窄屏下统计卡片可滚动且不溢出', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('zh'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsPage(
          loadStatistics: () async => const GameStatistics(
            totalGames: 12,
            totalMoves: 108,
            totalCaptures: 21,
          ),
          loadHistory: () async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('棋谱总览'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('statistics headings are localized in English', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: StatisticsPage(
          loadStatistics: () async => const GameStatistics(totalGames: 0),
          loadHistory: () async => const [],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Record overview'), findsOneWidget);
    expect(find.text('Two players · Last 20'), findsOneWidget);
  });
}

GameRecord _record(
  String id,
  String mode,
  GameResult Function({
    required String reason,
    required int moveCount,
    required Duration duration,
  }) resultFactory, {
  PieceType? humanPlayer,
}) {
  return GameRecord(
    id: id,
    completedAt: DateTime.utc(2026, 8, 1),
    mode: mode,
    startingPlayer: PieceType.black,
    humanPlayer: humanPlayer,
    result: resultFactory(
      reason: 'test',
      moveCount: 8,
      duration: const Duration(minutes: 2),
    ),
    moves: const [],
  );
}

GameRecord _drawRecord(
  String id,
  String mode, {
  PieceType? humanPlayer,
}) {
  return GameRecord(
    id: id,
    completedAt: DateTime.utc(2026, 8, 1),
    mode: mode,
    startingPlayer: PieceType.black,
    humanPlayer: humanPlayer,
    result: GameResult.draw(
      reason: 'test',
      moveCount: 8,
      duration: const Duration(minutes: 2),
    ),
    moves: const [],
  );
}
