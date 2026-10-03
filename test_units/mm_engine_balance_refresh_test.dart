import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/views/market_maker_bot/mm_engine_balance_refresh.dart';

void main() {
  testWidgets('auto refresh retains balances during requests and failures', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 3);
    var requests = 0;
    var pending = Completer<List<Map<String, dynamic>>>();
    final refresh = MmEngineBalanceRefresh(
      now: () => now,
      canRefresh: (_) => true,
      load: (_) {
        requests++;
        return pending.future;
      },
    );
    await tester.pump(const Duration(seconds: 1));
    expect(requests, 1);
    pending.complete([
      {'ticker': 'ARRR', 'available': '61.4'},
    ]);
    await tester.pump();
    expect(refresh.balances.single['available'], '61.4');
    expect(refresh.secondsRemaining, 60);
    now = now.add(const Duration(seconds: 59));
    await tester.pump(const Duration(seconds: 59));
    expect(requests, 1);
    expect(refresh.secondsRemaining, 1);
    pending = Completer();
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    expect(requests, 2);
    expect(refresh.loading, isTrue);
    expect(refresh.balances.single['ticker'], 'ARRR');
    await refresh.refresh();
    await tester.pump(const Duration(seconds: 5));
    expect(requests, 2); // No overlapping reads, including manual refresh.
    pending.completeError(StateError('Tor unavailable'));
    await tester.pump();
    expect(refresh.error, contains('Tor unavailable'));
    expect(refresh.balances.single['available'], '61.4');
    expect(refresh.secondsRemaining, 60);
    expect(refresh.loading, isFalse);
    refresh.dispose();
  });

  testWidgets('collapse pauses polling and venue caches remain separate', (
    tester,
  ) async {
    var now = DateTime.utc(2026, 10, 3);
    final requests = <String>[];
    final refresh = MmEngineBalanceRefresh(
      now: () => now,
      canRefresh: (_) => true,
      load: (venue) async {
        requests.add(venue);
        return [
          {'ticker': venue, 'available': '1'},
        ];
      },
    );
    await tester.pump(const Duration(seconds: 1));
    expect(refresh.balances.single['ticker'], 'MEXC');
    refresh.toggleExpanded();
    now = now.add(const Duration(minutes: 5));
    await tester.pump(const Duration(minutes: 5));
    expect(requests, ['MEXC']);
    refresh.toggleExpanded();
    await tester.pump();
    expect(requests, ['MEXC', 'MEXC']);
    refresh.selectVenue('GATE');
    expect(refresh.balances, isEmpty);
    await tester.pump();
    expect(refresh.balances.single['ticker'], 'GATE');
    refresh.selectVenue('MEXC');
    expect(refresh.balances.single['ticker'], 'MEXC');
    await tester.pump();
    refresh.dispose();
  });

  testWidgets(
    'busy or unconfigured venue cannot poll; old sessions cannot replace snapshots',
    (tester) async {
      var eligible = false;
      var requests = 0;
      final pending = Completer<List<Map<String, dynamic>>>();
      final refresh = MmEngineBalanceRefresh(
        canRefresh: (_) => eligible,
        load: (_) {
          requests++;
          return pending.future;
        },
      );
      await tester.pump(const Duration(seconds: 20));
      expect(requests, 0);
      eligible = true;
      await tester.pump(const Duration(seconds: 1));
      expect(requests, 1);
      refresh.invalidate(clear: true);
      pending.complete([
        {'ticker': 'old session'},
      ]);
      await tester.pump();
      expect(refresh.balances, isEmpty);
      expect(refresh.updatedAt, isNull);
      expect(refresh.loading, isFalse);
      refresh.dispose();
    },
  );

  testWidgets('late response from another venue is ignored', (tester) async {
    final pending = Completer<List<Map<String, dynamic>>>();
    final refresh = MmEngineBalanceRefresh(
      canRefresh: (_) => true,
      load: (venue) => venue == 'MEXC'
          ? pending.future
          : Future.value([
              {'ticker': 'GATE'},
            ]),
    );
    await tester.pump(const Duration(seconds: 1));
    refresh.selectVenue('GATE');
    pending.complete([
      {'ticker': 'MEXC'},
    ]);
    await tester.pump();
    expect(refresh.balances, isEmpty);
    await tester.pump(const Duration(seconds: 1));
    expect(refresh.balances.single['ticker'], 'GATE');
    refresh.dispose();
  });

  testWidgets('valid empty response replaces old display balances', (
    tester,
  ) async {
    var empty = false;
    final refresh = MmEngineBalanceRefresh(
      canRefresh: (_) => true,
      load: (_) async => empty
          ? []
          : [
              {'ticker': 'ARRR'},
            ],
    );
    await tester.pump(const Duration(seconds: 1));
    expect(refresh.balances.single['ticker'], 'ARRR');
    empty = true;
    await refresh.refresh();
    expect(refresh.balances, isEmpty);
    expect(refresh.error, isNull);
    expect(refresh.updatedAt, isNotNull);
    refresh.dispose();
  });

  testWidgets('disposal ignores a late network reply and cancels polling', (
    tester,
  ) async {
    final pending = Completer<List<Map<String, dynamic>>>();
    final refresh = MmEngineBalanceRefresh(
      canRefresh: (_) => true,
      load: (_) => pending.future,
    );
    var notifications = 0;
    refresh.addListener(() => notifications++);
    await tester.pump(const Duration(seconds: 1));
    final before = notifications;
    refresh.dispose();
    pending.complete([
      {'ticker': 'ARRR'},
    ]);
    await tester.pump(const Duration(minutes: 2));
    expect(notifications, before);
  });
}
