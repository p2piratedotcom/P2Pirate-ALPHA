import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/mm_engine_english.dart';
import 'mm_engine_amount.dart';
import 'mm_engine_scrollable_table.dart';

/// A result leads with coverage; original calculations remain inspectable.
class MmEngineRebalancePreview extends StatelessWidget {
  const MmEngineRebalancePreview({super.key, required this.ideal, this.plan});
  final Map<String, dynamic> ideal;
  final Map<String, dynamic>? plan;

  Widget table(List<String> headings, List<List<Object?>> rows) =>
      MmEngineScrollableTable(
        child: DataTable(
          horizontalMargin: 0,
          columnSpacing: 24,
          columns: [
            for (final heading in headings) DataColumn(label: Text(heading)),
          ],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final value in row) DataCell(MmEngineAmount(value)),
                ],
              ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final makers = (ideal['makers'] as List? ?? []).whereType<Map>();
    final indicative = ideal['indicative_targets'] as Map? ?? {};
    final funding = plan?['funding'] as Map? ?? {};
    final reserve = plan?['protected_targets'] as Map? ?? {};
    final budget = (plan?['allocation'] as Map?)?['remaining'] as Map? ?? {};
    final full = plan?['coverage_percent'] == '100.00';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Coverage result', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        if (plan == null)
          const Text(
            'The ideal reference is ready. Waiting for fresh CEX balances and market data.',
          )
        else ...[
          Text(
            'Current coverage: ${plan!['current_coverage_percent'] ?? 'Unverified'}${plan!['current_coverage_percent'] == null ? '' : '%'}',
          ),
          const SizedBox(height: 8),
          Text(
            plan!['coverage_percent'] == null
                ? 'Attainable coverage is unverified. See the block reasons.'
                : '${full ? 'Full' : 'Partial'} coverage attainable: ${plan!['coverage_percent']}% of the ideal target.',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          const Text(
            'This is the funding goal for the plan, not the outcome of its first trade. Makers retain their live hedge and depth checks.',
          ),
          table(
            ['Asset', 'Funded goal', 'Full ideal', 'Current shortfall'],
            [
              for (final entry in funding.entries)
                [
                  entry.key,
                  entry.value['required'],
                  entry.value['full_required'],
                  entry.value['ideal_missing'],
                ],
            ],
          ),
          if ((plan!['projected_orders'] as List? ?? []).isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Proposed sequence',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            for (final item
                in (plan!['projected_orders'] as List).whereType<Map>())
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: SelectableText(
                  '${item['side']} ${mmEngineDisplayAmount(item['quantity'])} ${item['asset']} · LIMIT ${mmEngineDisplayAmount(item['price'])} USDT · ${mmEngineDisplayAmount(item['notional'])} USDT before fees',
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Only the first funded step is submitted after confirmation. Verify its fill, then Analyze again.',
            ),
          ],
          for (final note in plan!['hedge_capacity'] as List? ?? [])
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SelectableText(
                '#${note['number']} · Current liquidity/minimum limits support ${note['maximum_percent']}% of the reference. ${mmEngineEnglish(note['reason'])}',
              ),
            ),
        ],
        const SizedBox(height: 16),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Ideal hedge target'),
          subtitle: const Text('Local maker reference · no CEX requests'),
          initiallyExpanded: plan == null,
          children: [
            const Text(
              'Saved maker quantities and reference prices, including fees and a 20% reserve. Auto sizing uses finite configured limits. These are not live CEX prices.',
            ),
            for (final maker in makers)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SelectableText(
                      '#${maker['number']} · Sell ${mmEngineDisplayAmount(maker['quantity'])} ${maker['sell']} → ${maker['buy']} at ${mmEngineDisplayAmount(maker['price'])} ${maker['buy']}/${maker['sell']}',
                    ),
                    for (final leg
                        in (maker['hedge_legs'] as List? ?? [])
                            .whereType<Map>())
                      SelectableText(
                        'Hedge after a wallet swap: ${leg['side']} ${mmEngineDisplayAmount(leg['quantity'])} ${leg['asset']} · pre-fund ${leg['side'] == 'BUY' ? 'USDT' : leg['asset']}',
                      ),
                  ],
                ),
              ),
            table(
              ['Prefund asset', 'Indicative ideal amount'],
              [
                for (final entry in indicative.entries)
                  [entry.key, entry.value],
              ],
            ),
            if ((ideal['unvalued_buy_assets'] as List? ?? []).isNotEmpty)
              const Text(
                'Some USDT equivalents need fresh CEX prices; native hedge quantities are already defined.',
              ),
          ],
        ),
        if (plan != null)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: const Text('Balances, reserves and spending limits'),
            subtitle: const Text(
              'Detailed comparison · exact values available on hover',
            ),
            children: [
              const Text(
                'Unselected maker reserves are protected. Required hedge coins remain destinations even at zero balance.',
              ),
              table(
                [
                  'Asset',
                  'Spot free',
                  'Available for makers',
                  'Other maker reserve',
                  'Debit left',
                  'Full ideal',
                  'Missing for full ideal',
                ],
                [
                  for (final entry in funding.entries)
                    [
                      entry.key,
                      entry.value['spot_free'],
                      entry.value['available'],
                      reserve[entry.key] ?? '0',
                      budget[entry.key] ?? '0',
                      entry.value['full_required'],
                      entry.value['ideal_missing'],
                    ],
                ],
              ),
            ],
          ),
      ],
    );
  }
}
