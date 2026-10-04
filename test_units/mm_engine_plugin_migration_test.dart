import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/services/mm_engine/mm_engine_plugin_migration.dart';

void main() {
  for (final available in [false, true]) {
    test(
      'recover live before clearing its preference (catalog: $available)',
      () async {
        final calls = <String>[];
        var livePreference = true;
        var recovery = true;
        await migrateCexPlugins(
          needsRecovery: recovery,
          isRunning: false,
          catalogAvailable: available,
          download: () async => calls.add('download'),
          recoverLive: () async {
            expect(livePreference, isTrue);
            calls.add('recover');
            recovery = false;
          },
          pauseAndStop: () async {
            calls.add('pause-stop');
          },
          clearLivePreference: () async {
            expect(recovery, isFalse);
            expect(calls, contains('pause-stop'));
            livePreference = false;
            calls.add('clear');
          },
          connectPreview: () async {
            expect(livePreference, isFalse);
            calls.add('preview');
          },
        );
        expect(
          calls,
          available
              ? ['recover', 'pause-stop', 'clear', 'download', 'preview']
              : ['download', 'recover', 'pause-stop', 'clear', 'preview'],
        );
      },
    );
  }
  test(
    'active-swap shutdown refusal preserves recovery and blocks preview',
    () async {
      final calls = <String>[];
      await expectLater(
        migrateCexPlugins(
          needsRecovery: true,
          isRunning: false,
          catalogAvailable: false,
          download: () async => calls.add('download'),
          recoverLive: () async => calls.add('recover'),
          pauseAndStop: () async => throw StateError('active swaps'),
          clearLivePreference: () async => calls.add('clear'),
          connectPreview: () async => calls.add('preview'),
        ),
        throwsStateError,
      );
      expect(calls, ['download', 'recover']);
    },
  );
  test('recovery failure never erases remembered live permission', () async {
    final calls = <String>[];
    await expectLater(
      migrateCexPlugins(
        needsRecovery: true,
        isRunning: false,
        catalogAvailable: true,
        download: () async => calls.add('download'),
        recoverLive: () async => throw StateError('recovery failed'),
        pauseAndStop: () async => calls.add('pause-stop'),
        clearLivePreference: () async => calls.add('clear'),
        connectPreview: () async => calls.add('preview'),
      ),
      throwsStateError,
    );
    expect(calls, isEmpty);
  });
  test('running session is stopped before replacing its snapshot', () async {
    final calls = <String>[];
    await migrateCexPlugins(
      needsRecovery: false,
      isRunning: true,
      catalogAvailable: true,
      download: () async => calls.add('download'),
      recoverLive: () async => calls.add('recover'),
      pauseAndStop: () async => calls.add('pause-stop'),
      clearLivePreference: () async => calls.add('clear'),
      connectPreview: () async => calls.add('preview'),
    );
    expect(calls, ['pause-stop', 'clear', 'download', 'preview']);
  });
  test('first preview install never invokes live recovery', () async {
    final calls = <String>[];
    await migrateCexPlugins(
      needsRecovery: false,
      isRunning: false,
      catalogAvailable: false,
      download: () async => calls.add('download'),
      recoverLive: () async => calls.add('recover'),
      pauseAndStop: () async => calls.add('pause-stop'),
      clearLivePreference: () async => calls.add('clear'),
      connectPreview: () async => calls.add('preview'),
    );
    expect(calls, ['clear', 'download', 'preview']);
  });
}
