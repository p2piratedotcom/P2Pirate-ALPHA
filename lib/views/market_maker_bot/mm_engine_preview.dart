import 'package:flutter/material.dart';

/// Human-readable summary; the engine remains the owner of sizing and pricing.
class MmEnginePreview extends StatelessWidget {
  const MmEnginePreview({super.key, required this.preview});
  final Map<String, dynamic> preview;

  @override
  Widget build(BuildContext context) {
    final items = preview['previews'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Preview only. No order has been placed.'),
        const SizedBox(height: 16),
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
            if (item['notice'] is String) Text(item['notice'] as String),
            const SizedBox(height: 16),
          ],
        const Text(
          'Saving keeps the strategy paused. Starting live trading is a separate action.',
        ),
      ],
    );
  }
}
