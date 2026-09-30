import 'dart:async';
import 'dart:io' show HttpOverrides;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kDebugMode, kIsWasm, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:komodo_cex_market_data/komodo_cex_market_data.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_dex/analytics/widgets/analytics_lifecycle_handler.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/app_config/package_information.dart';
import 'package:web_dex/bloc/analytics/analytics_repo.dart';
import 'package:web_dex/bloc/app_bloc_observer.dart';
import 'package:web_dex/bloc/app_bloc_root.dart' deferred as app_bloc_root;
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/cex_market_data/cex_market_data.dart';
import 'package:web_dex/bloc/cex_market_data/mockup/performance_mode.dart';
import 'package:web_dex/bloc/coins_bloc/coins_repo.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/bloc/trading_status/trading_status_repository.dart';
import 'package:web_dex/bloc/trading_status/trading_status_service.dart';
import 'package:web_dex/blocs/wallets_repository.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/mm2/mm2_api/mm2_api.dart';
import 'package:web_dex/model/stored_settings.dart';
import 'package:web_dex/performance_analytics/performance_analytics.dart';
import 'package:web_dex/sdk/widgets/window_close_handler.dart';
import 'package:web_dex/services/arrr_activation/arrr_activation_service.dart';
import 'package:web_dex/services/fd_monitor_service.dart';
import 'package:web_dex/services/feedback/app_feedback_wrapper.dart';
import 'package:web_dex/services/logger/get_logger.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/services/tor/pirate_tor_service.dart';
import 'package:web_dex/services/tor/pirate_tor_http_overrides.dart';
import 'package:web_dex/services/tor/pirate_webview_proxy.dart';
import 'package:web_dex/shared/constants.dart';
import 'package:web_dex/shared/screenshot/screenshot_sensitivity.dart';
import 'package:web_dex/shared/utils/platform_tuner.dart';
import 'package:web_dex/shared/utils/utils.dart';

part 'services/initializer/app_bootstrapper.dart';

PerformanceMode? _appDemoPerformanceMode;
bool _startupAborted = false;

PerformanceMode? get appDemoPerformanceMode =>
    _appDemoPerformanceMode ?? _getPerformanceModeFromUrl();

Future<void> main() async {
  await runZonedGuarded(() async {
    usePathUrlStrategy();
    WidgetsFlutterBinding.ensureInitialized();
    Bloc.observer = AppBlocObserver();
    PerformanceAnalytics.init();

    FlutterError.onError = (FlutterErrorDetails details) {
      catchUnhandledExceptions(details.exception, details.stack);
    };

    final stored = await SettingsRepository.loadStoredSettings();
    final torRequested =
        stored.torEnabled &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.linux;
    if (torRequested) {
      runApp(const _TorStarting());
      try {
        await PirateTorService.instance.start();
        HttpOverrides.global = PirateTorHttpOverrides(
          PirateTorService.instance.httpProxyPort!,
        );
        await PirateWebViewProxy.configure(
          PirateTorService.instance.httpProxyPort!,
        );
      } catch (error) {
        await PirateTorService.instance.stop();
        HttpOverrides.global = null;
        runApp(
          _TorStartupError(
            error: error.toString(),
            onDisable: () async {
              await SettingsRepository().updateSettings(
                stored.copyWith(torEnabled: false),
              );
              await _startWalletApp();
            },
          ),
        );
        return;
      }
    }

    try {
      if (torRequested) {
        await _startWalletApp().timeout(const Duration(minutes: 2));
      } else {
        await _startWalletApp();
      }
    } catch (error) {
      if (!torRequested) rethrow;
      _startupAborted = true;
      runApp(
        _TorStartupError(
          error: error.toString(),
          buttonLabel: 'Disable Tor for next launch',
          onDisable: () async {
            await SettingsRepository().updateSettings(
              stored.copyWith(torEnabled: false),
            );
            runApp(const _TorRestartRequired());
          },
        ),
      );
    }
  }, catchUnhandledExceptions);
}

