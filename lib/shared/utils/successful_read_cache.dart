/// Coalesces reads and retains successful data, never a failed Future.
/// Clearing fences an old completion from replacing a newer account's read.
class SuccessfulReadCache<T> {
  Future<T>? _read;

  void clear() => _read = null;

  Future<T> get(Future<T> Function() load) {
    final existing = _read;
    if (existing != null) return existing;
    late final Future<T> request;
    request = Future<T>.sync(load).catchError((Object error, StackTrace stack) {
      if (identical(_read, request)) _read = null;
      Error.throwWithStackTrace(error, stack);
    });
    _read = request;
    return request;
  }
}
