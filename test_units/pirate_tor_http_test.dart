import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:web_dex/services/tor/pirate_tor_http_bridge.dart';
import 'package:web_dex/services/tor/pirate_tor_http_overrides.dart';

void main() {
  tearDown(() => HttpOverrides.global = null);

  test('external HTTP uses SOCKS5 domain addressing', () async {
    final proxy = await _FakeSocksServer.start();
    final bridge = await PirateTorHttpBridge.start(proxy.port);
    addTearDown(proxy.close);
    addTearDown(bridge.close);
    HttpOverrides.global = PirateTorHttpOverrides(bridge.port);

    final response = await http.get(
      Uri.parse('http://no-local-dns.invalid/market'),
    );

    expect(response.statusCode, 200);
    expect(response.body, 'via tor');
    expect(proxy.requestedHost, 'no-local-dns.invalid');
    expect(proxy.requestedPort, 80);
  });

  test('local KDF RPC bypasses SOCKS5', () async {
    final proxy = await _FakeSocksServer.start();
    final bridge = await PirateTorHttpBridge.start(proxy.port);
    final rpc = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(proxy.close);
    addTearDown(bridge.close);
    addTearDown(() => rpc.close(force: true));
    rpc.listen((request) {
      request.response.write('local rpc');
      unawaited(request.response.close());
    });
    HttpOverrides.global = PirateTorHttpOverrides(bridge.port);

    final response = await http.get(Uri.parse('http://127.0.0.1:${rpc.port}/'));

    expect(response.body, 'local rpc');
    expect(proxy.connections, 0);
  });

  test('POST body passes through the SOCKS5 bridge', () async {
    final proxy = await _FakeSocksServer.start();
    final bridge = await PirateTorHttpBridge.start(proxy.port);
    addTearDown(proxy.close);
    addTearDown(bridge.close);
    HttpOverrides.global = PirateTorHttpOverrides(bridge.port);

    final response = await http.post(
      Uri.parse('http://no-local-dns.invalid/feedback'),
      body: 'ARRR',
    );

    expect(response.statusCode, 200);
    expect(proxy.lastRequest, contains('POST /feedback HTTP/1.1'));
    expect(proxy.lastRequest, contains('\r\n\r\nARRR'));
  });

  test('NetworkImage is loaded through SOCKS5', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final png = await File('assets/logo/pirate_icon.png').readAsBytes();
    final proxy = await _FakeSocksServer.start(
      body: png,
      contentType: 'image/png',
    );
    final bridge = await PirateTorHttpBridge.start(proxy.port);
    addTearDown(proxy.close);
    addTearDown(bridge.close);
    HttpOverrides.global = PirateTorHttpOverrides(bridge.port);

    final loaded = Completer<void>();
    final stream = const NetworkImage(
      'http://no-local-dns.invalid/icon.png',
    ).resolve(ImageConfiguration.empty);
    stream.addListener(
      ImageStreamListener(
        (_, _) => loaded.complete(),
        onError: (error, stack) => loaded.completeError(error, stack),
      ),
    );
    await loaded.future.timeout(const Duration(seconds: 10));

    expect(proxy.requestedHost, 'no-local-dns.invalid');
  });

  test('Tor outage has no direct fallback', () async {
    final proxy = await _FakeSocksServer.start();
    final bridge = await PirateTorHttpBridge.start(proxy.port);
    addTearDown(bridge.close);
    await proxy.close();
    HttpOverrides.global = PirateTorHttpOverrides(bridge.port);

    final response = await http.get(Uri.parse('http://no-local-dns.invalid/'));
    expect(response.statusCode, HttpStatus.badGateway);
  });

  test('HTTPS exits through Tor', () async {
    final port = int.parse(Platform.environment['PIRATE_TOR_SOCKS_PORT']!);
    final bridge = await PirateTorHttpBridge.start(port);
    addTearDown(bridge.close);
    HttpOverrides.global = PirateTorHttpOverrides(bridge.port);

    final response = await http
        .get(Uri.parse('https://check.torproject.org/api/ip'))
        .timeout(const Duration(seconds: 45));
    expect(response.statusCode, 200);
    expect(jsonDecode(response.body)['IsTor'], true);
  }, skip: Platform.environment['PIRATE_TOR_SOCKS_PORT'] == null);
}

class _FakeSocksServer {
  _FakeSocksServer(this._server, this.body, this.contentType) {
    _server.listen(_handleConnection);
  }

  final ServerSocket _server;
  final List<int> body;
  final String contentType;
  int connections = 0;
  String? requestedHost;
  int? requestedPort;
  String? lastRequest;

  int get port => _server.port;

  static Future<_FakeSocksServer> start({
    List<int>? body,
    String contentType = 'text/plain',
  }) async => _FakeSocksServer(
    await ServerSocket.bind(InternetAddress.loopbackIPv4, 0),
    body ?? utf8.encode('via tor'),
    contentType,
  );

  Future<void> close() => _server.close();

  void _handleConnection(Socket socket) {
    connections++;
    var stage = 0;
    var pending = <int>[];
    socket.listen((bytes) {
      pending.addAll(bytes);
      while (true) {
        if (stage == 0) {
          if (pending.length < 2) return;
          final length = 2 + pending[1];
          if (pending.length < length) return;
          expect(pending.sublist(0, length), [5, 1, 0]);
          pending = pending.sublist(length);
          socket.add([5, 0]);
          stage = 1;
        } else if (stage == 1) {
          if (pending.length < 5) return;
          expect(pending.sublist(0, 4), [5, 1, 0, 3]);
          final length = 5 + pending[4] + 2;
          if (pending.length < length) return;
          requestedHost = utf8.decode(pending.sublist(5, 5 + pending[4]));
          requestedPort = (pending[length - 2] << 8) | pending[length - 1];
          pending = pending.sublist(length);
          socket.add([5, 0, 0, 1, 127, 0, 0, 1, 0, 0]);
          stage = 2;
        } else {
          final requestText = latin1.decode(pending);
          final headerEnd = requestText.indexOf('\r\n\r\n');
          if (headerEnd < 0) return;
          final header = requestText.substring(0, headerEnd);
          final lengthMatch = RegExp(
            r'content-length: (\d+)',
            caseSensitive: false,
          ).firstMatch(header);
          final bodyLength = int.tryParse(lengthMatch?.group(1) ?? '') ?? 0;
          if (pending.length < headerEnd + 4 + bodyLength) return;
          lastRequest = requestText;
          socket.write(
            'HTTP/1.1 200 OK\r\n'
            'Content-Length: ${body.length}\r\n'
            'Content-Type: $contentType\r\n'
            'Connection: close\r\n'
            '\r\n',
          );
          socket.add(body);
          unawaited(socket.flush().then((_) => socket.close()));
          stage = 3;
          return;
        }
      }
    });
  }
}
