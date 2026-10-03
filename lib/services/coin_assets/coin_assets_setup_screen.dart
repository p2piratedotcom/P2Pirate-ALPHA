import 'package:flutter/material.dart';
import 'package:web_dex/services/coin_assets/coin_assets_service.dart';

class CoinAssetsSetupScreen extends StatefulWidget {
  const CoinAssetsSetupScreen({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  State<CoinAssetsSetupScreen> createState() => _CoinAssetsSetupScreenState();
}

class _CoinAssetsSetupScreenState extends State<CoinAssetsSetupScreen> {
  bool _working = false;
  String? _stage;
  String? _error;

  Future<void> _download() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await CoinAssetsService.instance.downloadLatest(
        onStage: (stage) {
          if (mounted) setState(() => _stage = stage);
        },
      );
      if (mounted) widget.onReady();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Download or verification failed: $error');
      }
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _stage = null;
        });
      }
    }
  }

  Future<void> _skip() async {
    try {
      await CoinAssetsService.instance.skipFirstDownload();
      if (mounted) widget.onReady();
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'Could not save your choice: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'P2Pirate coin assets',
    theme: ThemeData.dark(),
    home: Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Download coin assets',
                  style: TextStyle(fontSize: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Download the coin and token configuration and coin icons from the P2Pirate Assets repository. The files are verified before use. You can check for updates later in Settings.',
                ),
                const SizedBox(height: 16),
                if (_working) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 8),
                  Text(_stage ?? 'Preparing download…'),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton(
                      onPressed: _working ? null : _download,
                      child: const Text('Download assets'),
                    ),
                    OutlinedButton(
                      onPressed: _working ? null : _skip,
                      child: const Text('Use bundled catalog for now'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
