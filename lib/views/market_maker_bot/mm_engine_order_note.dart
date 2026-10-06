import 'package:flutter/material.dart';
import 'package:web_dex/shared/utils/mm_engine_english.dart';

/// Readable display text; full diagnostic precision remains selectable.
class MmEngineOrderNote extends StatefulWidget {
  const MmEngineOrderNote({super.key, required this.text});
  final String text;
  @override
  State<MmEngineOrderNote> createState() => _MmEngineOrderNoteState();
}

class _MmEngineOrderNoteState extends State<MmEngineOrderNote> {
  bool _expanded = false;
  String? _originalText;
  String _englishText = '';
  @override
  Widget build(BuildContext context) {
    if (_originalText != widget.text) {
      _originalText = widget.text;
      _englishText = mmEngineEnglish(widget.text);
    }
    final summary = _englishText.replaceAllMapped(RegExp(r'\d+\.\d{9,}'), (m) {
      final parts = m[0]!.split('.');
      return '${parts[0]}.${parts[1].substring(0, 8)}…';
    });
    final long =
        _englishText.length > 180 ||
        _englishText.contains('\n') ||
        summary != _englishText;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SelectableText(
          _expanded ? _englishText : summary,
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
