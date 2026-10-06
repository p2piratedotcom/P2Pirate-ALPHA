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
        ? (Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFFFFD166)
              : const Color(0xFF805600))
        : Theme.of(context).colorScheme.primary;
    final label = !running
        ? 'Engine stopped'
        : age == null
        ? 'Waiting for confirmed data'
        : stale
        ? 'Data may be out of date'
        : 'Confirmed maker data';
    return Container(
      constraints: const BoxConstraints(minHeight: 92),
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color),
        color: stale ? color.withValues(alpha: 0.08) : null,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$label${age == null ? '' : ' · ${age}s ago'}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Tooltip(
                  message: error ?? '',
                  child: Text(
                    error ??
                        (stale
                            ? 'Showing last confirmed orders. Refresh before starting or modifying.'
                            : 'Amounts and prices reflect the latest confirmed maker snapshot.'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
