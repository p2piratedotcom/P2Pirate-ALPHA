import 'dart:io';
import 'dart:ui' as ui;
import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_order_details.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_rebalance_preview.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_rebalance_panel.dart';

void main() {
  testWidgets('native presentation fixtures fit wide and narrow containers', (
    tester,
  ) async {
    final font = FontLoader('Manrope')
      ..addFont(rootBundle.load('assets/fonts/Manrope-Regular.ttf'));
    await font.load();
    final roboto = FontLoader('Roboto')
      ..addFont(
        rootBundle.load(
          'assets/fallback_fonts/roboto/v20/KFOmCnqEu92Fr1Me5WZLCzYlKw.ttf',
        ),
      );
    await roboto.load();
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final boundary = GlobalKey();
    final ideal = <String, dynamic>{
      'makers': [
        {
          'number': 2,
          'quantity': '60',
          'sell': 'USDT-BEP20',
          'buy': 'DASH',
          'price': '0.015',
          'hedge_legs': [
            {'side': 'SELL', 'quantity': '0.9', 'asset': 'DASH'},
          ],
        },
      ],
      'indicative_targets': {'DASH': '1.08'},
    };
    final plan = <String, dynamic>{
      'current_coverage_percent': '0.00',
      'coverage_percent': '75.00',
      'funding': {
        'DASH': {
          'spot_free': '0',
          'available': '0',
          'required': '0.81',
          'full_required': '1.08',
          'ideal_missing': '1.08',
        },
      },
      'projected_orders': [
        {
          'side': 'BUY',
          'quantity': '0.81',
          'asset': 'DASH',
          'price': '58',
          'notional': '46.98',
        },
      ],
    };
    for (final width in [1050.0, 620.0]) {
      tester.view.physicalSize = Size(width, 1400);
      tester.view.devicePixelRatio = 1;
      for (final name in ['details', 'rebalance']) {
        final Widget content = name == 'details'
            ? const MmEngineOrderDetails(
                row: {
                  'kdf_base': 'ARRR',
                  'kdf_rel': 'USDT-BEP20',
                  'kdf_volume': '40',
                  'kdf_price': '0.25',
                  'status': 'RUNNING',
                  'order_uuid': 'fixture-order',
                  'detail': 'Price and quantity are within thresholds.',
                },
                spec: {
                  'cex': 'MEXC',
                  'quantity_mode': 'auto',
                  'price_mode': 'auto',
                  'premium': '0.02',
                  'auto_fraction': '1',
                },
                strategy: {
                  'remaining_sold': '40',
                  'daily_remaining_sold': null,
                },
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MmEngineRebalancePanel(
                    venue: 'MEXC',
                    busy: false,
                    live: true,
                    configured: false,
                    onBusy: (_) {},
                    onChanged: () {},
                    strategies: const [
                      {
                        'id': 'fixture',
                        'creation_number': 2,
                        'state': 'RUNNING',
                        'spec': {
                          'cex': 'MEXC',
                          'base': {'ticker': 'DASH'},
                          'quote': {'ticker': 'USDT-BEP20'},
                        },
                      },
                    ],
                    balances: const [
                      {'ticker': 'LTC', 'available': '1.23456789'},
                      {'ticker': 'USDT', 'available': '27.123456789012345678'},
                    ],
                    balanceLoading: false,
                  ),
                  const SizedBox(height: 24),
                  MmEngineRebalancePreview(ideal: ideal, plan: plan),
                ],
              );
        await tester.pumpWidget(
          MaterialApp(
            theme: theme.currentGlobal,
            home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                body: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: content,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          final directory = Directory('/tmp/p2pirate-audit-visual')
            ..createSync(recursive: true);
          File(
            '${directory.path}/$name-${width.toInt()}.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
    }
    await tester.pumpWidget(const SizedBox());
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}
