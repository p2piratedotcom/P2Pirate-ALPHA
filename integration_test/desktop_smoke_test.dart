import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/model/settings_menu_value.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_dashboard.dart';
import 'package:web_dex/services/tor/pirate_tor_status.dart';
import 'package:web_dex/shared/widgets/pirate_wallet_logo.dart';
import 'package:web_dex/views/settings/widgets/settings_menu/settings_menu_item.dart';

/// Exercises the real Linux Flutter runner without starting the wallet or KDF.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('desktop renders P2Pirate identity and Tor status', (
    tester,
  ) async {
    addTearDown(() => pirateTorStatus.value = PirateTorStatus.disabled);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PirateWalletLogo(height: 72, stacked: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('P2Pirate'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
    expect(find.byType(Image), findsNothing);
    expect(find.text('Tor off'), findsOneWidget);
    pirateTorStatus.value = PirateTorStatus.ready;
    await tester.pump();
    expect(find.text('Tor active'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop Settings navigation selects App Info', (tester) async {
    SettingsMenuValue selected = SettingsMenuValue.general;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final menu in [
                  SettingsMenuValue.general,
                  SettingsMenuValue.security,
                  SettingsMenuValue.appInfo,
                ])
                  SizedBox(
                    width: 220,
                    child: SettingsMenuItem(
                      key: Key('settings-menu-item-${menu.name}'),
                      menu: menu,
                      isSelected: selected == menu,
                      onTap: (value) => setState(() => selected = value),
                      text: menu.name,
                      isMobile: false,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final appInfo = find.byKey(const Key('settings-menu-item-appInfo'));
    expect(appInfo, findsOneWidget);
    await tester.tap(appInfo);
    await tester.pumpAndSettle();
    expect(selected, SettingsMenuValue.appInfo);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'desktop separates live permission from selected order activation',
    (tester) async {
      var live = false;
      var selected = <String>{};
      var activations = 0;
      await tester.pumpWidget(
        MaterialApp(
          title: appTitle,
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, update) => MmEngineDashboard(
                  orders: const [],
                  strategies: const [
                    {
                      'id': 'fixture-order',
                      'creation_number': 1,
                      'state': 'PAUSED',
                      'enabled': 0,
                      'spec': {
                        'base': {'ticker': 'ARRR'},
                        'quote': {'ticker': 'USDT-BEP20'},
                        'cex': 'MEXC',
                        'price_mode': 'auto',
                        'quantity_mode': 'auto',
                      },
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
      await tester.pumpAndSettle();
      expect(appTitle, 'P2Pirate | Desktop');
      final check = find.byKey(const Key('select-maker-order-fixture-order'));
      await tester.ensureVisible(check);
      await tester.tap(check);
      await tester.pumpAndSettle();
      expect(selected, {'fixture-order'});
      final activate = find.widgetWithText(
        ElevatedButton,
        'Start selected orders (1)',
      );
      expect(tester.widget<ElevatedButton>(activate).onPressed, isNull);
      await tester.ensureVisible(find.text('Start live trading'));
      await tester.tap(find.text('Start live trading'));
      await tester.pumpAndSettle();
      expect(activations, 0);
      expect(find.text('PAUSED'), findsOneWidget);
      expect(find.text('Stop live trading'), findsOneWidget);
      await tester.ensureVisible(activate);
      await tester.tap(activate);
      await tester.pumpAndSettle();
      expect(activations, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
