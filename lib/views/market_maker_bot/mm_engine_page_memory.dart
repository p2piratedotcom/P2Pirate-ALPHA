import 'mm_engine_balance_source.dart';

/// One in-memory display model. It never authorizes orders or caches secrets.
/// A new wallet or engine process discards the previous account snapshots.
class MmEnginePageMemory {
  MmEnginePageMemory._(this.walletId, this.sessionRevision);
  static MmEnginePageMemory? _current;

  static MmEnginePageMemory forSession(String walletId, int revision) {
    final saved = _current;
    if (saved != null &&
        saved.walletId == walletId &&
        saved.sessionRevision == revision) {
      return saved;
    }
    clear();
    return _current = MmEnginePageMemory._(walletId, revision);
  }

  static void clear() {
    _current?.balances?.dispose();
    _current = null;
  }

  final String walletId;
  int sessionRevision;
  MmEngineBalanceSource? balances;
  Map<String, dynamic>? strategies, reconciliation, credentials;
  List<Map<String, dynamic>> orders = const [];
  DateTime? observedAt;
  double scrollOffset = 0;
}
