import 'dart:async';

import 'package:flutter/material.dart';
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
  });

  final String venue;
  final bool busy, live, configured;
  final ValueChanged<bool> onBusy;
  final VoidCallback onChanged;

  @override
  State<MmEngineRebalancePanel> createState() => _MmEngineRebalancePanelState();
}

class _MmEngineRebalancePanelState extends State<MmEngineRebalancePanel> {
  Map<String, dynamic>? _plan;
  List<String>? _scope;
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
          MmEngineService.instance.rebalanceSupported &&
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
          MmEngineService.instance.rebalanceSupported) {
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

  void _readStatus(Map<String, dynamic> result) {
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
    final ids = _scope;
    setState(() {
      _plan = null;
      _message = null;
    });
    final result = await _request('analyze', {
      if (ids != null && ids.isNotEmpty) 'strategy_ids': ids,
    });
    if (mounted) {
      setState(() {
        _plan = result;
        _scope = (result['strategy_ids'] as List).cast<String>();
      });
    }
  });

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
    final supported = MmEngineService.instance.rebalanceSupported;
    final disabled = _busy || widget.busy || !widget.configured || !supported;
    final plan = _plan;
    final funding = plan?['funding'] as Map? ?? {};
    final orders = (plan?['orders'] as List? ?? []).whereType<Map>();
    final blockers = plan?['execution_blockers'] as List? ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${widget.venue} REBALANCE',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            OutlinedButton.icon(
              onPressed: disabled ? null : _analyze,
              icon: const Icon(Icons.analytics_outlined),
              label: const Text('Analyze'),
            ),
            if (_scope != null)
              Tooltip(
                message:
                    'Select current open/enabled maker orders again, including newly added makers.',
                child: TextButton(
                  onPressed: disabled
                      ? null
                      : () {
                          setState(() {
                            _scope = null;
                            _plan = null;
                          });
                          unawaited(_analyze());
                        },
                  child: const Text('New analysis'),
                ),
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
          'Analyze coverage for open and enabled maker orders using fresh Spot balances and market depth, '
          'with a 20% reserve. When all makers are paused, analyze their configured targets. '
          'Only surplus in strategy assets can be sold; unrelated holdings are kept.',
        ),
        if (!supported)
          const Text('Update P2Pirate Trading Engine to enable rebalance.'),
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
          for (final entry in funding.entries)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(
                '${entry.key}: available ${entry.value['available']} · '
                'target ${entry.value['required']} · missing ${entry.value['missing']}',
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
