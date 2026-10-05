// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_local_auth/komodo_defi_local_auth.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart' show KdfUser;
import 'package:rational/rational.dart';
import 'package:web_dex/bloc/analytics/analytics_bloc.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/dex_repository.dart';
import 'package:web_dex/bloc/taker_form/taker_bloc.dart';
import 'package:web_dex/bloc/taker_form/taker_event.dart';
import 'package:web_dex/bloc/taker_form/taker_state.dart';
import 'package:web_dex/mm2/mm2_api/rpc/best_orders/best_orders.dart';
import 'package:web_dex/mm2/mm2_api/rpc/sell/sell_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/sell/sell_response.dart';
import 'package:web_dex/mm2/mm2_api/rpc/base.dart';
import 'package:web_dex/mm2/mm2_api/rpc/trade_preimage/trade_preimage_request.dart';
import 'package:web_dex/model/coin.dart';
import 'package:web_dex/model/data_from_service.dart';
import 'package:web_dex/model/trade_preimage.dart';

class _Auth implements KomodoDefiLocalAuth {
  @override
  Stream<KdfUser?> watchCurrentUser() => const Stream.empty();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Sdk implements KomodoDefiSdk {
  @override
  final KomodoDefiLocalAuth auth = _Auth();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Coins implements CoinsRepo {
  Coin? quoteCoin;
  @override
  Coin? getCoin(String abbr) => quoteCoin;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Analytics implements AnalyticsBloc {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Coin implements Coin {
  @override
  bool get isSuspended => false;
  @override
  Coin? get parentCoin => null;
  @override
  String get abbr => 'ARRR';
  @override
  String get protocolType => 'ZHTLC';
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Dex implements DexRepository {
  final response = Completer<SellResponse>();
  final quote = Completer<DataFromService<TradePreimage, BaseError>>();
  int calls = 0;
  @override
  Future<SellResponse> sell(SellRequest request) {
    calls++;
    return response.future;
  }

  @override
  Future<DataFromService<TradePreimage, BaseError>> getTradePreimage(
    String base,
    String rel,
    Rational price,
    String method, [
    Rational? volume,
    bool max = false,
  ]) => quote.future;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Quote implements TradePreimage {
  @override
  final request = TradePreimageRequest(
    base: 'ARRR',
    rel: 'USDT-BEP20',
    swapMethod: 'sell',
    price: Rational.one,
    volume: Rational.one,
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _settle() =>
    Future<void>.delayed(const Duration(milliseconds: 20));

void main() {
  late TakerBloc bloc;
  late _Dex dex;
  late _Coins coins;
  setUp(() {
    dex = _Dex();
    coins = _Coins();
    final sdk = _Sdk();
    GetIt.I.registerSingleton<KomodoDefiSdk>(sdk);
    bloc = TakerBloc(
      dexRepository: dex,
      coinsRepository: coins,
      kdfSdk: sdk,
      analyticsBloc: _Analytics(),
    );
  });
  tearDown(() async {
    await bloc.close();
    await GetIt.I.reset();
  });

  test(
    'successful RPC finishes progress without a confirmation widget',
    () async {
      bloc.emit(
        TakerState.initial().copyWith(
          step: () => TakerStep.confirm,
          sellCoin: () => _Coin(),
          sellAmount: () => Rational.one,
          selectedOrder: () => BestOrder(
            price: Rational.one,
            maxVolume: Rational.fromInt(100),
            minVolume: Rational.zero,
            coin: 'USDT-BEP20',
            address: const OrderAddress.transparent('other'),
            uuid: 'maker',
          ),
        ),
      );
      bloc.add(TakerStartSwap());
      await _settle();
      expect(bloc.state.inProgress, isTrue);
      dex.response.complete(
        SellResponse(result: SellResponseResult(uuid: 'swap')),
      );
      await _settle();
      expect(bloc.state.inProgress, isFalse);
      expect(bloc.state.swapUuid, 'swap');
      bloc.add(TakerStartSwap());
      await _settle();
      expect(dex.calls, 1);
      bloc.add(TakerFormOpened(walletReady: false));
      await _settle();
      expect(bloc.state.step, TakerStep.form);
      expect(bloc.state.swapUuid, isNull);
      expect(bloc.state.inProgress, isFalse);
    },
  );

  test('returning resets a completed legacy confirmation', () async {
    bloc.emit(
      TakerState.initial().copyWith(
        step: () => TakerStep.confirm,
        inProgress: () => true,
        swapUuid: () => 'completed',
      ),
    );
    bloc.add(TakerFormOpened(walletReady: false));
    await _settle();
    expect(bloc.state.step, TakerStep.form);
    expect(bloc.state.inProgress, isFalse);
  });

  test('returning does not reset an RPC still in flight', () async {
    bloc.emit(
      TakerState.initial().copyWith(
        step: () => TakerStep.confirm,
        inProgress: () => true,
      ),
    );
    bloc.add(TakerFormOpened(walletReady: false));
    bloc.add(TakerBackButtonClick());
    await _settle();
    expect(bloc.state.step, TakerStep.confirm);
    expect(bloc.state.inProgress, isTrue);
  });

  test(
    'returning preserves a pending confirmation instead of reselecting coins',
    () async {
      final coin = _Coin();
      bloc.emit(
        TakerState.initial().copyWith(
          step: () => TakerStep.confirm,
          sellCoin: () => coin,
        ),
      );
      bloc.add(TakerFormOpened(walletReady: true));
      await _settle();
      expect(bloc.state.step, TakerStep.confirm);
      expect(bloc.state.sellCoin, same(coin));
    },
  );

  test(
    'Back leaves quote timeout view and preserves unknown submission guard',
    () async {
      bloc.emit(
        TakerState.initial().copyWith(
          step: () => TakerStep.confirm,
          submissionOutcomeUnknown: true,
        ),
      );
      bloc.add(TakerBackButtonClick());
      await _settle();
      expect(bloc.state.step, TakerStep.form);
      expect(bloc.state.submissionOutcomeUnknown, isTrue);
      bloc.add(TakerStartSwap());
      await _settle();
      expect(dex.calls, 0);
    },
  );

  test('background fee updates do not erase confirmation state', () async {
    final quote = _Quote();
    bloc.emit(
      TakerState.initial().copyWith(
        step: () => TakerStep.confirm,
        tradePreimage: () => quote,
      ),
    );
    final before = bloc.state;
    bloc.add(TakerUpdateFees());
    await _settle();
    expect(bloc.state, same(before));
    expect(bloc.state.tradePreimage, same(quote));
  });

  test(
    'quote response after Back cannot repopulate the abandoned quote',
    () async {
      coins.quoteCoin = _Coin();
      bloc.emit(
        TakerState.initial().copyWith(
          sellCoin: () => _Coin(),
          sellAmount: () => Rational.one,
          selectedOrder: () => BestOrder(
            price: Rational.one,
            maxVolume: Rational.fromInt(100),
            minVolume: Rational.zero,
            coin: 'USDT-BEP20',
            address: const OrderAddress.transparent('other'),
            uuid: 'maker',
          ),
        ),
      );
      bloc.add(TakerUpdateFees());
      await _settle();
      bloc.add(TakerBackButtonClick());
      await _settle();
      dex.quote.complete(DataFromService(data: _Quote()));
      await _settle();
      expect(bloc.state.step, TakerStep.form);
      expect(bloc.state.tradePreimage, isNull);
    },
  );
}
