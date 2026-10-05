import 'dart:async';

import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:web_dex/services/mm_engine/mm_engine_service.dart';

/// Presentation only: targets, proposal ownership and trading live in the engine.
class MmEngineRebalancePanel extends StatefulWidget {
  const MmEngineRebalancePanel({
    super.key,
    required this.venue,
    required this.busy,
    required this.live,
    required this.configured,
    required this.onBusy,
    required this.onChanged,
    required this.strategies,
    required this.balances,
    required this.balanceLoading,
  });

  final String venue;
  final bool busy, live, configured;
  final ValueChanged<bool> onBusy;
  final VoidCallback onChanged;
  final List<Map<String, dynamic>> strategies, balances;
  final bool balanceLoading;

  @override
  State<MmEngineRebalancePanel> createState() => _MmEngineRebalancePanelState();
}

class _MmEngineRebalancePanelState extends State<MmEngineRebalancePanel> {
  Map<String, dynamic>? _plan;
  final _scope = <String>{};
  final _percentages = <String, int>{};
  final _enabledAssets = <String>{};
  String? _allocationId;
  Map? _allocation;
  bool _selectionTouched = false;
  List<Map<String, dynamic>> _history = [];
  String? _error, _message;
  bool _busy = false;
  bool _loadedStatus = false;
  DateTime? _nextStatusAt;
  Timer? _timer;

  bool get _pending => _history.any(
    (row) => !const {
      'FILLED',
      'CANCELED',
      'PARTIALLY_CANCELED',
      'REJECTED',
      'EXPIRED',
    }.contains(row['state']),
  );

