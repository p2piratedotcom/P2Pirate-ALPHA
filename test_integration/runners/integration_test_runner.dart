// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;

/// Runs native Linux UI tests with disposable XDG and Documents directories.
/// The tests in integration_test/ never launch KDF or unlock a wallet.
class IntegrationTestRunner {
  const IntegrationTestRunner({this.verbose = false});

  final bool verbose;

  Future<void> run() async {
    final profile = await Directory.systemTemp.createTemp('p2pirate-test-');
    try {
      final data = Directory(p.join(profile.path, 'data'));
      final config = Directory(p.join(profile.path, 'config'));
      final cache = Directory(p.join(profile.path, 'cache'));
      final documents = Directory(p.join(profile.path, 'documents'));
      for (final directory in [data, config, cache, documents]) {
        await directory.create(recursive: true);
      }
      await File(
        p.join(config.path, 'user-dirs.dirs'),
      ).writeAsString('XDG_DOCUMENTS_DIR="${documents.path}"\n');

      final environment = Map<String, String>.from(Platform.environment)
        ..addAll({
          'XDG_DATA_HOME': data.path,
          'XDG_CONFIG_HOME': config.path,
          'XDG_CACHE_HOME': cache.path,
        })
        ..remove('GNOME_KEYRING_CONTROL')
        ..remove('SSH_AUTH_SOCK');
      final flutter = Platform.environment['P2PIRATE_FLUTTER_BIN'] ?? 'flutter';
      final command = [
        '-a',
        '-s',
        '-screen 0 1440x900x24',
        'dbus-run-session',
        '--',
        flutter,
        'test',
        '--no-pub',
        '-d',
        'linux',
        if (verbose) '--verbose',
        'integration_test',
      ];
      final result = await Process.run(
        'xvfb-run',
        command,
        environment: environment,
      );
      stdout.write(result.stdout);
      stderr.write(result.stderr);
      if (result.exitCode != 0) {
        throw ProcessException(
          'xvfb-run',
          command,
          'Desktop test failed',
          result.exitCode,
        );
      }
    } finally {
      await profile.delete(recursive: true);
    }
  }
}
