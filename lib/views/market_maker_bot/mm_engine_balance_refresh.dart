import 'dart:async';
import 'package:flutter/foundation.dart';
import 'mm_engine_balance_source.dart';

/// Read-only display snapshots. These never replace the engine's freshness
/// checks used to size orders or authorize hedges.
class MmEngineBalanceRefresh extends ChangeNotifier {
  MmEngineBalanceRefresh({
    Future<List<Map<String, dynamic>>> Function(String venue)? load,
    bool Function(String venue)? canRefresh,
    this.shared,
    String initialVenue = 'MEXC',
    this.interval = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : assert(shared != null || (load != null && canRefresh != null)),
       load = load ?? shared!.load,
       canRefresh = canRefresh ?? shared!.canRefresh,
       _now = now ?? DateTime.now,
       venue = initialVenue {
    if (shared == null) {
      _startTimer();
    } else {
      shared!.observe(this, venue, expanded);
      shared!.addListener(_sharedChanged);
    }
  }
  final MmEngineBalanceSource? shared;
  void _sharedChanged() {
    if (!_disposed) notifyListeners();
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
  String venue;
  bool expanded = true;
  bool _loading = false;
  bool get loading => shared?.loading(venue) ?? _loading;
  bool _disposed = false;
  int _generation = 0;

  List<Map<String, dynamic>> get balances =>
      shared?.rows(venue) ?? _snapshots[venue] ?? const [];
  DateTime? get updatedAt =>
      shared == null ? _updated[venue] : shared!.updatedAt(venue);
  String? get error => shared == null ? _errors[venue] : shared!.error(venue);
  int get secondsRemaining {
    if (shared != null) return shared!.secondsRemaining(venue);
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
    shared?.observe(this, venue, expanded);
    notifyListeners();
    if (expanded) {
      if (shared != null) {
        unawaited(shared!.refresh(venue, force: false));
      } else {
        unawaited(refresh());
      }
    }
  }

  void toggleExpanded() {
    expanded = !expanded;
    if (shared != null) {
      shared!.observe(this, venue, expanded);
      if (expanded) unawaited(shared!.refresh(venue, force: false));
      notifyListeners();
      return;
    }
    _timer?.cancel();
    if (expanded) {
      _startTimer();
      if (secondsRemaining == 0) unawaited(refresh());
    }
    notifyListeners();
  }

  /// Ignore replies from a previous engine session or replaced API credentials.
  void invalidate({bool clear = false}) {
    if (shared != null) {
      shared!.invalidate(clear: clear);
      return;
    }
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
    if (shared != null) {
      if (!_disposed && expanded) await shared!.refresh(venue);
      return;
    }
    if (_disposed || loading || !expanded || !canRefresh(venue)) return;
    final requestedVenue = venue;
    final generation = _generation;
    _loading = true;
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
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    shared?.removeListener(_sharedChanged);
    shared?.unobserve(this);
    super.dispose();
  }
}
