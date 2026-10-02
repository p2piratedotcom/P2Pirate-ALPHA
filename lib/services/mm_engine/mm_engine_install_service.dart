import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:web_dex/bloc/settings/settings_repository.dart';
import 'package:web_dex/services/tor/pirate_tor_service.dart';

/// Installs a verified, immutable MM_Engine release for the current user.
/// No executable from the network is launched before its digest is checked.
class MmEngineInstallService {
  static const _repositoryId = 1401685191;
  static const _apiBase =
      'https://api.github.com/repos/p2piratedotcom/MM_Engine';
  static const _assetName = 'mm-engine-linux-x86_64';
  static const _maxBinaryBytes = 500 * 1024 * 1024;

  static Future<Directory> _installRoot() async {
    final support = await getApplicationSupportDirectory();
    return Directory(p.join(support.path, 'mm-engine', 'releases'));
  }

  static Future<File?> currentExecutable() async {
    if (!Platform.isLinux || Abi.current() != Abi.linuxX64) return null;
    final root = await _installRoot();
    final pointer = File(p.join(root.path, 'current.json'));
    if (!await pointer.exists() ||
        await FileSystemEntity.isLink(pointer.path)) {
      return null;
    }
    try {
      final metadata = jsonDecode(await pointer.readAsString());
      if (metadata is! Map<String, dynamic>) return null;
      final tag = metadata['tag'];
      final digest = metadata['sha256'];
      final noticesDigest = metadata['notices_sha256'];
      if (!_validTag(tag) ||
          !_validDigest(digest) ||
          !_validDigest(noticesDigest)) {
        return null;
      }
      final executable = File(p.join(root.path, tag, _assetName));
      final notices = File(p.join(root.path, tag, 'THIRD_PARTY_NOTICES.txt'));
      if (!await executable.exists() ||
          await FileSystemEntity.isLink(executable.path) ||
          !await notices.exists() ||
          await FileSystemEntity.isLink(notices.path)) {
        return null;
      }
      final actual = (await sha256.bind(executable.openRead()).first)
          .toString();
      final noticeActual = (await sha256.bind(notices.openRead()).first)
          .toString();
      return actual == digest && noticeActual == noticesDigest
          ? executable
          : null;
    } catch (_) {
      return null;
    }
  }

