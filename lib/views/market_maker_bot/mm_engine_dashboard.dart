import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_trading_controls.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_rebalance_panel.dart';

class MmEngineDashboard extends StatelessWidget {
  const MmEngineDashboard({
    super.key,
    required this.orders,
    required this.strategies,
    required this.venue,
    required this.credentials,
    required this.balances,
    required this.busy,
    required this.live,
    required this.onLive,
    required this.onNew,
    required this.onVenue,
    required this.onAdd,
    required this.onStrategy,
    required this.onBalances,
    this.venueLabels = const {'MEXC': 'MEXC', 'GATE': 'Gate'},
    this.selectedOrders = const {},
    this.onSelection,
    this.onStartSelected,
    this.onModify,
    this.onDetails,
    this.balanceError,
    this.balanceLoading = false,
    this.cexExpanded = true,
    this.onToggleCex,
    this.balanceRefreshSeconds,
    this.balanceUpdatedAt,
    this.onRebalanceBusy,
    this.onRebalanceChanged,
  });
  final List<Map<String, dynamic>> orders, strategies, balances;
  final String venue;
  final Map<String, String> venueLabels;
  final Set<String> selectedOrders;
  final ValueChanged<Set<String>>? onSelection;
  final VoidCallback? onStartSelected;
  final Map credentials;
  final bool busy, live, balanceLoading;
  final String? balanceError;
  final bool cexExpanded;
  final VoidCallback? onToggleCex;
  final int? balanceRefreshSeconds;
  final DateTime? balanceUpdatedAt;
  final ValueChanged<bool>? onRebalanceBusy;
  final VoidCallback? onRebalanceChanged;
  final VoidCallback onLive, onNew, onAdd, onBalances;
  final ValueChanged<String> onVenue;
  final void Function(String, bool) onStrategy;
  final ValueChanged<String>? onModify;
  final ValueChanged<Map<String, dynamic>>? onDetails;

