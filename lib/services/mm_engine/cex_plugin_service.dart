import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/services/tor/pirate_tor_service.dart';

/// Public, commit-pinned code and configuration. Credentials never enter this
/// service. The running engine keeps its snapshot until explicitly stopped.
class CexPluginService {
  CexPluginService({http.Client? client, Directory? root})
    : _client = client ?? http.Client(),
      _storage = root;

  static final instance = CexPluginService();
  static const repository = 'p2piratedotcom/CEX_configs';
  static const repositoryId = 1403646037;
  static final _commit = RegExp(r'^[a-f0-9]{40}$');
  static final _digest = RegExp(r'^[a-f0-9]{64}$');
  static final _snapshotName = RegExp(r'^[a-f0-9]{40}(?:-[a-f0-9]{64})?$');
  final http.Client _client;
  final Directory? _storage;
  Future<CexPluginSnapshot>? _installing;

  Future<Directory> get _root async =>
      _storage ??
      Directory(
        p.join((await getApplicationSupportDirectory()).path, 'cex-plugins'),
      );

  Future<CexPluginSnapshot?> current({bool localOverride = true}) async {
    if (localOverride && _storage == null) {
      final local = Platform.environment['P2PIRATE_CEX_PLUGIN_DIR'];
      if (local != null) {
        if (!p.isAbsolute(local)) {
          throw StateError('Local plugin path must be absolute');
        }
        return verify(Directory(local), 'local');
      }
    }
    final root = await _root;
    final pointer = File(p.join(root.path, 'current'));
    if (!await pointer.exists()) return null;
    if (await FileSystemEntity.isLink(pointer.path)) {
      throw const FormatException('Unsafe plugin pointer');
    }
    final name = (await pointer.readAsString()).trim();
    if (!_snapshotName.hasMatch(name)) {
      throw const FormatException('Invalid plugin commit');
    }
    final directory = Directory(p.join(root.path, name));
    final snapshot = await verify(directory, name.substring(0, 40));
    if (name.length > 40) {
      final manifest = File(p.join(directory.path, 'catalog.json'));
      if (await FileSystemEntity.isLink(manifest.path) ||
          await manifest.length() > 65536 ||
          sha256.convert(await manifest.readAsBytes()).toString() !=
              name.substring(41)) {
        throw const FormatException('Invalid plugin snapshot identity');
      }
    }
    return snapshot;
  }

  /// Explicit installation may repair corruption; startup still uses current()
  /// and refuses any invalid installed snapshot.
  Future<CexPluginSnapshot?> currentForDownload() async {
    try {
      return await current(localOverride: false);
    } on FormatException {
      return null;
    } on FileSystemException {
      return null;
    }
  }

  Future<String> latestCommit() async {
    if (_storage == null) {
      final stored = await SettingsRepository.loadStoredSettings();
      if (stored.torEnabled &&
          PirateTorService.instance.httpProxyPort == null) {
        throw StateError(
          'Tor must be connected before downloading CEX plugins',
        );
      }
    }
    final metadata =
        jsonDecode(
              utf8.decode(
                await _get(
                  Uri.parse('https://api.github.com/repos/$repository'),
                  65536,
                ),
              ),
            )
            as Map;
    if (metadata['id'] != repositoryId || metadata['full_name'] != repository) {
      throw const FormatException('CEX plugin repository identity changed');
    }
    final branch =
        jsonDecode(
              utf8.decode(
                await _get(
                  Uri.parse(
                    'https://api.github.com/repos/$repository/branches/main',
                  ),
                  65536,
                ),
              ),
            )
            as Map;
    final commit = (branch['commit'] as Map)['sha'];
    if (commit is! String || !_commit.hasMatch(commit)) {
      throw const FormatException('Invalid CEX plugin commit');
    }
    return commit;
  }

  /// Fetch only the bounded public catalog before the user selects downloads.
  Future<CexPluginCatalog> catalog({String? commit}) async {
    final pinned = commit ?? await latestCommit();
    if (!_commit.hasMatch(pinned)) {
      throw const FormatException('Invalid plugin commit');
    }
    final bytes = await _file(pinned, 'catalog.json', 65536);
    final parsed = _manifest(bytes);
    return CexPluginCatalog(pinned, parsed.$1, parsed.$2);
  }

  bool selectionIsCurrent(
    CexPluginSnapshot? installed,
    CexPluginCatalog catalog,
    Set<String> venues,
  ) =>
      installed != null &&
      installed.licenseDigest == catalog.licenseDigest &&
      venues.isNotEmpty &&
      venues.every((venue) {
        final old = installed.entries.where((entry) => entry['venue'] == venue);
        final next = catalog.entries.where((entry) => entry['venue'] == venue);
        return old.length == 1 &&
            next.length == 1 &&
            next.single.keys.every(
              (key) => old.single[key] == next.single[key],
            );
      });

