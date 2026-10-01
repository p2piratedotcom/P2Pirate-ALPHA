// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;

/// Runs native Linux tests with a disposable home, XDG profile, and D-Bus.
/// The optional KDF test launches only a reviewed binary on an isolated port.
class IntegrationTestRunner {
  const IntegrationTestRunner({this.verbose = false, this.runKdf = false});

  final bool verbose;
  final bool runKdf;

  Future<void> run() async {
    final originalHome = Platform.environment['HOME'];
    if (originalHome == null || originalHome.isEmpty) {
      throw StateError('A home directory is required to locate the pub cache');
    }
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
          'HOME': profile.path,
          'PUB_CACHE':
              Platform.environment['PUB_CACHE'] ??
              p.join(originalHome, '.pub-cache'),
        })
        ..remove('GNOME_KEYRING_CONTROL')
        ..remove('SSH_AUTH_SOCK');
      final flutter = Platform.environment['P2PIRATE_FLUTTER_BIN'] ?? 'flutter';
      int? kdfPort;
      if (runKdf) {
        final binary = environment['P2PIRATE_KDF_PATH'];
        if (binary == null || binary.isEmpty || !p.isAbsolute(binary)) {
          throw ArgumentError(
            '--kdf requires an absolute P2PIRATE_KDF_PATH to the reviewed KDF 2.7 binary',
          );
        }
        final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
        kdfPort = socket.port;
        await socket.close();
      }
      final command = [
        '-a',
        '-s',
        '-screen 0 1440x900x24',
        'dbus-run-session',
        '--',
        if (runKdf) ...[
          'bash',
          '-e',
          '-o',
          'pipefail',
          '-c',
          'printf %s p2pirate-test-keyring | '
              'gnome-keyring-daemon --unlock --components=secrets >/dev/null; '
              'exec "\$@"',
          'p2pirate-test-shell',
        ],
        flutter,
        'test',
        '--no-pub',
        '-d',
        'linux',
        if (verbose) '--verbose',
        if (kdfPort != null) '--dart-define=P2PIRATE_LOCAL_RPC_PORT=$kdfPort',
        runKdf
            ? 'integration_test/kdf_process_isolation_test.dart'
            : 'integration_test/desktop_smoke_test.dart',
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
