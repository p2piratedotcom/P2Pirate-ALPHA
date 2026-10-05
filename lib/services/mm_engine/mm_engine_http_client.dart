import 'dart:convert';
import 'dart:io';

class MmEngineRequestException implements Exception {
  const MmEngineRequestException(this.message, this.statusCode);
  final String message;
  final int statusCode;
  @override
  String toString() => message.replaceAll(
    RegExp(r'MM[_ ]Engine', caseSensitive: false),
    'P2Pirate Trading Engine',
  );
}

/// Sends one request to the local P2Pirate Trading Engine API.
/// The Python service requires Content-Length for every POST, including {}.
Future<Map<String, dynamic>> sendMmEngineRequest(
  Uri baseUrl,
  String token,
  String method,
  String path, {
  Map<String, Object?> body = const {},
}) async {
  if (!path.startsWith('/v1/')) throw ArgumentError.value(path, 'path');
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final call = await client.openUrl(method, baseUrl.resolve(path));
    call.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
    call.headers.contentType = ContentType.json;
    if (method == 'POST') {
      final bytes = utf8.encode(jsonEncode(body));
      call.contentLength = bytes.length;
      call.add(bytes);
    }
    // A strategy preview can fetch uncached public CEX metadata over Tor for
    // both legs before it computes a quote. The engine still enforces a short
    // independent freshness deadline on the final order book.
    final responseTimeout =
        path == '/v1/strategies/preview' ||
            path == '/v1/strategies/create' ||
            path.startsWith('/v1/exchanges/balances')
        ? const Duration(seconds: 60)
        : const Duration(seconds: 20);
    final response = await call.close().timeout(responseTimeout);
    final payload = jsonDecode(
      await utf8.decoder.bind(response).join().timeout(responseTimeout),
    );
    if (payload is! Map<String, dynamic>) {
      throw StateError('Invalid P2Pirate Trading Engine response');
    }
    if (response.statusCode >= 400) {
      throw MmEngineRequestException(
        payload['error']?.toString() ??
            'P2Pirate Trading Engine request failed (${response.statusCode})',
        response.statusCode,
      );
    }
    return payload;
  } finally {
    client.close(force: true);
  }
}
