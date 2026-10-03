import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_dashboard.dart';

void main() {
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
    await tester.tap(find.text('Start all live trading'));
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
    await tester.tap(find.text('GATE').last);
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
