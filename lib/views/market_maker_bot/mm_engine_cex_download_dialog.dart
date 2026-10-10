import 'package:flutter/material.dart';
import 'package:web_dex/services/mm_engine/cex_plugin_service.dart';

/// Selection is download consent only; it does not configure keys or trading.
class MmEngineCexDownloadDialog extends StatefulWidget {
  const MmEngineCexDownloadDialog({
    super.key,
    required this.catalog,
    this.installed,
  });
  final CexPluginCatalog catalog;
  final CexPluginSnapshot? installed;

  @override
  State<MmEngineCexDownloadDialog> createState() =>
      _MmEngineCexDownloadDialogState();
}

class _MmEngineCexDownloadDialogState extends State<MmEngineCexDownloadDialog> {
  final _selected = <String>{};

  String _status(Map<String, dynamic> entry) {
    final installed = widget.installed?.entries.where(
      (item) => item['venue'] == entry['venue'],
    );
    if (installed == null || installed.isEmpty) {
      return 'Available v${entry['version']}';
    }
    final old = installed.single;
    final unchanged = entry.keys.every((key) => entry[key] == old[key]);
    return unchanged
        ? 'Installed v${old['version']} · Up to date'
        : 'Installed v${old['version']} · Update available (v${entry['version']})';
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    scrollable: true,
    title: const Text('Choose CEX plugins'),
    content: SizedBox(
      width: 480,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Select the exchanges to download or update. Plugins already installed stay available when left unselected.',
          ),
          const SizedBox(height: 16),
          for (final entry in widget.catalog.entries)
            CheckboxListTile(
              contentPadding: EdgeInsetsDirectional.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(
                widget.installed?.labels[entry['venue']] ??
                    entry['venue'] as String,
              ),
              subtitle: Text(_status(entry)),
              value: _selected.contains(entry['venue']),
              onChanged: (checked) => setState(() {
                final venue = entry['venue'] as String;
                checked == true
                    ? _selected.add(venue)
                    : _selected.remove(venue);
              }),
            ),
          const SizedBox(height: 16),
          const Text(
            'API keys stay local. Installing an update pauses running makers and reconnects the engine in preview. Existing trading must be reconciled first; unresolved swaps can prevent installation.',
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _selected.isEmpty
            ? null
            : () => Navigator.pop(context, Set<String>.of(_selected)),
        child: Text('Download selected (${_selected.length})'),
      ),
    ],
  );
}