  static Future<MmEngineRelease> latestRelease() async {
    _requirePlatform();
    final repository = await _getJson(Uri.parse(_apiBase));
    if (repository['id'] != _repositoryId ||
        repository['full_name'] != 'p2piratedotcom/MM_Engine') {
      throw StateError('MM_Engine repository identity has changed');
    }
    final release = await _getJson(Uri.parse('$_apiBase/releases/latest'));
    if (release['immutable'] != true ||
        release['draft'] != false ||
        release['prerelease'] != false) {
      throw StateError('No verified immutable MM_Engine release is available');
    }
    final tag = release['tag_name'];
    if (tag is! String || !_validTag(tag)) {
      throw StateError('Invalid MM_Engine release tag');
    }
    final assets = release['assets'];
    if (assets is! List) throw StateError('MM_Engine release has no assets');
    final matches = assets
        .where(
          (asset) =>
              asset is Map<String, dynamic> && asset['name'] == _assetName,
        )
        .toList();
    if (matches.length != 1) {
      throw StateError('MM_Engine Linux x64 binary is missing');
    }
    final asset = matches.single as Map<String, dynamic>;
    final digest = asset['digest'];
    final url = Uri.tryParse(asset['browser_download_url']?.toString() ?? '');
    if (digest is! String ||
        !digest.startsWith('sha256:') ||
        !_validDigest(digest.substring(7)) ||
        url == null ||
        url.scheme != 'https' ||
        url.host != 'github.com' ||
        !url.path.startsWith(
          '/p2piratedotcom/MM_Engine/releases/download/$tag/',
        )) {
      throw StateError('MM_Engine asset metadata is invalid');
    }
    final size = asset['size'];
    if (size is! int || size < 1 || size > _maxBinaryBytes) {
      throw StateError('MM_Engine asset size is invalid');
    }
    final manifestMatches = assets
        .where(
          (item) =>
              item is Map<String, dynamic> &&
              item['name'] == 'compatibility.json',
        )
        .toList();
    if (manifestMatches.length != 1) {
      throw StateError('MM_Engine compatibility manifest is missing');
    }
    final manifestAsset = manifestMatches.single as Map<String, dynamic>;
    final manifestDigest = manifestAsset['digest'];
    final manifestUrl = Uri.tryParse(
      manifestAsset['browser_download_url']?.toString() ?? '',
    );
    if (manifestDigest is! String ||
        !manifestDigest.startsWith('sha256:') ||
        !_validDigest(manifestDigest.substring(7)) ||
        manifestUrl == null ||
        manifestUrl.scheme != 'https' ||
        manifestUrl.host != 'github.com' ||
        manifestUrl.path !=
            '/p2piratedotcom/MM_Engine/releases/download/$tag/compatibility.json') {
      throw StateError('MM_Engine manifest metadata is invalid');
    }
    final manifest = await _getJson(
      manifestUrl,
      expectedDigest: manifestDigest.substring(7),
      maxBytes: 65536,
    );
    final commit = manifest['source_commit'];
    if (manifest['schema'] != 1 ||
        manifest['version'] != tag ||
        manifest['platform'] != 'linux' ||
        manifest['architecture'] != 'x86_64' ||
        manifest['wallet_protocol'] != 1 ||
        manifest['kdf_major_minor'] != '2.7' ||
        manifest['binary'] != _assetName ||
        manifest['binary_sha256'] != digest.substring(7) ||
        commit is! String ||
        !RegExp(r'^[0-9a-f]{40}$').hasMatch(commit)) {
      throw StateError('MM_Engine release is incompatible with this wallet');
    }
    final noticeMatches = assets
        .where(
          (item) =>
              item is Map<String, dynamic> &&
              item['name'] == 'THIRD_PARTY_NOTICES.txt',
        )
        .toList();
    if (noticeMatches.length != 1) {
      throw StateError('MM_Engine third-party notices are missing');
    }
    final noticeAsset = noticeMatches.single as Map<String, dynamic>;
    final noticeDigest = noticeAsset['digest'];
    final noticeSize = noticeAsset['size'];
    final noticeUrl = Uri.tryParse(
      noticeAsset['browser_download_url']?.toString() ?? '',
    );
    if (noticeDigest is! String ||
        !noticeDigest.startsWith('sha256:') ||
        !_validDigest(noticeDigest.substring(7)) ||
        noticeSize is! int ||
        noticeSize < 1 ||
        noticeSize > 2 * 1024 * 1024 ||
        noticeUrl == null ||
        noticeUrl.scheme != 'https' ||
        noticeUrl.host != 'github.com' ||
        noticeUrl.path !=
            '/p2piratedotcom/MM_Engine/releases/download/$tag/THIRD_PARTY_NOTICES.txt') {
      throw StateError('MM_Engine third-party notices are invalid');
    }
    return MmEngineRelease(
      tag,
      digest.substring(7),
      url,
      size,
      noticeUrl,
      noticeDigest.substring(7),
      noticeSize,
    );
  }

  /// Call only after the user explicitly accepts the displayed release.
  static Future<File> install(MmEngineRelease release) async {
    _requirePlatform();
    final root = await _installRoot();
    await root.create(recursive: true);
    await _chmod(root.path, '700');
    final version = Directory(p.join(root.path, release.tag));
    await version.create(recursive: true);
    await _chmod(version.path, '700');
    final temp = File(p.join(version.path, '$_assetName.part'));
    final executable = File(p.join(version.path, _assetName));
    final noticeTemp = File(
      p.join(version.path, 'THIRD_PARTY_NOTICES.txt.part'),
    );
    final notices = File(p.join(version.path, 'THIRD_PARTY_NOTICES.txt'));
    if (await FileSystemEntity.isLink(temp.path) ||
        await FileSystemEntity.isLink(executable.path) ||
        await FileSystemEntity.isLink(noticeTemp.path) ||
        await FileSystemEntity.isLink(notices.path)) {
      throw StateError('MM_Engine installation path is unsafe');
    }
    try {
      await _download(release.url, temp, release.size, _maxBinaryBytes);
      final actual = (await sha256.bind(temp.openRead()).first).toString();
      if (actual != release.sha256) {
        throw StateError('MM_Engine SHA-256 verification failed');
      }
      await _download(
        release.noticeUrl,
        noticeTemp,
        release.noticeSize,
        2 * 1024 * 1024,
      );
      final noticeActual = (await sha256.bind(noticeTemp.openRead()).first)
          .toString();
      if (noticeActual != release.noticeSha256) {
        throw StateError('MM_Engine notices SHA-256 verification failed');
      }
      await _chmod(temp.path, '700');
      await temp.rename(executable.path);
      await _chmod(noticeTemp.path, '600');
      await noticeTemp.rename(notices.path);
      final pointerTemp = File(p.join(root.path, 'current.json.part'));
      if (await FileSystemEntity.isLink(pointerTemp.path)) {
        throw StateError('MM_Engine metadata path is unsafe');
      }
      await pointerTemp.writeAsString(
        jsonEncode({
          'tag': release.tag,
          'sha256': release.sha256,
          'notices_sha256': release.noticeSha256,
        }),
        flush: true,
      );
      await _chmod(pointerTemp.path, '600');
      await pointerTemp.rename(p.join(root.path, 'current.json'));
      return executable;
    } finally {
      if (await temp.exists()) await temp.delete();
      if (await noticeTemp.exists()) await noticeTemp.delete();
    }
  }

