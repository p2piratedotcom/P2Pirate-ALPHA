import 'dart:async';
import 'dart:convert';

import 'package:flutter/scheduler.dart';
import 'package:komodo_defi_framework/komodo_defi_framework.dart';
import 'package:logging/logging.dart';

/// Aggregated local metrics only: never inspect state or event contents.
class UiPerformanceDiagnostics {
  static final _logger = Logger('UiPerformanceDiagnostics');
  static final Map<String, int> _changes = {};
  static Timer? _timer;
  static int _frames = 0;
  static int _slowBuild = 0;
  static int _slowRaster = 0;
  static int _buildUs = 0;
  static int _rasterUs = 0;
  static int _maxBuildUs = 0;
  static int _maxRasterUs = 0;
  static final _window = Stopwatch();

  static void start() {
    if (_timer != null) return;
    _window.start();
    SchedulerBinding.instance.addTimingsCallback(_onTimings);
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _flush());
  }

  static void stateChanged(Type type) {
    if (!KdfLoggingConfig.verboseLogging) return;
    final name = type.toString();
    _changes.update(name, (count) => count + 1, ifAbsent: () => 1);
  }

  static void _onTimings(List<FrameTiming> timings) {
    if (!KdfLoggingConfig.verboseLogging) return;
    for (final timing in timings) {
      final build = timing.buildDuration.inMicroseconds;
      final raster = timing.rasterDuration.inMicroseconds;
      _frames++;
      _buildUs += build;
      _rasterUs += raster;
      if (build > _maxBuildUs) _maxBuildUs = build;
      if (raster > _maxRasterUs) _maxRasterUs = raster;
      if (build > 16667) _slowBuild++;
      if (raster > 16667) _slowRaster++;
    }
  }

  static void _flush() {
    if (KdfLoggingConfig.verboseLogging) {
      _logger.info(
        jsonEncode({
          'window_ms': _window.elapsedMilliseconds,
          'frames': _frames,
          'build_mean_ms': _frames == 0 ? 0 : _buildUs / _frames / 1000,
          'raster_mean_ms': _frames == 0 ? 0 : _rasterUs / _frames / 1000,
          'build_max_ms': _maxBuildUs / 1000,
          'raster_max_ms': _maxRasterUs / 1000,
          'build_over_16_67_ms': _slowBuild,
          'raster_over_16_67_ms': _slowRaster,
          'state_changes_by_type': _changes,
        }),
      );
    }
    _changes.clear();
    _frames = _slowBuild = _slowRaster = 0;
    _buildUs = _rasterUs = _maxBuildUs = _maxRasterUs = 0;
    _window.reset();
  }
}
