import 'package:flutter/widgets.dart';

/// Owns the application's explicitly selected display language.
class AppLocaleController extends ValueNotifier<Locale> {
  AppLocaleController([Locale initialLocale = const Locale('zh')])
      : super(_normalize(initialLocale.languageCode));

  static const List<Locale> supportedLocales = <Locale>[
    Locale('zh'),
    Locale('en'),
    Locale('ja'),
  ];

  static bool supports(String languageCode) {
    return supportedLocales.any(
      (locale) => locale.languageCode == languageCode,
    );
  }

  static Locale _normalize(String languageCode) {
    return supports(languageCode) ? Locale(languageCode) : const Locale('zh');
  }

  /// Selects a supported language and reports whether the request was valid.
  bool select(String languageCode) {
    if (!supports(languageCode)) {
      return false;
    }

    final nextLocale = Locale(languageCode);
    if (value != nextLocale) {
      value = nextLocale;
    }
    return true;
  }
}

/// Exposes the locale controller to pages below [WidgetsApp].
class AppLocaleScope extends InheritedNotifier<AppLocaleController> {
  const AppLocaleScope({
    required AppLocaleController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static AppLocaleController of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppLocaleScope>();
    assert(scope != null, 'No AppLocaleScope found in context');
    return scope!.notifier!;
  }
}
