import 'mm_engine_balance_source.dart';

/// Uncertainty about a configuration write; never a quote or live approval.
class MmEngineUnconfirmedMakerSave {
  MmEngineUnconfirmedMakerSave(Set<String> ids, Map<String, Object?> draft)
    : ids = Set.unmodifiable(ids),
      draft = Map.unmodifiable(draft),
      requestedAt = DateTime.now();

  final Set<String> ids;
  final Map<String, Object?> draft;
  final DateTime requestedAt;
}

/// One in-memory display model. It never authorizes orders or caches secrets.
/// A new wallet or engine process discards the previous account snapshots.
class MmEnginePageMemory {
  MmEnginePageMemory._(this.walletId, this.sessionRevision);
  static MmEnginePageMemory? _current;
  // Keep uncertain IDs/raw input within their original wallet when the display
  // session is replaced. A new process still requires a fresh list read.
  static final _unconfirmedSaves = <String, MmEngineUnconfirmedMakerSave>{};

  static MmEnginePageMemory forSession(String walletId, int revision) {
    final saved = _current;
    if (saved != null &&
        saved.walletId == walletId &&
        saved.sessionRevision == revision) {
      return saved;
    }
    clear();
    final memory = MmEnginePageMemory._(walletId, revision);
    final pending = memory.unconfirmedMakerSave;
    if (pending != null) memory.makerDrafts['new'] = Map.of(pending.draft);
    return _current = memory;
  }

  static void clear() {
    _current?.makerDrafts.clear();
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

  void adoptSession(int revision) {
    if (sessionRevision == revision) return;
    makerDrafts.clear();
    final pending = unconfirmedMakerSave;
    if (pending != null) makerDrafts['new'] = Map.of(pending.draft);
    strategies = null;
    reconciliation = null;
    credentials = null;
    orders = const [];
    observedAt = null;
    sessionRevision = revision;
  }

  /// Raw form input only; no preview, credentials or execution authorization.
  final makerDrafts = <String, Map<String, Object?>>{};

  MmEngineUnconfirmedMakerSave? get unconfirmedMakerSave =>
      _unconfirmedSaves[walletId];

  void markMakerSaveUnconfirmed(Set<String> ids) {
    _unconfirmedSaves[walletId] = MmEngineUnconfirmedMakerSave(
      ids,
      makerDrafts['new'] ?? const {},
    );
  }

  void confirmMakerSave() => _unconfirmedSaves.remove(walletId);
}
