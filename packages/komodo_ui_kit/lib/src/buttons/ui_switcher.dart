import 'package:flutter/material.dart';

/// Native switch owns focus, toggle semantics, animation and its disposal.
class UiSwitcher extends StatelessWidget {
  const UiSwitcher({
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    super.key,
  });
  final bool value;
  final void Function(bool) onChanged;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) => Semantics(
    label: semanticLabel,
    child: Switch.adaptive(value: value, onChanged: onChanged),
  );
}
