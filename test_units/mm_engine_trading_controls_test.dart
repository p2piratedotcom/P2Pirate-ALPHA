import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/app_config/app_config.dart';
import 'package:web_dex/services/mm_engine/mm_engine_http_client.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_trading_controls.dart';

void main() {
  test(
    'modification approval cannot cross an awaited session refresh',
    () async {
      var currentSession = true;
      final writes = <String>[];
      await expectLater(
        saveMmEnginePausedMaker(
          spec: const {'strategy_id': 'paused-fixture'},
          modifying: true,
          isCurrentSession: () => currentSession,
          verifyModification: () async {
            await Future<void>.delayed(Duration.zero);
            currentSession = false;
          },
          request: (method, path, {required body}) async {
            writes.add(path);
            return {};
          },
        ),
        throwsStateError,
      );
      expect(writes, isEmpty);
      currentSession = true;
      await saveMmEnginePausedMaker(
        spec: const {'strategy_id': 'paused-fixture'},
        modifying: true,
        isCurrentSession: () => currentSession,
        verifyModification: () async {},
        request: (method, path, {required body}) async {
          expect(body['confirmation'], 'AGGIORNA IN PAUSA');
          writes.add(path);
          return {};
        },
      );
      expect(writes, ['/v1/strategies/update']);
    },
  );
  test('display title and live notice describe separate order activation', () {
    expect(appTitle, 'P2Pirate | Desktop');
    expect(mmEngineStartLiveNotice, contains('keeps all orders paused'));
    expect(mmEngineStartLiveNotice, contains('Start selected orders'));
    expect(
      mmEngineStartLiveNotice,
      isNot(contains('All paused strategies will be started')),
    );
    expect(
      const MmEngineRequestException('MM_Engine failed', 500).toString(),
      'P2Pirate Trading Engine failed',
    );
    expect(
      const MmEngineRequestException('MM_engine failed', 500).toString(),
      'P2Pirate Trading Engine failed',
    );
  });

  for (final enabled in [true, false]) {
    test(
      'live permission $enabled pauses persisted orders before startup',
      () async {
        final events = <String>[];
        var previouslyEnabled = true;
        await switchMmEngineTradingMode(
          enabled: enabled,
          request: (method, path, {required body}) async {
            expect(method, 'POST');
            expect(path, '/v1/strategies/pause-all');
            expect(body, {'confirmation': 'PAUSA TUTTE'});
            previouslyEnabled = false;
            events.add('pause');
            return {};
          },
          stop: () async => events.add('stop'),
          clearLivePreference: () async => events.add('clear'),
          start: (live) async {
            expect(previouslyEnabled, isFalse);
            expect(live, enabled);
            events.add('start');
          },
        );
        expect(
          events,
          enabled
              ? ['pause', 'stop', 'start']
              : ['pause', 'stop', 'clear', 'start'],
        );
      },
    );
  }

  test('failed pausing blocks permission change and engine startup', () async {
    var started = false;
    var stopped = false;
    await expectLater(
      switchMmEngineTradingMode(
        enabled: true,
        request: (_, _, {required body}) async =>
            throw StateError('withdrawal uncertain'),
        stop: () async {
          stopped = true;
        },
        start: (_) async {
          started = true;
        },
        clearLivePreference: () async {},
      ),
      throwsStateError,
    );
    expect(started, isFalse);
    expect(stopped, isFalse);
  });

  test(
    'in-flight swaps block stop/start and preserve live preference',
    () async {
      var started = false;
      var cleared = false;
      await expectLater(
        switchMmEngineTradingMode(
          enabled: false,
          request: (_, _, {required body}) async => {},
          stop: () async => throw StateError('active swap'),
          start: (_) async {
            started = true;
          },
          clearLivePreference: () async {
            cleared = true;
          },
        ),
        throwsStateError,
      );
      expect(started, isFalse);
      expect(cleared, isFalse);
    },
  );

  test('only clean, disabled, unpublished PAUSED orders are selectable', () {
    final rows = [
      {'id': 'clean', 'enabled': 0, 'state': 'PAUSED'},
      {'id': 'published', 'enabled': 0, 'state': 'PAUSED'},
      {'id': 'running', 'enabled': 1, 'state': 'WAITING'},
      for (final state in [
        'WRITING',
        'REVIEW_REQUIRED',
        'EXHAUSTED',
        'DELETED',
      ])
        {'id': state, 'enabled': 0, 'state': state},
    ];
    expect(
      startableMakerOrderIds(rows, [
        {'strategy_id': 'published'},
      ]),
      {'clean'},
    );
  });

  test(
    'activation sends exactly the selected orders once with individual confirmations',
    () async {
      final sent = <String>[];
      final result = await startSelectedMakerOrders(
        ids: ['two', 'one', 'two'],
        eligible: {'one', 'two', 'unselected'},
        live: true,
        request: (method, path, {required body}) async {
          final id = body['strategy_id'] as String;
          expect(method, 'POST');
          expect(path, '/v1/strategies/start');
          expect(body['confirmation'], 'AVVIA $id');
          sent.add(id);
          return {};
        },
      );
      expect(sent, ['two', 'one']);
      expect(result.started, {'two', 'one'});
      expect(result.error, isNull);
    },
  );

  test(
    'preview mode and invalid selections never send activation requests',
    () async {
      var calls = 0;
      for (final ids in [
        <String>[],
        ['bad'],
        ['good', 'bad'],
      ]) {
        await expectLater(
          startSelectedMakerOrders(
            ids: ids,
            eligible: {'good'},
            live: true,
            request: (_, _, {required body}) async {
              calls++;
              return {};
            },
          ),
          throwsStateError,
        );
      }
      await expectLater(
        startSelectedMakerOrders(
          ids: ['good'],
          eligible: {'good'},
          live: false,
          request: (_, _, {required body}) async {
            calls++;
            return {};
          },
        ),
        throwsStateError,
      );
      expect(calls, 0);
    },
  );

  test(
    'an ambiguous failure stops the batch without retrying or claiming full success',
    () async {
      final sent = <String>[];
      final result = await startSelectedMakerOrders(
        ids: ['one', 'two', 'three'],
        eligible: {'one', 'two', 'three'},
        live: true,
        request: (_, _, {required body}) async {
          final id = body['strategy_id'] as String;
          sent.add(id);
          if (id == 'two') throw StateError('response lost');
          return {};
        },
      );
      expect(sent, ['one', 'two']);
      expect(result.started, {'one'});
      expect(result.error, isNotNull);
    },
  );
}
