import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/services/mm_engine/mm_engine_http_client.dart';

void main() {
  test('credential POST has a byte-accurate Content-Length', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = server.first.then((request) async {
      final bytes = await request.fold<List<int>>(
        <int>[],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      expect(request.headers.contentLength, bytes.length);
      expect(request.headers.contentLength, greaterThan(0));
      expect(request.headers.chunkedTransferEncoding, isFalse);
      expect(
        request.headers.value(HttpHeaders.authorizationHeader),
        'Bearer test',
      );
      expect(jsonDecode(utf8.decode(bytes)), {
        'venue': 'MEXC',
        'api_key': 'fake-key',
        'api_secret': 'fake-sécret',
      });
      request.response
        ..headers.contentType = ContentType.json
        ..write('{"stored":true}');
      await request.response.close();
    });

    final result = await sendMmEngineRequest(
      Uri.parse('http://127.0.0.1:${server.port}'),
      'test',
      'POST',
      '/v1/credentials/store',
      body: {
        'venue': 'MEXC',
        'api_key': 'fake-key',
        'api_secret': 'fake-sécret',
      },
    );
    await received;
    expect(result['stored'], true);
  });

  test('empty POST still sends a nonzero JSON body size', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = server.first.then((request) async {
      expect(request.headers.contentLength, 2);
      expect(await utf8.decoder.bind(request).join(), '{}');
      request.response
        ..headers.contentType = ContentType.json
        ..write('{"stopping":true}');
      await request.response.close();
    });

    final result = await sendMmEngineRequest(
      Uri.parse('http://127.0.0.1:${server.port}'),
      'test',
      'POST',
      '/v1/engine/shutdown',
    );
    await received;
    expect(result['stopping'], true);
  });
  test('engine errors retain status and have no Bad state prefix', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    final received = server.first.then((request) async {
      await request.drain<void>();
      request.response
        ..statusCode = 422
        ..headers.contentType = ContentType.json
        ..write('{"error":"MEXC: check Spot read permission"}');
      await request.response.close();
    });
    await expectLater(
      sendMmEngineRequest(
        Uri.parse('http://127.0.0.1:${server.port}'),
        'test',
        'POST',
        '/v1/strategies/preview',
      ),
      throwsA(
        isA<MmEngineRequestException>()
            .having((error) => error.statusCode, 'status', 422)
            .having(
              (error) => error.toString(),
              'message',
              'MEXC: check Spot read permission',
            ),
      ),
    );
    await received;
  });
}
