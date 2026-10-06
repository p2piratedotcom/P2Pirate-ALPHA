import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/shared/utils/successful_read_cache.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_amount.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_order_details.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_rebalance_preview.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_status_strip.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_strategy_form.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_page_memory.dart';

void main() {
  testWidgets(
    'inactive draft keeps its original coin and cannot preview a substituted budget',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var previews = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MmEngineStrategyForm(
              strategyId: 'inactive-draft',
              activeTickers: const ['ARRR', 'USDT-BEP20'],
              draft: const {
                'baseTicker': 'BTC',
                'quoteTicker': 'USDT-BEP20',
                'baseAsset': 'BTC',
                'quoteAsset': 'USDT',
                'budget': '0.02',
              },
              onPreview: (_) async {
                previews++;
                return false;
              },
            ),
          ),
        ),
      );
      final budget = find.ancestor(
        of: find.byWidgetPredicate(
          (w) =>
              w is InputDecorator &&
              w.decoration.labelText == 'Total sold budget',
        ),
        matching: find.byType(TextFormField),
      );
      expect(find.text('BTC (inactive)'), findsWidgets);
      expect(tester.widget<TextFormField>(budget).controller!.text, '0.02');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(previews, 0);
      final base = tester
          .widgetList<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .firstWhere((w) => w.decoration.labelText == 'Base wallet coin');
      base.onChanged!('ARRR');
      await tester.pump();
      expect(tester.widget<TextFormField>(budget).controller!.text, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );
  test('maker drafts are cleared across wallet and engine sessions', () {
    final first = MmEnginePageMemory.forSession('wallet-a', 1);
    first.makerDrafts['new'] = {'budget': '12.345'};
    expect(
      MmEnginePageMemory.forSession(
        'wallet-a',
        1,
      ).makerDrafts['new']!['budget'],
      '12.345',
    );
    expect(MmEnginePageMemory.forSession('wallet-b', 1).makerDrafts, isEmpty);
    expect(first.makerDrafts, isEmpty);
    MmEnginePageMemory.clear();
  });

  testWidgets(
    'closing to fix prerequisites and reopening restores raw maker draft',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      Map<String, Object?>? draft;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (_) => MmEngineStrategyForm(
                    activeTickers: const ['ARRR', 'USDT-BEP20'],
                    strategyId: 'draft-stable',
                    draft: draft,
                    onDraftChanged: (value) => draft = value,
                    onPreview: (_) async =>
                        throw StateError('Configure the CEX first'),
                  ),
                ),
                child: const Text('Open maker'),
              ),
            ),
          ),
        ),
      );
      final budget = find.ancestor(
        of: find.byWidgetPredicate(
          (w) =>
              w is InputDecorator &&
              w.decoration.labelText == 'Total sold budget',
        ),
        matching: find.byType(TextFormField),
      );
      await tester.tap(find.text('Open maker'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(budget);
      await tester.enterText(budget, '12.345');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(draft!['budget'], '12.345');
      await tester.tap(find.text('Open maker'));
      await tester.pumpAndSettle();
      expect(tester.widget<TextFormField>(budget).controller!.text, '12.345');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
  test(
    'failed read retries, concurrent reads coalesce, success stays cached',
    () async {
      final cache = SuccessfulReadCache<int>();
      var calls = 0;
      Future<int> load() async {
        calls++;
        if (calls == 1) throw StateError('temporary');
        return 7;
      }

      await expectLater(cache.get(load), throwsStateError);
      final a = cache.get(load), b = cache.get(load);
      expect(identical(a, b), isTrue);
      expect(await a, 7);
      expect(await cache.get(load), 7);
      expect(calls, 2);
    },
  );

  test('late old account failure cannot evict newer successful read', () async {
    final cache = SuccessfulReadCache<int>();
    final old = Completer<int>();
    final failure = expectLater(cache.get(() => old.future), throwsStateError);
    cache.clear();
    expect(await cache.get(() async => 9), 9);
    old.completeError(StateError('old account'));
    await failure;
    expect(await cache.get(() async => 10), 9);
  });

  test(
    'tiny nonzero amounts remain nonzero; display cannot change exact input',
    () {
      const exact = '0.000000000123456789';
      expect(mmEngineDisplayAmount(exact), '≈ 0.00000000012345678');
      expect(mmEngineDisplayAmount('24.123456789012345678'), '≈ 24.123456');
      expect(mmEngineDisplayAmount('0.000000000000000000'), '0');
      expect(mmEngineDisplayAmount('40.0000000000'), '40');
      expect(exact, '0.000000000123456789');
    },
  );

  testWidgets(
    'native shared switch has a name and toggle state; removal is clean',
    (tester) async {
      final semantics = tester.ensureSemantics();
      var enabled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, set) => Scaffold(
              body: UiSwitcher(
                value: enabled,
                semanticLabel: 'Route through Tor',
                onChanged: (value) => set(() => enabled = value),
              ),
            ),
          ),
        ),
      );
      final node = tester
          .getSemantics(find.byType(UiSwitcher))
          .getSemanticsData();
      expect(node.label, 'Route through Tor');
      expect(node.hasFlag(SemanticsFlag.hasToggledState), isTrue);
      expect(node.hasFlag(SemanticsFlag.isToggled), isFalse);
      await tester.tap(find.byType(Switch));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
      semantics.dispose();
    },
  );

  testWidgets('freshness transitions do not move the following action', (
    tester,
  ) async {
    Future<void> show(String? error) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MmEngineStatusStrip(
                updated: DateTime.now(),
                running: true,
                error: error,
              ),
              const Text('Action', key: Key('action')),
            ],
          ),
        ),
      ),
    );
    await show(null);
    final position = tester.getTopLeft(find.byKey(const Key('action')));
    await show('Engine is updating orders; showing the last confirmed state.');
    expect(tester.getTopLeft(find.byKey(const Key('action'))), position);
  });

  testWidgets(
    'maker opens before balance read and keeps draft after failed/back preview',
    (tester) async {
      tester.view.physicalSize = const Size(900, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final balance = Completer<String?>();
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MmEngineStrategyForm(
              strategyId: 'draft',
              activeTickers: const ['ARRR', 'USDT-BEP20'],
              loadBalance: (_) => balance.future,
              onPreview: (_) async {
                attempts++;
                if (attempts == 1)
                  throw StateError('Temporary preview failure');
                return false;
              },
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('New Maker Order'), findsOneWidget);
      expect(find.textContaining('loading…'), findsOneWidget);
      final budget = find.ancestor(
        of: find.byWidgetPredicate(
          (w) =>
              w is InputDecorator &&
              w.decoration.labelText == 'Total sold budget',
        ),
        matching: find.byType(TextFormField),
      );
      await tester.ensureVisible(budget);
      await tester.enterText(budget, '12.345');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Temporary preview failure'), findsOneWidget);
      expect(tester.widget<TextFormField>(budget).controller!.text, '12.345');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();
      expect(attempts, 2);
      expect(tester.widget<TextFormField>(budget).controller!.text, '12.345');
      balance.complete('15');
      await tester.pumpAndSettle();
      expect(find.text('Available base coin: 15 ARRR'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('details show unit-bearing summary; raw params stay collapsed', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MmEngineOrderDetails(
              row: {
                'kdf_base': 'ARRR',
                'kdf_rel': 'USDT-BEP20',
                'kdf_volume': '40',
                'kdf_price': '0.31',
                'status': 'RUNNING',
              },
              spec: {
                'cex': 'MEXC',
                'quantity_mode': 'auto',
                'price_mode': 'auto',
                'premium': '0.02',
                'auto_fraction': '1',
              },
              strategy: {'remaining_sold': '40', 'daily_remaining_sold': null},
            ),
          ),
        ),
      ),
    );
    expect(find.text('40 ARRR'), findsOneWidget);
    expect(find.text('0.31 USDT-BEP20 per ARRR'), findsOneWidget);
    expect(find.text('Technical details'), findsOneWidget);
    expect(find.textContaining('"auto_fraction"'), findsNothing);
    expect(find.text('No limit'), findsOneWidget);
  });

  testWidgets(
    'coverage result leads and wide exact tables scroll at narrow width',
    (tester) async {
      tester.view.physicalSize = const Size(620, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MmEngineRebalancePreview(
                ideal: {
                  'makers': [],
                  'indicative_targets': {'USDT': '12'},
                },
                plan: {
                  'current_coverage_percent': '50.00',
                  'coverage_percent': '75.00',
                  'funding': {
                    'USDT': {
                      'spot_free': '10',
                      'available': '9',
                      'required': '15',
                      'full_required': '20',
                      'ideal_missing': '11',
                    },
                  },
                },
              ),
            ),
          ),
        ),
      );
      expect(find.text('Coverage result'), findsOneWidget);
      expect(
        find.textContaining('Partial coverage attainable: 75.00%'),
        findsOneWidget,
      );
      expect(find.byType(Scrollbar), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
