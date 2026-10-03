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
  testWidgets('modify keeps existing parameters and locks routing', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MmEngineStrategyForm(
            markets: ['LTC-DASH'],
            strategyId: 'original',
            initialSpec: {
              'base': {'ticker': 'ARRR', 'asset': 'ARRR', 'symbol': 'ARRRUSDT'},
              'quote': {
                'ticker': 'USDT-BEP20',
                'asset': 'USDT',
                'symbol': null,
              },
              'side': 'SELL_ARRR',
              'cex': 'GATE',
              'premium': '0.025',
              'price_mode': 'fixed',
              'quantity_mode': 'fixed',
              'fixed_price': '0.3',
              'fixed_sold': '5',
              'total_sold_budget': '20',
              'update_seconds': '90',
              'replenish': true,
            },
          ),
        ),
      ),
    );
    expect(find.text('Modify Maker Order'), findsOneWidget);
    final dropdowns = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    expect(dropdowns.every((field) => field.onChanged == null), isTrue);
    expect(tester.takeException(), isNull);
  });
}
