import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';

/// Display precision never feeds back into approved amounts or LIMIT prices.
String mmEngineDisplayAmount(Object? raw) {
  if (raw == null) return 'Unavailable';
  final value = Decimal.tryParse('$raw');
  if (value == null) return '$raw';
  final text = value.toString();
  final parts = text.split('.');
  if (parts.length == 1) return text;
  final integer = parts.first.replaceFirst('-', '');
  final fractional = parts.last.replaceFirst(RegExp(r'0+$'), '');
  if (fractional.isEmpty) return parts.first;
  final leading = RegExp(r'^0*').firstMatch(fractional)!.group(0)!.length;
  final digits = integer == '0'
      ? leading + 8
      : (8 - integer.length).clamp(0, 8);
  if (fractional.length <= digits) return '${parts.first}.$fractional';
  return '≈ ${parts.first}${digits == 0 ? '' : '.${fractional.substring(0, digits)}'}';
}

class MmEngineAmount extends StatelessWidget {
  const MmEngineAmount(this.value, {this.unit, super.key});
  final Object? value;
  final String? unit;
  @override
  Widget build(BuildContext context) => Tooltip(
    message: '${value ?? 'Unavailable'}${unit == null ? '' : ' $unit'}',
    child: SelectableText(
      '${mmEngineDisplayAmount(value)}${unit == null ? '' : ' $unit'}',
    ),
  );
}
