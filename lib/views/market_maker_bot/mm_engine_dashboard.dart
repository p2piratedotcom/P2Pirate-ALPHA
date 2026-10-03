import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

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
    this.onModify,
    this.onDetails,
    this.balanceError,
    this.balanceLoading = false,
  });
  final List<Map<String, dynamic>> orders, strategies, balances;
  final String venue;
  final Map credentials;
  final bool busy, live, balanceLoading;
  final String? balanceError;
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
        width: constraints.maxWidth < 850 ? 850 : constraints.maxWidth,
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
    final showModify = rows.any((row) => row['modifiable'] == true);
    final headings = [
      '#',
      'SELL',
      'AMOUNT',
      'PRICE',
      'BUY',
      'PREMIUM',
      'HEDGING CEX',
      'STATUS',
      'PAUSE',
      if (showModify) 'MODIFY',
    ];
    Widget line(List<Widget> cells) => Row(
      children: [
        for (var i = 0; i < cells.length; i++)
          Expanded(
            flex: i == 0
                ? 1
                : i == 6 || i == 7
                ? 3
                : 2,
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: cells[i],
            ),
          ),
      ],
    );
    Widget value(Object? raw) => Tooltip(
      message: '${raw ?? '—'}',
      child: Text('${raw ?? '—'}', overflow: TextOverflow.ellipsis),
    );
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: constraints.maxWidth < 1100 ? 1100 : constraints.maxWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              line([
                for (final heading in headings)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Text(heading),
                  ),
              ]),
              const Divider(height: 1),
              for (var i = 0; i < rows.length; i++) ...[
                Builder(
                  builder: (context) {
                    final row = rows[i];
                    final id = row['strategy_id'];
                    final enabled =
                        row['enabled'] == 1 || row['order_uuid'] != null;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: line([
                        value(row['creation_number'] ?? i + 1),
                        value(row['kdf_base']),
                        value(row['kdf_volume']),
                        value(row['kdf_price']),
                        value(row['kdf_rel']),
                        value(_premium(row['configured_premium'])),
                        value(row['cex']),
                        value(row['status']),
                        TextButton(
                          onPressed:
                              busy || id is! String || (!enabled && !live)
                              ? null
                              : () => onStrategy(id, !enabled),
                          child: Text(enabled ? 'Pause' : 'Start'),
                        ),
                        if (showModify)
                          row['modifiable'] == true && id is String
                              ? TextButton(
                                  onPressed: busy || onModify == null
                                      ? null
                                      : () => onModify!(id),
                                  child: const Text('Modify'),
                                )
                              : const SizedBox.shrink(),
                      ]),
                    );
                  },
                ),
                Wrap(
                  spacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SelectableText(
                      'UUID: ${rows[i]['order_uuid'] ?? 'not published'}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if ('${rows[i]['detail'] ?? ''}'.isNotEmpty)
                      Text(
                        '${rows[i]['detail']}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    TextButton(
                      onPressed: onDetails == null
                          ? null
                          : () => onDetails!(rows[i]),
                      child: const Text('Details'),
                    ),
                  ],
                ),
                const Divider(height: 1),
              ],
            ],
          ),
        ),
      ),
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
      return {
        ...order,
        'strategy_id': strategy?['id'] ?? order['strategy_id'],
        'creation_number': strategy?['creation_number'],
        'status': strategy?['state'] ?? order['status'],
        'detail': '${strategy?['detail'] ?? ''}'.isNotEmpty
            ? strategy!['detail']
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
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: busy ? null : onLive,
              child: Text(
                live ? 'Stop all live trading' : 'Start all live trading',
              ),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              onPressed: busy ? null : onNew,
              icon: const Icon(Icons.add),
              label: const Text('New Maker Order'),
            ),
          ],
        ),
        const SizedBox(height: 28),
        Text(
          'MY MAKER ORDERS',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
        const SizedBox(height: 120),
        Text(
          'MY CEXs',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: [
            for (final exchange in ['MEXC', 'GATE'])
              ChoiceChip(
                label: Text(exchange),
                selected: venue == exchange,
                selectedColor: Theme.of(context).colorScheme.primary,
                showCheckmark: false,
                onSelected: busy ? null : (_) => onVenue(exchange),
              ),
            TextButton(
              onPressed: busy ? null : onAdd,
              child: const Text('ADD CEX'),
            ),
          ],
        ),
        const SizedBox(height: 28),
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
        if (balanceLoading) const LinearProgressIndicator(),
        if (balanceError != null)
          Text(
            balanceError!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        if (credentials[venue] != true)
          TextButton(
            onPressed: busy ? null : onAdd,
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
          const Text('Refresh balances to load your Spot account.'),
        const SizedBox(height: 30),
        Text(
          '$venue REBALANCE CHECK',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        const Text(
          'Balances are read only. Preview checks funds required for each hedge; no funds are transferred here.',
        ),
      ],
    );
  }
}
