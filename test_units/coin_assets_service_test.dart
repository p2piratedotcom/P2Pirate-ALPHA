import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:komodo_ui/komodo_ui.dart' show AssetIcon;
import 'package:web_dex/services/coin_assets/coin_assets_setup_screen.dart';
import 'package:web_dex/services/coin_assets/coin_assets_service.dart';

void main() {
  const commit = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';

  Future<Directory> temporaryRoot() async {
    final root = await Directory.systemTemp.createTemp('p2pirate-assets-test-');
    addTearDown(() => root.delete(recursive: true));
    return root;
  }

  List<int> makeArchive({bool corruptIcon = false}) {
    final files = <String, List<int>>{
      'coins': utf8.encode('[]'),
      'seed-nodes.json': utf8.encode('[]'),
      'utils/coins_config_unfiltered.json': utf8.encode('{}'),
      'icons/arrr.png': <int>[137, 80, 78, 71],
    };
    final manifest = utf8.encode(
      jsonEncode({
        'schema': 1,
        'icon_count': 1,
        'sha256': {
          for (final entry in files.entries)
            entry.key: sha256.convert(entry.value).toString(),
        },
      }),
    );
    final archive = Archive();
    for (final entry in files.entries) {
      final contents = corruptIcon && entry.key == 'icons/arrr.png'
          ? <int>[0]
          : entry.value;
      archive.addFile(
        ArchiveFile('Assets-$commit/${entry.key}', contents.length, contents),
      );
    }
    archive.addFile(
      ArchiveFile('Assets-$commit/manifest.json', manifest.length, manifest),
    );
    return ZipEncoder().encode(archive);
  }

  CoinAssetsService service(Directory root, List<int> archive) =>
      CoinAssetsService(
        storageRoot: root,
        client: MockClient((request) async {
          if (request.url.host == 'api.github.com') {
            return http.Response(
              jsonEncode({
                'commit': {'sha': commit},
              }),
              200,
            );
          }
          return http.Response.bytes(archive, 200);
        }),
      );

  test('downloads a verified snapshot and tracks its commit', () async {
    final root = await temporaryRoot();
    final assets = service(root, makeArchive());
    expect(await assets.currentCommit, isNull);
    expect(await assets.checkUpdates(), isTrue);
    expect(await assets.downloadLatest(), commit);
    expect(await assets.currentCommit, commit);
    expect(await assets.checkUpdates(), isFalse);
    expect(await File('${root.path}/$commit/icons/arrr.png').exists(), isTrue);
  });

  test('rejects a corrupt archive without activating it', () async {
    final root = await temporaryRoot();
    final assets = service(root, makeArchive(corruptIcon: true));
    await expectLater(assets.downloadLatest(), throwsFormatException);
    expect(await assets.currentCommit, isNull);
    expect(await File('${root.path}/current').exists(), isFalse);
  });

  testWidgets('first-launch screen asks before downloading', (tester) async {
    await tester.pumpWidget(CoinAssetsSetupScreen(onReady: () {}));
    expect(find.text('Download coin assets'), findsOneWidget);
    expect(find.text('Download assets'), findsOneWidget);
    expect(find.text('Use bundled catalog for now'), findsOneWidget);
  });

  test('coin widget resolves icons from the installed directory', () async {
    final root = await temporaryRoot();
    await File('${root.path}/arrr.png').writeAsBytes([1]);
    AssetIcon.setRuntimeIconDirectory(root.path);
    addTearDown(() => AssetIcon.setRuntimeIconDirectory(null));
    expect(AssetIcon.assetIconExists('ARRR'), isTrue);
    expect(AssetIcon.assetIconExists('BTC'), isFalse);
  });
}
