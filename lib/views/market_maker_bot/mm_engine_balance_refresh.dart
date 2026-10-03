import 'dart:async';
import 'package:flutter/foundation.dart';

/// Read-only display snapshots. These never replace the engine's freshness
/// checks used to size orders or authorize hedges.
class MmEngineBalanceRefresh extends ChangeNotifier {
  MmEngineBalanceRefresh({
    required this.load,
    required this.canRefresh,
    this.interval = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _startTimer();
  }

  final Future<List<Map<String, dynamic>>> Function(String venue) load;
  final bool Function(String venue) canRefresh;
  final Duration interval;
  final DateTime Function() _now;
  final _snapshots = <String, List<Map<String, dynamic>>>{};
  final _updated = <String, DateTime>{};
  final _due = <String, DateTime>{};
  final _errors = <String, String>{};
  Timer? _timer;
  String venue = 'MEXC';
  bool expanded = true;
  bool loading = false;
  bool _disposed = false;
  int _generation = 0;

  List<Map<String, dynamic>> get balances => _snapshots[venue] ?? const [];
  DateTime? get updatedAt => _updated[venue];
  String? get error => _errors[venue];
  int get secondsRemaining {
    final milliseconds = (_due[venue] ?? _now())
        .difference(_now())
        .inMilliseconds;
    return milliseconds <= 0 ? 0 : (milliseconds / 1000).ceil();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      if (secondsRemaining == 0 && !loading && canRefresh(venue)) {
        unawaited(refresh());
      } else {
        notifyListeners();
      }
    });
  }

  void selectVenue(String value) {
    if (value == venue) return;
    _generation++;
    venue = value;
    notifyListeners();
    if (expanded) unawaited(refresh());
  }

  void toggleExpanded() {
    expanded = !expanded;
    _timer?.cancel();
    if (expanded) {
      _startTimer();
      if (secondsRemaining == 0) unawaited(refresh());
    }
    notifyListeners();
  }

  /// Ignore replies from a previous engine session or replaced API credentials.
  void invalidate({bool clear = false}) {
    _generation++;
    _due.clear();
    if (clear) {
      _snapshots.clear();
      _updated.clear();
      _errors.clear();
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    if (_disposed || loading || !expanded || !canRefresh(venue)) return;
    final requestedVenue = venue;
    final generation = _generation;
    loading = true;
    _errors.remove(requestedVenue);
    notifyListeners();
    try {
      final rows = await load(requestedVenue);
      if (_disposed || generation != _generation) return;
      _snapshots[requestedVenue] = rows;
      _updated[requestedVenue] = _now();
    } catch (failure) {
      if (!_disposed && generation == _generation) {
        _errors[requestedVenue] = '$failure';
      }
    } finally {
      if (!_disposed) {
        // Delay retries even after failure; never flood an exchange over Tor.
        if (generation == _generation) {
          _due[requestedVenue] = _now().add(interval);
        }
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    super.dispose();
  }
}
