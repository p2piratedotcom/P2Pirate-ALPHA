import 'package:flutter/material.dart';
import 'package:web_dex/app_config/app_config.dart';

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

    final mark = Image.asset(
      '$assetsPath/logo/p2pirate_mark.png',
      width: height,
      height: height,
      filterQuality: FilterQuality.high,
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
              children: [mark, const SizedBox(height: 8), name],
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
