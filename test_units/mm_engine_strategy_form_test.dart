import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_strategy_form.dart';
import 'package:web_dex/shared/widgets/pirate_peer_status.dart';

void main() {
  test('empty market response still permits the saved edit route only', () {
    const spec = {
      'base': {'ticker': 'ARRR'},
      'quote': {'ticker': 'USDT-BEP20'},
    };
    expect(makerOrderMarkets({}), isEmpty);
    expect(makerOrderMarkets(null), isEmpty);
    expect(makerOrderMarkets({}, existingSpec: spec), ['ARRR-USDT-BEP20']);
    expect(makerOrderMarkets(null, existingSpec: spec), ['ARRR-USDT-BEP20']);
    expect(makerOrderMarkets({'ARRR-USDT-BEP20': {}}, existingSpec: spec), [
      'ARRR-USDT-BEP20',
    ]);
  });
  testWidgets(
    'both maker coin selectors use active tickers and preserve networks',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MmEngineStrategyForm(
              activeTickers: ['ARRR', 'DASH', 'USDT-BEP20', 'BTC-segwit'],
              strategyId: 'active-pair',
              availableBalances: {'USDT-BEP20': '40'},
            ),
          ),
        ),
      );
      DropdownButtonFormField<String> selector(String label) => tester
          .widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .firstWhere((w) => w.decoration.labelText == label);
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.descendant(
                of: find.byWidget(selector('Quote wallet coin')),
                matching: find.byType(DropdownButton<String>),
              ),
            )
            .items!
            .map((i) => i.value),
        containsAll(['DASH', 'USDT-BEP20', 'BTC-segwit']),
      );
      expect(
        tester
            .widget<DropdownButton<String>>(
              find.descendant(
                of: find.byWidget(selector('Quote wallet coin')),
                matching: find.byType(DropdownButton<String>),
              ),
            )
            .items!
            .map((i) => i.value),
        isNot(contains('ARRR')),
      );
      selector('Quote wallet coin').onChanged!('DASH');
      await tester.pump();
      selector('Base wallet coin').onChanged!('USDT-BEP20');
      await tester.pump();
      expect(selector('Base wallet coin').initialValue, 'USDT-BEP20');
      expect(selector('Quote wallet coin').initialValue, 'DASH');
      expect(find.text('Available base coin: 40 USDT-BEP20'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'USDT on wallet base preserves sold coin and reverses engine route',
    (tester) async {
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
                      activeTickers: ['ARRR', 'DASH', 'USDT-BEP20'],
                      strategyId: 'usd-base',
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
      DropdownButtonFormField<String> selector(String label) => tester
          .widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .firstWhere((w) => w.decoration.labelText == label);
      selector('Quote wallet coin').onChanged!('DASH');
      await tester.pump();
      selector('Base wallet coin').onChanged!('USDT-BEP20');
      await tester.pump();
      final budget = find.ancestor(
        of: find.byWidgetPredicate(
          (w) =>
              w is InputDecorator &&
              w.decoration.labelText == 'Total sold budget',
        ),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(budget);
      await tester.enterText(budget, '10');
      await tester.ensureVisible(find.text('Preview'));
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect((saved?['base'] as Map)['ticker'], 'DASH');
      expect((saved?['quote'] as Map)['ticker'], 'USDT-BEP20');
      expect((saved?['quote'] as Map)['symbol'], isNull);
      expect(saved?['side'], 'BUY_ARRR');
      expect(tester.takeException(), isNull);
    },
  );

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
  testWidgets('maker form accepts only venues from the installed catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MmEngineStrategyForm(
            markets: ['ARRR-USDT-BEP20'],
            strategyId: 'demo-order',
            venues: {'DEMO': 'Demo Spot'},
          ),
        ),
      ),
    );
    expect(find.text('Demo Spot'), findsOneWidget);
    expect(find.text('MEXC Spot'), findsNothing);
    expect(tester.takeException(), isNull);
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
  testWidgets('removed saved venue stays visible and blocks preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MmEngineStrategyForm(
            markets: ['ARRR-USDT-BEP20'],
            strategyId: 'old-venue-order',
            venues: {'DEMO': 'Demo Spot'},
            initialSpec: {
              'base': {'ticker': 'ARRR', 'asset': 'ARRR'},
              'quote': {'ticker': 'USDT-BEP20', 'asset': 'USDT'},
              'cex': 'GATE',
              'side': 'SELL_ARRR',
              'premium': '0.02',
              'price_mode': 'auto',
              'quantity_mode': 'auto',
              'total_sold_budget': '10',
              'update_seconds': '60',
            },
          ),
        ),
      ),
    );
    expect(find.text('GATE (plugin unavailable)'), findsOneWidget);
    final preview = find.widgetWithText(ElevatedButton, 'Preview');
    expect(tester.widget<ElevatedButton>(preview).onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

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
