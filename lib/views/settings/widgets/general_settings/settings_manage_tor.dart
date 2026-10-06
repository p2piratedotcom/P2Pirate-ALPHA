import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:komodo_ui_kit/komodo_ui_kit.dart';
import 'package:web_dex/bloc/settings/settings_bloc.dart';
import 'package:web_dex/bloc/settings/settings_event.dart';
import 'package:web_dex/bloc/settings/settings_state.dart';
import 'package:web_dex/views/settings/widgets/common/settings_section.dart';

class SettingsManageTor extends StatelessWidget {
  const SettingsManageTor({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.linux) {
      return const SizedBox.shrink();
    }

    return SettingsSection(
      title: 'Tor network',
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) => Row(
          children: [
            UiSwitcher(
              semanticLabel: 'Route wallet and KDF traffic through Tor',
              key: const Key('tor-enabled-switcher'),
              value: state.torEnabled,
              onChanged: (enabled) => context.read<SettingsBloc>().add(
                TorEnabledChanged(torEnabled: enabled),
              ),
            ),
            const SizedBox(width: 15),
            const Flexible(
              child: Text(
                'Route wallet and KDF traffic through Tor (restart required)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
