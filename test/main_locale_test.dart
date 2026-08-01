import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('application exposes all Phase 2 locales', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'first_launch': false,
    });

    await tester.pumpWidget(const FourSquareGameApp());
    await tester.pumpAndSettle();

    final app = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(app.supportedLocales, const <Locale>[
      Locale('zh'),
      Locale('en'),
      Locale('ja'),
    ]);
    expect(app.locale, const Locale('zh'));
  });
}
