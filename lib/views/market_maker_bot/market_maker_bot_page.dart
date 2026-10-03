import 'package:flutter/material.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_trading_controls.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_balance_refresh.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_defi_sdk/komodo_defi_sdk.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/services/mm_engine/mm_engine_install_service.dart';
import 'package:web_dex/services/mm_engine/mm_engine_service.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_strategy_form.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_preview.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_dashboard.dart';

/// A thin wallet client. Strategy and exchange logic belongs to P2Pirate Trading Engine.
class MarketMakerBotPage extends StatefulWidget {
  const MarketMakerBotPage({super.key});

  @override
  State<MarketMakerBotPage> createState() => _MarketMakerBotPageState();
}

class _MarketMakerBotPageState extends State<MarketMakerBotPage> {
  bool _busy = true;
  bool _installed = false;
  String? _error;
  String? _downloadStatus;
  MmEngineInstallProgress? _downloadProgress;
  Map<String, dynamic>? _strategies;
  Map<String, dynamic>? _reconciliation;
  Map<String, dynamic>? _credentials;
  Map<String, dynamic>? _markets;
  List<Map<String, dynamic>> _orders = [];
  final _selectedOrders = <String>{};
  late final MmEngineBalanceRefresh _balanceRefresh;
  String get _venue => _balanceRefresh.venue;
  bool get _balanceLoading => _balanceRefresh.loading;

