import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/services/mm_engine/mm_engine_install_service.dart';
import 'package:web_dex/services/mm_engine/mm_engine_service.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_strategy_form.dart';

/// A thin wallet client. Strategy and exchange logic belongs to MM_Engine.
class MarketMakerBotPage extends StatefulWidget {
  const MarketMakerBotPage({super.key});

  @override
  State<MarketMakerBotPage> createState() => _MarketMakerBotPageState();
}

class _MarketMakerBotPageState extends State<MarketMakerBotPage> {
  bool _busy = true;
  bool _installed = false;
  String? _error;
  Map<String, dynamic>? _strategies;
  Map<String, dynamic>? _reconciliation;
  Map<String, dynamic>? _credentials;
  Map<String, dynamic>? _markets;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      _installed = await MmEngineInstallService.currentExecutable() != null;
      if (_installed) {
        await _connect();
      }
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _connect() async {
    final user = context.read<AuthBloc>().state.currentUser;
    if (user == null) {
      throw StateError('Log in to the wallet before opening MM_Engine');
    }
    await MmEngineService.instance.start(
      sdk: RepositoryProvider.of<KomodoDefiSdk>(context),
      walletId: user.walletId.compoundId,
    );
    await _refresh();
  }

  Future<void> _refresh() async {
    final engine = MmEngineService.instance;
    final strategies = await engine.request('GET', '/v1/strategies');
    final reconciliation = await engine.request('GET', '/v1/reconciliation');
    final credentials = await engine.request('GET', '/v1/credentials/status');
    final markets = await engine.request('GET', '/v1/markets');
    if (!mounted) return;
    setState(() {
      _strategies = strategies;
      _reconciliation = reconciliation;
      _credentials = credentials;
      _markets = markets;
      _error = null;
    });
  }

