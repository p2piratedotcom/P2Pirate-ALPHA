import 'package:flutter/material.dart';
import 'package:web_dex/services/coin_assets/coin_assets_service.dart';

class SettingsCoinAssets extends StatefulWidget {
  const SettingsCoinAssets({super.key});

  @override
  State<SettingsCoinAssets> createState() => _SettingsCoinAssetsState();
}

class _SettingsCoinAssetsState extends State<SettingsCoinAssets> {
  bool _busy = false;
  bool _updateAvailable = false;
  String? _message;

  Future<void> _check() async {
    setState(() {
      _busy = true;
      _message = 'Checking P2Pirate Assets…';
    });
    try {
      final available = await CoinAssetsService.instance.checkUpdates();
      if (mounted) {
        setState(() {
          _updateAvailable = available;
          _message = available
              ? 'New coin assets are available.'
              : 'Coin assets are up to date.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = 'Could not check updates: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _download() async {
    setState(() {
      _busy = true;
      _message = 'Downloading P2Pirate Assets…';
    });
    try {
      await CoinAssetsService.instance.downloadLatest(
        onStage: (stage) {
          if (mounted) setState(() => _message = stage);
        },
      );
      if (mounted) {
        setState(() {
          _updateAvailable = false;
          _message =
              'Assets downloaded and verified. Restart P2Pirate to use the new coin list and icons.';
        });
      }
    } catch (error) {
      if (mounted) setState(() => _message = 'Download failed: $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Coin assets', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      const Text(
        'Coin configuration and icons from the P2Pirate Assets repository.',
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          OutlinedButton(
            onPressed: _busy ? null : _check,
            child: const Text('Check updates'),
          ),
          if (_updateAvailable)
            FilledButton(
              onPressed: _busy ? null : _download,
              child: const Text('Download update'),
            ),
        ],
      ),
      if (_busy)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: LinearProgressIndicator(),
        ),
      if (_message != null)
        Padding(padding: const EdgeInsets.only(top: 8), child: Text(_message!)),
    ],
  );
}
