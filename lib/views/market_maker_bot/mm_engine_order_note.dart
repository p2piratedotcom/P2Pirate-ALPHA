import 'package:flutter/material.dart';

/// Readable display text; full diagnostic precision remains selectable.
class MmEngineOrderNote extends StatefulWidget {
  const MmEngineOrderNote({super.key, required this.text});
  final String text;
  @override
  State<MmEngineOrderNote> createState() => _MmEngineOrderNoteState();
}

class _MmEngineOrderNoteState extends State<MmEngineOrderNote> {
  bool _expanded = false;
  @override
  Widget build(BuildContext context) {
    final summary = widget.text.replaceAllMapped(RegExp(r'\d+\.\d{9,}'), (m) {
      final parts = m[0]!.split('.');
      return '${parts[0]}.${parts[1].substring(0, 8)}…';
    });
    final long =
        widget.text.length > 180 ||
        widget.text.contains('\n') ||
        summary != widget.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          _expanded ? widget.text : summary,
          maxLines: !_expanded && long ? 3 : null,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        if (long)
          TextButton(
            onPressed: () => setState(() => _expanded = !_expanded),
            child: Text(
              _expanded ? 'Hide full diagnostic' : 'Show full diagnostic',
            ),
          ),
      ],
    );
  }
}
