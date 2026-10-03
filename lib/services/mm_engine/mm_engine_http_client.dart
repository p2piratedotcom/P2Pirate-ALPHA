import 'dart:convert';
import 'dart:io';

/// Sends one request to the local MM_Engine API.
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
        path == '/v1/strategies/preview' || path == '/v1/strategies/create'
        ? const Duration(seconds: 60)
        : const Duration(seconds: 20);
    final response = await call.close().timeout(responseTimeout);
    final payload = jsonDecode(await utf8.decoder.bind(response).join());
    if (payload is! Map<String, dynamic>) {
      throw StateError('Invalid MM_Engine response');
    }
    if (response.statusCode >= 400) {
      throw StateError(
        payload['error']?.toString() ??
            'MM_Engine request failed (${response.statusCode})',
      );
    }
    return payload;
  } finally {
    client.close(force: true);
  }
}
