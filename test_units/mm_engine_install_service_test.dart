import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/services/mm_engine/mm_engine_install_service.dart';

void main() {
  test('no local override permits normal release resolution', () async {
    expect(await MmEngineInstallService.localExecutable({}), isNull);
  });
  for (final key in ['P2PIRATE_MM_ENGINE_PATH', 'P2PIRATE_MM_ENGINE_SHA256']) {
    test('incomplete local override fails closed: $key', () async {
      await expectLater(
        MmEngineInstallService.localExecutable({key: 'value'}),
        throwsStateError,
      );
    });
  }
  test('local candidate must match supplied checksum', () async {
    final dir = await Directory.systemTemp.createTemp('mm-candidate-test-');
    addTearDown(() => dir.delete(recursive: true));
    final file = File('${dir.path}/engine');
    final bytes = [1, 2, 3];
    await file.writeAsBytes(bytes);
    final environment = {
      'P2PIRATE_MM_ENGINE_PATH': file.path,
      'P2PIRATE_MM_ENGINE_SHA256': sha256.convert(bytes).toString(),
    };
    expect(
      (await MmEngineInstallService.localExecutable(environment))?.path,
      file.path,
    );
    await file.writeAsBytes([4]);
    await expectLater(
      MmEngineInstallService.localExecutable(environment),
      throwsStateError,
    );
  });
}