  Future<CexPluginSnapshot> download({
    String? commit,
    Set<String>? venues,
    CexPluginCatalog? available,
    void Function(String)? onStage,
  }) {
    if (_installing != null) {
      throw StateError('A CEX plugin installation is already in progress');
    }
    return _installing = _download(
      commit,
      venues == null ? null : Set<String>.unmodifiable(venues),
      available,
      onStage,
    ).whenComplete(() => _installing = null);
  }

  Future<CexPluginSnapshot> _download(
    String? expectedCommit,
    Set<String>? venues,
    CexPluginCatalog? available,
    void Function(String)? onStage,
  ) async {
    onStage?.call('Checking CEX plugin catalog…');
    // Preserve the legacy API's verified offline reuse. The interactive picker
    // always supplies its fetched catalog and explicit selection.
    if (available == null && venues == null && expectedCommit != null) {
      if (!_commit.hasMatch(expectedCommit)) {
        throw const FormatException('Invalid plugin commit');
      }
      final installed = await currentForDownload();
      if (installed?.commit == expectedCommit) return installed!;
    }
    final remote = available ?? await catalog(commit: expectedCommit);
    final commit = remote.commit;
    if (!_commit.hasMatch(commit)) {
      throw const FormatException('Invalid plugin commit');
    }
    _manifest(
      utf8.encode(
        jsonEncode({
          'schema': 1,
          'protocol': 1,
          'license_sha256': remote.licenseDigest,
          'plugins': remote.entries,
        }),
      ),
    );
    if (expectedCommit != null && expectedCommit != commit) {
      throw const FormatException('CEX plugin catalog changed');
    }
    final selected =
        venues ??
        remote.entries.map((entry) => entry['venue'] as String).toSet();
    final known = remote.entries
        .map((entry) => entry['venue'] as String)
        .toSet();
    if (selected.isEmpty || !known.containsAll(selected)) {
      throw const FormatException('Select at least one available CEX plugin');
    }
    final existing = await currentForDownload();
    if (selectionIsCurrent(existing, remote, selected) &&
        (venues != null || existing!.commit == commit)) {
      return existing!;
    }
    final retained = venues == null
        ? <Map<String, dynamic>>[]
        : (existing?.entries ?? <Map<String, dynamic>>[])
              .where((entry) => !selected.contains(entry['venue']))
              .toList();
    if (retained.isNotEmpty &&
        existing!.licenseDigest != remote.licenseDigest) {
      throw StateError(
        'The plugin license changed. Select all installed exchanges to update them together.',
      );
    }
    final downloaded = remote.entries
        .where((entry) => selected.contains(entry['venue']))
        .toList();
    final combined = [...retained, ...downloaded]
      ..sort((a, b) => (a['venue'] as String).compareTo(b['venue'] as String));
    if (combined.length > 32) {
      throw const FormatException('Too many installed CEX plugins');
    }
    final manifest = utf8.encode(
      jsonEncode({
        'schema': 1,
        'protocol': 1,
        'license_sha256': remote.licenseDigest,
        'plugins': combined,
      }),
    );
    final name = venues == null
        ? commit
        : '$commit-${sha256.convert(manifest)}';
    final root = await _root;
    var parent = root;
    while (true) {
      if (await FileSystemEntity.isLink(parent.path)) {
        throw const FormatException('Unsafe plugin storage');
      }
      final next = parent.parent;
      if (next.path == parent.path) break;
      parent = next;
    }
    await root.create(recursive: true);
    final staging = await root.createTemp('.download-');
    try {
      final license = await _file(commit, 'LICENSE', 65536);
      if (sha256.convert(license).toString() != remote.licenseDigest) {
        throw const FormatException('Plugin license checksum mismatch');
      }
      await File(
        p.join(staging.path, 'LICENSE'),
      ).writeAsBytes(license, flush: true);
      var count = 0;
      for (final item in downloaded) {
        onStage?.call(
          'Downloading ${item['venue']} plugin (${++count}/${downloaded.length})…',
        );
        for (final field in ['config', 'adapter']) {
          final name = item[field] as String;
          final bytes = await _file(
            commit,
            name,
            field == 'config' ? 16384 : 1024 * 1024,
          );
          if (sha256.convert(bytes).toString() != item['${field}_sha256']) {
            throw const FormatException('CEX plugin checksum mismatch');
          }
          final file = File(p.join(staging.path, name));
          await file.parent.create(recursive: true);
          await file.writeAsBytes(bytes, flush: true);
        }
      }
      // Carry unselected installed plugins forward unchanged. Verify their
      // bytes again before activation; never fetch their adapters or configs.
      for (final item in retained) {
        for (final field in ['config', 'adapter']) {
          final source = File(
            p.join(existing!.directory.path, item[field] as String),
          );
          var parent = source.parent;
          while (true) {
            if (await FileSystemEntity.isLink(parent.path)) {
              throw const FormatException('Unsafe retained CEX plugin parent');
            }
            final next = parent.parent;
            if (next.path == parent.path) break;
            parent = next;
          }
          if (await FileSystemEntity.isLink(source.path) ||
              await source.length() >
                  (field == 'config' ? 16384 : 1024 * 1024)) {
            throw const FormatException('Unsafe retained CEX plugin');
          }
          final bytes = await source.readAsBytes();
          if (sha256.convert(bytes).toString() != item['${field}_sha256']) {
            throw const FormatException(
              'Retained CEX plugin checksum mismatch',
            );
          }
          final target = File(p.join(staging.path, item[field] as String));
          await target.parent.create(recursive: true);
          await target.writeAsBytes(bytes, flush: true);
        }
      }
      final sources = <String, String>{
        for (final item in retained)
          item['venue'] as String:
              existing!.pluginCommits[item['venue']] ?? existing.commit,
        for (final item in downloaded) item['venue'] as String: commit,
      };
      await File(
        p.join(staging.path, 'plugin-sources.json'),
      ).writeAsString(jsonEncode(sources), flush: true);
      await File(
        p.join(staging.path, 'catalog.json'),
      ).writeAsBytes(manifest, flush: true);
      onStage?.call('Verifying CEX plugin compatibility…');
      await verify(staging, commit);
      final target = Directory(p.join(root.path, name));
      final targetType = await FileSystemEntity.type(
        target.path,
        followLinks: false,
      );
      if (targetType != FileSystemEntityType.notFound) {
        var valid = false;
        try {
          await verify(target, commit);
          valid =
              venues == null ||
              sha256
                      .convert(
                        await File(
                          p.join(target.path, 'catalog.json'),
                        ).readAsBytes(),
                      )
                      .toString() ==
                  sha256.convert(manifest).toString();
        } on FormatException {
          // Replacement staging was fully verified above; retain the bad copy.
        } on FileSystemException {
          // Missing/unreadable installed content can also be repaired explicitly.
        }
        if (!valid) {
          final quarantine = await root.createTemp('.quarantine-');
          final saved = p.join(quarantine.path, 'snapshot');
          switch (targetType) {
            case FileSystemEntityType.directory:
              await target.rename(saved);
            case FileSystemEntityType.link:
              await Link(target.path).rename(saved);
            default:
              await File(target.path).rename(saved);
          }
          try {
            await staging.rename(target.path);
          } catch (_) {
            // Preserve the old pointer and restore its entry if installation fails.
            switch (targetType) {
              case FileSystemEntityType.directory:
                await Directory(saved).rename(target.path);
              case FileSystemEntityType.link:
                await Link(saved).rename(target.path);
              default:
                await File(saved).rename(target.path);
            }
            rethrow;
          }
        }
      } else {
        await staging.rename(target.path);
      }
      final pointer = File(p.join(root.path, '.current-new'));
      if (await FileSystemEntity.isLink(pointer.path)) {
        throw const FormatException('Unsafe plugin pointer');
      }
      await pointer.writeAsString('$name\n', flush: true);
      await pointer.rename(p.join(root.path, 'current'));
      return await verify(target, commit);
    } finally {
      if (await staging.exists()) await staging.delete(recursive: true);
    }
  }

