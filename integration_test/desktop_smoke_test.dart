import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_dex/model/settings_menu_value.dart';
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
    expect(find.byType(Image), findsOneWidget);
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
}
