/// Presentation preferences only, bounded to the current wallet session.
class WalletPageMemory {
  WalletPageMemory._(this.walletId);
  static WalletPageMemory? _current;
  static WalletPageMemory forWallet(String? walletId) {
    if (_current?.walletId != walletId) {
      _current = WalletPageMemory._(walletId);
    }
    return _current ??= WalletPageMemory._(walletId);
  }

  static void clear() => _current = null;
  final String? walletId;
  int tabIndex = 0;
  String search = '';
  double scrollOffset = 0;
}
