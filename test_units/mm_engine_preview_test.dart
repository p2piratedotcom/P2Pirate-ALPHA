import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_preview.dart';

void main() {
  testWidgets('preview shows units and does not imply publication', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MmEnginePreview(
            preview: {
              'previews': [
                {
                  'plan': {
                    'kdf_base': 'ARRR',
                    'kdf_rel': 'USDTBEP20',
                    'kdf_volume': '10',
                    'kdf_price': '0.4',
                  },
                  'hedge_legs': [
                    {
                      'cex': 'MEXC',
                      'side': 'BUY',
                      'quantity': '10',
                      'asset': 'ARRR',
                    },
                  ],
                },
              ],
            },
          ),
        ),
      ),
    );
    expect(find.text('ARRR → USDTBEP20'), findsOneWidget);
    expect(find.text('Sell amount: 10 ARRR'), findsOneWidget);
    expect(find.text('MEXC: BUY 10 ARRR'), findsOneWidget);
    expect(
      find.text('Preview only. No order has been placed.'),
      findsOneWidget,
    );
  });
}