  Future<List<Map<String, dynamic>>> _fetchBalances(String venue) async {
    final result = await MmEngineService.instance.request(
      'GET',
      '/v1/exchanges/balances?venue=$venue',
    );
    if (!mounted) return [];
    final assets = RepositoryProvider.of<KomodoDefiSdk>(
      context,
    ).assets.available.values;
    final names = <String, String>{
      for (final asset in assets) asset.id.id: asset.id.name,
    };
    final rows = result['balances'];
    if (rows is! List) throw const FormatException('Missing Spot balances');
    return rows
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => <String, dynamic>{
            ...row,
            'name': names[row['ticker']] ?? row['ticker'],
          },
        )
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _balanceRefresh = MmEngineBalanceRefresh(
      load: _fetchBalances,
      canRefresh: (venue) =>
          !_busy &&
          MmEngineService.instance.isRunning &&
          (_credentials?['venues'] as Map?)?[venue] == true,
    )..addListener(_onBalanceChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _onBalanceChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _balanceRefresh.removeListener(_onBalanceChanged);
    _balanceRefresh.dispose();
    super.dispose();
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
    _balanceRefresh.invalidate(clear: true);
    final user = context.read<AuthBloc>().state.currentUser;
    if (user == null) {
      throw StateError(
        'Log in to the wallet before opening P2Pirate Trading Engine',
      );
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
    final orders = await engine.request('GET', '/v1/orders');
    if (!mounted) return;
    setState(() {
      _strategies =
          orders['strategy_states'] as Map<String, dynamic>? ?? strategies;
      _reconciliation = reconciliation;
      _credentials = credentials;
      _markets = markets;
      _orders = (orders['orders'] as List)
          .whereType<Map<String, dynamic>>()
          .toList();
      final saved =
          (_strategies?['strategies'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .toList() ??
          <Map<String, dynamic>>[];
      _selectedOrders.retainAll(startableMakerOrderIds(saved, _orders));
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
    if (enabled &&
        (keyring is! Map || !keyring.values.any((value) => value == true))) {
      setState(
        () => _error = 'Configure at least one exchange before live trading.',
      );
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(enabled ? 'Start live trading?' : 'Stop live trading?'),
        content: Text(
          enabled
              ? mmEngineStartLiveNotice
              : 'The engine will pause all maker orders, cancel its open orders '
                    'and return to preview mode. Active swaps must finish first.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(enabled ? 'Start live trading' : 'Stop live trading'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final user = context.read<AuthBloc>().state.currentUser;
    final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    if (user == null) throw StateError('Wallet is no longer signed in');
    await _runBusy(() async {
      _balanceRefresh.invalidate();
      try {
        await switchMmEngineTradingMode(
          enabled: enabled,
          request: MmEngineService.instance.request,
          stop: MmEngineService.instance.stop,
          clearLivePreference: () => MmEngineService.instance
              .clearLivePreference(user.walletId.compoundId),
          start: (live) => MmEngineService.instance.start(
            sdk: sdk,
            walletId: user.walletId.compoundId,
            liveTrading: live,
          ),
        );
      } finally {
        if (mounted && MmEngineService.instance.isRunning) await _refresh();
      }
    });
  }

  Future<void> _startSelectedOrders() async {
    if (_busy || !MmEngineService.instance.liveEnabled) return;
    final rows =
        ((_strategies?['strategies'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .toList()
          ..sort(
            (a, b) => (a['creation_number'] as int? ?? 999999).compareTo(
              b['creation_number'] as int? ?? 999999,
            ),
          );
    final eligible = startableMakerOrderIds(rows, _orders);
    final selected = rows
        .where(
          (row) =>
              _selectedOrders.contains(row['id']) &&
              eligible.contains(row['id']),
        )
        .toList();
    if (selected.isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${selected.length} selected maker orders?'),
        content: SizedBox(
          width: 540,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Only the orders below will be activated. This can publish real KDF maker orders and hedge completed swaps on their configured exchanges.',
                ),
                const SizedBox(height: 16),
                for (final row in selected)
                  Text(
                    'Order #${row['creation_number'] ?? '—'} · '
                    '${(row['spec'] as Map)['base']['ticker']} / ${(row['spec'] as Map)['quote']['ticker']}',
                  ),
              ],
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
            child: const Text('Start selected orders'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _runBusy(() async {
      final result = await startSelectedMakerOrders(
        ids: selected.map((row) => row['id'] as String).toList(),
        eligible: eligible,
        live: MmEngineService.instance.liveEnabled,
        request: MmEngineService.instance.request,
      );
      if (!mounted) return;
      _selectedOrders.removeAll(result.started);
      await _refresh();
      if (mounted && result.error != null) {
        setState(
          () => _error =
              'Activation interrupted after ${result.started.length} confirmed starts. '
              'Check Status for the remaining selected orders: ${result.error}',
        );
      }
    });
  }

  Future<void> _configureCredentials(String venue) async {
    if (_busy || _balanceLoading) return;
    final key = TextEditingController();
    final secret = TextEditingController();
    var selectedVenue = venue;
    try {
      final submitted = await showDialog<bool>(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, update) => AlertDialog(
            title: Text('Configure $selectedVenue Spot API'),
            content: SizedBox(
              width: 480,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Use a trading-only API key. Transfer permissions '
                    'are not used by P2Pirate Trading Engine.',
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: selectedVenue,
                    decoration: const InputDecoration(labelText: 'CEX name'),
                    items: const [
                      DropdownMenuItem(value: 'MEXC', child: Text('MEXC')),
                      DropdownMenuItem(value: 'GATE', child: Text('Gate')),
                    ],
                    onChanged: (value) => update(() => selectedVenue = value!),
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
            'venue': selectedVenue,
            'api_key': apiKey,
            'api_secret': apiSecret,
            'confirmation': 'STORE $selectedVenue',
          },
        );
        await _refresh();
        if (mounted) {
          _balanceRefresh.invalidate(clear: true);
          _balanceRefresh.selectVenue(selectedVenue);
        }
      });
    } finally {
      key.dispose();
      secret.dispose();
    }
  }

  Future<void> _createStrategy({Map<String, dynamic>? existing}) async {
    if (_busy) return;
    final existingSpec = existing?['spec'] as Map<String, dynamic>?;
    final markets = makerOrderMarkets(
      _markets?['markets'],
      existingSpec: existingSpec,
    );
    if (markets.isEmpty) {
      setState(() => _error = 'No KDF markets are available.');
      return;
    }
    setState(() => _busy = true);
    final sdk = RepositoryProvider.of<KomodoDefiSdk>(context);
    final baseBalances = <String, String>{};
    final bases = markets.map((m) => m.split('-').first).toSet();
    await Future.wait(
      bases.map((ticker) async {
        final matches = sdk.assets.available.values.where(
          (asset) => asset.id.id == ticker,
        );
        if (matches.isEmpty) return;
        try {
          final balance = await sdk.balances
              .getBalance(matches.first.id)
              .timeout(const Duration(seconds: 8));
          baseBalances[ticker] = balance.spendable.toString();
        } catch (_) {
          /* Unavailable is displayed explicitly, never as zero. */
        }
      }),
    );
    if (!mounted) return;
    setState(() => _busy = false);
    final spec = await showDialog<Map<String, Object?>>(
      context: context,
      builder: (context) => MmEngineStrategyForm(
        markets: markets,
        strategyId:
            existing?['id'] as String? ??
            'order-${DateTime.now().microsecondsSinceEpoch}',
        initialSpec: existingSpec,
        availableBalances: baseBalances,
      ),
    );
    if (spec == null || !mounted) return;
    final venue = spec['cex'];
    final available = _credentials?['venues'];
    if (available is! Map || available[venue] != true) {
      setState(
        () => _error = 'Configure $venue API credentials before preview.',
      );
      return;
    }
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
          title: Text(
            existing == null
                ? 'Save maker order paused?'
                : 'Save modified order paused?',
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: MmEnginePreview(preview: preview),
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
        existing == null ? '/v1/strategies/create' : '/v1/strategies/update',
        body: existing == null
            ? {
                'specs': [spec],
                'confirmation': 'SALVA IN PAUSA',
              }
            : {'spec': spec, 'confirmation': 'AGGIORNA IN PAUSA'},
      );
      await _refresh();
    });
  }

  Future<void> _modifyStrategy(String id) async {
    final rows = (_strategies?['strategies'] as List?) ?? [];
    final matches = rows.whereType<Map<String, dynamic>>().where(
      (row) => row['id'] == id,
    );
    if (matches.isEmpty) return;
    final row = matches.first;
    if (row['enabled'] == 1 ||
        _orders.any((o) => o['strategy_id'] == id) ||
        ['WRITING', 'REVIEW_REQUIRED', 'DELETED'].contains(row['state'])) {
      setState(
        () => _error = 'Pause and withdraw this order before modifying it.',
      );
      return;
    }
    await _createStrategy(existing: row);
  }

  Future<void> _showDetails(Map<String, dynamic> row) async {
    final id = row['strategy_id'];
    final strategies = (_strategies?['strategies'] as List?) ?? [];
    final matches = strategies.whereType<Map>().where((s) => s['id'] == id);
    final spec = matches.isEmpty
        ? const <String, dynamic>{}
        : (matches.first['spec'] as Map);
    final entries = <String, Object?>{
      'Order UUID': row['order_uuid'] ?? 'Not published',
      'Status': row['status'],
      'Amount': row['kdf_volume'],
      'Price': row['kdf_price'],
      'Sell': row['kdf_base'],
      'Buy': row['kdf_rel'],
      'Remaining sold budget': matches.isEmpty
          ? 'unavailable'
          : matches.first['remaining_sold'],
      'Remaining daily budget': matches.isEmpty
          ? 'unavailable'
          : matches.first['daily_remaining_sold'],
      'Reason': row['detail'] ?? '',
      for (final entry in spec.entries) '${entry.key}': entry.value,
    };
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Maker Order #${row['creation_number'] ?? '—'} · Details'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in entries.entries)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: SelectableText('${entry.key}: ${entry.value}'),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
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
      _downloadStatus = 'Checking the latest P2Pirate Trading Engine release…';
      _downloadProgress = null;
    });
    try {
      final release = await MmEngineInstallService.latestRelease();
      if (!mounted) return;
      final accepted = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Install P2Pirate Trading Engine?'),
          content: Text(
            'Download version ${release.tag} from the P2Pirate Trading Engine repository. '
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
        setState(() => _downloadStatus = 'Stopping the current engine…');
        await MmEngineService.instance.stop();
      }
      setState(() => _downloadStatus = 'Downloading P2Pirate Trading Engine…');
      await MmEngineInstallService.install(
        release,
        onProgress: (progress) {
          if (!mounted ||
              (_downloadProgress?.percent == progress.percent &&
                  _downloadProgress?.stage == progress.stage)) {
            return;
          }
          setState(() {
            _downloadProgress = progress;
            _downloadStatus = switch (progress.stage) {
              MmEngineInstallStage.binary =>
                'Downloading P2Pirate Trading Engine…',
              MmEngineInstallStage.notices => 'Downloading license notices…',
              MmEngineInstallStage.verifying => 'Verifying the download…',
            };
          });
        },
      );
      _installed = true;
      if (mounted) {
        setState(() {
          _downloadStatus = 'Starting P2Pirate Trading Engine…';
          _downloadProgress = null;
        });
      }
      await _connect();
    } catch (error) {
      _error = '$error';
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _downloadStatus = null;
          _downloadProgress = null;
        });
      }
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
    return SelectionArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1050),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OverflowBar(
                alignment: MainAxisAlignment.spaceBetween,
                spacing: 12,
                overflowSpacing: 8,
                children: [
                  Text(
                    'P2PIRATE TRADING ENGINE',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Wrap(
                    children: [
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
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 20),
              if (_busy) ...[
                if (_downloadStatus != null) ...[
                  Text(_downloadStatus!),
                  const SizedBox(height: 8),
                ],
                LinearProgressIndicator(value: _downloadProgress?.fraction),
                if (_downloadProgress case final progress?) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${progress.percent}% · '
                    '${(progress.receivedBytes / (1024 * 1024)).toStringAsFixed(1)} / '
                    '${(progress.totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB',
                  ),
                ],
              ],
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: SelectableText(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
              if (!_installed)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('P2Pirate Trading Engine is not installed'),
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
                MmEngineDashboard(
                  orders: _orders,
                  strategies: strategies.toList(),
                  venue: _venue,
                  credentials: credentials,
                  balances: _balanceRefresh.balances,
                  busy: _busy,
                  live: live,
                  balanceError: _balanceRefresh.error,
                  balanceUpdatedAt: _balanceRefresh.updatedAt,
                  balanceRefreshSeconds: _balanceRefresh.secondsRemaining,
                  cexExpanded: _balanceRefresh.expanded,
                  onToggleCex: _balanceRefresh.toggleExpanded,
                  balanceLoading: _balanceLoading,
                  selectedOrders: _selectedOrders,
                  onSelection: (ids) => setState(() {
                    _selectedOrders
                      ..clear()
                      ..addAll(ids);
                  }),
                  onStartSelected: _startSelectedOrders,
                  onLive: () => _setLive(!live),
                  onNew: () => _createStrategy(),
                  onVenue: (venue) {
                    if (_balanceLoading || _busy) return;
                    _balanceRefresh.selectVenue(venue);
                  },
                  onAdd: () => _configureCredentials(_venue),
                  onBalances: _balanceRefresh.refresh,
                  onModify: _modifyStrategy,
                  onDetails: _showDetails,
                  onStrategy: (id, start) => _changeStrategy(id, start: start),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