  bool get _expired {
    final expires = _plan?['expires'];
    return expires is! num ||
        DateTime.now().millisecondsSinceEpoch >= expires * 1000;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && _plan != null) setState(() {});
      if (mounted &&
          !_busy &&
          !widget.busy &&
          widget.configured &&
          MmEngineService.instance.rebalanceSelectionSupported &&
          (!_loadedStatus ||
              (_pending &&
                  (_nextStatusAt == null ||
                      !DateTime.now().isBefore(_nextStatusAt!))))) {
        unawaited(_status());
      }
    });
    // Recover a previous submission after navigation/restart. This never submits.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          !widget.busy &&
          widget.configured &&
          MmEngineService.instance.rebalanceSelectionSupported) {
        unawaited(_status());
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy || widget.busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    widget.onBusy(true);
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _error = '$error');
    } finally {
      widget.onBusy(false);
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<Map<String, dynamic>> _request(
    String action, [
    Map<String, Object?> extra = const {},
  ]) => MmEngineService.instance.request(
    'POST',
    '/v1/rebalance/$action',
    body: {'venue': widget.venue, ...extra},
  );

  void _selectionChanged(VoidCallback change) {
    setState(() {
      change();
      _selectionTouched = true;
      _allocationId = null;
      _allocation = null;
      _plan = null;
      _message =
          'Selection changed. Analyze starts a new spending budget from fresh balances.';
    });
  }

  List<Map<String, dynamic>> get _makers => widget.strategies.where((row) {
    final spec = row['spec'] as Map?;
    return spec?['cex'] == widget.venue && row['state'] != 'DELETED';
  }).toList();

  bool get _validSelection =>
      _scope.isNotEmpty &&
      _scope.every((id) => _makers.any((row) => '${row['id']}' == id)) &&
      _enabledAssets.any((asset) => (_percentages[asset] ?? 0) > 0);

  String _amount(String asset, Object? raw) {
    final value = Decimal.tryParse('$raw') ?? Decimal.zero;
    return (value *
            Decimal.fromInt(_percentages[asset] ?? 0) *
            Decimal.parse('0.01'))
        .toString();
  }

  void _readStatus(Map<String, dynamic> result) {
    final allocation = result['allocation'];
    if (!_selectionTouched && _allocationId == null && allocation is Map) {
      _allocationId = '${allocation['id']}';
      _scope.addAll((allocation['strategy_ids'] as List).cast<String>());
      for (final entry in (allocation['percentages'] as Map).entries) {
        _percentages['${entry.key}'] = entry.value as int;
        _enabledAssets.add('${entry.key}');
      }
    }
    if (allocation is Map && allocation['id'] == _allocationId) {
      _allocation = allocation;
    }
    _loadedStatus = true;
    _nextStatusAt = DateTime.now().add(const Duration(seconds: 15));
    _history = (result['orders'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final errors = (result['errors'] as List? ?? [])
        .map((e) => '$e')
        .join('\n');
    if (errors.isNotEmpty) _error = errors;
  }

  Future<void> _status() => _run(() async {
    final result = await _request('status');
    if (!mounted) return;
    setState(() => _readStatus(result));
    widget.onChanged();
  });

  Future<void> _analyze() => _run(() async {
    if (!_validSelection || widget.balanceLoading) return;
    final ids = _scope.toList()..sort();
    setState(() {
      _plan = null;
      _message = null;
    });
    final result = await _request('analyze', {
      'strategy_ids': ids,
      'asset_percentages': {
        for (final asset in _enabledAssets) asset: _percentages[asset] ?? 0,
      },
      if (_allocationId != null) 'allocation_id': _allocationId,
    });
    if (mounted) {
      setState(() {
        _plan = result;
        _allocation = result['allocation'] as Map;
        _allocationId = _allocation!['id'] as String;
      });
    }
  });

  Future<void> _resetBudget() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset spending limits?'),
        content: const Text(
          'The next Analyze applies your percentages to fresh balances and starts a new budget. '
          'This authorizes additional spending beyond the previous budget. No trade is sent by resetting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset limits'),
          ),
        ],
      ),
    );
    if (yes == true && mounted) {
      _selectionChanged(() {});
    }
  }

  Future<void> _pause() async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause maker orders for rebalance?'),
        content: const Text(
          'Pause all maker orders and withdraw their published quotes. '
          'Existing swaps and hedges must finish before a Spot rebalance can be executed. '
          'Orders stay paused until you start them again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pause maker orders'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted) return;
    await _run(() async {
      await MmEngineService.instance.request(
        'POST',
        '/v1/strategies/pause-all',
        body: {'confirmation': 'PAUSA TUTTE'},
      );
      if (mounted) {
        setState(() {
          // Keep the selected scope for the required fresh analysis after pause.
          _plan?['can_execute'] = false;
          _message =
              'Maker orders paused. Wait for reconciliation, then Analyze again.';
        });
      }
      widget.onChanged();
    });
  }

  Future<void> _execute() async {
    final plan = _plan;
    final orders = plan?['orders'];
    if (plan == null ||
        _expired ||
        _pending ||
        plan['can_execute'] != true ||
        !widget.live ||
        orders is! List ||
        orders.isEmpty) {
      return;
    }
    final first = Map<String, dynamic>.from(orders.first as Map);
    final id = '${plan['id']}';
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Execute ${widget.venue} rebalance?'),
        content: SelectableText(
          '${first['side']} ${first['quantity']} ${first['asset']} on ${widget.venue}\n'
          'Symbol: ${first['symbol']}\nLimit price: ${first['price']} USDT\n'
          'Notional: ${first['notional']} USDT, before fees.\n\n'
          'This submits only this first LIMIT order. It can remain open or partially filled. '
          'After its confirmed completion, analyze again for the next step. '
          'The engine rechecks balances, prices, permissions and maker/hedge safety. '
          'If its outcome is uncertain, use Refresh trade status; do not resubmit.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Execute first trade'),
          ),
        ],
      ),
    );
    if (yes != true || !mounted || _expired || !widget.live) return;
    await _run(() async {
      // Consume the UI proposal before the write, including on HTTP timeout.
      // Its server-side identity and durable journal prevent double submission.
      setState(() {
        _plan = null;
        _loadedStatus = false;
      });
      try {
        final result = await _request('execute', {
          'id': id,
          'confirmation': 'EXECUTE REBALANCE $id',
        });
        if (mounted) {
          setState(() {
            _message = '${result['message']}';
            _readStatus(result);
          });
        }
      } finally {
        if (mounted) {
          try {
            final result = await _request('status');
            if (mounted) setState(() => _readStatus(result));
          } catch (_) {
            if (mounted) {
              setState(
                () => _message =
                    'Outcome not confirmed. Refresh trade status before any further execution.',
              );
            }
          }
          widget.onChanged();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final supported = MmEngineService.instance.rebalanceSelectionSupported;
    final disabled = _busy || widget.busy || !widget.configured || !supported;
    final inputDisabled = disabled || widget.balanceLoading || _pending;
    final plan = _plan;
    final funding = plan?['funding'] as Map? ?? {};
    final orders = (plan?['orders'] as List? ?? []).whereType<Map>();
    final blockers = plan?['execution_blockers'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SELECT MAKER ORDERS TO REBALANCE ON ${widget.venue}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        if (_makers.isEmpty)
          const Text('No maker orders configured for this CEX.'),
        if (_makers.isNotEmpty)
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Select all maker orders'),
            value: _makers.every((row) => _scope.contains('${row['id']}')),
            onChanged: inputDisabled
                ? null
                : (value) => _selectionChanged(() {
                    _scope.clear();
                    if (value == true) {
                      _scope.addAll(_makers.map((row) => '${row['id']}'));
                    }
                  }),
          ),
        for (final row in _makers)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "#${row['creation_number']} · ${(row['spec'] as Map)['base']['ticker']} / ${(row['spec'] as Map)['quote']['ticker']}",
            ),
            subtitle: Text('${row['state']}'),
            value: _scope.contains('${row['id']}'),
            onChanged: inputDisabled
                ? null
                : (value) => _selectionChanged(() {
                    if (value) {
                      _scope.add('${row['id']}');
                    } else {
                      _scope.remove('${row['id']}');
                    }
                  }),
          ),
        const SizedBox(height: 24),
        Text(
          'SELECT ${widget.venue} COINS AND HOW MUCH TO USE',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Percentages limit total debits, including fees. Existing hedge reserves are protected. '
          'Budgets stay fixed across partial fills and repeated Analyze; changing the selection starts a new budget.',
        ),
        const SizedBox(height: 12),
        for (final row in widget.balances.where(
          (row) =>
              (Decimal.tryParse('${row['available']}') ?? Decimal.zero) >
              Decimal.zero,
        ))
          LayoutBuilder(
            builder: (context, constraints) {
              final asset = '${row['ticker']}';
              final enabled = _enabledAssets.contains(asset);
              final percent = _percentages[asset] ?? 0;
              final remaining = _allocation?['remaining'] as Map?;
              final caps = _allocation?['caps'] as Map?;
              final selectedAmount = _allocationId == null
                  ? '$percent% · ${_amount(asset, row['available'])} $asset'
                  : '$percent% · limit ${caps?[asset] ?? "0"} $asset · left ${remaining?[asset] ?? "0"}';
              final description =
                  '$selectedAmount\nAvailable Spot balance: ${row['available']} $asset';
              final selector = Row(
                children: [
                  Switch(
                    value: enabled,
                    onChanged: inputDisabled
                        ? null
                        : (value) => _selectionChanged(() {
                            if (value) {
                              _enabledAssets.add(asset);
                            } else {
                              _enabledAssets.remove(asset);
                            }
                          }),
                  ),
                  SizedBox(width: 70, child: Text(asset)),
                  Expanded(
                    child: Tooltip(
                      message:
                          'Maximum percentage of the fresh available balance to use. Fees count against this limit.',
                      child: Slider(
                        value: percent.toDouble(),
                        min: 0,
                        max: 100,
                        divisions: 20,
                        label: '$percent%',
                        onChanged: inputDisabled || !enabled
                            ? null
                            : (value) => _selectionChanged(
                                () => _percentages[asset] = value.round(),
                              ),
                      ),
                    ),
                  ),
                ],
              );
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: constraints.maxWidth < 720
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [selector, SelectableText(description)],
                      )
                    : Row(
                        children: [
                          Expanded(child: selector),
                          SizedBox(
                            width: 290,
                            child: SelectableText(description),
                          ),
                        ],
                      ),
              );
            },
          ),
        for (final asset in _enabledAssets.where(
          (asset) => !widget.balances.any((row) => row['ticker'] == asset),
        ))
          Text(
            '$asset: no current available balance. Analyze rechecks the remaining budget.',
          ),
        if (widget.balances.isEmpty && !widget.balanceLoading)
          const Text('Refresh balances to choose available Spot coins.'),
        if (_allocation != null)
          SelectableText(
            'Remaining spending budget, including confirmed sale proceeds: '
            '${(_allocation!['remaining'] as Map).entries.map((e) => "${e.key} ${e.value}").join(', ')}',
          ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: inputDisabled || !_validSelection ? null : _analyze,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Analyze'),
            ),
            if (_allocationId != null)
              TextButton(
                onPressed: inputDisabled ? null : _resetBudget,
                child: const Text('Reset spending limits'),
              ),
            ElevatedButton.icon(
              onPressed:
                  disabled ||
                      !widget.live ||
                      _expired ||
                      _pending ||
                      plan?['can_execute'] != true
                  ? null
                  : _execute,
              icon: const Icon(Icons.balance),
              label: const Text('Execute rebalance'),
            ),
            TextButton.icon(
              onPressed: disabled ? null : _status,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh trade status'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const SelectableText(
          'Analyze the selected maker hedge targets, with a 20% reserve. Selected coins can fund conversions via USDT. '
          'Only the first confirmed LIMIT trade is sent; later steps require a verified fill and another Analyze. '
          'Partial coverage does not change maker quantities or bypass live hedge checks.',
        ),
        if (!supported)
          const Text(
            'Update P2Pirate Trading Engine to enable selected-coin rebalance.',
          ),
        if (!widget.live)
          const Text(
            'Analysis is available in preview mode. Execution requires live mode and paused makers.',
          ),
        if (_busy)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SelectableText(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        if (_message != null)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SelectableText(_message!),
          ),
        if (plan != null) ...[
          const SizedBox(height: 12),
          SelectableText(
            'Maker orders included: ${(plan['maker_orders'] as List? ?? []).map((row) => "#${row['number']} ${row['sell']}/${row['buy']}").join(', ')} · '
            '${_expired ? 'Proposal expired — Analyze again' : 'Proposal valid until ${DateTime.fromMillisecondsSinceEpoch(((plan['expires'] as num) * 1000).toInt()).toLocal().toIso8601String().split('.').first.replaceAll('T', ' ')}'}',
          ),
          if (plan['coverage_percent'] != null)
            SelectableText(
              'Maximum common coverage: ${plan['coverage_percent']}% · includes 20% reserve',
            ),
          for (final entry in funding.entries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                '${entry.key}: available ${entry.value['available']} · '
                'target ${entry.value['required']} · full target ${entry.value['full_required'] ?? entry.value['required']} · missing ${entry.value['missing']}',
              ),
            ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            const SelectableText(
              'No executable buy/sell proposed. Check coverage and the notes below.',
            ),
          for (final item in orders)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SelectableText(
                '${item['side']} ${item['quantity']} ${item['asset']} · '
                '${item['symbol']} · limit ${item['price']} USDT · ${item['notional']} USDT before fees',
              ),
            ),
          if ((plan['projected_orders'] as List? ?? []).isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Projected sequence — later buys depend on confirmed sale proceeds:',
            ),
            for (final item in plan['projected_orders'] as List)
              SelectableText(
                '${item['side']} ${item['quantity']} ${item['asset']} · limit ${item['price']} USDT',
              ),
          ],
          for (final note in plan['notes'] as List? ?? [])
            SelectableText('$note'),
          for (final action in plan['strategy_actions'] as List? ?? [])
            SelectableText(
              '${action['route']}: ${action['reason']} · ${action['action']}',
            ),
          for (final reason in blockers) SelectableText('$reason'),
          if (plan['pause_required'] == true)
            TextButton.icon(
              onPressed: disabled ? null : _pause,
              icon: const Icon(Icons.pause),
              label: const Text('Pause maker orders'),
            ),
        ],
        if (_history.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'REBALANCE TRADES',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final row in _history)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                '${row['order']['side']} ${row['order']['quantity']} ${row['order']['asset']} · '
                '${row['state']} · ${row['id']}',
              ),
            ),
          if (_pending)
            const SelectableText(
              'A trade is open or its result is uncertain. Maker publication remains blocked. '
              'Refresh trade status after completion or after cancelling the order directly on the exchange.',
            ),
        ],
      ],
    );
  }
}
