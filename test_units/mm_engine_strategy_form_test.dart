import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_strategy_form.dart';
import 'package:web_dex/shared/widgets/pirate_peer_status.dart';

void main() {
  test('connected peer count counts IDs, not addresses', () {
    expect(
      connectedPeerCount({
        'result': {
          'peer1': ['a', 'b'],
          'peer2': ['c'],
        },
      }),
      2,
    );
    expect(connectedPeerCount({'result': {}}), 0);
    expect(
      () => connectedPeerCount({'error': 'offline'}),
      throwsFormatException,
    );
  });
  testWidgets(
    'new maker form has no name, explains fields and shows wallet base balance',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MmEngineStrategyForm(
              markets: ['ARRR-USDT-BEP20'],
              strategyId: 'order-test',
              availableBalances: {'ARRR': '12.5'},
            ),
          ),
        ),
      );
      expect(find.text('Strategy name'), findsNothing);
      expect(find.text('New Maker Order'), findsOneWidget);
      expect(find.text('Available base coin: 12.5 ARRR'), findsOneWidget);
      expect(find.byType(Tooltip), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'modify preserves route mappings, precise premium and risk settings',
    (tester) async {
      const original = {
        'base': {'ticker': 'ARRR', 'asset': 'ARRR', 'symbol': 'PIRATEUSDT'},
        'quote': {'ticker': 'USDT-BEP20', 'asset': 'USDT', 'symbol': null},
        'side': 'SELL_ARRR',
        'cex': 'GATE',
        'premium': '0.025123456789',
        'price_mode': 'fixed',
        'quantity_mode': 'fixed',
        'fixed_price': '0.3',
        'fixed_sold': '5',
        'total_sold_budget': '20',
        'update_seconds': '90',
        'replenish': true,
        'impact': '0.008',
        'depth_fraction': '0.4',
        'quantity_threshold': '0.15',
        'price_threshold': '0.005',
        'confirmations': 5,
        'scale_group': 'existing-group',
        'auto_fraction': '0.8',
      };
      Map<String, Object?>? saved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  saved = await showDialog<Map<String, Object?>>(
                    context: context,
                    builder: (_) => const MmEngineStrategyForm(
                      markets: ['LTC-DASH'],
                      strategyId: 'original',
                      initialSpec: original,
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(find.text('Modify Maker Order'), findsOneWidget);
      final dropdowns = tester.widgetList<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(dropdowns.every((field) => field.onChanged == null), isTrue);
      await tester.ensureVisible(find.text('Preview'));
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(saved?['strategy_id'], 'original');
      for (final entry in original.entries) {
        expect(saved?[entry.key], entry.value, reason: entry.key);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
