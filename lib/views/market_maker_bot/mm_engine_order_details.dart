import 'dart:convert';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/mm_engine_english.dart';
import 'mm_engine_amount.dart';

class MmEngineOrderDetails extends StatelessWidget {
  const MmEngineOrderDetails({
    super.key,
    required this.row,
    required this.spec,
    this.strategy,
    this.updated,
  });
  final Map<String, dynamic> row;
  final Map spec;
  final Map? strategy;
  final DateTime? updated;

  String budget(String key) {
    if (strategy == null || !strategy!.containsKey(key)) return 'Unavailable';
    final value = strategy![key];
    if (value == null) return 'No limit';
    return mmEngineEnglish(value);
  }

  Widget field(BuildContext context, String label, Widget value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        value,
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final sell =
        '${row['kdf_base'] ?? (spec['base'] as Map?)?['ticker'] ?? '—'}';
    final buy =
        '${row['kdf_rel'] ?? (spec['quote'] as Map?)?['ticker'] ?? '—'}';
    final quantityAuto = spec['quantity_mode'] == 'auto';
    final priceAuto = spec['price_mode'] == 'auto';
    final published = row['order_uuid'] != null;
    final reason = mmEngineEnglish(row['detail']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Sell $sell for $buy',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          '${row['status'] ?? strategy?['state'] ?? 'Unknown'} · '
          '${spec['hedging_enabled'] == false ? 'Hedging off (locked)' : 'Hedging on ${spec['cex'] ?? 'Unavailable'} (locked)'}',
        ),
        if (updated != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Snapshot confirmed at ${updated!.toLocal().toIso8601String().split('.').first.replaceAll('T', ' ')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        if (reason.isNotEmpty)
          field(context, 'Current reason', SelectableText(reason)),
        const Divider(height: 24),
        field(
          context,
          quantityAuto
              ? '${published ? 'Published' : 'Configured'} amount · Automatic'
              : '${published ? 'Published' : 'Configured'} amount · Fixed',
          MmEngineAmount(row['kdf_volume'], unit: sell),
        ),
        if (quantityAuto)
          Text(
            published
                ? 'Automatically sized. This is the latest confirmed published quantity, not a fixed limit.'
                : 'Automatically sized when published. No open order in this snapshot.',
          ),
        field(
          context,
          priceAuto
              ? '${published ? 'Published' : 'Configured'} price · Automatic'
              : '${published ? 'Published' : 'Configured'} price · Fixed',
          MmEngineAmount(row['kdf_price'], unit: '$buy per $sell'),
        ),
        if (priceAuto)
          const Text(
            'Updated when market conditions and strategy thresholds allow.',
          ),
        const Divider(height: 24),
        field(
          context,
          'Remaining sold budget ($sell)',
          MmEngineAmount(budget('remaining_sold')),
        ),
        field(
          context,
          'Remaining daily budget ($sell)',
          MmEngineAmount(budget('daily_remaining_sold')),
        ),
        if (spec['premium'] != null)
          field(
            context,
            'Premium',
            Tooltip(
              message:
                  'Markup over the hedge reference price. This is not guaranteed net profit.',
              child: Text(
                '${(Decimal.tryParse('${spec['premium']}') ?? Decimal.zero) * Decimal.fromInt(100)}%',
              ),
            ),
          ),
        const SizedBox(height: 16),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Technical details'),
          subtitle: const Text('Order identity and exact saved parameters'),
          children: [
            field(
              context,
              'Order UUID',
              SelectableText('${row['order_uuid'] ?? 'Not published'}'),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                const JsonEncoder.withIndent('  ').convert(spec),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
