import 'package:flutter/material.dart';

import '../../app_theme.dart';

const ColorSchemeExtension _colorSchemeExtension = ColorSchemeExtension(
  primary: Color(0xFFBB9645),
  p50: Color(0xFF8C6F31),
  p40: Color(0xFF6D5626),
  p10: Color(0xFF1D180E),
  secondary: Color(0xFFFFFFFF),
  s70: Color.fromRGBO(121, 123, 137, 1),
  s50: Color.fromRGBO(87, 88, 98, 1),
  s40: Color.fromRGBO(69, 70, 78, 1),
  s30: Color.fromRGBO(52, 53, 59, 1),
  s20: Color.fromRGBO(35, 35, 39, 1),
  s10: Color.fromRGBO(17, 18, 20, 1),
  e10: Color.fromRGBO(21, 6, 10, 1),
  e20: Color.fromRGBO(42, 11, 21, 1),
  e50: Color.fromRGBO(105, 29, 52, 1),
  error: Color(0xFFB33430),
  g10: Color.fromRGBO(9, 19, 17, 1),
  g20: Color.fromRGBO(18, 38, 34, 1),
  green: Color(0xFF19A974),
  surf: Color.fromRGBO(255, 255, 255, 1),
  surfCont: Color(0xFF0B0B0B),
  surfContHigh: Color(0xFF171717),
  surfContHighest: Color(0xFF222222),
  surfContLow: Color(0xFF050505),
  surfContLowest: Color(0xFF000000),
  orange: Color(0xFFBB9645),
  yellow: Color(0xFFD0B572),
  purple: Color(0xFF8E8370),
);

final ColorScheme _colorScheme = theme.global.dark.colorScheme.copyWith(
  primary: _colorSchemeExtension.primary,
  secondary: _colorSchemeExtension.secondary,
);
final TextTheme _textTheme = theme.global.dark.textTheme.copyWith();
final TextThemeExtension _textThemeExtension = TextThemeExtension(
  textColor: _colorSchemeExtension.secondary,
);

final ThemeData newThemeDataDark = theme.global.dark.copyWith(
  colorScheme: _colorScheme,
  textTheme: _textTheme,
  inputDecorationTheme: theme.global.dark.inputDecorationTheme.copyWith(
    hintStyle: _textThemeExtension.bodySBold.copyWith(
      color: _colorSchemeExtension.s50,
    ),
    labelStyle: _textThemeExtension.bodyXSBold.copyWith(
      color: _colorSchemeExtension.primary,
    ),
    errorStyle: _textThemeExtension.bodyS.copyWith(
      color: _colorSchemeExtension.error,
    ),
    enabledBorder: _outlineBorderLight(_colorSchemeExtension.secondary),
    disabledBorder: _outlineBorderLight(_colorSchemeExtension.secondary),
    focusedBorder: _outlineBorderLight(_colorSchemeExtension.primary),
    errorBorder: _outlineBorderLight(_colorSchemeExtension.error),
    fillColor: Colors.transparent,
    hoverColor: Colors.transparent,
  ),
  extensions: [_colorSchemeExtension, _textThemeExtension],
);

OutlineInputBorder _outlineBorderLight(Color accentColor) => OutlineInputBorder(
  borderSide: BorderSide(color: accentColor, width: 2),
  borderRadius: BorderRadius.circular(12),
);
