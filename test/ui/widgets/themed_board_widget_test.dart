import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/models/board_state.dart';
import 'package:foursquare/theme/packs/modern_eastern_theme_pack.dart';
import 'package:foursquare/ui/widgets/animated_board_widget.dart';
import 'package:foursquare/ui/widgets/board_painter.dart';
import 'package:foursquare/ui/widgets/themed_board_widget.dart';

void main() {
  testWidgets('主题包注入且系统减少动态会关闭动画和粒子', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: ThemedBoardWidget(
            boardState: BoardState.initial(),
            themePack: modernEasternThemePack,
            size: 320,
            onPositionTapped: (_) {},
          ),
        ),
      ),
    );

    final animatedBoard = tester.widget<AnimatedBoardWidget>(
      find.byType(AnimatedBoardWidget),
    );
    expect(animatedBoard.animationEnabled, isFalse);
    expect(animatedBoard.particleEnabled, isFalse);
    final adapter = animatedBoard.theme! as ThemePackBoardThemeAdapter;
    expect(adapter.themePack, same(modernEasternThemePack));
  });
}
