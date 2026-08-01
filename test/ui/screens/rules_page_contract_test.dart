import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/ui/screens/rules_page.dart';

void main() {
  testWidgets('规则页与正式吃子、计时和终局规则一致', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: RulesPage()));

    expect(find.text('精确吃子'), findsOneWidget);
    expect(find.textContaining('一手最多吃两枚'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.textContaining('连续 50 个单方落子'),
      300,
    );
    expect(find.textContaining('连续 50 个单方落子'), findsOneWidget);
    expect(find.textContaining('30 秒重连宽限'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.textContaining('局域网对战不提供撤销'),
      300,
    );
    expect(find.textContaining('局域网对战不提供撤销'), findsOneWidget);
  });
}
