import 'dart:async';

import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/trading_status/app_geo_status.dart';

/// The wallet does not depend on the legacy GLEEC geo-blocking service.
/// Preserve the formerly effective unrestricted result and stream contract.
class TradingStatusRepository {
  TradingStatusRepository(KomodoDefiSdk sdk);

  Future<AppGeoStatus> fetchStatus({bool? forceFail}) async =>
      const AppGeoStatus();

  Future<bool> isTradingEnabled({bool? forceFail}) async => true;

  Stream<AppGeoStatus> watchTradingStatus({
    Duration pollingInterval = const Duration(minutes: 1),
    bool? forceFail,
  }) async* {
    yield const AppGeoStatus();
    await for (final _ in Stream.periodic(pollingInterval)) {
      yield const AppGeoStatus();
    }
  }

  void dispose() {}
}
