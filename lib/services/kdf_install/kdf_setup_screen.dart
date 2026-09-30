import 'package:flutter/material.dart';
import 'package:web_dex/services/kdf_install/kdf_install_service.dart';

/// Shown only when no external KDF is present on Linux desktop.
class KdfSetupScreen extends StatefulWidget {
  const KdfSetupScreen({super.key, required this.onReady});

  final VoidCallback onReady;

  @override
  State<KdfSetupScreen> createState() => _KdfSetupScreenState();
}

class _KdfSetupScreenState extends State<KdfSetupScreen> {
  bool _working = false;
  String? _error;

  Future<void> _install() async {
    setState(() {
      _working = true;
      _error = null;
    });
    try {
      await KdfInstallService().install();
      if (mounted) widget.onReady();
    } catch (error) {
      if (mounted) {
        setState(
          () => _error = error is StateError || error is UnsupportedError
              ? error.toString()
              : 'Download or verification failed. Check the connection and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _checkAgain() async {
    if (await KdfInstallService.hasExecutable()) {
      if (mounted) widget.onReady();
    } else if (mounted) {
      setState(
        () =>
            _error = 'No executable KDF was found in the supported locations.',
      );
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'P2Pirate KDF setup',
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
                const Text('Install KDF 2.7', style: TextStyle(fontSize: 28)),
                const SizedBox(height: 16),
                const Text(
                  'P2Pirate needs a separate KDF engine. Download the reviewed '
                  'Linux x86-64 v2.7.0-beta executable from the original '
                  'ShorelineCrypto release. The archive and executable are '
                  'verified with SHA-256 before use.',
                ),
                const SizedBox(height: 10),
                const Text(
                  'The P2Pirate SDK fork does not yet publish a compatible KDF '
                  'release. This download comes directly from the original publisher.',
                ),
                const SizedBox(height: 24),
                if (_working) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    FilledButton(
                      onPressed: _working ? null : _install,
                      child: const Text('Download and verify KDF'),
                    ),
                    OutlinedButton(
                      onPressed: _working ? null : _checkAgain,
                      child: const Text('I installed KDF separately'),
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
