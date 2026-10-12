import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_dashboard_read.dart';

void main() {
  for (final boundary in [
    'logout',
    'replacement wallet',
    'engine restart',
    'new generation',
    'unmount',
  ]) {
    test('drops successful dashboard replies after $boundary', () async {
      var current = true;
      final response = Completer<Map<String, dynamic>>();
      final read = readMmEngineDashboard(
        load: () => response.future,
        isCurrentSession: () => current,
      );
      current = false;
      response.complete({
        'orders': ['previous-wallet-order'],
      });
      expect(await read, isNull);
    });
    test('drops failed dashboard replies after $boundary', () async {
      var current = true;
      final response = Completer<Map<String, dynamic>>();
      final read = readMmEngineDashboard(
        load: () => response.future,
        isCurrentSession: () => current,
      );
      current = false;
      response.completeError(StateError('previous session unavailable'));
      expect(await read, isNull);
    });
  }
  test('does not request a dashboard for an already stale session', () async {
    var calls = 0;
    final read = await readMmEngineDashboard(
      load: () async {
        calls++;
        return <String, dynamic>{};
      },
      isCurrentSession: () => false,
    );
    expect(read, isNull);
    expect(calls, 0);
  });
  test('retains the exact response for the current session', () async {
    final response = {'observed_at_ms': 42, 'orders': <Object>[]};
    expect(
      await readMmEngineDashboard(
        load: () async => response,
        isCurrentSession: () => true,
      ),
      same(response),
    );
  });
  test('current-session failures remain visible to the caller', () async {
    final error = StateError('current session unavailable');
    expect(
      readMmEngineDashboard(
        load: () async => throw error,
        isCurrentSession: () => true,
      ),
      throwsA(same(error)),
    );
  });
}
