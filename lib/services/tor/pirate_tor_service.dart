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

  int? get socksPort => _socksPort;
  int? get httpProxyPort => _httpBridge?.port;

  Future<void> start() async {
    try {
      await _start();
    } catch (_) {
      pirateTorStatus.value = PirateTorStatus.unavailable;
      rethrow;
    }
  }

  Future<void> _start() async {
    if (!Platform.isLinux) {
      throw UnsupportedError('Bundled Tor is currently supported on Linux');
    }
    if (_process != null) return;
    pirateTorStatus.value = PirateTorStatus.connecting;

    final torBinary = _findArtifact('tor');
    final torsocksLibrary = _findArtifact('libtorsocks.so');
    if (torBinary == null || torsocksLibrary == null) {
      pirateTorStatus.value = PirateTorStatus.unavailable;
      throw StateError('Bundled Tor transport is missing from P2Pirate');
    }

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
    final ready = Completer<void>();
    process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
          if (line.contains('Bootstrapped 100%') && !ready.isCompleted) {
            ready.complete();
          }
        });
    process.stderr.transform(utf8.decoder).listen((_) {});
    unawaited(
      process.exitCode.then((code) {
        if (!ready.isCompleted) {
          ready.completeError(
            StateError('Tor exited before bootstrap ($code)'),
          );
        }
        if (identical(_process, process)) {
          _process = null;
          pirateTorStatus.value = PirateTorStatus.unavailable;
        }
      }),
    );

    try {
      await ready.future.timeout(const Duration(minutes: 2));
      KdfTorConfig.configure(
        port: port,
        libraryPath: torsocksLibrary.path,
        configPath: configFile.path,
      );
      _socksPort = port;
      _httpBridge = await PirateTorHttpBridge.start(port);
      pirateTorStatus.value = identical(_process, process)
          ? PirateTorStatus.ready
          : PirateTorStatus.unavailable;
    } catch (_) {
      await stop();
      pirateTorStatus.value = PirateTorStatus.unavailable;
      rethrow;
    }
  }

  Future<void> stop() async {
    pirateTorStatus.value = PirateTorStatus.disabled;
    final process = _process;
    _process = null;
    _socksPort = null;
    final bridge = _httpBridge;
    _httpBridge = null;
    if (bridge != null) await bridge.close();
    KdfTorConfig.disable();
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      await process.exitCode;
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
