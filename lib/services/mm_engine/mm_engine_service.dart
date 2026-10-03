import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:komodo_coins/komodo_coins.dart' show StartupCoinsProvider;
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/services/mm_engine/mm_engine_install_service.dart';
import 'package:web_dex/services/mm_engine/mm_engine_http_client.dart';
import 'package:web_dex/services/tor/pirate_tor_service.dart';

/// The wallet is the KDF/Tor owner; this client only supervises MM_Engine.
/// The service continues running when its page is hidden and stops at logout
/// or application close. Every profile gets an isolated persistent journal.
class MmEngineService {
  MmEngineService._();

  static final MmEngineService instance = MmEngineService._();

  final ValueNotifier<String?> attention = ValueNotifier<String?>(null);

  Process? _process;
  Uri? _baseUrl;
  String? _token;
  String? _profile;
  bool _liveEnabled = false;
  bool _stopping = false;
  bool _needsRecovery = false;
  Future<void>? _starting;
  Completer<Map<String, dynamic>>? _stopReport;

  bool get isRunning => _process != null && _baseUrl != null;
  bool get liveEnabled => _liveEnabled;
  bool get needsRecovery => _needsRecovery;
  String? get profile => _profile;

  Future<void> start({
    required KomodoDefiSdk sdk,
    required String walletId,
    bool? liveTrading,
  }) => _starting ??= _start(
    sdk: sdk,
    walletId: walletId,
    liveTrading: liveTrading,
  ).whenComplete(() => _starting = null);

