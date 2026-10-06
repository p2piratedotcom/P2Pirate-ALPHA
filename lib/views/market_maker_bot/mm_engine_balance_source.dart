import 'dart:async';
import 'package:flutter/foundation.dart';

/// One display request, snapshot and refresh schedule per venue per page.
/// These snapshots never authorize trading or replace engine freshness checks.
class MmEngineBalanceSource extends ChangeNotifier {
  MmEngineBalanceSource({
    required this.load,
    required this.canRefresh,
    this.interval = const Duration(seconds: 60),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now {
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_disposed) return;
      final venues = {
        for (final view in _views.values)
          if (view.$2) view.$1,
      };
      if (venues.isEmpty) return;
      for (final venue in venues) {
        if (secondsRemaining(venue) == 0 && canRefresh(venue)) {
          unawaited(refresh(venue, force: false));
        }
      }
      clock.value++;
    });
  }

  Future<List<Map<String, dynamic>>> Function(String) load;
  bool Function(String) canRefresh;
  final ValueNotifier<int> clock = ValueNotifier(0);
  final Map<String, (String, bool)> viewPreferences = {};
  void resume({
    required Future<List<Map<String, dynamic>>> Function(String) load,
    required bool Function(String) canRefresh,
  }) {
    if (_disposed) return;
    this.load = load;
    this.canRefresh = canRefresh;
    _startTimer();
  }

  void suspend() {
    _timer?.cancel();
    _timer = null;
    // Release the page callbacks while retaining data and in-flight reads.
    load = (_) async => const [];
    canRefresh = (_) => false;
  }

  final Duration interval;
  final DateTime Function() _now;
  final _rows = <String, List<Map<String, dynamic>>>{};
  final _updated = <String, DateTime>{};
  final _due = <String, DateTime>{};
  final _errors = <String, String>{};
  final _requests = <String, Future<void>>{};
  final _views = <Object, (String, bool)>{};
  Timer? _timer;
  int _generation = 0;
  bool _disposed = false;
  List<Map<String, dynamic>> rows(String venue) => _rows[venue] ?? const [];
  DateTime? updatedAt(String venue) => _updated[venue];
  String? error(String venue) => _errors[venue];
  bool loading(String venue) => _requests.containsKey(venue);
  int secondsRemaining(String venue) {
    final ms = (_due[venue] ?? _now()).difference(_now()).inMilliseconds;
    return ms <= 0 ? 0 : (ms / 1000).ceil();
  }

  void observe(Object view, String venue, bool expanded) {
    _views[view] = (venue, expanded);
  }

  void unobserve(Object view) => _views.remove(view);
  void invalidate({bool clear = false}) {
    _generation++;
    _due.clear();
    if (clear) {
      _rows.clear();
      _updated.clear();
      _errors.clear();
    }
    if (!_disposed) notifyListeners();
  }

  Future<void> refresh(String venue, {bool force = true}) {
    if (_disposed) return Future.value();
    final pending = _requests[venue];
    if (pending != null) return pending;
    if (!canRefresh(venue) || (!force && secondsRemaining(venue) > 0)) {
      return Future.value();
    }
    final generation = _generation;
    _errors.remove(venue);
    late Future<void> request;
    request = _fetch(venue, generation).whenComplete(() {
      if (identical(_requests[venue], request)) _requests.remove(venue);
      if (!_disposed) notifyListeners();
    });
    _requests[venue] = request;
    notifyListeners();
    return request;
  }

  Future<void> _fetch(String venue, int generation) async {
    try {
      final values = await load(venue);
      if (_disposed || generation != _generation) return;
      _rows[venue] = values;
      _updated[venue] = _now();
    } catch (error) {
      if (!_disposed && generation == _generation) _errors[venue] = '$error';
    } finally {
      if (!_disposed && generation == _generation) {
        _due[venue] = _now().add(interval);
      }
    }
  }

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _timer?.cancel();
    _views.clear();
    clock.dispose();
    super.dispose();
  }
}
