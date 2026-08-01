import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/services/app_locale_controller.dart';
import 'package:foursquare/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('AppLocaleController', () {
    test('legacy settings default to Chinese', () {
      final settings = GameSettings.fromJson(const {});

      expect(settings.localeCode, 'zh');
    });

    test('locale survives settings JSON round trip', () {
      const settings = GameSettings(localeCode: 'ja');

      final restored = GameSettings.fromJson(settings.toJson());

      expect(restored.localeCode, 'ja');
    });

    test('locale survives the settings persistence boundary', () async {
      SharedPreferences.setMockInitialValues(const <String, Object>{});
      final preferences = await SharedPreferences.getInstance();
      final storage = StorageService.forTesting(preferences: preferences);

      expect(
        await storage.saveSettings(const GameSettings(localeCode: 'en')),
        isTrue,
      );

      expect((await storage.loadSettings()).localeCode, 'en');
    });

    test('accepts only the three Phase 2 locales', () {
      final controller = AppLocaleController(const Locale('zh'));

      expect(controller.select('en'), isTrue);
      expect(controller.value, const Locale('en'));
      expect(controller.select('ja'), isTrue);
      expect(controller.value, const Locale('ja'));
      expect(controller.select('fr'), isFalse);
      expect(controller.value, const Locale('ja'));
      expect(AppLocaleController.supportedLocales, const [
        Locale('zh'),
        Locale('en'),
        Locale('ja'),
      ]);
    });
  });
}
