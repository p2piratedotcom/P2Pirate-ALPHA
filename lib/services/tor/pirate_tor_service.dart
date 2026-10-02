import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:komodo_defi_framework/komodo_defi_framework.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_dex/services/tor/pirate_tor_http_bridge.dart';
import 'package:web_dex/services/tor/pirate_tor_status.dart';

class PirateTorService {
  PirateTorService._();

  static final PirateTorService instance = PirateTorService._();

  Process? _process;
  int? _socksPort;
  PirateTorHttpBridge? _httpBridge;
  Future<void>? _startup;
  Future<void>? _shutdownFuture;
  bool _shuttingDown = false;

  int? get socksPort => _socksPort;
  int? get httpProxyPort => _httpBridge?.port;

  Future<void> start() async {
    if (_shuttingDown) throw StateError('Tor is shutting down');
    if (_socksPort != null && _httpBridge != null) return;
    final pending = _startup;
    if (pending != null) return pending;
    final startup = _startWithRetry();
    _startup = startup;
    try {
      await startup;
    } finally {
      _startup = null;
    }
  }

  Future<void> _startWithRetry() async {
    if (!Platform.isLinux) {
      throw UnsupportedError('Bundled Tor is currently supported on Linux');
    }

    final torBinary = _findArtifact('tor');
    final torsocksLibrary = _findArtifact('libtorsocks.so');
    if (torBinary == null || torsocksLibrary == null) {
      pirateTorStatus.value = PirateTorStatus.unavailable;
      throw StateError('Bundled Tor transport is missing from P2Pirate');
    }

    // A relay connection or directory fetch can fail temporarily. A fresh
    // Tor process gets one more chance, while every network path remains
    // blocked until bootstrap and the seed check have both succeeded.
    for (var attempt = 0; attempt < 2; attempt++) {
      if (_shuttingDown) throw StateError('Tor is shutting down');
      pirateTorStatus.value = PirateTorStatus.connecting;
      try {
        await _start(torBinary, torsocksLibrary);
        return;
      } catch (error) {
        await stop();
        if (attempt == 1 || error is! _TorStartupFailure) {
          pirateTorStatus.value = PirateTorStatus.unavailable;
          rethrow;
        }
      }
    }
  }

  Future<void> _start(File torBinary, File torsocksLibrary) async {
    final support = await getApplicationSupportDirectory();
    final torData = Directory(p.join(support.path, 'tor'));
    await torData.create(recursive: true);

    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();

    final configFile = File(p.join(torData.path, 'torsocks.conf'));
    await configFile.writeAsString(
      'TorAddress 127.0.0.1\n'
      'TorPort $port\n'
      'AllowOutboundLocalhost 0\n'
      'AllowInbound 0\n',
      flush: true,
    );

    final process = await Process.start(torBinary.path, [
      '--DataDirectory',
      torData.path,
      '--SocksPort',
      '127.0.0.1:$port',
      '--ClientOnly',
      '1',
      '--Log',
      'notice stdout',
    ]);
    _process = process;
    if (_shuttingDown) {
      await stop();
      throw StateError('Tor is shutting down');
    }
    final ready = Completer<void>();
    var progress = 0;
    Timer? stalled;
    void armStallTimer() {
      stalled?.cancel();
      stalled = Timer(const Duration(seconds: 75), () {
        if (!ready.isCompleted) {
          ready.completeError(
            _TorStartupFailure('Tor bootstrap stalled at $progress%'),
          );
        }
      });
    }

    armStallTimer();
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          final match = RegExp(r'Bootstrapped (\d+)%').firstMatch(line);
          if (match != null) {
            final next = int.parse(match.group(1)!);
            if (next > progress) {
              progress = next;
              armStallTimer();
            }
          }
          if (line.contains('Bootstrapped 100%') && !ready.isCompleted) {
            ready.complete();
          }
        });
    process.stderr.transform(utf8.decoder).listen((_) {});
    unawaited(
      process.exitCode.then((code) {
        if (!ready.isCompleted) {
          ready.completeError(
            _TorStartupFailure(
              'Tor exited before bootstrap at $progress% (exit $code)',
            ),
          );
        }
        if (identical(_process, process)) {
          _process = null;
          pirateTorStatus.value = PirateTorStatus.unavailable;
        }
      }),
    );

    try {
      await ready.future.timeout(
        const Duration(minutes: 3),
        onTimeout: () =>
            throw _TorStartupFailure('Tor bootstrap timed out at $progress%'),
      );
      KdfTorConfig.configure(
        port: port,
        libraryPath: torsocksLibrary.path,
        configPath: configFile.path,
      );
      // Confirm that a KDF seed resolves through Tor before SDK bootstrap.
      // This exposes an unusable Tor circuit as a startup error.
      try {
        await SeedNodeService.fetchSeedNodes().timeout(
          const Duration(seconds: 50),
        );
      } catch (_) {
        throw const _TorStartupFailure('Tor seed lookup failed');
      }
      _socksPort = port;
      _httpBridge = await PirateTorHttpBridge.start(port);
      if (!identical(_process, process)) {
        throw const _TorStartupFailure('Tor exited after bootstrap');
      }
      pirateTorStatus.value = PirateTorStatus.ready;
    } finally {
      stalled?.cancel();
    }
  }

  Future<void> stop() async {
    pirateTorStatus.value = PirateTorStatus.disabled;
    final process = _process;
    _process = null;
    _socksPort = null;
    final bridge = _httpBridge;
    _httpBridge = null;
    KdfTorConfig.disable();
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      try {
        await process.exitCode.timeout(const Duration(seconds: 5));
      } on TimeoutException {
        process.kill(ProcessSignal.sigkill);
        await process.exitCode;
      }
    }
    // A failed proxy cleanup must never leave the Tor child running.
    if (bridge != null) await bridge.close();
  }

  /// Stop Tor for app exit and prevent startup retries from spawning a new
  /// child while the window is closing.
  Future<void> shutdown() => _shutdownFuture ??= _shutdownTor();

  Future<void> _shutdownTor() async {
    _shuttingDown = true;
    try {
      await stop();
    } finally {
      final startup = _startup;
      if (startup != null) {
        try {
          await startup.timeout(const Duration(seconds: 6));
        } catch (_) {
          // Startup may fail because its Tor process was just terminated.
        }
      }
      await stop();
    }
  }

  File? _findArtifact(String name) {
    final candidates = [
      p.join(p.dirname(Platform.resolvedExecutable), 'lib', name),
      p.join(Directory.current.path, 'lib', name),
      p.join(Directory.current.path, 'artifacts', 'tor', 'linux-x64', name),
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) return file.absolute;
    }
    return null;
  }
}

class _TorStartupFailure implements Exception {
  const _TorStartupFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
