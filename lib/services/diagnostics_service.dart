import 'dart:async';

import 'package:sentry_flutter/sentry_flutter.dart';

/// Privacy-bounded crash and performance diagnostics.
///
/// No SDK is initialized when the DSN is absent or the user opted out. The
/// application never adds account, room, move, board or free-form log context.
class DiagnosticsService {
  static final DiagnosticsService _instance = DiagnosticsService._internal();
  factory DiagnosticsService() => _instance;
  DiagnosticsService._internal();

  String _dsn = '';
  String _environment = 'development';
  bool _enabled = false;

  static bool shouldInitialize({
    required bool enabled,
    required String? dsn,
  }) =>
      enabled && dsn != null && dsn.trim().isNotEmpty;

  Future<void> run({
    required bool enabled,
    required String? dsn,
    required String environment,
    required FutureOr<void> Function() appRunner,
  }) async {
    _enabled = enabled;
    _dsn = dsn?.trim() ?? '';
    _environment = environment;

    if (!shouldInitialize(enabled: enabled, dsn: _dsn)) {
      await appRunner();
      return;
    }
    await SentryFlutter.init(_configure, appRunner: appRunner);
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!enabled) {
      if (Sentry.isEnabled) await Sentry.close();
      return;
    }
    if (_dsn.isNotEmpty && !Sentry.isEnabled) {
      await SentryFlutter.init(_configure);
    }
  }

  void _configure(SentryFlutterOptions options) {
    options
      ..dsn = _dsn
      ..environment = _environment
      ..sendDefaultPii = false
      ..attachScreenshot = false
      ..attachViewHierarchy = false
      ..enableUserInteractionBreadcrumbs = false
      ..enableUserInteractionTracing = false
      ..enableAutoNativeBreadcrumbs = false
      ..enableAppLifecycleBreadcrumbs = false
      ..enableWindowMetricBreadcrumbs = false
      ..enableBrightnessChangeBreadcrumbs = false
      ..enableTextScaleChangeBreadcrumbs = false
      ..enableMemoryPressureBreadcrumbs = false
      ..maxRequestBodySize = MaxRequestBodySize.never
      ..tracesSampleRate = 0.1
      ..profilesSampleRate = 0
      ..beforeBreadcrumb = ((_, __) => null)
      ..beforeSend = ((event, _) => _enabled ? event : null);
    options.replay
      ..sessionSampleRate = 0
      ..onErrorSampleRate = 0;
  }
}
