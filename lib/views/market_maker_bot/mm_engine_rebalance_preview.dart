import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:web_dex/shared/utils/mm_engine_english.dart';

/// Render the local reference, actual account comparison, and achievable goal.
class MmEngineRebalancePreview extends StatelessWidget {
  const MmEngineRebalancePreview({super.key, required this.ideal, this.plan});
  final Map<String, dynamic> ideal;
  final Map<String, dynamic>? plan;
  String _amount(Object? raw) {
    if (raw == null) return '—';
    final value = Decimal.tryParse('$raw');
    if (value == null) return '$raw';
    final text = value.toString();
    final parts = text.split('.');
    return parts.length == 2 && parts[1].length > 8
        ? '≈ ${parts[0]}.${parts[1].substring(0, 8)}'
        : text;
  }

  Widget _heading(BuildContext context, String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleMedium),
  );
  Widget _table(List<String> headings, List<List<Object?>> rows) =>
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          horizontalMargin: 0,
          columnSpacing: 22,
          columns: [for (final h in headings) DataColumn(label: Text(h))],
          rows: [
            for (final row in rows)
              DataRow(
                cells: [
                  for (final value in row) DataCell(SelectableText('$value')),
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
        _heading(context, '1 · IDEAL HEDGE COVERAGE — MAKER REFERENCE'),
        const SelectableText(
          'Calculated locally, without CEX requests. Auto quantities use the configured maximum or nominal maker budget; '
          'open liabilities are preserved. Prices below are saved maker references, not live CEX quotes. Includes fees and a 20% reserve.',
        ),
        for (final maker in makers)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  '#${maker['number']} · Sell ${_amount(maker['quantity'])} ${maker['sell']} → ${maker['buy']} '
                  'at reference ${_amount(maker['price'])} ${maker['buy']}/${maker['sell']}',
                ),
                for (final leg
                    in (maker['hedge_legs'] as List).whereType<Map>())
                  SelectableText(
                    'CEX hedge after a wallet swap: ${leg['side']} ${_amount(leg['quantity'])} ${leg['asset']} '
                    '· pre-fund ${leg['side'] == 'BUY' ? 'USDT to buy ${leg['asset']}' : leg['asset']}',
                  ),
              ],
            ),
          ),
        _table(
          ['PREFUND ASSET', 'INDICATIVE IDEAL AMOUNT'],
          [
            for (final entry in indicative.entries)
              [entry.key, _amount(entry.value)],
          ],
        ),
        if ((ideal['unvalued_buy_assets'] as List? ?? []).isNotEmpty)
          const Text(
            'Some USDT equivalents require fresh CEX prices in step 2; native hedge quantities are already defined.',
          ),
        _heading(context, '2 · ACTUAL CEX BALANCES VS IDEAL'),
        if (plan == null)
          const SelectableText(
            'Waiting for fresh account and market data. The local maker reference above remains available if that read fails.',
          )
        else ...[
          const SelectableText(
            'Ideal quantities stay fixed; USDT funding is valued using current CEX buy prices. '
            'Zero-balance hedge destinations are included. Reserves for other active makers are excluded from available funds.',
          ),
          _table(
            [
              'ASSET',
              'REAL SPOT FREE',
              'FREE FOR SELECTED MAKERS',
              'OTHER MAKER RESERVE',
              'AUTHORIZED DEBIT LEFT',
              'FULL IDEAL AT CEX PRICES',
              'MISSING FOR FULL IDEAL',
            ],
            [
              for (final entry in funding.entries)
                [
                  entry.key,
                  _amount(entry.value['spot_free']),
                  _amount(entry.value['available']),
                  _amount(reserve[entry.key] ?? '0'),
                  _amount(budget[entry.key] ?? '0'),
                  _amount(entry.value['full_required']),
                  _amount(entry.value['ideal_missing']),
                ],
            ],
          ),
        ],
        _heading(context, '3 · REBALANCE GOAL'),
        if (plan != null) ...[
          SelectableText(
            'Current financial coverage: ${plan!['current_coverage_percent']}%.',
          ),
          SelectableText(
            plan!['coverage_percent'] == null
                ? 'Attainable coverage is not verified. Check the block reasons below.'
                : '${full ? "FULL" : "PARTIAL"} financial coverage attainable: ${plan!['coverage_percent']}% of the ideal reference.',
          ),
          _table(
            ['ASSET', 'FUNDED GOAL', 'FULL IDEAL'],
            [
              for (final entry in funding.entries)
                [
                  entry.key,
                  _amount(entry.value['required']),
                  _amount(entry.value['full_required']),
                ],
            ],
          ),
          const SizedBox(height: 8),
          for (final item
              in (plan!['projected_orders'] as List? ?? []).whereType<Map>())
            SelectableText(
              '${item['side']} ${_amount(item['quantity'])} ${item['asset']} · LIMIT ${_amount(item['price'])} USDT · ${_amount(item['notional'])} USDT before fees',
            ),
          const SelectableText(
            'Only the first funded step is submitted after confirmation. Later buys require confirmed sale proceeds and another Analyze. '
            'This funds the hedge inventory; it does not execute a hedge or change maker quantities. Live hedge/depth checks still apply.',
          ),
          for (final note in plan!['hedge_capacity'] as List? ?? [])
            SelectableText(
              '#${note['number']} · current hedge liquidity/minimum limits support ${note['maximum_percent']}% of the reference. ${mmEngineEnglish(note['reason'])}',
            ),
        ],
      ],
    );
  }
}