  static Future<void> _download(Uri url, File target, int size, int max) async {
    final client = await _client();
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.userAgentHeader, 'P2Pirate-MM-Engine');
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException('Download failed (${response.statusCode})');
      }
      final output = target.openWrite();
      var received = 0;
      try {
        await for (final chunk in response) {
          received += chunk.length;
          if (received > max || received > size) {
            throw StateError('MM_Engine download exceeded expected size');
          }
          output.add(chunk);
        }
        await output.flush();
      } finally {
        await output.close();
      }
      if (received != size) {
        throw StateError('MM_Engine download is incomplete');
      }
    } finally {
      client.close(force: true);
    }
  }

  static Future<Map<String, dynamic>> _getJson(
    Uri url, {
    String? expectedDigest,
    int maxBytes = 1024 * 1024,
  }) async {
    final client = await _client();
    try {
      final request = await client.getUrl(url);
      request.headers.set(HttpHeaders.userAgentHeader, 'P2Pirate-MM-Engine');
      request.headers.set(
        HttpHeaders.acceptHeader,
        'application/vnd.github+json',
      );
      final response = await request.close();
      if (response.statusCode != HttpStatus.ok) {
        throw HttpException(
          'GitHub release lookup failed (${response.statusCode})',
        );
      }
      final bytes = <int>[];
      await for (final chunk in response) {
        bytes.addAll(chunk);
        if (bytes.length > maxBytes) {
          throw StateError('GitHub release metadata is too large');
        }
      }
      if (expectedDigest != null &&
          sha256.convert(bytes).toString() != expectedDigest) {
        throw StateError('MM_Engine manifest SHA-256 verification failed');
      }
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw StateError('Invalid GitHub release metadata');
      }
      return decoded;
    } finally {
      client.close(force: true);
    }
  }

  static Future<HttpClient> _client() async {
    final stored = await SettingsRepository.loadStoredSettings();
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20)
      ..idleTimeout = const Duration(seconds: 20);
    if (stored.torEnabled) {
      final proxyPort = PirateTorService.instance.httpProxyPort;
      if (proxyPort == null) {
        client.close(force: true);
        throw StateError('Tor is enabled but its HTTP bridge is unavailable');
      }
      client.findProxy = (_) => 'PROXY 127.0.0.1:$proxyPort';
    }
    return client;
  }

  static void _requirePlatform() {
    if (!Platform.isLinux || Abi.current() != Abi.linuxX64) {
      throw UnsupportedError('MM_Engine is currently available for Linux x64');
    }
  }

  static bool _validTag(Object? tag) =>
      tag is String && RegExp(r'^v[0-9]+\.[0-9]+\.[0-9]+$').hasMatch(tag);

  static bool _validDigest(Object? digest) =>
      digest is String && RegExp(r'^[0-9a-f]{64}$').hasMatch(digest);

  static Future<void> _chmod(String path, String mode) async {
    final result = await Process.run('chmod', [mode, path]);
    if (result.exitCode != 0) {
      throw StateError('Cannot protect MM_Engine installation files');
    }
  }
}

class MmEngineRelease {
  const MmEngineRelease(
    this.tag,
    this.sha256,
    this.url,
    this.size,
    this.noticeUrl,
    this.noticeSha256,
    this.noticeSize,
  );

  final String tag;
  final String sha256;
  final Uri url;
  final int size;
  final Uri noticeUrl;
  final String noticeSha256;
  final int noticeSize;
}
