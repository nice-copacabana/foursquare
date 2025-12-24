import 'package:flutter/scheduler.dart';
import 'logger_service.dart';

class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  bool _enabled = false;
  final List<FrameTiming> _buffer = [];
  static const int _sampleSize = 60;
  static const double _jankThresholdMs = 16.7;

  bool get isEnabled => _enabled;

  void setEnabled(bool enabled) {
    if (_enabled == enabled) return;
    _enabled = enabled;

    if (enabled) {
      SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);
      logger.info('Performance monitor enabled', 'PerformanceMonitor');
    } else {
      SchedulerBinding.instance.removeTimingsCallback(_onFrameTimings);
      _buffer.clear();
      logger.info('Performance monitor disabled', 'PerformanceMonitor');
    }
  }

  void _onFrameTimings(List<FrameTiming> timings) {
    if (!_enabled) return;
    _buffer.addAll(timings);

    while (_buffer.length >= _sampleSize) {
      final sample = _buffer.sublist(0, _sampleSize);
      _buffer.removeRange(0, _sampleSize);

      var buildMsTotal = 0.0;
      var rasterMsTotal = 0.0;
      var maxBuildMs = 0.0;
      var maxRasterMs = 0.0;
      var jankCount = 0;

      for (final timing in sample) {
        final buildMs = timing.buildDuration.inMicroseconds / 1000.0;
        final rasterMs = timing.rasterDuration.inMicroseconds / 1000.0;
        final totalMs = timing.totalSpan.inMicroseconds / 1000.0;

        buildMsTotal += buildMs;
        rasterMsTotal += rasterMs;
        if (buildMs > maxBuildMs) maxBuildMs = buildMs;
        if (rasterMs > maxRasterMs) maxRasterMs = rasterMs;
        if (totalMs > _jankThresholdMs) jankCount++;
      }

      final avgBuild = buildMsTotal / sample.length;
      final avgRaster = rasterMsTotal / sample.length;

      logger.info(
        'frames=${sample.length} avgBuild=${avgBuild.toStringAsFixed(2)}ms '
        'avgRaster=${avgRaster.toStringAsFixed(2)}ms '
        'maxBuild=${maxBuildMs.toStringAsFixed(2)}ms '
        'maxRaster=${maxRasterMs.toStringAsFixed(2)}ms '
        'jank=$jankCount',
        'PerformanceMonitor',
      );
    }
  }
}
