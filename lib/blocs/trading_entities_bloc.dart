import 'dart:async';

import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:rational/rational.dart';
import 'package:web_dex/blocs/bloc_base.dart';
import 'package:web_dex/generated/codegen_loader.g.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/mm2/mm2_api/rpc/cancel_order/cancel_order_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_taker_vol/max_taker_vol_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/max_taker_vol/max_taker_vol_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_recent_swaps/my_recent_swaps_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/my_recent_swaps/my_recent_swaps_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/recover_funds_of_swap/recover_funds_of_swap_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/recover_funds_of_swap/recover_funds_of_swap_response.dart';
import 'package:web_dex/model/main_menu_value.dart';
import 'package:web_dex/model/my_orders/my_order.dart';
import 'package:web_dex/model/swap.dart';
import 'package:web_dex/router/state/routing_state.dart';
import 'package:web_dex/services/orders_service/my_orders_service.dart';
import 'package:web_dex/services/swaps/swap_history_storage.dart';
import 'package:web_dex/shared/utils/utils.dart';

class TradingEntitiesBloc implements BlocBase {
  TradingEntitiesBloc(
    KomodoDefiSdk kdfSdk,
    Mm2Api mm2Api,
    MyOrdersService myOrdersService,
  ) : _mm2Api = mm2Api,
      _myOrdersService = myOrdersService,
      _kdfSdk = kdfSdk;

  final KomodoDefiSdk _kdfSdk;
  final MyOrdersService _myOrdersService;
  final Mm2Api _mm2Api;
  final SwapHistoryStorage _historyStorage = const SwapHistoryStorage();
  StreamSubscription<KdfUser?>? _authModeListener;
  List<MyOrder> _myOrders = [];
  List<Swap> _swaps = [];
  WalletId? _walletId;
  int _walletRevision = 0;
  int _authRevision = 0;
  Future<void>? _historyLoad;
  List<Swap> _lastStoredSwaps = [];
  bool _savingHistory = false;
  Timer? timer;
  bool _closed = false;
  DateTime? _lastFetchAt;
  bool _hasLoadedInitialSwaps = false;
  Map<String, SwapRecoveryReceipt> _recoveries = {};
  final Set<String> _submittingRecoveries = {};
  DateTime? _lastRecoveryCheck;
  bool _checkingRecoveries = false;
  final StreamController<void> _recoveryController =
      StreamController<void>.broadcast();
  Stream<void> get outRecoveries => _recoveryController.stream;
  bool isRecoveryPending(String uuid) =>
      _submittingRecoveries.contains(uuid) ||
      (_recoveries[uuid] != null && !_recoveries[uuid]!.confirmed);
  bool isRecoveryConfirmed(String uuid) => _recoveries[uuid]?.confirmed == true;

  static const Duration _pollingInterval = Duration(seconds: 10);
  static const Duration _backgroundFetchInterval = Duration(seconds: 45);
  static const int _initialSwapsLimit = 1000;
  static const int _refreshSwapsLimit = 250;

  final StreamController<List<MyOrder>> _myOrdersController =
      StreamController<List<MyOrder>>.broadcast();
  Sink<List<MyOrder>> get _inMyOrders => _myOrdersController.sink;
  Stream<List<MyOrder>> get outMyOrders => _myOrdersController.stream;
  List<MyOrder> get myOrders => _myOrders;
  set myOrders(List<MyOrder> orderList) {
    orderList.sort((first, second) => second.createdAt - first.createdAt);
    _myOrders = orderList;
    _inMyOrders.add(_myOrders);
  }

  final StreamController<List<Swap>> _swapsController =
      StreamController<List<Swap>>.broadcast();
  Sink<List<Swap>> get _inSwaps => _swapsController.sink;
  Stream<List<Swap>> get outSwaps => _swapsController.stream;
  List<Swap> get swaps => _swaps;
  set swaps(List<Swap> swapList) {
    swapList.sort(
      (first, second) =>
          (second.myInfo?.startedAt ?? 0) - (first.myInfo?.startedAt ?? 0),
    );
    _swaps = swapList;
    _inSwaps.add(_swaps);
  }

