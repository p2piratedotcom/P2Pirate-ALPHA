import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/services/tor/pirate_tor_status.dart';

/// P2Pirate identity in the menu and the theme selector.
class PirateWalletLogo extends StatelessWidget {
  const PirateWalletLogo({
    super.key,
    this.height = 32,
    this.themeMode,
    this.stacked = false,
  });

  final double height;
  final ThemeMode? themeMode;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == null && Theme.of(context).brightness == Brightness.dark);

    final mark = SvgPicture.asset(
      '$assetsPath/logo/p2pirate_mark.svg',
      width: height,
      height: height,
      fit: BoxFit.contain,
    );
    final name = Text(
      appShortTitle,
      style: TextStyle(
        fontSize: stacked ? 21 : height * 0.65,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : Colors.black,
      ),
    );

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: stacked
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                mark,
                const SizedBox(height: 8),
                name,
                ValueListenableBuilder<PirateTorStatus>(
                  valueListenable: pirateTorStatus,
                  builder: (context, status, _) {
                    final ready = status == PirateTorStatus.ready;
                    final label = switch (status) {
                      PirateTorStatus.disabled => 'Tor off',
                      PirateTorStatus.connecting => 'Tor connecting…',
                      PirateTorStatus.ready => 'Tor active',
                      PirateTorStatus.unavailable => 'Tor unavailable',
                    };
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          ready ? Icons.shield_outlined : Icons.info_outline,
                          size: 13,
                          color: ready ? const Color(0xFF55CBA6) : null,
                        ),
                        const SizedBox(width: 4),
                        Text(label, style: const TextStyle(fontSize: 11)),
                      ],
                    );
                  },
                ),
              ],
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                mark,
                SizedBox(width: height * 0.3),
                name,
              ],
            ),
    );
  }
}