  Future<void> _start({
    required KomodoDefiSdk sdk,
    required String walletId,
    required bool? liveTrading,
  }) async {
    bool desiredLive;
    try {
      desiredLive = liveTrading ?? await _readLivePreference(walletId);
    } catch (_) {
      _needsRecovery = true;
      rethrow;
    }
    if (isRunning && _profile == walletId && _liveEnabled == desiredLive) {
      return;
    }
    if (desiredLive) _needsRecovery = true;
    if (_needsRecovery && !desiredLive) {
      throw StateError('MM_Engine needs live recovery before preview mode');
    }
    if (_process != null) await _stopProcess();
    if (!Platform.isLinux) {
      throw UnsupportedError(
        'MM_Engine wallet integration currently supports Linux',
      );
    }
    final executable = await MmEngineInstallService.currentExecutable();
    if (executable == null) throw StateError('MM_Engine is not installed');
    final password = await sdk.getRpcPassword();
    if (password == null || password.isEmpty) {
      throw StateError('KDF RPC credentials are not available');
    }
    final stored = await SettingsRepository.loadStoredSettings();
    final torPort = PirateTorService.instance.httpProxyPort;
    if (stored.torEnabled && torPort == null) {
      throw StateError('Tor is required but its proxy is unavailable');
    }
    final stateDir = await _profileDirectory(walletId);
    await stateDir.create(recursive: true);
    final permissions = await Process.run('chmod', ['700', stateDir.path]);
    if (permissions.exitCode != 0) {
      throw StateError('Cannot protect MM_Engine profile directory');
    }
    final coins = await StartupCoinsProvider.fetchRawCoinsForStartup();
    final coinsFile = File(p.join(stateDir.path, 'coins.json'));
    await coinsFile.writeAsString(jsonEncode(coins), flush: true);
    final token = _randomToken();
    final process = await Process.start(executable.path, ['wallet-service']);
    _process = process;
    final ready = Completer<int>();
    _stopReport = Completer<Map<String, dynamic>>();
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen(
          (line) {
            if (line.startsWith('MM_ENGINE_STOPPED ')) {
              try {
                final payload = jsonDecode(
                  line.substring('MM_ENGINE_STOPPED '.length),
                );
                if (payload is! Map<String, dynamic>) {
                  throw const FormatException('Invalid MM_Engine stop report');
                }
                if (_stopReport?.isCompleted == false) {
                  _stopReport!.complete(payload);
                }
              } catch (error) {
                if (_stopReport?.isCompleted == false) {
                  _stopReport!.completeError(error);
                }
              }
              return;
            }
            if (!line.startsWith('MM_ENGINE_READY ') || ready.isCompleted) {
              return;
            }
            try {
              final message = jsonDecode(
                line.substring('MM_ENGINE_READY '.length),
              );
              if (message is! Map<String, dynamic> ||
                  message['protocol'] != 1 ||
                  message['port'] is! int ||
                  message['port'] < 1) {
                throw const FormatException('Incompatible MM_Engine protocol');
              }
              ready.complete(message['port'] as int);
            } catch (error) {
              ready.completeError(error);
            }
          },
          onError: (Object error) {
            if (!ready.isCompleted) ready.completeError(error);
          },
        );
    unawaited(process.stderr.drain<void>());
    unawaited(
      process.exitCode.then((code) {
        if (!ready.isCompleted) {
          ready.completeError(
            StateError('MM_Engine exited before startup ($code)'),
          );
        }
        if (identical(_process, process)) {
          if (!_stopping && desiredLive) {
            _needsRecovery = true;
            attention.value =
                'Trading engine stopped unexpectedly. Open it to recover.';
          }
          _process = null;
          _baseUrl = null;
          _token = null;
          _profile = null;
        }
      }),
    );
    final rpcPort = const int.fromEnvironment(
      'P2PIRATE_LOCAL_RPC_PORT',
      defaultValue: 7783,
    );
    final bootstrap = <String, Object>{
      'state_dir': stateDir.path,
      'coin_registry_path': coinsFile.path,
      'kdf_rpc_url': 'http://127.0.0.1:$rpcPort',
      'kdf_rpc_userpass': password,
      'agent_token': token,
      // Isolate CEX keys from other wallets and the standalone TUI profile.
      'cex_profile':
          'p2p-${sha256.convert(utf8.encode(walletId)).toString().substring(0, 48)}',
      'network_mode': stored.torEnabled ? 'tor' : 'direct',
      if (stored.torEnabled) 'tor_http_proxy': 'http://127.0.0.1:$torPort',
      'with_cex': desiredLive,
      'live': {
        'kdf_order_writes': desiredLive,
        'auto_hedge': desiredLive,
        'cex_trading': desiredLive,
      },
    };
    try {
      process.stdin.writeln(jsonEncode(bootstrap));
      await process.stdin.flush();
      final port = await ready.future.timeout(const Duration(seconds: 30));
      _baseUrl = Uri.parse('http://127.0.0.1:$port');
      _token = token;
      _profile = walletId;
      final capabilities = await request('GET', '/v1/capabilities');
      if (capabilities['protocol'] != 1 ||
          capabilities['kdf_owner'] != 'wallet' ||
          capabilities['live_enabled'] != desiredLive) {
        throw StateError('MM_Engine is incompatible with this wallet');
      }
      _liveEnabled = desiredLive;
      _needsRecovery = false;
      attention.value = null;
      if (liveTrading != null) {
        await _writeLivePreference(walletId, liveTrading);
      }
    } catch (_) {
      if (desiredLive) {
        _needsRecovery = true;
        attention.value =
            'Trading engine needs recovery before closing the wallet.';
      }
      await _forceStopFailedStartup(process);
      rethrow;
    }
  }

  Future<Directory> _profileDirectory(String walletId) async {
    final support = await getApplicationSupportDirectory();
    final hash = sha256.convert(utf8.encode(walletId)).toString();
    return Directory(p.join(support.path, 'mm-engine', 'profiles', hash));
  }

  Future<bool> _readLivePreference(String walletId) async {
    final directory = await _profileDirectory(walletId);
    final file = File(p.join(directory.path, 'wallet-preferences.json'));
    if (!await file.exists()) return false;
    final decoded = jsonDecode(await file.readAsString());
    if (decoded is! Map<String, dynamic> || decoded['live_enabled'] is! bool) {
      throw StateError('MM_Engine wallet preference is invalid');
    }
    return decoded['live_enabled'] as bool;
  }

