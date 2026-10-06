import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/market_maker_bot/market_maker_bot/market_maker_bot_bloc.dart';
import 'package:web_dex/bloc/auth_bloc/auth_bloc.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/services/mm_engine/mm_engine_service.dart';
import 'package:web_dex/views/settings/widgets/common/settings_section.dart';
import 'package:web_dex/shared/utils/mm_engine_english.dart';

/// The switch controls visibility only. P2Pirate Trading Engine is a separate download and
/// its live trading permissions are never enabled by a settings toggle.
class SettingsManageTradingBot extends StatefulWidget {
  const SettingsManageTradingBot({super.key});

  @override
  State<SettingsManageTradingBot> createState() =>
      _SettingsManageTradingBotState();
}

class _SettingsManageTradingBotState extends State<SettingsManageTradingBot> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) => SettingsSection(
    title: 'Trading engine',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) => Row(
            children: [
              UiSwitcher(
                semanticLabel: 'Show Trading Engine in the wallet',
                key: const Key('enable-trading-bot-switcher'),
                value: state.mmBotSettings.isMMBotEnabled,
                onChanged: (value) {
                  if (!_busy) _change(value);
                },
              ),
              const SizedBox(width: 15),
              const Flexible(
                child: Text('Show P2Pirate Trading Engine in the wallet'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'The engine is installed separately when you open its page. '
          'Turning this on does not place any orders.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    ),
  );

  Future<void> _change(bool enabled) async {
    setState(() => _busy = true);
    final user = context.read<AuthBloc>().state.currentUser;
    try {
      if (!enabled) {
        await MmEngineService.instance.stop();
        if (user != null) {
          await MmEngineService.instance.clearLivePreference(
            user.walletId.compoundId,
          );
        }
      }
      if (!mounted) return;
      // A previously started legacy KDF bot must not coexist with the
      // standalone engine, even for older persisted wallet configurations.
      context.read<MarketMakerBotBloc>().add(
        const MarketMakerBotStopRequested(),
      );
      final stored = await SettingsRepository().loadSettings();
      final settings = stored.marketMakerBotSettings.copyWith(
        isMMBotEnabled: enabled,
      );
      if (!mounted) return;
      context.read<SettingsBloc>().add(MarketMakerBotSettingsChanged(settings));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.maybeOf(
        context,
      )?.showSnackBar(SnackBar(content: Text(mmEngineEnglish(error))));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
