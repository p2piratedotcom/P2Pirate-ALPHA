import 'package:flutter/material.dart';

/// Distinguishes a visible snapshot from fresh, confirmed operational data.
class MmEngineStatusStrip extends StatelessWidget {
  const MmEngineStatusStrip({
    super.key,
    required this.updated,
    required this.error,
    required this.running,
  });
  final DateTime? updated;
  final String? error;
  final bool running;
  @override
  Widget build(BuildContext context) {
    final age = updated == null
        ? null
        : DateTime.now().difference(updated!).inSeconds.clamp(0, 86400);
    final stale = age == null || age > 30 || error != null || !running;
    final color = !running
        ? Theme.of(context).colorScheme.error
        : stale
        ? Theme.of(context).colorScheme.tertiary
        : Theme.of(context).colorScheme.primary;
    final label = !running
        ? 'Engine stopped'
        : age == null
        ? 'Waiting for confirmed data'
        : stale
        ? 'Data may be out of date'
        : 'Confirmed maker data';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            stale ? Icons.update : Icons.check_circle_outline,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SelectableText(
              '$label${age == null ? '' : ' · ${age}s ago'}${error == null ? '' : '\n$error'}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
