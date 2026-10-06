/// Small, non-persistent navigation preferences, scoped to one account.
class SessionNavigationMemory {
  static String? _wallet;
  static int swapTab = 0;
  static int bridgeTab = 0;
  static void bindWallet(String? wallet) {
    if (wallet == _wallet) return;
    _wallet = wallet;
    swapTab = 0;
    bridgeTab = 0;
  }

  static void clear() {
    _wallet = null;
    swapTab = 0;
    bridgeTab = 0;
  }
}
