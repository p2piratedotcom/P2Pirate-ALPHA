import 'package:app_theme/app_theme.dart';
import 'package:flutter/material.dart';

class DexFormTitle extends StatelessWidget {
  const DexFormTitle(this.title, {this.readable = false});

  final String title;
  final bool readable;

  @override
  Widget build(BuildContext context) {
    final titleStyle = TextStyle(
      fontSize: readable ? 14 : 11,
      fontWeight: FontWeight.w500,
      color: dexPageColors.activeText,
      letterSpacing: readable ? 0 : 4,
    );

    return Text(title, style: titleStyle);
  }
}
