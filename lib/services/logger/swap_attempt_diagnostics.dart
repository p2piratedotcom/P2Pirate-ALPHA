import 'dart:convert';

import 'package:komodo_defi_framework/komodo_defi_framework.dart';
import 'package:logging/logging.dart';

/// Local diagnostics only. Never serialize requests, responses or exceptions.
class SwapAttemptDiagnostics {
  SwapAttemptDiagnostics(this.phase) : _id = ++_sequence {
    _write('started');
  }

  static int _sequence = 0;
  static final _logger = Logger('SwapAttemptDiagnostics');
  final String phase;
  final int _id;
  final Stopwatch _timer = Stopwatch()..start();

  void finish(String outcome, {Object? error}) {
    _timer.stop();
    _write(outcome, error: error);
  }

  void _write(String outcome, {Object? error}) {
    if (!KdfLoggingConfig.verboseLogging) return;
    _logger.info(
      jsonEncode({
        'local_operation': _id,
        'phase': phase,
        'outcome': outcome,
        'elapsed_ms': _timer.elapsedMilliseconds,
        if (error != null) 'category': classify(error),
      }),
    );
  }

  static String classify(Object error) {
    final text = error.toString().toLowerCase();
    if (text.contains('timeout') || text.contains('timed out')) {
      return 'timeout';
    }
    if (text.contains('transport') ||
        text.contains('connection') ||
        text.contains('socket')) {
      return 'connection';
    }
    if (text.contains('notsufficient') || text.contains('insufficient')) {
      return 'insufficient_balance';
    }
    if (text.contains('volumetoolow')) return 'volume_too_low';
    if (text.contains('notactivated') || text.contains('not activated')) {
      return 'coin_not_active';
    }
    if (text.contains('invalidparam')) return 'invalid_parameter';
    return 'unclassified';
  }
}
