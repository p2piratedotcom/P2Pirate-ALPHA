import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_dashboard.dart';

void main() {
  for (final width in [360.0, 800.0, 1050.0, 1700.0]) {
    testWidgets(
      'CEX controls accept a catalog exchange without registry edits',
      (tester) async {
        String? selected;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: MmEngineDashboard(
                  orders: const [],
                  strategies: const [],
                  venue: 'DEMO',
                  venueLabels: const {'DEMO': 'Demo Spot'},
                  credentials: const {'DEMO': true},
                  balances: const [],
                  busy: false,
                  live: false,
                  onLive: () {},
                  onNew: () {},
                  onVenue: (value) => selected = value,
                  onAdd: () {},
                  onStrategy: (_, __) {},
                  onBalances: () {},
                ),
              ),
            ),
          ),
        );
        expect(find.text('Gate'), findsNothing);
        expect(find.text('MEXC'), findsNothing);
        await tester.tap(find.text('Demo Spot'));
        expect(selected, 'DEMO');
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('order footer actions and copy UUID fit width $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? copied;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
            if (call.method == 'Clipboard.setData') {
              copied = (call.arguments as Map)['text'] as String;
            }
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(SystemChannels.platform, null),
      );
      var modified = false;
      var paused = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SelectionArea(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: MmEngineDashboard(
                    orders: const [
                      {
                        'strategy_id': 'active',
                        'order_uuid': '8e137e55-1234-4db6-9123-abc123456789',
                        'kdf_base': 'ARRR',
                        'kdf_rel': 'USDT-BEP20',
                        'status': 'OPEN',
                      },
                    ],
                    strategies: const [
                      {
                        'id': 'paused',
                        'enabled': 0,
                        'state': 'PAUSED',
                        'spec': {
                          'base': {'ticker': 'DASH'},
                          'quote': {'ticker': 'LTC'},
                        },
                      },
                    ],
                    venue: 'MEXC',
                    credentials: const {'MEXC': true},
                    balances: const [
                      {'ticker': 'ARRR', 'available': '61.4'},
                    ],
                    busy: false,
                    live: false,
                    balanceLoading: true,
                    onLive: () {},
                    onNew: () {},
                    onVenue: (_) {},
                    onAdd: () {},
                    onBalances: () {},
                    onStrategy: (_, _) => paused = true,
                    onModify: (_) => modified = true,
                    onDetails: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      for (final label in ['Pause', 'Modify']) {
        final button = find.widgetWithText(OutlinedButton, label);
        await tester.ensureVisible(button);
        final bounds = tester.getRect(button);
        expect(bounds.left, greaterThanOrEqualTo(0));
        expect(bounds.right, lessThanOrEqualTo(width));
        await tester.tap(button);
      }
      expect(modified, isTrue);
      expect(paused, isTrue);
      await tester.ensureVisible(find.byTooltip('Copy UUID'));
      await tester.tap(find.byTooltip('Copy UUID'));
      expect(copied, '8e137e55-1234-4db6-9123-abc123456789');
      expect(find.text('61.4'), findsOneWidget); // Retained while refresh runs.
      expect(find.byType(SelectionArea), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  for (final width in [360.0, 1050.0]) {
    testWidgets(
      'select one, several or all without enabling orders at width $width',
      (tester) async {
        tester.view.physicalSize = Size(width, 1500);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var live = false;
        var selected = <String>{};
        var activations = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StatefulBuilder(
                  builder: (context, update) => MmEngineDashboard(
                    orders: const [],
                    strategies: const [
                      {
                        'id': 'one',
                        'creation_number': 1,
                        'enabled': 0,
                        'state': 'PAUSED',
                        'spec': {
                          'base': {'ticker': 'ARRR'},
                          'quote': {'ticker': 'USDT-BEP20'},
                        },
                      },
                      {
                        'id': 'two',
                        'creation_number': 2,
                        'enabled': 0,
                        'state': 'PAUSED',
                        'spec': {
                          'base': {'ticker': 'DASH'},
                          'quote': {'ticker': 'LTC'},
                        },
                      },
                      {
                        'id': 'blocked',
                        'enabled': 0,
                        'state': 'REVIEW_REQUIRED',
                        'spec': {},
                      },
                    ],
                    selectedOrders: selected,
                    onSelection: (ids) => update(() => selected = ids),
                    onStartSelected: () => activations++,
                    venue: 'MEXC',
                    credentials: const {},
                    balances: const [],
                    busy: false,
                    live: live,
                    onLive: () => update(() => live = !live),
                    onNew: () {},
                    onVenue: (_) {},
                    onAdd: () {},
                    onStrategy: (_, _) {},
                    onBalances: () {},
                  ),
                ),
              ),
            ),
          ),
        );
        final first = find.byKey(const Key('select-maker-order-one'));
        await tester.ensureVisible(first);
        await tester.tap(first);
        await tester.pump();
        expect(selected, {'one'});
        expect(
          tester
              .widget<Checkbox>(
                find.byKey(const Key('select-all-maker-orders')),
              )
              .value,
          isNull,
        );
        expect(
          tester
              .widget<Checkbox>(
                find.byKey(const Key('select-maker-order-blocked')),
              )
              .onChanged,
          isNull,
        );
        var activate = find.widgetWithText(
          ElevatedButton,
          'Start selected orders (1)',
        );
        expect(tester.widget<ElevatedButton>(activate).onPressed, isNull);
        await tester.ensureVisible(find.text('Start live trading'));
        await tester.tap(find.text('Start live trading'));
        await tester.pump();
        expect(activations, 0);
        expect(find.text('Stop live trading'), findsOneWidget);
        final all = find.byKey(const Key('select-all-maker-orders'));
        await tester.ensureVisible(all);
        await tester.tap(all);
        await tester.pump();
        expect(selected, {'one', 'two'});
        expect(tester.widget<Checkbox>(all).value, isTrue);
        activate = find.widgetWithText(
          ElevatedButton,
          'Start selected orders (2)',
        );
        await tester.ensureVisible(activate);
        await tester.tap(activate);
        expect(activations, 1);
        await tester.ensureVisible(all);
        await tester.tap(all);
        await tester.pump();
        expect(selected, isEmpty);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('CEX section can collapse and displays the refresh countdown', (
    tester,
  ) async {
    var expanded = true;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: StatefulBuilder(
              builder: (context, update) => MmEngineDashboard(
                orders: const [],
                strategies: const [],
                venue: 'MEXC',
                credentials: const {'MEXC': true},
                balances: const [
                  {'ticker': 'ARRR', 'available': '61.4'},
                ],
                busy: false,
                live: false,
                cexExpanded: expanded,
                onToggleCex: () => update(() => expanded = !expanded),
                balanceRefreshSeconds: 42,
                balanceUpdatedAt: DateTime(2026, 10, 3, 20, 30),
                onLive: () {},
                onNew: () {},
                onVenue: (_) {},
                onAdd: () {},
                onStrategy: (_, _) {},
                onBalances: () {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.text('Next refresh in 42s'), findsOneWidget);
    await tester.tap(find.text('Hide'));
    await tester.pump();
    expect(find.text('MY CEXs'), findsOneWidget);
    expect(find.text('61.4'), findsNothing);
    expect(find.byType(ChoiceChip), findsNothing);
    await tester.tap(find.text('Show'));
    await tester.pump();
    expect(find.text('61.4'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('primary actions remain usable at desktop minimum width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var livePressed = false;
    var newPressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SingleChildScrollView(
              child: MmEngineDashboard(
                orders: const [],
                strategies: const [],
                venue: 'MEXC',
                credentials: const {},
                balances: const [],
                busy: false,
                live: false,
                onLive: () => livePressed = true,
                onNew: () => newPressed = true,
                onVenue: (_) {},
                onAdd: () {},
                onStrategy: (_, _) {},
                onBalances: () {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Start live trading'));
    await tester.tap(find.text('New Maker Order'));
    expect(livePressed, isTrue);
    expect(newPressed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'paused order has tickers, auto values, number and read-only details',
    (tester) async {
      String? modified;
      Map<String, dynamic>? details;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MmEngineDashboard(
                orders: const [],
                strategies: const [
                  {
                    'id': 'internal',
                    'creation_number': 12,
                    'state': 'PAUSED',
                    'enabled': 0,
                    'detail': 'Manual pause',
                    'spec': {
                      'base': {'ticker': 'ARRR'},
                      'quote': {'ticker': 'USDT-BEP20'},
                      'side': 'BUY_ARRR',
                      'price_mode': 'auto',
                      'quantity_mode': 'auto',
                      'premium': '0.02',
                      'cex': 'MEXC',
                    },
                  },
                ],
                venue: 'MEXC',
                credentials: const {},
                balances: const [],
                busy: false,
                live: false,
                onLive: () {},
                onNew: () {},
                onVenue: (_) {},
                onAdd: () {},
                onStrategy: (_, _) {},
                onBalances: () {},
                onModify: (id) => modified = id,
                onDetails: (row) => details = row,
              ),
            ),
          ),
        ),
      );
      expect(find.text('12'), findsOneWidget);
      expect(find.text('ARRR'), findsOneWidget);
      expect(find.text('USDT-BEP20'), findsOneWidget);
      expect(find.text('auto'), findsNWidgets(2));
      expect(find.text('Manual pause'), findsOneWidget);
      await tester.ensureVisible(find.text('Modify'));
      await tester.tap(find.text('Modify'));
      expect(modified, 'internal');
      await tester.ensureVisible(find.text('Details'));
      await tester.tap(find.text('Details'));
      expect(details?['creation_number'], 12);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('paused fixed buy price uses bought per sold coin units', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MmEngineDashboard(
              orders: const [],
              strategies: const [
                {
                  'id': 'buy-fixed',
                  'creation_number': 1,
                  'state': 'PAUSED',
                  'enabled': 0,
                  'spec': {
                    'base': {'ticker': 'ARRR'},
                    'quote': {'ticker': 'USDT-BEP20'},
                    'side': 'BUY_ARRR',
                    'price_mode': 'fixed',
                    'fixed_price': '0.25',
                    'quantity_mode': 'fixed',
                    'fixed_sold': '5',
                    'cex': 'MEXC',
                  },
                },
              ],
              venue: 'MEXC',
              credentials: const {},
              balances: const [],
              busy: false,
              live: false,
              onLive: () {},
              onNew: () {},
              onVenue: (_) {},
              onAdd: () {},
              onStrategy: (_, _) {},
              onBalances: () {},
            ),
          ),
        ),
      ),
    );
    expect(find.text('4'), findsOneWidget);
    expect(find.text('0.25'), findsNothing);
    expect(find.text('5'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('balance loading disables all venue and credential switches', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MmEngineDashboard(
              orders: const [],
              strategies: const [],
              venue: 'MEXC',
              credentials: const {},
              balances: const [],
              busy: false,
              balanceLoading: true,
              live: false,
              onLive: () {},
              onNew: () {},
              onVenue: (_) {},
              onAdd: () {},
              onStrategy: (_, _) {},
              onBalances: () {},
            ),
          ),
        ),
      ),
    );
    for (final text in ['ADD CEX', 'Configure MEXC API credentials']) {
      final button = tester.widget<TextButton>(
        find.ancestor(of: find.text(text), matching: find.byType(TextButton)),
      );
      expect(button.onPressed, isNull);
    }
    expect(
      tester
          .widgetList<ChoiceChip>(find.byType(ChoiceChip))
          .every((chip) => chip.onSelected == null),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('maker table and CEX controls render without overflow', (
    tester,
  ) async {
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-Regular.ttf'));
    await font.load();
    tester.view.physicalSize = const Size(1171, 1111);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var selected = '';
    final capture = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark().copyWith(
          scaffoldBackgroundColor: Colors.black,
          textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Manrope'),
          colorScheme: const ColorScheme.dark(primary: Color(0xffb9973d)),
        ),
        home: RepaintBoundary(
          key: capture,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 90, vertical: 24),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'P2PIRATE TRADING ENGINE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(),
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'Preview mode · Active swaps: 0 · Open maker orders: 2',
                        ),
                      ),
                    ),
                    MmEngineDashboard(
                      orders: const [
                        {
                          'order_uuid': 'test-order-1',
                          'kdf_base': 'ARRR',
                          'kdf_rel': 'USDT-BEP20',
                          'kdf_volume': '15',
                          'kdf_price': '0.31',
                          'cex': 'MEXC',
                          'configured_premium': '0.025',
                          'status': 'OPEN',
                        },
                        {
                          'order_uuid': 'test-order-2',
                          'kdf_base': 'LTC',
                          'kdf_rel': 'DASH',
                          'kdf_volume': '0.25',
                          'kdf_price': '70.1',
                          'cex': 'GATE',
                          'configured_premium': '0.021',
                          'status': 'OPEN',
                        },
                      ],
                      strategies: const [],
                      venue: 'MEXC',
                      credentials: const {'MEXC': true},
                      balances: const [
                        {
                          'ticker': 'ARRR',
                          'name': 'Pirate Chain',
                          'available': '61.4',
                        },
                        {'ticker': 'USDT', 'available': '19.7'},
                      ],
                      busy: false,
                      live: false,
                      onLive: () {},
                      onNew: () {},
                      onVenue: (value) => selected = value,
                      onAdd: () {},
                      onStrategy: (id, start) {},
                      onBalances: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('MY MAKER ORDERS'), findsOneWidget);
    expect(find.text('MY CEXs'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(find.text('Pirate Chain'), findsOneWidget);
    expect(find.text('USDT'), findsNWidgets(2));
    await tester.tap(find.text('Gate').last);
    expect(selected, 'GATE');
    expect(tester.takeException(), isNull);
    final output = Platform.environment['P2PIRATE_DESIGN_CAPTURE'];
    if (output != null) {
      await tester.runAsync(() async {
        final boundary =
            capture.currentContext!.findRenderObject() as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final data = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(output).writeAsBytes(data!.buffer.asUint8List());
      });
    }
  });
}
