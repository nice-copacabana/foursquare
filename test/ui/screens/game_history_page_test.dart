import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/game_record.dart';
import 'package:foursquare/models/game_result.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/ui/screens/game_history_page.dart';

void main() {
  testWidgets('完成记录显示模式、结果并提供回放入口', (tester) async {
    final record = GameRecord(
      id: 'match-1',
      completedAt: DateTime.utc(2026, 8, 1, 12),
      mode: 'pve',
      difficulty: 'hard',
      startingPlayer: PieceType.white,
      humanPlayer: PieceType.black,
      result: GameResult.blackWin(
        reason: '白方无合法移动',
        moveCount: 0,
        duration: const Duration(minutes: 2),
      ),
      moves: const [],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: GameHistoryPage(loadHistory: () async => [record]),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('人机 · 困难 · 墨方胜'), findsOneWidget);
    expect(find.textContaining('0 手'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right_rounded), findsOneWidget);
  });

  testWidgets('无记录时说明最近20局规则', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: GameHistoryPage(loadHistory: () async => const [])),
    );
    await tester.pumpAndSettle();

    expect(find.text('尚无已完成对局'), findsOneWidget);
    expect(find.textContaining('最近 20 局'), findsOneWidget);
  });
}
