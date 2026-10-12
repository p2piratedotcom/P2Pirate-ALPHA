import 'package:flutter/material.dart';
import 'package:decimal/decimal.dart';
import 'package:web_dex/shared/utils/mm_engine_english.dart';

/// Human-readable summary; the engine remains the owner of sizing and pricing.
class MmEnginePreview extends StatelessWidget {
  const MmEnginePreview({super.key, required this.preview});
  final Map<String, dynamic> preview;

  @override
  Widget build(BuildContext context) {
    final items = preview['previews'];
    final specs = preview['specs'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preview only. No order has been placed.'),
        const SizedBox(height: 16),
        if (specs is List && specs.length > 1) ...[
          const Text(
            'Two independent maker orders. Both will be saved paused.',
          ),
          const SizedBox(height: 8),
          for (final spec in specs.whereType<Map>())
            if (spec['base'] is Map && spec['quote'] is Map) ...[
              Text(
                '${spec['side'] == 'SELL_ARRR' ? spec['base']['ticker'] : spec['quote']['ticker']} '
                '→ ${spec['side'] == 'SELL_ARRR' ? spec['quote']['ticker'] : spec['base']['ticker']}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                'Premium: ${Decimal.tryParse('${spec['premium']}') == null ? 'unavailable' : '${Decimal.parse('${spec['premium']}') * Decimal.fromInt(100)}%'}',
              ),
              Text(
                'Total sold budget: ${spec['total_sold_budget']} '
                '${spec['side'] == 'SELL_ARRR' ? spec['base']['ticker'] : spec['quote']['ticker']}',
              ),
              if (spec['max_sold'] != null)
                Text('Maximum sold per order: ${spec['max_sold']}'),
              if (spec['daily_sold_cap'] != null)
                Text('Daily sold cap: ${spec['daily_sold_cap']}'),
              const SizedBox(height: 12),
            ],
          const Text(
            'Each order uses its own sold-coin budget. Both must pass the shared funding and depth checks.',
          ),
          const SizedBox(height: 16),
        ],
        if (items is List)
          for (final item in items.whereType<Map>()) ...[
            if (item['plan'] is Map) ...[
              Text(
                '${item['plan']['kdf_base']} → ${item['plan']['kdf_rel']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Sell amount: ${item['plan']['kdf_volume']} ${item['plan']['kdf_base']}',
              ),
              Text(
                'Order price: ${item['plan']['kdf_price']} '
                '${item['plan']['kdf_rel']}/${item['plan']['kdf_base']}',
              ),
            ],
            const SizedBox(height: 8),
            const Text('Exchange hedge'),
            if (item['hedge_legs'] is List)
              for (final leg in (item['hedge_legs'] as List).whereType<Map>())
                Text(
                  '${leg['cex']}: ${leg['side']} ${leg['quantity']} ${leg['asset']}',
                ),
            if (item['notice'] is String) Text(mmEngineEnglish(item['notice'])),
            const SizedBox(height: 16),
          ],
        const Text(
          'Saving keeps the strategy paused. Starting live trading is a separate action.',
        ),
      ],
    );
  }
}
