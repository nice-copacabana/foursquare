import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/piece_type.dart';
import 'package:foursquare/ui/widgets/game_info_panel.dart';

void main() {
  testWidgets('显示60秒回合计时并启用可用的撤销重做操作', (tester) async {
    var undoCount = 0;
    var redoCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GameInfoPanel(
            currentPlayer: PieceType.black,
            blackPieceCount: 4,
            whitePieceCount: 4,
            moveHistory: const [],
            canUndo: true,
            canRedo: true,
            turnRemaining: const Duration(seconds: 42),
            onUndo: () => undoCount++,
            onRedo: () => redoCount++,
          ),
        ),
      ),
    );

    expect(find.text('墨方回合'), findsOneWidget);
    expect(find.text('42 秒'), findsOneWidget);
    await tester.tap(find.text('撤销'));
    await tester.tap(find.text('重做'));
    expect(undoCount, 1);
    expect(redoCount, 1);
  });
}