  Future<void> _writeLivePreference(String walletId, bool enabled) async {
    final directory = await _profileDirectory(walletId);
    await directory.create(recursive: true);
    final permissions = await Process.run('chmod', ['700', directory.path]);
    if (permissions.exitCode != 0) {
      throw StateError('Cannot protect MM_Engine profile directory');
    }
    final file = File(p.join(directory.path, 'wallet-preferences.json'));
    await file.writeAsString(
      jsonEncode({'live_enabled': enabled}),
      flush: true,
    );
    final filePermissions = await Process.run('chmod', ['600', file.path]);
    if (filePermissions.exitCode != 0) {
      throw StateError('Cannot protect MM_Engine wallet preferences');
    }
  }

  Future<void> clearLivePreference(String walletId) =>
      _writeLivePreference(walletId, false);

  Future<void> _forceStopFailedStartup(Process process) async {
    await process.stdin.close();
    try {
      await process.exitCode.timeout(const Duration(seconds: 10));
    } on TimeoutException {
      process.kill(ProcessSignal.sigterm);
      await process.exitCode.timeout(const Duration(seconds: 5));
    } finally {
      if (identical(_process, process)) {
        _clearProcess();
      }
    }
  }

  Future<Map<String, dynamic>> request(
    String method,
    String path, {
    Map<String, Object?> body = const {},
  }) async {
    final baseUrl = _baseUrl;
    final token = _token;
    if (baseUrl == null || token == null) {
      throw StateError('MM_Engine is not running');
    }
    return sendMmEngineRequest(baseUrl, token, method, path, body: body);
  }

  Future<void> stop() async {
    final starting = _starting;
    if (starting != null) {
      try {
        await starting;
      } catch (_) {
        // The failed startup cleanup has already run.
      }
    }
    await _stopProcess();
  }

  Future<void> _stopProcess() async {
    final process = _process;
    if (process == null) {
      if (_needsRecovery) {
        throw StateError(
          'MM_Engine exited unexpectedly; recover maker orders and hedges',
        );
      }
      return;
    }
    final reconciliation = await request('GET', '/v1/reconciliation');
    final activeSwaps = reconciliation['active_owned_swaps'];
    final openOrders = reconciliation['owned_open_orders'];
    final problemOrders = reconciliation['problem_orders'];
    if (activeSwaps is! int ||
        activeSwaps > 0 ||
        openOrders is! int ||
        problemOrders is! int ||
        problemOrders > 0) {
      throw StateError(
        'MM_Engine has active swaps or unresolved order problems. '
        'Keep P2Pirate open and check the trading journal.',
      );
    }
    _stopping = true;
    try {
      if (_baseUrl != null) {
        await request(
          'POST',
          '/v1/engine/shutdown',
        ).timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Closing stdin still asks the engine to reconcile and withdraw orders.
    }
    await process.stdin.close();
    try {
      final exit = await process.exitCode.timeout(const Duration(seconds: 30));
      final report = await _stopReport?.future.timeout(
        const Duration(seconds: 2),
      );
      if (exit != 0 ||
          report == null ||
          report['orders_remaining'] != 0 ||
          report['cancel_error'] != null) {
        throw StateError(
          'MM_Engine could not confirm cancellation of its maker orders. '
          'Keep KDF and Tor running and inspect the trading journal.',
        );
      }
      _needsRecovery = false;
      attention.value = null;
    } on TimeoutException {
      _needsRecovery = true;
      attention.value = 'Trading engine did not stop safely.';
      throw StateError('MM_Engine did not stop; check open maker orders');
    } catch (_) {
      _needsRecovery = true;
      attention.value = 'Trading engine could not confirm order cancellation.';
      rethrow;
    } finally {
      _stopping = false;
      if (identical(_process, process) &&
          await process.exitCode.timeout(
                const Duration(seconds: 1),
                onTimeout: () => -999,
              ) !=
              -999) {
        _clearProcess();
      }
    }
  }

  void _clearProcess() {
    _process = null;
    _baseUrl = null;
    _token = null;
    _profile = null;
    _liveEnabled = false;
    _stopReport = null;
  }

  String _randomToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(48, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
