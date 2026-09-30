import 'dart:async';
import 'dart:io';

import 'package:socks5_proxy/socks_client.dart';

/// A loopback-only HTTP proxy whose upstream is Tor SOCKS5.
class PirateTorHttpBridge {
  PirateTorHttpBridge._(this._server, this.socksPort) {
    _server.listen(_handleRequest);
  }

  final HttpServer _server;
  final int socksPort;

  int get port => _server.port;

  static Future<PirateTorHttpBridge> start(int socksPort) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return PirateTorHttpBridge._(server, socksPort);
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final target = _target(request);
      if (target == null || _isLoopback(target.host)) {
        request.response.statusCode = HttpStatus.badRequest;
        await request.response.close();
        return;
      }

      final pending = SocksTCPClient.connect(
        [ProxySettings(InternetAddress.loopbackIPv4, socksPort)],
        InternetAddress(target.host, type: InternetAddressType.unix),
        target.port,
      );
      final upstream = await pending.timeout(
        const Duration(seconds: 35),
        onTimeout: () {
          unawaited(
            pending.then((socket) => socket.destroy(), onError: (_) {}),
          );
          throw TimeoutException('Tor SOCKS connection timed out');
        },
      );

      if (request.method == 'CONNECT') {
        final downstream = await request.response.detachSocket(
          writeHeaders: false,
        );
        downstream.write('HTTP/1.1 200 Connection established\r\n\r\n');
        await downstream.flush();
        _relay(downstream, upstream);
      } else {
        await _forwardHttp(request, target, upstream);
      }
    } catch (_) {
      try {
        request.response.statusCode = HttpStatus.badGateway;
        await request.response.close();
      } catch (_) {
        // A detached CONNECT socket is already outside HttpServer ownership.
      }
    }
  }

  Uri? _target(HttpRequest request) {
    if (request.method == 'CONNECT') {
      final authority = request.uri.toString().replaceFirst(RegExp(r'^/'), '');
      final uri = Uri.tryParse('http://$authority');
      if (uri == null || uri.host.isEmpty || uri.port == 0) return null;
      return uri;
    }
    final uri = request.requestedUri;
    if (uri.host.isEmpty || uri.scheme != 'http') return null;
    return uri;
  }

  Future<void> _forwardHttp(
    HttpRequest request,
    Uri target,
    Socket upstream,
  ) async {
    final path = target.hasQuery
        ? '${target.path.isEmpty ? '/' : target.path}?${target.query}'
        : (target.path.isEmpty ? '/' : target.path);
    final chunked = request.headers.chunkedTransferEncoding;
    final contentLength = request.contentLength;
    upstream.write('${request.method} $path HTTP/1.1\r\n');
    request.headers.forEach((name, values) {
      if (name == HttpHeaders.connectionHeader ||
          name == 'proxy-connection' ||
          name == HttpHeaders.proxyAuthorizationHeader ||
          name == HttpHeaders.teHeader ||
          name == HttpHeaders.trailerHeader ||
          name == HttpHeaders.upgradeHeader ||
          name == HttpHeaders.transferEncodingHeader ||
          name == HttpHeaders.contentLengthHeader) {
        return;
      }
      for (final value in values) {
        upstream.write('$name: $value\r\n');
      }
    });
    upstream.write('Connection: close\r\n');
    if (chunked) {
      upstream.write('Transfer-Encoding: chunked\r\n');
    } else if (contentLength >= 0) {
      upstream.write('Content-Length: $contentLength\r\n');
    }
    upstream.write('\r\n');
    await for (final chunk in request) {
      if (chunk.isEmpty) continue;
      if (chunked) upstream.write('${chunk.length.toRadixString(16)}\r\n');
      upstream.add(chunk);
      if (chunked) upstream.write('\r\n');
    }
    if (chunked) upstream.write('0\r\n\r\n');
    await upstream.flush();
    final downstream = await request.response.detachSocket(writeHeaders: false);
    _relay(downstream, upstream);
  }

  void _relay(Socket downstream, Socket upstream) {
    downstream.listen(
      upstream.add,
      onDone: () => unawaited(upstream.close()),
      onError: (_) => upstream.destroy(),
    );
    upstream.listen(
      downstream.add,
      onDone: () => unawaited(downstream.close()),
      onError: (_) => downstream.destroy(),
    );
  }

  bool _isLoopback(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';
}
