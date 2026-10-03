import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:komodo_coin_updates/komodo_coin_updates.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Downloads a complete, commit-pinned coin catalog and restored icon set.
/// A failed update leaves the previous verified snapshot available.
class CoinAssetsService {
  CoinAssetsService({http.Client? client, Directory? storageRoot})
    : _client = client ?? http.Client(),
      _storageRoot = storageRoot;

  static final CoinAssetsService instance = CoinAssetsService();
  static const repository = 'p2piratedotcom/Assets';
  static const _maxArchiveBytes = 40 * 1024 * 1024;
  static final _commitPattern = RegExp(r'^[a-f0-9]{40}$');
  static final _safePath = RegExp(
    r'^(?:icons/[a-z0-9_]+\.png|coins|seed-nodes\.json|utils/coins_config_unfiltered\.json)$',
  );

  final http.Client _client;
  final Directory? _storageRoot;

  Future<Directory> get _root async {
    if (_storageRoot != null) return _storageRoot;
    final app = await getApplicationSupportDirectory();
    return Directory(p.join(app.path, 'p2pirate-coin-assets'));
  }

  Future<bool> get skipped async {
    final file = File(p.join((await _root).path, 'skip-first-download'));
    return file.exists();
  }

  Future<void> skipFirstDownload() async {
    final root = await _root;
    await root.create(recursive: true);
    await File(p.join(root.path, 'skip-first-download')).writeAsString('1');
  }

  Future<String?> get currentCommit async {
    final root = await _root;
    final pointer = File(p.join(root.path, 'current'));
    if (!await pointer.exists()) return null;
    final commit = (await pointer.readAsString()).trim();
    if (!_commitPattern.hasMatch(commit)) return null;
    final snapshot = Directory(p.join(root.path, commit));
    if (!await snapshot.exists()) return null;
    try {
      await _verifyDirectory(snapshot);
      return commit;
    } catch (_) {
      return null;
    }
  }

  Future<String> get latestCommit async {
    final response = await _client
        .get(
          Uri.parse('https://api.github.com/repos/$repository/branches/main'),
          headers: const {
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'P2Pirate-Wallet',
          },
        )
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw StateError(
        'Assets repository returned HTTP ${response.statusCode}',
      );
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final commit = (body['commit'] as Map<String, dynamic>)['sha'] as String;
    if (!_commitPattern.hasMatch(commit)) {
      throw const FormatException('Invalid Assets commit');
    }
    return commit;
  }

  Future<bool> checkUpdates() async =>
      await currentCommit != await latestCommit;