  Future<List<int>> _file(String commit, String path, int limit) => _get(
    Uri.parse('https://raw.githubusercontent.com/$repository/$commit/$path'),
    limit,
  );

  Future<List<int>> _get(Uri uri, int limit) async {
    final request = http.Request('GET', uri)
      ..headers.addAll({
        'Accept': 'application/vnd.github+json',
        'User-Agent': 'P2Pirate-Desktop',
      });
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 45));
    if (response.statusCode != 200) {
      throw StateError(
        'CEX plugin download returned HTTP ${response.statusCode}',
      );
    }
    final deadline = Stopwatch()..start();
    final bytes = <int>[];
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 45),
    )) {
      if (deadline.elapsed > const Duration(seconds: 90)) {
        throw StateError('Plugin download deadline exceeded');
      }
      if (bytes.length + chunk.length > limit) {
        throw const FormatException('Plugin file too large');
      }
      bytes.addAll(chunk);
    }
    return bytes;
  }

  static (List<Map<String, dynamic>>, String) _manifest(List<int> bytes) {
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map ||
        data['schema'] != 1 ||
        data['protocol'] != 1 ||
        data.keys.toSet().difference({
          'schema',
          'protocol',
          'license_sha256',
          'plugins',
        }).isNotEmpty ||
        data['license_sha256'] is! String ||
        !_digest.hasMatch(data['license_sha256'])) {
      throw const FormatException('Incompatible CEX plugin catalog');
    }
    final raw = data['plugins'];
    if (raw is! List || raw.isEmpty || raw.length > 32) {
      throw const FormatException('Invalid plugin count');
    }
    final venues = <String>{};
    final entries = <Map<String, dynamic>>[];
    for (final item in raw) {
      if (item is! Map ||
          item.length != 6 ||
          item['venue'] is! String ||
          !RegExp(r'^[A-Z][A-Z0-9_]{0,31}$').hasMatch(item['venue']) ||
          !venues.add(item['venue']) ||
          item['version'] is! String ||
          !RegExp(r'^\d+\.\d+\.\d+$').hasMatch(item['version'])) {
        throw const FormatException('Invalid plugin identity');
      }
      final slug = (item['venue'] as String).toLowerCase().replaceAll('_', '-');
      if (item['config'] != 'plugins/$slug/config.json' ||
          item['adapter'] != 'plugins/$slug/adapter.zip' ||
          item['config_sha256'] is! String ||
          !_digest.hasMatch(item['config_sha256']) ||
          item['adapter_sha256'] is! String ||
          !_digest.hasMatch(item['adapter_sha256'])) {
        throw const FormatException('Invalid plugin paths or checksums');
      }
      entries.add(Map<String, dynamic>.from(item));
    }
    return (entries, data['license_sha256'] as String);
  }

  static Future<CexPluginSnapshot> verify(
    Directory directory,
    String commit,
  ) async {
    if (await FileSystemEntity.isLink(directory.path)) {
      throw const FormatException('Unsafe plugin directory');
    }
    Future<List<int>> read(String name, int max) async {
      final file = File(p.join(directory.path, name));
      var parent = file.parent;
      while (true) {
        if (await FileSystemEntity.isLink(parent.path)) {
          throw const FormatException('Unsafe plugin parent');
        }
        final next = parent.parent;
        if (next.path == parent.path) break;
        parent = next;
      }
      if (await FileSystemEntity.isLink(file.path) ||
          !await file.exists() ||
          await file.length() > max) {
        throw const FormatException('Plugin file missing, unsafe or too large');
      }
      return file.readAsBytes();
    }

    final manifest = _manifest(await read('catalog.json', 65536));
    if (sha256.convert(await read('LICENSE', 65536)).toString() !=
        manifest.$2) {
      throw const FormatException('Invalid plugin license');
    }
    final labels = <String, String>{};
    for (final item in manifest.$1) {
      final configBytes = await read(item['config'], 16384);
      final adapter = await read(item['adapter'], 1024 * 1024);
      if (sha256.convert(configBytes).toString() != item['config_sha256'] ||
          sha256.convert(adapter).toString() != item['adapter_sha256']) {
        throw const FormatException('Installed plugin checksum mismatch');
      }
      final config = jsonDecode(utf8.decode(configBytes));
      validateConfiguration(config, item['venue'], item['version']);
      // Inspect headers without decompressing untrusted content (including links).
      final archive = ZipDirectory()..read(InputMemoryStream(adapter));
      final names = <String>{};
      var size = 0;
      for (final file in archive.fileHeaders) {
        size += file.uncompressedSize;
        if (!names.add(file.filename) ||
            ((file.externalFileAttributes >> 16) & 0xf000) == 0xa000 ||
            !RegExp(
              r'^cex_plugin/(?:[a-z][a-z0-9_]*|__init__)\.py$',
            ).hasMatch(file.filename)) {
          throw const FormatException('Unsafe plugin source bundle');
        }
      }
      if (names.length > 64 ||
          size > 3 * 1024 * 1024 ||
          !names.contains('cex_plugin/adapter.py')) {
        throw const FormatException('Invalid plugin source bundle');
      }
      labels[item['venue']] = config['display_name'];
    }
    final sourcesFile = File(p.join(directory.path, 'plugin-sources.json'));
    final sources = <String, String>{
      for (final venue in labels.keys) venue: commit,
    };
    if (await FileSystemEntity.type(sourcesFile.path, followLinks: false) !=
        FileSystemEntityType.notFound) {
      final decoded = jsonDecode(
        utf8.decode(await read('plugin-sources.json', 8192)),
      );
      if (decoded is! Map ||
          decoded.length != labels.length ||
          decoded.keys.any((key) => !labels.containsKey(key)) ||
          decoded.values.any(
            (value) => value is! String || !_commit.hasMatch(value),
          )) {
        throw const FormatException('Invalid CEX plugin source metadata');
      }
      sources.addAll(Map<String, String>.from(decoded));
    }
    return CexPluginSnapshot(
      directory,
      commit,
      Map<String, String>.unmodifiable(labels),
      entries: List<Map<String, dynamic>>.unmodifiable(
        manifest.$1.map(Map<String, dynamic>.unmodifiable),
      ),
      licenseDigest: manifest.$2,
      pluginCommits: Map<String, String>.unmodifiable(sources),
    );
  }

  static void validateConfiguration(
    dynamic data,
    String venue,
    String version,
  ) {
    const expected = {
      'schema',
      'protocol',
      'version',
      'venue',
      'display_name',
      'base_url',
      'legacy_keys',
      'private_read_timeout',
      'time_sync_budget_ms',
      'recv_window_ms',
      'timestamp_error_codes',
      'symbols_error_codes',
      'taker_fee',
      'credential_fields',
      'settings',
    };
    if (data is! Map ||
        data.length != expected.length ||
        data.keys.toSet().difference(expected).isNotEmpty) {
      throw const FormatException('Invalid CEX configuration fields');
    }
    final url = data['base_url'] is String
        ? Uri.tryParse(data['base_url'])
        : null;
    final fee = data['taker_fee'] is String
        ? Decimal.tryParse(data['taker_fee'])
        : null;
    bool bounded(String key, num limit) =>
        data[key] is num && data[key] > 0 && data[key] <= limit;
    if (data['schema'] != 1 ||
        data['protocol'] != 'p2pirate-spot-v1' ||
        data['venue'] != venue ||
        data['version'] != version ||
        data['display_name'] is! String ||
        (data['display_name'] as String).isEmpty ||
        (data['display_name'] as String).length > 64 ||
        url == null ||
        url.scheme != 'https' ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment ||
        ['localhost', '127.0.0.1', '::1'].contains(url.host) ||
        data['legacy_keys'] != (venue == 'MEXC') ||
        data['legacy_keys'] is! bool ||
        !bounded('private_read_timeout', 10) ||
        data['time_sync_budget_ms'] is! int ||
        !bounded('time_sync_budget_ms', 12000) ||
        data['recv_window_ms'] is! int ||
        !bounded('recv_window_ms', 60000) ||
        fee == null ||
        fee < Decimal.zero ||
        fee >= Decimal.one ||
        jsonEncode(data['credential_fields']) != '["api_key","api_secret"]' ||
        data['settings'] is! Map) {
      throw const FormatException('Incompatible Spot plugin configuration');
    }
    for (final key in ['timestamp_error_codes', 'symbols_error_codes']) {
      final list = data[key];
      if (list is! List ||
          list.length > 32 ||
          list.any((v) => v is! String || v.length > 64)) {
        throw const FormatException('Invalid plugin error policy');
      }
    }
    void publicOnly(dynamic value) {
      if (value is Map) {
        for (final entry in value.entries) {
          final key = entry.key.toString().toLowerCase().replaceAll('-', '_');
          if ([
            'api_key',
            'api_secret',
            'password',
            'passphrase',
            'token',
          ].any(key.contains)) {
            throw const FormatException(
              'Credentials do not belong in public CEX files',
            );
          }
          publicOnly(entry.value);
        }
      } else if (value is List) {
        for (final child in value) {
          publicOnly(child);
        }
      }
    }

    publicOnly(data['settings']);
  }
}

class CexPluginSnapshot {
  const CexPluginSnapshot(
    this.directory,
    this.commit,
    this.labels, {
    this.entries = const [],
    this.licenseDigest = '',
    this.pluginCommits = const {},
  });
  final Directory directory;
  final String commit;
  final Map<String, String> labels;
  final List<Map<String, dynamic>> entries;
  final String licenseDigest;
  final Map<String, String> pluginCommits;
}

class CexPluginCatalog {
  CexPluginCatalog(
    this.commit,
    List<Map<String, dynamic>> entries,
    this.licenseDigest,
  ) : entries = List.unmodifiable(
        entries.map((entry) => Map<String, dynamic>.unmodifiable(entry)),
      );
  final String commit;
  final List<Map<String, dynamic>> entries;
  final String licenseDigest;
}