  Future<void> _runBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setLive(bool enabled) async {
    final keyring = _credentials?['venues'];
    if (enabled && (keyring is! Map || keyring['MEXC'] != true)) {
      setState(
        () => _error = 'Configure MEXC credentials before live trading.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enabled ? 'Enable live trading?' : 'Stop live trading?'),
        content: Text(
          enabled
              ? 'MM_Engine can publish funded KDF maker orders and place real '
                    'hedges on the selected CEX after you start a strategy. '
                    'Enabled strategies resume when you next open this wallet. '
                    'Check balances, CEX API permissions and strategy limits first.'
              : 'The engine will cancel its open maker orders and restart in '
                    'preview mode. Active swaps must finish first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(enabled ? 'Enable live mode' : 'Stop live mode'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final user = context.read<AuthBloc>().state.currentUser;
    final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    if (user == null) throw StateError('Wallet is no longer signed in');
    await _runBusy(() async {
      await MmEngineService.instance.stop();
      if (!enabled) {
        await MmEngineService.instance.clearLivePreference(
          user.walletId.compoundId,
        );
      }
      await MmEngineService.instance.start(
        sdk: sdk,
        walletId: user.walletId.compoundId,
        liveTrading: enabled,
      );
      await _refresh();
    });
  }

  Future<void> _configureCredentials(String venue) async {
    final key = TextEditingController();
    final secret = TextEditingController();
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Configure $venue Spot API'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Use a trading-only API key. Transfer permissions '
                  'are not used by MM_Engine.',
                ),
                TextField(
                  controller: key,
                  decoration: const InputDecoration(labelText: 'API key'),
                ),
                TextField(
                  controller: secret,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'API secret'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Store in system keyring'),
            ),
          ],
        ),
      );
      if (submitted != true || !mounted) return;
      final apiKey = key.text.trim();
      final apiSecret = secret.text.trim();
      if (apiKey.isEmpty || apiSecret.isEmpty) {
        setState(() => _error = 'Both API key and secret are required.');
        return;
      }
      await _runBusy(() async {
        await MmEngineService.instance.request(
          'POST',
          '/v1/credentials/store',
          body: {
            'venue': venue,
            'api_key': apiKey,
            'api_secret': apiSecret,
            'confirmation': 'STORE $venue',
          },
        );
        await _refresh();
      });
    } finally {
      key.dispose();
      secret.dispose();
    }
  }

  Future<void> _createStrategy() async {
    final markets = _markets?['markets'];
    if (markets is! Map || markets.isEmpty) {
      setState(() => _error = 'No KDF markets are available.');
      return;
    }
    final spec = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => MmEngineStrategyForm(
        markets: markets.keys.whereType<String>().toList(),
      ),
    );
    if (spec == null || !mounted) return;
    await _runBusy(() async {
      final preview = await MmEngineService.instance.request(
        'POST',
        '/v1/strategies/preview',
        body: {
          'specs': [spec],
        },
      );
      if (!mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Save strategy paused?'),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(preview['previews']),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save paused'),
            ),
          ],
        ),
      );
      if (accepted != true) return;
      await MmEngineService.instance.request(
        'POST',
        '/v1/strategies/create',
        body: {
          'specs': [spec],
          'confirmation': 'SALVA IN PAUSA',
        },
      );
      await _refresh();
    });
  }

  Future<void> _changeStrategy(String id, {required bool start}) async {
    if (start && !MmEngineService.instance.liveEnabled) {
      setState(() => _error = 'Enable live mode before starting a strategy.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(start ? 'Start $id?' : 'Pause $id?'),
        content: Text(
          start
              ? 'This can publish real KDF maker orders and hedge completed '
                    'swaps on the selected exchange.'
              : 'This will cancel the strategy’s maker order.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(start ? 'Start' : 'Pause'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runBusy(() async {
      await MmEngineService.instance.request(
        'POST',
        start ? '/v1/strategies/start' : '/v1/strategies/pause',
        body: {
          'strategy_id': id,
          'confirmation': '${start ? 'AVVIA' : 'PAUSA'} $id',
        },
      );
      await _refresh();
    });
  }

  Future<void> _download() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final release = await MmEngineInstallService.latestRelease();
      if (!mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Install MM_Engine?'),
          content: Text(
            'Download version ${release.tag} from the MM_Engine repository. '
            'P2Pirate will verify that the release is immutable and its '
            'binary matches the SHA-256 published by GitHub.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Download'),
            ),
          ],
        ),
      );
      if (accepted != true || !mounted) return;
      if (MmEngineService.instance.isRunning) {
        await MmEngineService.instance.stop();
      }
      await MmEngineInstallService.install(release);
      _installed = true;
      await _connect();
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _strategies?['strategies'];
    final strategies = rows is List
        ? rows.whereType<Map<String, dynamic>>()
        : <Map<String, dynamic>>[];
    final keyring = _credentials?['venues'];
    final credentials = keyring is Map ? keyring : const {};
    final live = MmEngineService.instance.liveEnabled;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1050),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Trading engine',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const Spacer(),
                if (_installed && MmEngineService.instance.isRunning)
                  TextButton.icon(
                    onPressed: _busy ? null : _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                if (_installed)
                  TextButton.icon(
                    onPressed: _busy ? null : _download,
                    icon: const Icon(Icons.system_update_alt),
                    label: const Text('Check updates'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'MM_Engine runs as a separate application connected to this '
              'wallet’s KDF and Tor processes. Enabling this page never '
              'starts live trading.',
            ),
            const SizedBox(height: 20),
            if (_busy) const LinearProgressIndicator(),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: SelectableText(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!_installed)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('MM_Engine is not installed'),
                      const SizedBox(height: 10),
                      const Text(
                        'The wallet can download the latest verified Linux release when you choose.',
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _busy ? null : _download,
                        child: const Text('Check and download'),
                      ),
                    ],
                  ),
                ),
              )
            else if (MmEngineService.instance.isRunning) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    '${live ? 'LIVE trading enabled' : 'Preview mode'} · '
                    'Active swaps: ${_reconciliation?['active_owned_swaps'] ?? '—'} · '
                    'Open maker orders: ${_reconciliation?['owned_open_orders'] ?? '—'}',
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _configureCredentials('MEXC'),
                    child: Text(
                      'MEXC key: ${credentials['MEXC'] == true ? 'configured' : 'configure'}',
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _busy
                        ? null
                        : () => _configureCredentials('GATE'),
                    child: Text(
                      'Gate key: ${credentials['GATE'] == true ? 'configured' : 'configure'}',
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _busy ? null : () => _setLive(!live),
                    child: Text(
                      live ? 'Stop live trading' : 'Enable live trading',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Strategies',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    onPressed: _busy ? null : _createStrategy,
                    icon: const Icon(Icons.add),
                    label: const Text('New strategy'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              if (strategies.isEmpty)
                const Text(
                  'No strategies have been created for this wallet profile.',
                )
              else
                ...strategies.map((row) {
                  final spec = row['spec'];
                  final details = spec is Map ? spec : const {};
                  return Card(
                    child: ListTile(
                      title: Text(row['id']?.toString() ?? 'Strategy'),
                      subtitle: Text(
                        '${details['cex'] ?? '—'} · ${details['side'] ?? '—'} · '
                        '${row['state'] ?? '—'} · '
                        'Remaining: ${row['remaining_sold'] ?? '—'}',
                      ),
                      trailing: TextButton(
                        onPressed: _busy
                            ? null
                            : () => _changeStrategy(
                                row['id']?.toString() ?? '',
                                start: row['enabled'] != 1,
                              ),
                        child: Text(row['enabled'] == 1 ? 'Pause' : 'Start'),
                      ),
                    ),
                  );
                }),
            ],
          ],
        ),
      ),
    );
  }
}