Future<void> _startWalletApp() async {
  final KomodoDefiSdk komodoDefiSdk = await mm2.initialize();

  // Note: SDK debug logging is now controlled by the diagnostic logging toggle
  // in Settings. The flags are initialized in SettingsBloc from stored settings.

  final mm2Api = Mm2Api(mm2: mm2, sdk: komodoDefiSdk);
  // Sparkline is dependent on Hive initialization, so we pass it on to the
  // bootstrapper here
  final sparklineRepository = SparklineRepository.defaultInstance();
  await AppBootstrapper.instance.ensureInitialized(
    komodoDefiSdk,
    mm2Api,
    sparklineRepository,
  );

  final tradingStatusRepository = TradingStatusRepository(komodoDefiSdk);
  final tradingStatusService = TradingStatusService(tradingStatusRepository);
  await tradingStatusService.initialize();
  final arrrActivationService = ArrrActivationService(komodoDefiSdk, mm2);

  final coinsRepo = CoinsRepo(
    kdfSdk: komodoDefiSdk,
    mm2: mm2,
    tradingStatusService: tradingStatusService,
    arrrActivationService: arrrActivationService,
  );
  final walletsRepository = WalletsRepository(
    komodoDefiSdk,
    mm2Api,
    getStorage(),
  );

  // Start FD monitoring on iOS (works in both Debug and Release)
  if (PlatformTuner.isIOS) {
    try {
      final result = await FdMonitorService().start(intervalSeconds: 60.0);
      if (result['success'] == true) {
        log(
          'FD Monitor started successfully in ${kDebugMode ? "DEBUG" : "RELEASE"} mode',
        );
      } else {
        log('FD Monitor failed to start: ${result['message']}');
      }
    } catch (e) {
      log('Failed to start FD Monitor: $e');
    }
  }

  // A timed-out SDK initialization can complete later. Keep the error screen.
  if (_startupAborted) return;
  runApp(
    EasyLocalization(
      supportedLocales: localeList,
      fallbackLocale: localeList.first,
      useFallbackTranslations: true,
      useOnlyLangCode: true,
      path: '$assetsPath/translations',
      child: MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: komodoDefiSdk),
          RepositoryProvider.value(value: mm2Api),
          RepositoryProvider.value(value: arrrActivationService),
          RepositoryProvider.value(value: coinsRepo),
          RepositoryProvider.value(value: walletsRepository),
          RepositoryProvider.value(value: sparklineRepository),
          RepositoryProvider.value(value: tradingStatusRepository),
          RepositoryProvider.value(value: tradingStatusService),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class _TorStarting extends StatelessWidget {
  const _TorStarting();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'P2Pirate',
    home: Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Connecting through Tor and loading wallet…'),
          ],
        ),
      ),
    ),
  );
}

class _TorStartupError extends StatelessWidget {
  const _TorStartupError({
    required this.error,
    required this.onDisable,
    this.buttonLabel = 'Disable Tor and continue',
  });

  final String error;
  final Future<void> Function() onDisable;
  final String buttonLabel;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'P2Pirate',
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet could not start over Tor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'No direct connection was made. Check Tor connectivity and restart. You can disable Tor explicitly for the next launch.',
                ),
                const SizedBox(height: 12),
                SelectableText(error),
                const SizedBox(height: 24),
                FilledButton(onPressed: onDisable, child: Text(buttonLabel)),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TorRestartRequired extends StatelessWidget {
  const _TorRestartRequired();

  @override
  Widget build(BuildContext context) => const MaterialApp(
    title: 'P2Pirate',
    home: Scaffold(
      body: Center(child: Text('Tor is disabled. Close and reopen P2Pirate.')),
    ),
  );
}

void catchUnhandledExceptions(Object error, StackTrace? stack) {
  log('Uncaught exception: $error.\n$stack');
  if (isTestMode) {
    debugPrintStack(stackTrace: stack, label: error.toString(), maxFrames: 100);
  }

  // Rethrow the error if it has a stacktrace (valid, traceable error)
  // async errors from the sdk are not traceable so do not rethrow them.
  if (!isTestMode && stack != null && stack.toString().isNotEmpty) {
    Error.throwWithStackTrace(error, stack);
  }
}

PerformanceMode? _getPerformanceModeFromUrl() {
  String? maybeEnvPerformanceMode;

  maybeEnvPerformanceMode = const bool.hasEnvironment('DEMO_MODE_PERFORMANCE')
      ? const String.fromEnvironment('DEMO_MODE_PERFORMANCE')
      : null;

  if (kIsWeb) {
    final uri = Uri.base;
    maybeEnvPerformanceMode =
        uri.queryParameters['demo_mode_performance'] ?? maybeEnvPerformanceMode;
  }

  switch (maybeEnvPerformanceMode) {
    case 'good':
      return PerformanceMode.good;
    case 'mediocre':
      return PerformanceMode.mediocre;
    case 'very_bad':
      return PerformanceMode.veryBad;
    default:
      return null;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final komodoDefiSdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    final walletsRepository = RepositoryProvider.of<WalletsRepository>(context);
    final tradingStatusService = RepositoryProvider.of<TradingStatusService>(
      context,
    );

    final sensitivityController = ScreenshotSensitivityController();
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>(
          create: (_) {
            final bloc = AuthBloc(
              komodoDefiSdk,
              walletsRepository,
              SettingsRepository(),
              tradingStatusService,
            );
            bloc.add(const AuthLifecycleCheckRequested());
            return bloc;
          },
        ),
      ],
      child: AppFeedbackWrapper(
        child: AnalyticsLifecycleHandler(
          child: WindowCloseHandler(
            child: ScreenshotSensitivity(
              controller: sensitivityController,
              child: app_bloc_root.AppBlocRoot(
                storedPrefs: _storedSettings!,
                komodoDefiSdk: komodoDefiSdk,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
