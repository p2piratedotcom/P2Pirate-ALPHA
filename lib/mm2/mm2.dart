import 'dart:async';

import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:komodo_defi_types/komodo_defi_type_utils.dart';
import 'package:web_dex/mm2/mm2_api/rpc/version/version_request.dart';
import 'package:web_dex/mm2/mm2_api/rpc/version/version_response.dart';
import 'package:web_dex/shared/utils/utils.dart';

final MM2 mm2 = MM2();

final class MM2 {
  MM2();

  void configurePriceApi(String url) {
    final customUrl = url.trim();
    if (_isInitializing || _initCompleter.isCompleted || _kdfSdk != null) {
      throw StateError('Price API must be configured before SDK startup');
    }
    final uri = Uri.tryParse(customUrl);
    if (customUrl.isNotEmpty &&
        (uri == null ||
            uri.scheme != 'https' ||
            uri.host.isEmpty ||
            uri.userInfo.isNotEmpty)) {
      throw ArgumentError.value(customUrl, 'url', 'Expected an HTTPS URL');
    }
    _marketDataConfig = customUrl.isEmpty
        ? const MarketDataConfig()
        : MarketDataConfig(
            enableBinance: false,
            enableCoinGecko: false,
            enableCoinPaprika: false,
            komodoPriceProvider: KomodoPriceProvider(mainTickersUrl: customUrl),
          );
    _configuredPriceApiUrl = customUrl;
  }

  KomodoDefiSdk get _sdk => _kdfSdk ??= KomodoDefiSdk(
    config: KomodoDefiSdkConfig(
      // Syncing pre-activation coin states is not yet implemented,
      // so we disable it for now.
      // TODO: sync pre-activation of coins (show activating coins in list)
      preActivateHistoricalAssets: false,
      preActivateDefaultAssets: false,
      marketDataConfig: _marketDataConfig,
      localRpcPort: const int.fromEnvironment(
        'P2PIRATE_LOCAL_RPC_PORT',
        defaultValue: 7783,
      ),
    ),
    onLog: _handleSdkLog,
  );

  KomodoDefiSdk? _kdfSdk;
  MarketDataConfig _marketDataConfig = const MarketDataConfig();
  String _configuredPriceApiUrl = '';
  String get configuredPriceApiUrl => _configuredPriceApiUrl;
  bool _isInitializing = false;
  final Completer<KomodoDefiSdk> _initCompleter = Completer<KomodoDefiSdk>();

  Future<bool> isSignedIn() => _sdk.auth.isSignedIn();

  /// Dispose the SDK and clean up resources
  Future<void> dispose() async {
    final sdk = _kdfSdk;
    if (sdk == null) return;
    try {
      await sdk.dispose();
      log('KomodoDefiSdk disposed successfully');
    } catch (e) {
      log('Error disposing KomodoDefiSdk: $e', isError: true);
    }
  }

  Future<KomodoDefiSdk> initialize() async {
    if (_initCompleter.isCompleted) return _sdk;
    if (_isInitializing) return _initCompleter.future;

    try {
      _isInitializing = true;

      await _sdk.initialize();
      // Hack to ensure that kdf is running in noauth mode
      await _sdk.auth.getUsers();

      _initCompleter.complete(_sdk);
      return _sdk;
    } catch (e) {
      _initCompleter.completeError(e);
      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  Future<String> version() async {
    final JsonMap responseJson = await call(VersionRequest());
    final VersionResponse response = VersionResponse.fromJson(responseJson);

    return response.result;
  }

  @Deprecated(
    'Use KomodoDefiSdk.client.rpc or KomodoDefiSdk.client.executeRpc '
    'instead. This method is the legacy way of calling RPC methods which '
    'injects an empty user password into the legacy models which override '
    'the legacy base RPC request model',
  )
  Future<JsonMap> call(dynamic request) async {
    try {
      final dynamic requestWithUserpass = _assertPass(request);
      final JsonMap jsonRequest = requestWithUserpass is Map
          ? JsonMap.from(requestWithUserpass)
          // ignore: avoid_dynamic_calls
          : (requestWithUserpass?.toJson != null
                // ignore: avoid_dynamic_calls
                ? requestWithUserpass.toJson() as JsonMap
                : requestWithUserpass as JsonMap);

      return await _sdk.client.executeRpc(jsonRequest);
    } catch (e) {
      log('RPC call error: $e', path: 'mm2 => call', isError: true).ignore();
      rethrow;
    }
  }

  // this is a necessary evil for now becuase of the RPC models that override
  // or use the `late String? userpass` field, which would require refactoring
  // most of the RPC models and directly affected code.
  dynamic _assertPass(dynamic req) {
    if (req is List) {
      for (final dynamic element in req) {
        // ignore: avoid_dynamic_calls
        element.userpass = '';
      }
    } else {
      if (req is Map) {
        req['userpass'] = '';
      } else {
        // ignore: avoid_dynamic_calls
        req.userpass = '';
      }
    }

    return req;
  }

  void _handleSdkLog(String message) {
    log(message, path: 'KomodoDefiSdk').ignore();
  }
}

// 0 - MM2 is not running yet.
// 1 - MM2 is running, but no context yet.
// 2 - MM2 is running, but no RPC yet.
// 3 - MM2's RPC is up.
enum MM2Status {
  isNotRunningYet,
  runningWithoutContext,
  runningWithoutRPC,
  rpcIsUp;

  static MM2Status fromInt(int status) {
    switch (status) {
      case 0:
        return isNotRunningYet;
      case 1:
        return runningWithoutContext;
      case 2:
        return runningWithoutRPC;
      case 3:
        return rpcIsUp;
      default:
        return isNotRunningYet;
    }
  }
}
