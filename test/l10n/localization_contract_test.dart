import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foursquare/l10n/app_localizations.dart';

void main() {
  test('Chinese, English, and Japanese preserve authoritative rule terms', () {
    final zh = lookupAppLocalizations(const Locale('zh'));
    final en = lookupAppLocalizations(const Locale('en'));
    final ja = lookupAppLocalizations(const Locale('ja'));

    expect(AppLocalizations.supportedLocales, const [
      Locale('en'),
      Locale('ja'),
      Locale('zh'),
    ]);
    expect(zh.rulesEndingLine4, contains('50'));
    expect(en.rulesEndingLine4, contains('50 consecutive plies'));
    expect(ja.rulesEndingLine4, contains('50 ply'));
    expect(zh.rulesCaptureLine3, contains('最多吃两枚'));
    expect(en.rulesCaptureLine3, contains('up to two pieces'));
    expect(ja.rulesCaptureLine3, contains('最大 2 個'));
  });

  test('settings and accessibility vocabulary exists in every locale', () {
    for (final locale in const [Locale('zh'), Locale('en'), Locale('ja')]) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.settingsLanguage, isNotEmpty);
      expect(l10n.settingsAnonymousDiagnosticsDescription, isNotEmpty);
      expect(l10n.boardCellPosition(1, 2), isNotEmpty);
      expect(l10n.firstPlayerAnnouncement(l10n.blackSide), isNotEmpty);
    }
  });
}