  Future<void> fetch() async {
    if (_closed) return;
    final authRevision = _authRevision;
    final user = await _kdfSdk.auth.currentUser;
    if (_closed || authRevision != _authRevision) return;
    _selectWallet(user?.walletId);
    if (user == null) return;

    final walletId = user.walletId;
    final walletRevision = _walletRevision;
    await _historyLoad;
    if (!await _isCurrentWallet(walletId, walletRevision)) return;
    final orders = await _myOrdersService.getOrders();
    if (!await _isCurrentWallet(walletId, walletRevision)) return;
    myOrders = orders ?? [];
    final recentSwaps =
        await getRecentSwaps(
          MyRecentSwapsRequest(
            limit: _hasLoadedInitialSwaps
                ? _refreshSwapsLimit
                : _initialSwapsLimit,
          ),
        ) ??
        [];
    if (!await _isCurrentWallet(walletId, walletRevision)) return;
    _hasLoadedInitialSwaps = true;
    swaps = _mergeSwaps(_swaps, recentSwaps);
    final completed = _swaps.where(_isCompletedForCache).toList();
    if (!_savingHistory &&
        !const ListEquality<Swap>().equals(_lastStoredSwaps, completed)) {
      unawaited(_saveHistory(walletId, walletRevision, completed));
    }
    _lastFetchAt = DateTime.now();
    unawaited(_checkRecoveryConfirmations(walletId, walletRevision));
  }

  bool _isCompletedForCache(Swap swap) => swap.events.any(
    (event) =>
        swap.errorEvents.contains(event.event.type) ||
        (swap.successEvents.isNotEmpty &&
            event.event.type == swap.successEvents.last),
  );

  Future<void> _loadHistory(WalletId walletId, int revision) async {
    try {
      final cached = await _historyStorage.read(walletId);
      if (!await _isCurrentWallet(walletId, revision)) return;
      _lastStoredSwaps = cached;
      if (cached.isNotEmpty) swaps = _mergeSwaps(_swaps, cached);
    } catch (_) {
      await log(
        'Local swap history is unavailable',
        path: 'TradingEntitiesBloc',
      );
    }
    try {
      final recoveries = await _historyStorage.readRecoveries(walletId);
      if (!await _isCurrentWallet(walletId, revision)) return;
      _recoveries = recoveries;
      _recoveryController.add(null);
    } catch (_) {
      await log(
        'Local recovery status is unavailable',
        path: 'TradingEntitiesBloc',
      );
    }
  }

  Future<void> _saveHistory(
    WalletId walletId,
    int revision,
    List<Swap> completed,
  ) async {
    _savingHistory = true;
    try {
      await _historyStorage.write(walletId, completed);
      if (await _isCurrentWallet(walletId, revision)) {
        _lastStoredSwaps = completed;
      }
    } catch (_) {
      await log(
        'Could not save local swap history',
        path: 'TradingEntitiesBloc',
      );
    } finally {
      _savingHistory = false;
    }
  }

  void _selectWallet(WalletId? walletId) {
    if (_walletId == walletId) return;
    _walletId = walletId;
    _walletRevision++;
    _hasLoadedInitialSwaps = false;
    _lastFetchAt = null;
    _lastStoredSwaps = [];
    _recoveries = {};
    _submittingRecoveries.clear();
    _lastRecoveryCheck = null;
    _recoveryController.add(null);
    myOrders = [];
    swaps = [];
    _historyLoad = walletId == null
        ? null
        : _loadHistory(walletId, _walletRevision);
  }

  Future<bool> _isCurrentWallet(WalletId walletId, int revision) async {
    if (_closed || _walletRevision != revision || _walletId != walletId) {
      return false;
    }
    final currentUser = await _kdfSdk.auth.currentUser;
    return !_closed &&
        _walletRevision == revision &&
        _walletId == walletId &&
        currentUser?.walletId == walletId;
  }

  @override
  void dispose() {
    _closed = true;
    _authModeListener?.cancel();
    timer?.cancel();
    _myOrdersController.close();
    _swapsController.close();
    _recoveryController.close();
  }

