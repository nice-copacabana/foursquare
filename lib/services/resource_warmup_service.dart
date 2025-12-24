import 'package:flutter/widgets.dart';
import 'logger_service.dart';

class ResourceWarmupService {
  static final ResourceWarmupService _instance = ResourceWarmupService._internal();
  factory ResourceWarmupService() => _instance;
  ResourceWarmupService._internal();

  bool _warmed = false;

  Future<void> warmup(BuildContext context, {bool force = false}) async {
    if (_warmed && !force) return;
    _warmed = true;

    final assets = <String>[
      'assets/icon/app_icon.png',
      'assets/icon/adaptive_foreground.png',
      'assets/splash/logo.png',
    ];

    for (final asset in assets) {
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (e) {
        logger.warning('Failed to precache $asset: $e', 'ResourceWarmup');
      }
    }
  }
}