  Widget _table(
    BuildContext context,
    List<String> headings,
    List<List<Widget>> rows,
  ) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: constraints.maxWidth < 520 ? 520 : constraints.maxWidth,
        child: DataTable(
          horizontalMargin: 0,
          columnSpacing: 20,
          headingRowHeight: 38,
          dataRowMinHeight: 36,
          dataRowMaxHeight: 48,
          columns: [
            for (final heading in headings) DataColumn(label: Text(heading)),
          ],
          rows: [
            for (final row in rows)
              DataRow(cells: [for (final cell in row) DataCell(cell)]),
          ],
        ),
      ),
    ),
  );

  Widget _makerTable(BuildContext context, List<Map<String, dynamic>> rows) {
    const headings = [
      '#',
      'SELL',
      'AMOUNT',
      'PRICE',
      'BUY',
      'PREMIUM',
      'HEDGING CEX',
      'STATUS',
    ];
    final theme = Theme.of(context);
    Widget value(Object? raw) => Text('${raw ?? '—'}');
    final eligible = {
      for (final row in rows)
        if (row['selectable'] == true) row['strategy_id'] as String,
    };
    final selected = selectedOrders.intersection(eligible);
    final allSelected =
        eligible.isNotEmpty && selected.length == eligible.length;
    Widget selectAll() => Tooltip(
      message: 'Select all paused orders',
      child: Checkbox(
        key: const Key('select-all-maker-orders'),
        tristate: true,
        value: selected.isEmpty
            ? false
            : allSelected
            ? true
            : null,
        onChanged: busy || eligible.isEmpty || onSelection == null
            ? null
            : (_) {
                onSelection!(allSelected ? <String>{} : {...eligible});
              },
      ),
    );
    Widget selectRow(Map<String, dynamic> row) {
      final id = row['strategy_id'];
      return Tooltip(
        message: row['selectable'] == true
            ? 'Select this paused order'
            : 'Only paused orders ready to start can be selected',
        child: Checkbox(
          key: Key('select-maker-order-$id'),
          value: selected.contains(id),
          onChanged: busy || row['selectable'] != true || onSelection == null
              ? null
              : (checked) {
                  final next = {...selected};
                  if (checked == true) {
                    next.add(id as String);
                  } else {
                    next.remove(id);
                  }
                  onSelection!(next);
                },
        ),
      );
    }

    Widget line(List<Widget> cells, Widget selection) => Row(
      children: [
        SizedBox(width: 40, child: selection),
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: i == 0
                ? 1
                : i == 4 || i == 6 || i == 7
                ? 3
                : 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: cells[i],
            ),
          ),
      ],
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 780;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (compact)
              Row(
                children: [
                  selectAll(),
                  const Flexible(child: Text('Select all paused orders')),
                ],
              ),
            if (!compact) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: line([
                  for (final heading in headings)
                    Text(
                      heading,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ], selectAll()),
              ),
              const Divider(height: 1),
            ],
            for (var i = 0; i < rows.length; i++)
              Builder(
                builder: (context) {
                  final row = rows[i];
                  final id = row['strategy_id'];
                  final uuid = row['order_uuid']?.toString();
                  final recovering =
                      row['recovery'] is Map &&
                      (row['recovery'] as Map)['held'] != true;
                  final enabled =
                      row['enabled'] == 1 || uuid != null || recovering;
                  final values = [
                    row['creation_number'] ?? i + 1,
                    row['kdf_base'],
                    row['kdf_volume'],
                    row['kdf_price'],
                    row['kdf_rel'],
                    _premium(row['configured_premium']),
                    row['cex'],
                    row['status'],
                  ];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (compact) ...[
                          Row(
                            children: [
                              selectRow(row),
                              const Flexible(child: Text('Select order')),
                            ],
                          ),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (var j = 0; j < headings.length; j++)
                                SizedBox(
                                  width: (constraints.maxWidth - 12) / 2,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        headings[j],
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                      value(values[j]),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ] else
                          line([
                            for (final raw in values) value(raw),
                          ], selectRow(row)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            SizedBox(
                              width: constraints.maxWidth < 540
                                  ? constraints.maxWidth
                                  : 490,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: SelectableText(
                                      'UUID: ${uuid ?? 'not published'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                  if (uuid != null)
                                    IconButton(
                                      tooltip: 'Copy UUID',
                                      icon: const Icon(Icons.copy, size: 16),
                                      onPressed: () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: uuid),
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text('UUID copied'),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                ],
                              ),
                            ),
                            OutlinedButton.icon(
                              onPressed: onDetails == null
                                  ? null
                                  : () => onDetails!(row),
                              icon: const Icon(Icons.info_outline, size: 16),
                              label: const Text('Details'),
                            ),
                            OutlinedButton.icon(
                              onPressed:
                                  busy ||
                                      id is! String ||
                                      (!enabled &&
                                          (!live || row['selectable'] != true))
                                  ? null
                                  : () => onStrategy(id, !enabled),
                              icon: Icon(
                                enabled ? Icons.pause : Icons.play_arrow,
                                size: 16,
                              ),
                              label: Text(
                                recovering && uuid == null
                                    ? 'Pause recovery'
                                    : enabled
                                    ? 'Pause'
                                    : 'Start',
                              ),
                            ),
                            if (row['modifiable'] == true && id is String)
                              OutlinedButton.icon(
                                onPressed: busy || onModify == null
                                    ? null
                                    : () => onModify!(id),
                                icon: const Icon(Icons.edit_outlined, size: 16),
                                label: const Text('Modify'),
                              ),
                          ],
                        ),
                        if ('${row['detail'] ?? ''}'.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            '${row['detail']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                      ],
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }

  String? _premium(Object? value) {
    final premium = double.tryParse('$value');
    return premium == null ? null : '${(premium * 100).toStringAsFixed(2)}%';
  }

  String? _fixedPrice(Map spec, bool sellBase) {
    final raw = spec['fixed_price']?.toString();
    if (raw == null || sellBase) return raw;
    final price = Decimal.tryParse(raw);
    if (price == null || price <= Decimal.zero) return null;
    // KDF quotes bought coin per sold coin; BUY spends the quote coin.
    return (Decimal.one / price)
        .toDecimal(scaleOnInfinitePrecision: 20)
        .toString();
  }

  @override
  Widget build(BuildContext context) {
    final startable = startableMakerOrderIds(strategies, orders);
    final byId = {for (final row in strategies) row['id']: row};
    final activeIds = orders.map((order) => order['strategy_id']).toSet();
    Map<String, dynamic> decorate(
      Map<String, dynamic> order,
      Map<String, dynamic>? strategy,
    ) {
      final spec = strategy?['spec'] as Map? ?? const {};
      final sellBase = spec['side'] != 'BUY_ARRR';
      final sold = spec[sellBase ? 'base' : 'quote'] as Map?;
      final bought = spec[sellBase ? 'quote' : 'base'] as Map?;
      final active = order['order_uuid'] != null;
      final recovery = strategy?['recovery'] as Map?;
      final detail = '${strategy?['detail'] ?? ''}';
      final recoveryDetail = recovery == null || recovery['held'] == true
          ? detail
          : '$detail · Next check in ${recovery['next_retry_seconds'] ?? 10}s';
      return {
        ...order,
        'strategy_id': strategy?['id'] ?? order['strategy_id'],
        'recovery': recovery,
        'selectable': startable.contains(
          strategy?['id'] ?? order['strategy_id'],
        ),
        'creation_number': strategy?['creation_number'],
        'status': strategy?['state'] ?? order['status'],
        'detail': recoveryDetail.isNotEmpty
            ? recoveryDetail
            : strategy?['state'] == 'PAUSED'
            ? 'Not publishing: this order is paused.'
            : '',
        'enabled': strategy?['enabled'] ?? (active ? 1 : 0),
        'kdf_base': sold?['ticker'] ?? order['kdf_base'],
        'kdf_rel': bought?['ticker'] ?? order['kdf_rel'],
        'cex': spec['cex'] ?? order['cex'],
        'configured_premium': spec['premium'] ?? order['configured_premium'],
        'kdf_volume': active
            ? order['kdf_volume']
            : spec['quantity_mode'] == 'auto'
            ? 'auto'
            : spec['fixed_sold'],
        'kdf_price': active
            ? order['kdf_price']
            : spec['price_mode'] == 'auto'
            ? 'auto'
            : _fixedPrice(spec, sellBase),
        'modifiable':
            strategy != null &&
            strategy['enabled'] == 0 &&
            !active &&
            ![
              'WRITING',
              'REVIEW_REQUIRED',
              'RECOVERING',
              'DELETED',
            ].contains(strategy['state']),
      };
    }

    final display =
        <Map<String, dynamic>>[
          for (final order in orders)
            decorate(order, byId[order['strategy_id']]),
          for (final strategy in strategies)
            if (!activeIds.contains(strategy['id']))
              decorate(const {}, strategy),
        ]..sort(
          (a, b) => (a['creation_number'] as int? ?? 999999).compareTo(
            b['creation_number'] as int? ?? 999999,
          ),
        );
    final selectionCount = selectedOrders.intersection(startable).length;
    Text text(Object? value) => Text(value?.toString() ?? '—');
    final positive =
        balances
            .where((row) => (double.tryParse('${row['available']}') ?? 0) > 0)
            .toList()
          ..sort((a, b) => '${a['ticker']}'.compareTo('${b['ticker']}'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 30),
        OverflowBar(
          alignment: MainAxisAlignment.spaceBetween,
          spacing: 12,
          overflowSpacing: 12,
          children: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: busy ? null : onLive,
              child: Text(live ? 'Stop live trading' : 'Start live trading'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              onPressed: busy ? null : onNew,
              icon: const Icon(Icons.add),
              label: const Text('New Maker Order'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OverflowBar(
                  alignment: MainAxisAlignment.spaceBetween,
                  spacing: 12,
                  overflowSpacing: 8,
                  children: [
                    Text(
                      'MY MAKER ORDERS',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Tooltip(
                      message: live
                          ? 'Activate only the selected paused orders'
                          : 'Start live trading first; then activate the selected orders',
                      child: ElevatedButton.icon(
                        onPressed: busy || !live || selectionCount == 0
                            ? null
                            : onStartSelected,
                        icon: const Icon(Icons.play_arrow),
                        label: Text('Start selected orders ($selectionCount)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _makerTable(context, display),
                if (display.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No maker orders yet. Create a new order to preview and save it paused.',
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        Card(
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'MY CEXs',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: onToggleCex,
                      icon: Icon(
                        cexExpanded ? Icons.expand_less : Icons.expand_more,
                      ),
                      label: Text(cexExpanded ? 'Hide' : 'Show'),
                    ),
                  ],
                ),
                if (cexExpanded) ...[
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (final exchange in venueLabels.keys)
                        ChoiceChip(
                          label: Text(venueLabels[exchange] ?? exchange),
                          selected: venue == exchange,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          showCheckmark: false,
                          onSelected: busy || balanceLoading
                              ? null
                              : (_) => onVenue(exchange),
                        ),
                      TextButton(
                        onPressed: busy || balanceLoading ? null : onAdd,
                        child: const Text('ADD CEX'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  OverflowBar(
                    alignment: MainAxisAlignment.spaceBetween,
                    spacing: 12,
                    overflowSpacing: 8,
                    children: [
                      Text(
                        '$venue BALANCES',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      TextButton.icon(
                        onPressed: busy || balanceLoading ? null : onBalances,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh balances'),
                      ),
                    ],
                  ),
                  if (credentials[venue] == true) ...[
                    Text(
                      balanceLoading
                          ? 'Refreshing balances…'
                          : 'Next refresh in ${balanceRefreshSeconds ?? 60}s',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (balanceUpdatedAt != null)
                      Text(
                        'Last update: ${balanceUpdatedAt!.toLocal().toIso8601String().split('.').first.replaceAll('T', ' ')}'
                        '${balanceError != null ? ' · Last received balances; refresh failed.' : ''}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    const SizedBox(height: 8),
                  ],
                  if (balanceLoading) const LinearProgressIndicator(),
                  if (balanceError != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        balanceError!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (credentials[venue] != true)
                    TextButton(
                      onPressed: busy || balanceLoading ? null : onAdd,
                      child: Text('Configure $venue API credentials'),
                    ),
                  _table(
                    context,
                    ['COIN', 'TICKER', 'AVAILABLE SPOT BALANCE'],
                    [
                      for (final row in positive)
                        [
                          text(row['name'] ?? row['ticker']),
                          text(row['ticker']),
                          text(row['available']),
                        ],
                    ],
                  ),
                  if (positive.isEmpty &&
                      !balanceLoading &&
                      balanceError == null &&
                      credentials[venue] == true)
                    Text(
                      balanceUpdatedAt == null
                          ? 'Loading your Spot account automatically.'
                          : 'No positive Spot balances.',
                    ),
                  const SizedBox(height: 24),
                  MmEngineRebalancePanel(
                    key: ValueKey(venue),
                    venue: venue,
                    busy: busy || balanceLoading,
                    live: live,
                    configured: credentials[venue] == true,
                    onBusy: onRebalanceBusy ?? (_) {},
                    onChanged: onRebalanceChanged ?? () {},
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
