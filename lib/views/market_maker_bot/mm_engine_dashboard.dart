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

  String? _premium(Object? value) {
    final premium = double.tryParse('$value');
    return premium == null ? null : '${(premium * 100).toStringAsFixed(2)}%';
  }

  @override
  Widget build(BuildContext context) {
    final activeIds = orders.map((order) => order['strategy_id']).toSet();
    final display = <Map<String, dynamic>>[
      ...orders,
      for (final strategy in strategies)
        if (!activeIds.contains(strategy['id']))
          {
            'strategy_id': strategy['id'], 'status': strategy['state'],
            'cex': (strategy['spec'] as Map?)?['cex'],
            'configured_premium': (strategy['spec'] as Map?)?['premium'],
            'enabled': strategy['enabled'],
            'kdf_base':
                ((strategy['preview'] as Map?)?['plan'] as Map?)?['kdf_base'],
            'kdf_rel':
                ((strategy['preview'] as Map?)?['plan'] as Map?)?['kdf_rel'],
            // Paused configurations are not open orders; no live amount or price.
          },
    ];
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
        _table(
          context,
          [
            'SELL',
            'AMOUNT',
            'PRICE',
            'BUY',
            'PREMIUM',
            'HEDGING CEX',
            'STATUS',
          ],
          [
            for (final row in display)
              [
                text(row['kdf_base']),
                text(row['kdf_volume']),
                text(row['kdf_price']),
                text(row['kdf_rel']),
                text(_premium(row['configured_premium'])),
                text(row['cex']),
                row['strategy_id'] is String
                    ? TextButton(
                        onPressed: busy
                            ? null
                            : () => onStrategy(
                                row['strategy_id'] as String,
                                !row.containsKey('order_uuid') &&
                                    row['enabled'] != 1,
                              ),
                        child: text(row['status']),
                      )
                    : text(row['status']),
              ],
          ],
        ),
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
