import 'package:flutter/material.dart';
import 'package:web_dex/app_config/app_config.dart';

/// P2Pirate identity in the menu and the theme selector.
class PirateWalletLogo extends StatelessWidget {
  const PirateWalletLogo({super.key, this.height = 32, this.themeMode});

  final double height;
  final ThemeMode? themeMode;

  @override
  Widget build(BuildContext context) {
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == null && Theme.of(context).brightness == Brightness.dark);

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            '$assetsPath/logo/pirate_icon.png',
            width: height,
            height: height,
            filterQuality: FilterQuality.high,
          ),
          SizedBox(width: height * 0.3),
          Text(
            appShortTitle,
            style: TextStyle(
              fontSize: height * 0.65,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
