import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Reviewed KDF 2.7 asset. Update the URL and both digests together after
/// reviewing the new binary, source revision, compatibility and license.
class KdfInstallService {
  static const version = 'v2.7.0-beta-968f32a';
  static const sourceRepository =
      'https://github.com/ShorelineCrypto/komodo-defi-framework';
  static final archiveUri = Uri.parse(
    '$sourceRepository/releases/download/v2.7.0-beta/'
    'kdf_968f32a-linux-x86-64.zip',
  );
  static const archiveSha256 =
      'cf80e5d5ae78605d6f0f6a806aa9ae5b83bbee0ef79ccd5ad85022ae2a5d7d27';
  static const executableSha256 =
      'bd171eeee7a1e0d43b070c8ba6ba60a845a26b3db0ef57ca25a394a2b6c02129';

  static String get installRoot => p.join(
    Platform.environment['HOME'] ?? '',
    '.local',
    'share',
    'p2pirate',
    'kdf',
  );

  static Future<bool> hasExecutable() async {
    if (!Platform.isLinux) return true;
    final configured = Platform.environment['P2PIRATE_KDF_PATH']?.trim();
    if (configured != null && configured.isNotEmpty) {
      // The SDK reports an invalid explicit path rather than overriding it.
      return true;
    }
    final home = Platform.environment['HOME'];
    if (home == null || home.isEmpty) return false;
    for (final path in [
      p.join(installRoot, 'current', 'kdf'),
      '/usr/local/bin/kdf',
      '/usr/bin/kdf',
      p.join(home, '.local', 'bin', 'kdf'),
    ]) {
      final file = File(path);
      if (await file.exists() && (await file.stat()).mode & 0x49 != 0) {
        return true;
      }
    }
    return false;
  }

  Future<void> install() async {
    if (Abi.current() != Abi.linuxX64) {
      throw UnsupportedError(
        'Automatic KDF installation supports Linux x86-64 only',
      );
    }
    if (!Platform.isLinux || Platform.environment['HOME']?.isEmpty != false) {
      throw StateError('A Linux home directory is required');
    }
    final root = Directory(installRoot);
    await root.create(recursive: true);
    final finalDir = Directory(p.join(root.path, version));
    final installed = File(p.join(finalDir.path, 'kdf'));
    if (!await installed.exists() ||
        await _fileHash(installed) != executableSha256) {
      final staging = await Directory(root.path).createTemp('.install-');
      try {
        final archiveFile = File(p.join(staging.path, 'kdf.zip'));
        await _download(archiveFile);
        if (await _fileHash(archiveFile) != archiveSha256) {
          throw StateError('KDF archive checksum mismatch');
        }
        final archive = ZipDecoder().decodeBytes(
          await archiveFile.readAsBytes(),
        );
        final matching = archive.files
            .where(
              (entry) =>
                  entry.isFile &&
                  (entry.name == 'kdf' || entry.name.endsWith('/kdf')),
            )
            .toList();
        if (matching.length != 1) {
          throw StateError('KDF archive does not contain one executable');
        }
        if (matching.single.size > 100 * 1024 * 1024) {
          throw StateError('KDF executable is larger than expected');
        }
        final extracted = File(p.join(staging.path, 'kdf'));
        await extracted.writeAsBytes(matching.single.content, flush: true);
        if (await _fileHash(extracted) != executableSha256) {
          throw StateError('KDF executable checksum mismatch');
        }
        final chmod = await Process.run('chmod', ['700', extracted.path]);
        if (chmod.exitCode != 0) {
          throw StateError('Could not make KDF executable');
        }
        if (await finalDir.exists()) {
          throw StateError(
            'A different KDF installation already uses $version',
          );
        }
        await finalDir.create();
        try {
          await extracted.rename(installed.path);
        } catch (_) {
          await finalDir.delete(recursive: true);
          rethrow;
        }
      } finally {
        if (await staging.exists()) await staging.delete(recursive: true);
      }
    }

    // Only switch the active version after both checks and installation pass.
    final next = Link(p.join(root.path, '.current-next'));
    if (await next.exists()) await next.delete();
    await next.create(version);
    final current = Link(p.join(root.path, 'current'));
    try {
      await next.rename(current.path);
    } catch (_) {
      if (await next.exists()) await next.delete();
      rethrow;
    }
  }

  Future<void> _download(File target) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 20);
    try {
      var uri = archiveUri;
      HttpClientResponse? response;
      for (var redirects = 0; redirects < 6; redirects++) {
        if (uri.scheme != 'https' ||
            !(uri.host == 'github.com' ||
                uri.host.endsWith('.githubusercontent.com'))) {
          throw StateError('KDF download redirected outside GitHub HTTPS');
        }
        final request = await client.getUrl(uri);
        request.followRedirects = false;
        response = await request.close().timeout(const Duration(minutes: 2));
        if (response.statusCode < 300 || response.statusCode >= 400) break;
        final location = response.headers.value(HttpHeaders.locationHeader);
        await response.drain<void>();
        if (location == null) {
          throw StateError('KDF download redirect is invalid');
        }
        uri = uri.resolve(location);
        response = null;
      }
      if (response?.statusCode != HttpStatus.ok) {
        throw StateError('The official KDF download is unavailable over HTTPS');
      }
      final sink = target.openWrite();
      var bytes = 0;
      try {
        await for (final chunk in response!.timeout(
          const Duration(minutes: 5),
        )) {
          bytes += chunk.length;
          if (bytes > 200 * 1024 * 1024) {
            throw StateError('KDF archive is larger than expected');
          }
          sink.add(chunk);
        }
        await sink.flush();
      } finally {
        await sink.close();
      }
    } finally {
      client.close(force: true);
    }
  }

  Future<String> _fileHash(File file) async =>
      (await sha256.bind(file.openRead()).first).toString();
}
