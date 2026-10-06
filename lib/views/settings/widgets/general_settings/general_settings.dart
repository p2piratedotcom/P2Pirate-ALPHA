import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_dex/bloc/trading_status/trading_status_bloc.dart';
import 'package:web_dex/common/screen.dart';
import 'package:web_dex/shared/widgets/hidden_with_wallet.dart';
import 'package:web_dex/shared/widgets/hidden_without_wallet.dart';
import 'package:web_dex/views/settings/widgets/general_settings/import_swaps.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_coin_assets.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_hide_balances.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_manage_diagnostic_logging.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_manage_test_coins.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_manage_tor.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_market_prices.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_manage_trading_bot.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_manage_weak_passwords.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_reset_activated_coins.dart';
import 'package:web_dex/views/settings/widgets/general_settings/settings_theme_switcher.dart';
import 'package:web_dex/views/settings/widgets/general_settings/show_swap_data.dart';

class GeneralSettings extends StatelessWidget {
  const GeneralSettings({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) const SizedBox(height: 20),
        Text(
          'Appearance & privacy',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        const SettingsThemeSwitcher(),
        const SizedBox(height: 20),
        const SettingsHideBalances(),
        const SizedBox(height: 32),
        Text('Network', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        const SettingsManageTor(),
        const SizedBox(height: 32),
        Text(
          'Market data & assets',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        const SettingsMarketPrices(),
        const SizedBox(height: 24),
        const SettingsCoinAssets(),
        const SizedBox(height: 32),
        if (context.watch<TradingStatusBloc>().state.isEnabled)
          const HiddenWithoutWallet(
            isHiddenForHw: true,
            child: SettingsManageTradingBot(),
          ),
        const SizedBox(height: 24),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Advanced settings'),
          subtitle: const Text(
            'Test assets, password policy, diagnostics and maintenance',
          ),
          children: const [
            SettingsManageTestCoins(),
            SizedBox(height: 20),
            HiddenWithoutWallet(
              isHiddenForHw: true,
              isHiddenElse: false,
              child: SettingsManageWeakPasswords(),
            ),
            SizedBox(height: 20),
            SettingsManageDiagnosticLogging(),
            SizedBox(height: 20),
            HiddenWithWallet(child: SettingsResetActivatedCoins()),
            SizedBox(height: 20),
            HiddenWithoutWallet(isHiddenForHw: true, child: ShowSwapData()),
            HiddenWithoutWallet(isHiddenForHw: true, child: ImportSwaps()),
          ],
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
