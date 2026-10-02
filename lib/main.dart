import 'dart:async';
import 'dart:io' show HttpOverrides, ProcessSignal, exit;

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
import 'package:web_dex/services/kdf_install/kdf_install_service.dart';
import 'package:web_dex/services/kdf_install/kdf_setup_screen.dart';
import 'package:web_dex/services/logger/ui_performance_diagnostics.dart';
import 'package:web_dex/services/storage/get_storage.dart';
import 'package:web_dex/services/tor/pirate_tor_service.dart';
import 'package:web_dex/services/tor/pirate_tor_status.dart';
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
    UiPerformanceDiagnostics.start();

    FlutterError.onError = (FlutterErrorDetails details) {
      catchUnhandledExceptions(details.exception, details.stack);
    };

    final stored = await SettingsRepository.loadStoredSettings();
    mm2.configurePriceApi(stored.customPriceApiUrl);
    final torRequested =
        stored.torEnabled &&
        !kIsWeb &&
        defaultTargetPlatform == TargetPlatform.linux;
    if (torRequested) {
      for (final signal in [ProcessSignal.sigint, ProcessSignal.sigterm]) {
        signal.watch().listen((_) async {
          try {
            await PirateTorService.instance.shutdown().timeout(
              const Duration(seconds: 15),
            );
          } finally {
            exit(0);
          }
        });
      }
      runApp(const WindowCloseHandler(child: _TorStarting()));
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
        _showTorFailure(error.toString(), stored);
        return;
      }
    }

    try {
      await _ensureKdfReady();
      if (torRequested) {
        await _startWalletApp().timeout(const Duration(minutes: 2));
      } else {
        await _startWalletApp();
      }
      if (torRequested && !_startupAborted) {
        // A Tor process can exit after the wallet has opened. Stop showing
        // the wallet and ask before any direct connection can be selected.
        void onTorStatusChanged() {
          if (pirateTorStatus.value != PirateTorStatus.unavailable ||
              _startupAborted) {
            return;
          }
          _startupAborted = true;
          _showTorFailure('Tor stopped while the wallet was running.', stored);
          unawaited(mm2.dispose());
        }

        pirateTorStatus.addListener(onTorStatusChanged);
        onTorStatusChanged();
      }
    } catch (error) {
      if (!torRequested) rethrow;
      _startupAborted = true;
      _showTorFailure(error.toString(), stored);
    }
  }, catchUnhandledExceptions);
}

Future<void> _ensureKdfReady() async {
  if (kIsWeb ||
      defaultTargetPlatform != TargetPlatform.linux ||
      await KdfInstallService.hasExecutable()) {
    return;
  }
  final ready = Completer<void>();
  runApp(
    WindowCloseHandler(
      child: KdfSetupScreen(
        onReady: () {
          if (!ready.isCompleted) ready.complete();
        },
      ),
    ),
  );
  await ready.future;
}

void _showTorFailure(String error, StoredSettings stored) {
  runApp(
    _TorStartupError(
      error: error,
      onRetry: () => runApp(
        const _TorRestartRequired(
          message: 'Close and reopen P2Pirate to retry Tor.',
        ),
      ),
      onUseDirect: () async {
        await SettingsRepository().updateSettings(
          stored.copyWith(torEnabled: false),
        );
        runApp(
          const _TorRestartRequired(
            message:
                'Tor is disabled for the next launch. Close and reopen P2Pirate to use a direct connection.',
          ),
        );
      },
      onClose: () async {
        try {
          await mm2.dispose().timeout(const Duration(seconds: 5));
        } catch (_) {
          // Closing still takes priority if SDK cleanup has stalled.
        }
        try {
          await PirateTorService.instance.stop().timeout(
            const Duration(seconds: 5),
          );
        } finally {
          exit(0);
        }
      },
    ),
  );
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

class _TorStartupError extends StatefulWidget {
  const _TorStartupError({
    required this.error,
    required this.onRetry,
    required this.onUseDirect,
    required this.onClose,
  });

  final String error;
  final VoidCallback onRetry;
  final Future<void> Function() onUseDirect;
  final Future<void> Function() onClose;

  @override
  State<_TorStartupError> createState() => _TorStartupErrorState();
}

class _TorStartupErrorState extends State<_TorStartupError> {
  bool _busy = false;
  String? _actionError;

  Future<void> _runAction(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _actionError = null;
    });
    try {
      await action();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _actionError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'P2Pirate',
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Wallet could not continue over Tor',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'P2Pirate will not use a direct connection unless you choose it. How would you like to proceed?',
                ),
                const SizedBox(height: 12),
                SelectableText(widget.error),
                if (_actionError != null) ...[
                  const SizedBox(height: 12),
                  SelectableText('Could not save your choice: $_actionError'),
                ],
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _busy ? null : widget.onRetry,
                  child: const Text('Retry Tor after restart'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _runAction(widget.onUseDirect),
                  child: const Text('Use direct connection after restart'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy ? null : () => _runAction(widget.onClose),
                  child: const Text('Close wallet'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _TorRestartRequired extends StatelessWidget {
  const _TorRestartRequired({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'P2Pirate',
    home: Scaffold(body: Center(child: Text(message))),
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
