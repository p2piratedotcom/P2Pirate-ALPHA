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
                          'kdf_base': 'ARRR',
                          'kdf_rel': 'USDT-BEP20',
                          'kdf_volume': '15',
                          'kdf_price': '0.31',
                          'cex': 'MEXC',
                          'configured_premium': '0.025',
                          'status': 'OPEN',
                        },
                        {
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
                        {'ticker': 'ARRR', 'available': '61.4'},
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