  void runUpdate() {
    bool updateInProgress = false;

    _authModeListener?.cancel();
    _authModeListener = _kdfSdk.auth.watchCurrentUser().listen((user) {
      if (_closed) return;
      _authRevision++;
      _selectWallet(user?.walletId);
      if (user != null) unawaited(_fetchAfterAuthChange());
    });

    timer?.cancel();
    timer = Timer.periodic(_pollingInterval, (_) async {
      if (_closed) return;
      if (updateInProgress) return;
      if (!_shouldRunBackgroundFetch()) return;
      // TODO!: do not run for hidden login or HW

      updateInProgress = true;
      try {
        await fetch();
      } catch (e) {
        if (e is StateError && e.message.contains('disposed')) {
          _closed = true;
        } else {
          await log('fetch error: $e', path: 'TradingEntitiesBloc.fetch');
        }
      } finally {
        updateInProgress = false;
      }
    });
  }

  Future<void> _fetchAfterAuthChange() async {
    try {
      await fetch();
    } catch (_) {
      await log(
        'Could not refresh trading history after wallet change',
        path: 'TradingEntitiesBloc.fetch',
      );
    }
  }

  bool _shouldRunBackgroundFetch() {
    if (_isTradingMenuActive) return true;
    if (_lastFetchAt == null) return true;
    return DateTime.now().difference(_lastFetchAt!) >= _backgroundFetchInterval;
  }

  bool get _isTradingMenuActive {
    final currentMenu = routingState.selectedMenu;
    return currentMenu == MainMenuValue.dex ||
        currentMenu == MainMenuValue.bridge;
  }

  List<Swap> _mergeSwaps(List<Swap> existing, List<Swap> incoming) {
    if (existing.isEmpty) return incoming;
    if (incoming.isEmpty) return existing;

    final merged = <String, Swap>{for (final swap in existing) swap.uuid: swap};
    for (final swap in incoming) {
      merged[swap.uuid] = swap;
    }
    return merged.values.toList();
  }

  Future<String?> cancelOrder(String uuid) async {
    final Map<String, dynamic> response = await _mm2Api.cancelOrder(
      CancelOrderRequest(uuid: uuid),
    );
    return response['error'];
  }

  bool isCoinBusy(String coin) {
    return (_swaps
                .where((swap) => !swap.isCompleted)
                .where((swap) => swap.sellCoin == coin || swap.buyCoin == coin)
                .toList()
                .length +
            _myOrders
                .where((order) => order.base == coin || order.rel == coin)
                .toList()
                .length) >
        0;
  }

  bool hasActiveSwap(String coin) {
    return _swaps
        .where((swap) => !swap.isCompleted)
        .any((swap) => swap.sellCoin == coin || swap.buyCoin == coin);
  }

  bool hasOpenOrders(String coin) {
    return _myOrders.any((order) => order.base == coin || order.rel == coin);
  }

  int openOrdersCount(String coin) {
    return _myOrders
        .where((order) => order.base == coin || order.rel == coin)
        .length;
  }

  Future<void> cancelOrdersForCoin(String coin) async {
    final futures = _myOrders
        .where((o) => o.base == coin || o.rel == coin)
        .map((o) => cancelOrder(o.uuid));
    await Future.wait(futures);
  }

  double getPriceFromAmount(Rational sellAmount, Rational buyAmount) {
    final sellDoubleAmount = sellAmount.toDouble();
    final buyDoubleAmount = buyAmount.toDouble();

    if (sellDoubleAmount == 0 || buyDoubleAmount == 0) return 0;
    return buyDoubleAmount / sellDoubleAmount;
  }

  String getTypeString(bool isTaker) =>
      isTaker ? LocaleKeys.takerOrder.tr() : LocaleKeys.makerOrder.tr();

  Swap? getSwap(String uuid) =>
      swaps.firstWhereOrNull((swap) => swap.uuid == uuid);

  double getProgressFillSwap(MyOrder order) {
    final List<Swap> swaps = (order.startedSwaps ?? [])
        .map((id) => getSwap(id))
        .whereType<Swap>()
        .toList();
    final double swapFill = swaps.fold(
      0,
      (previousValue, swap) => previousValue + (swap.myInfo?.myAmount ?? 0),
    );
    return swapFill / order.baseAmount.toDouble();
  }

  Future<void> cancelAllOrders() async {
    final futures = myOrders.map((o) => cancelOrder(o.uuid));
    Future.wait(futures);
  }

