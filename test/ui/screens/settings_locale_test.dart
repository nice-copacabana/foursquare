import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/l10n/app_localizations.dart';
import 'package:foursquare/services/app_locale_controller.dart';
import 'package:foursquare/ui/screens/settings_page.dart';

void main() {
  testWidgets('changes the application language without restarting', (
    tester,
  ) async {
    final controller = AppLocaleController(const Locale('en'));

    await tester.pumpWidget(_LocalizedSettings(controller: controller));
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('App language'), findsOneWidget);

    await tester.ensureVisible(find.text('App language'));
    await tester.tap(find.text('App language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('日本語'));
    await tester.pumpAndSettle();

    expect(controller.value, const Locale('ja'));
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('表示言語'), findsOneWidget);
  });
}

class _LocalizedSettings extends StatelessWidget {
  const _LocalizedSettings({required this.controller});

  final AppLocaleController controller;

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: controller,
      child: ValueListenableBuilder<Locale>(
        valueListenable: controller,
        builder: (context, locale, child) {
          return MaterialApp(
            locale: locale,
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocaleController.supportedLocales,
            home: const SettingsPage(),
          );
        },
      ),
    );
  }
}
