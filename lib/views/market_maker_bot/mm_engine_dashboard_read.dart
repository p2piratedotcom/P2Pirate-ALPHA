/// Read-only dashboard replies belong to the captured wallet/process session.
/// A null result means that the caller must leave its displayed state alone.
Future<T?> readMmEngineDashboard<T>({
  required Future<T> Function() load,
  required bool Function() isCurrentSession,
}) async {
  if (!isCurrentSession()) return null;
  try {
    final reply = await load();
    return isCurrentSession() ? reply : null;
  } catch (_) {
    // An old request's error must not mark the replacement wallet as stale.
    if (!isCurrentSession()) return null;
    rethrow;
  }
}