  Future<List<Swap>?> getRecentSwaps(MyRecentSwapsRequest request) async {
    final MyRecentSwapsResponse? response = await _mm2Api.getMyRecentSwaps(
      request,
    );
    if (response == null) {
      return null;
    }

    return response.result.swaps;
  }

  Future<RecoverFundsOfSwapResponse?> recoverFundsOfSwap(String uuid) async {
    if (_closed || isRecoveryPending(uuid) || isRecoveryConfirmed(uuid)) {
      return null;
    }
    final walletId = _walletId;
    final revision = _walletRevision;
    if (walletId == null || !await _isCurrentWallet(walletId, revision)) {
      return null;
    }
    _submittingRecoveries.add(uuid);
    _recoveryController.add(null);
    final RecoverFundsOfSwapRequest request = RecoverFundsOfSwapRequest(
      uuid: uuid,
    );
    try {
      final response = await _mm2Api.recoverFundsOfSwap(request);
      if (response != null && await _isCurrentWallet(walletId, revision)) {
        _recoveries[uuid] = SwapRecoveryReceipt(
          coin: response.result.coin,
          txHash: response.result.txHash,
          confirmed: false,
        );
        _lastRecoveryCheck = null;
        _recoveryController.add(null);
        try {
          await _historyStorage.writeRecoveries(walletId, _recoveries);
        } catch (_) {
          await log(
            'Could not save local recovery status',
            path: 'TradingEntitiesBloc',
          );
        }
        unawaited(_checkRecoveryConfirmations(walletId, revision));
      }
      return response;
    } finally {
      _submittingRecoveries.remove(uuid);
      if (!_closed) _recoveryController.add(null);
    }
  }

  Future<void> _checkRecoveryConfirmations(
    WalletId walletId,
    int revision,
  ) async {
    if (_checkingRecoveries ||
        !await _isCurrentWallet(walletId, revision) ||
        !_recoveries.values.any((receipt) => !receipt.confirmed)) {
      return;
    }
    final now = DateTime.now();
    if (_lastRecoveryCheck != null &&
        now.difference(_lastRecoveryCheck!) < const Duration(minutes: 5)) {
      return;
    }
    _lastRecoveryCheck = now;
    _checkingRecoveries = true;
    try {
      var changed = false;
      final pending = _recoveries.entries
          .where((entry) => !entry.value.confirmed)
          .toList();
      for (final coin in pending.map((entry) => entry.value.coin).toSet()) {
        if (!await _isCurrentWallet(walletId, revision)) return;
        final assets = _kdfSdk.assets.findAssetsByConfigId(coin);
        if (assets.isEmpty) continue;
        try {
          final page = await _kdfSdk.transactions.getTransactionHistory(
            assets.first,
            pagination: const PagePagination(pageNumber: 1, itemsPerPage: 200),
          );
          if (!await _isCurrentWallet(walletId, revision)) return;
          for (final entry in pending.where(
            (entry) => entry.value.coin == coin,
          )) {
            final confirmed = page.transactions.any(
              (tx) =>
                  tx.txHash?.toLowerCase() ==
                      entry.value.txHash.toLowerCase() &&
                  tx.confirmations > 0,
            );
            if (confirmed) {
              changed = true;
              _recoveries[entry.key] = SwapRecoveryReceipt(
                coin: coin,
                txHash: entry.value.txHash,
                confirmed: true,
              );
            }
          }
        } catch (_) {
          // Transaction history can be unavailable until activation completes.
        }
      }
      if (changed && await _isCurrentWallet(walletId, revision)) {
        _recoveryController.add(null);
        await _historyStorage.writeRecoveries(walletId, _recoveries);
      }
    } catch (_) {
      await log(
        'Could not verify recovery confirmations',
        path: 'TradingEntitiesBloc',
      );
    } finally {
      _checkingRecoveries = false;
    }
  }

  Future<Rational?> getMaxTakerVolume(String coinAbbr) async {
    final MaxTakerVolResponse? response = await _mm2Api.getMaxTakerVolume(
      MaxTakerVolRequest(coin: coinAbbr),
    );
    if (response == null) {
      return null;
    }

    return fract2rat(response.result.toJson());
  }
}
