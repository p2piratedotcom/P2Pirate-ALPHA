import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:web_dex/services/mm_engine/cex_plugin_service.dart';

const firstCommit = '1111111111111111111111111111111111111111';
const nextCommit = '2222222222222222222222222222222222222222';

Map<String, List<int>> fixture({int protocol = 1, bool duplicate = false}) {
  final config = <String, dynamic>{
    'schema': 1,
    'protocol': 'p2pirate-spot-v1',
    'version': '0.1.0',
    'venue': 'DEMO',
    'display_name': 'Demo Spot',
    'base_url': 'https://exchange.example/api',
    'legacy_keys': false,
    'private_read_timeout': 8,
    'time_sync_budget_ms': 12000,
    'recv_window_ms': 5000,
    'timestamp_error_codes': <String>[],
    'symbols_error_codes': <String>[],
    'taker_fee': '0.001',
    'credential_fields': ['api_key', 'api_secret'],
    'settings': <String, dynamic>{},
  };
  final archive = Archive()
    ..addFile(ArchiveFile.string('cex_plugin/adapter.py', '# fixture'));
  if (duplicate) {
    archive.addFile(ArchiveFile.string('../escape.py', '# unsafe'));
  }
  final files = {
    'LICENSE': utf8.encode('Unlicense fixture'),
    'plugins/demo/config.json': utf8.encode(jsonEncode(config)),
    'plugins/demo/adapter.zip': ZipEncoder().encode(archive),
  };
  files['catalog.json'] = utf8.encode(
    jsonEncode({
      'schema': 1,
      'protocol': protocol,
      'license_sha256': sha256.convert(files['LICENSE']!).toString(),
      'plugins': [
        {
          'venue': 'DEMO',
          'version': '0.1.0',
          'config': 'plugins/demo/config.json',
          'adapter': 'plugins/demo/adapter.zip',
          'config_sha256': sha256
              .convert(files['plugins/demo/config.json']!)
              .toString(),
          'adapter_sha256': sha256
              .convert(files['plugins/demo/adapter.zip']!)
              .toString(),
        },
      ],
    }),
  );
  return files;
}

void main() {
  late Directory root;
  setUp(
    () async =>
        root = await Directory.systemTemp.createTemp('cex-plugins-test-'),
  );
  tearDown(() async => root.delete(recursive: true));

  CexPluginService service(
    Map<String, List<int>> files, {
    bool corrupt = false,
  }) => CexPluginService(
    root: root,
    client: MockClient((request) async {
      final path = request.url.path.split('/').skip(4).join('/');
      if (corrupt && path.endsWith('adapter.zip')) {
        return http.Response.bytes([1, 2, 3], 200);
      }
      expect(request.url.host, 'raw.githubusercontent.com');
      expect(request.url.path.split('/')[3], anyOf(firstCommit, nextCommit));
      return http.Response.bytes(files[path]!, 200);
    }),
  );

  test('first install is commit pinned and reused offline', () async {
    final downloaded = await service(fixture()).download(commit: firstCommit);
    expect(downloaded.labels, {'DEMO': 'Demo Spot'});
    final offline = CexPluginService(
      root: root,
      client: MockClient((_) async {
        fail('Installed snapshot must work offline');
      }),
    );
    expect((await offline.current())?.commit, firstCommit);
    expect((await offline.download(commit: firstCommit)).commit, firstCommit);
  });

  test('failed update retains previous snapshot and cleans staging', () async {
    await service(fixture()).download(commit: firstCommit);
    await expectLater(
      service(fixture(), corrupt: true).download(commit: nextCommit),
      throwsFormatException,
    );
    expect((await service(fixture()).current())?.commit, firstCommit);
    expect(await Directory('${root.path}/$nextCommit').exists(), isFalse);
    expect(
      await root.list().where((e) => e.path.contains('.download-')).isEmpty,
      isTrue,
    );
  });

  test('unsupported protocol and unsafe source paths are rejected', () async {
    for (final files in [fixture(protocol: 2), fixture(duplicate: true)]) {
      await expectLater(
        service(files).download(commit: firstCommit),
        throwsFormatException,
      );
      expect(await File('${root.path}/current').exists(), isFalse);
    }
  });

  test(
    'installed files and pointers cannot be symlinks or corrupted',
    () async {
      await service(fixture()).download(commit: firstCommit);
      final config = File('${root.path}/$firstCommit/plugins/demo/config.json');
      await config.writeAsString('{}');
      await expectLater(service(fixture()).current(), throwsFormatException);
      await config.delete();
      await Link(config.path).create('${root.path}/$firstCommit/LICENSE');
      await expectLater(service(fixture()).current(), throwsFormatException);
    },
  );

  for (final damage in ['missing', 'checksum', 'pointer']) {
    test(
      'explicit download repairs $damage but startup stays fail closed',
      () async {
        await service(fixture()).download(commit: firstCommit);
        final adapter = File(
          '${root.path}/$firstCommit/plugins/demo/adapter.zip',
        );
        if (damage == 'missing') {
          await adapter.delete();
        } else if (damage == 'checksum') {
          await adapter.writeAsBytes([1, 2, 3]);
        } else {
          await File('${root.path}/current').writeAsString('broken pointer');
        }
        await expectLater(service(fixture()).current(), throwsFormatException);
        expect(await service(fixture()).currentForDownload(), isNull);
        final repaired = await service(fixture()).download(commit: firstCommit);
        expect(repaired.labels, {'DEMO': 'Demo Spot'});
        expect((await service(fixture()).current())?.commit, firstCommit);
        if (damage != 'pointer') {
          expect(
            await root
                .list()
                .where((e) => e.path.contains('.quarantine-'))
                .length,
            1,
          );
        }
      },
    );
  }

  test('invalid replacement leaves a damaged snapshot untouched', () async {
    await service(fixture()).download(commit: firstCommit);
    final adapter = File('${root.path}/$firstCommit/plugins/demo/adapter.zip');
    await adapter.writeAsBytes([7, 8, 9]);
    await expectLater(
      service(fixture(), corrupt: true).download(commit: firstCommit),
      throwsFormatException,
    );
    expect(await adapter.readAsBytes(), [7, 8, 9]);
    expect(
      await root.list().where((e) => e.path.contains('.quarantine-')).isEmpty,
      isTrue,
    );
    await expectLater(service(fixture()).current(), throwsFormatException);
  });

  test('repository identity is checked before resolving a download', () async {
    final wrong = CexPluginService(
      root: root,
      client: MockClient(
        (_) async => http.Response(
          jsonEncode({'id': 1, 'full_name': CexPluginService.repository}),
          200,
        ),
      ),
    );
    await expectLater(wrong.latestCommit(), throwsFormatException);
    final correct = CexPluginService(
      root: root,
      client: MockClient(
        (request) async => http.Response(
          jsonEncode(
            request.url.path.endsWith('/main')
                ? {
                    'commit': {'sha': firstCommit},
                  }
                : {
                    'id': CexPluginService.repositoryId,
                    'full_name': CexPluginService.repository,
                  },
          ),
          200,
        ),
      ),
    );
    expect(await correct.latestCommit(), firstCommit);
  });

  test('public settings cannot contain credential fields', () {
    final config = jsonDecode(
      utf8.decode(fixture()['plugins/demo/config.json']!),
    );
    config['settings'] = {
      'nested': {'api_secret': 'fixture'},
    };
    expect(
      () => CexPluginService.validateConfiguration(config, 'DEMO', '0.1.0'),
      throwsFormatException,
    );
  });
}