  /// Returns the installed commit. Network traffic respects the wallet's
  /// global Tor HTTP override when Tor is enabled.
  Future<String> downloadLatest({void Function(String)? onStage}) async {
    onStage?.call('Checking latest Assets commit…');
    final commit = await latestCommit;
    if (await currentCommit == commit) return commit;
    final root = await _root;
    await root.create(recursive: true);
    final staging = await root.createTemp('.download-');
    try {
      onStage?.call('Downloading coin catalog and icons…');
      final bytes = await _downloadArchive(commit);
      onStage?.call('Verifying downloaded files…');
      final archive = ZipDecoder().decodeBytes(bytes);
      final prefix = 'Assets-$commit/';
      final files = <String, List<int>>{};
      var uncompressedBytes = 0;
      for (final entry in archive.files.where((file) => file.isFile)) {
        if (!entry.name.startsWith(prefix)) continue;
        final name = entry.name.substring(prefix.length);
        if (name == 'manifest.json' || _safePath.hasMatch(name)) {
          if (files.containsKey(name)) {
            throw const FormatException('Duplicate asset path');
          }
          uncompressedBytes += entry.size;
          if (uncompressedBytes > 80 * 1024 * 1024) {
            throw const FormatException('Assets contents are too large');
          }
          files[name] = entry.content as List<int>;
        }
      }
      final manifestBytes = files.remove('manifest.json');
      if (manifestBytes == null) {
        throw const FormatException('Assets manifest missing');
      }
      final hashes = _readManifest(manifestBytes);
      if (hashes.length != files.length ||
          hashes.keys.toSet().difference(files.keys.toSet()).isNotEmpty) {
        throw const FormatException(
          'Assets manifest does not match archive files',
        );
      }
      for (final entry in files.entries) {
        if (sha256.convert(entry.value).toString() != hashes[entry.key]) {
          throw FormatException('Asset checksum mismatch: ${entry.key}');
        }
        final target = File(p.join(staging.path, entry.key));
        await target.parent.create(recursive: true);
        await target.writeAsBytes(entry.value, flush: true);
      }
      await File(
        p.join(staging.path, 'manifest.json'),
      ).writeAsBytes(manifestBytes, flush: true);
      final finalDir = Directory(p.join(root.path, commit));
      final type = await FileSystemEntity.type(
        finalDir.path,
        followLinks: false,
      );
      if (type == FileSystemEntityType.link ||
          type == FileSystemEntityType.file) {
        throw const FormatException('Unsafe Assets installation path');
      }
      if (type == FileSystemEntityType.directory) {
        try {
          await _verifyDirectory(finalDir);
        } catch (_) {
          await finalDir.delete(recursive: true);
          await staging.rename(finalDir.path);
        }
      } else {
        await staging.rename(finalDir.path);
      }
      final pointer = File(p.join(root.path, '.current-new'));
      await pointer.writeAsString('$commit\n', flush: true);
      await pointer.rename(p.join(root.path, 'current'));
      return commit;
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  Future<List<int>> _downloadArchive(String commit) async {
    final request = http.Request(
      'GET',
      Uri.parse('https://codeload.github.com/$repository/zip/$commit'),
    );
    request.headers['User-Agent'] = 'P2Pirate-Wallet';
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 60));
    if (response.statusCode != 200) {
      throw StateError('Assets archive returned HTTP ${response.statusCode}');
    }
    final chunks = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 90),
    )) {
      if (chunks.length + chunk.length > _maxArchiveBytes) {
        throw const FormatException('Assets archive is too large');
      }
      chunks.addAll(chunk);
    }
    return chunks;
  }

  Map<String, String> _readManifest(List<int> bytes) {
    final manifest = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    if (manifest['schema'] != 1) {
      throw const FormatException('Unsupported Assets manifest');
    }
    final hashes = Map<String, String>.from(manifest['sha256'] as Map);
    if (hashes.length < 4 ||
        hashes.length > 1500 ||
        hashes.keys.any((key) => !_safePath.hasMatch(key)) ||
        hashes.values.any(
          (hash) => !RegExp(r'^[a-f0-9]{64}$').hasMatch(hash),
        )) {
      throw const FormatException('Invalid Assets manifest entries');
    }
    if (manifest['icon_count'] !=
            hashes.keys.where((key) => key.startsWith('icons/')).length ||
        !hashes.containsKey('coins') ||
        !hashes.containsKey('seed-nodes.json') ||
        !hashes.containsKey('utils/coins_config_unfiltered.json')) {
      throw const FormatException('Incomplete Assets manifest');
    }
    return hashes;
  }

  Future<void> _verifyDirectory(Directory snapshot) async {
    final manifest = File(p.join(snapshot.path, 'manifest.json'));
    final hashes = _readManifest(await manifest.readAsBytes());
    for (final entry in hashes.entries) {
      final file = File(p.join(snapshot.path, entry.key));
      if (!await file.exists() ||
          sha256.convert(await file.readAsBytes()).toString() != entry.value) {
        throw FormatException(
          'Installed asset checksum mismatch: ${entry.key}',
        );
      }
    }
  }

  /// Installs the selected catalog into the SDK store before SDK startup.
  /// Settings downloads take effect after restarting the wallet.
  Future<String?> activateCurrent() async {
    final commit = await currentCommit;
    if (commit == null) return null;
    final root = await _root;
    final configFile = File(
      p.join(root.path, commit, 'utils/coins_config_unfiltered.json'),
    );
    final config =
        jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
    const transformer = CoinConfigTransformer();
    final transformed = <String, Map<String, dynamic>>{
      for (final item in config.entries)
        item.key: transformer.apply(
          Map<String, dynamic>.from(item.value as Map),
        ),
    };
    final assets = const AssetParser().parseAssetsFromConfig(
      transformed,
      shouldFilterCoin: (coin) => const CoinFilter().shouldFilter(coin),
      logContext: 'from verified P2Pirate Assets',
    );
    if (assets.length < 100) {
      throw const FormatException('Assets catalog is unexpectedly small');
    }
    final documents = await getApplicationDocumentsDirectory();
    await KomodoCoinUpdater.ensureInitialized(
      p.join(documents.path, 'komodo_coins'),
    );
    final runtimeConfig = await AssetRuntimeUpdateConfigRepository().load();
    final repository = CoinConfigRepository.withDefaults(runtimeConfig);
    if (await repository.getCurrentCommit() != commit) {
      await repository.upsertAssets(assets, commit);
    }
    return p.join(root.path, commit, 'icons');
  }
}
