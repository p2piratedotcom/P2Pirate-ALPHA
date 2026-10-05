import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/bloc/transformers.dart';

void main() {
  test('source completion flushes the last value and closes', () async {
    expect(
      await debounceStream(
        Stream.fromIterable([1, 2, 3]),
        const Duration(seconds: 1),
      ).toList().timeout(const Duration(seconds: 2)),
      [3],
    );
  });
  test('cancelling output cancels upstream and its pending timer', () async {
    var cancelled = false;
    final source = StreamController<int>(onCancel: () => cancelled = true);
    final values = <int>[];
    final listener = debounceStream(
      source.stream,
      const Duration(milliseconds: 20),
    ).listen(values.add);
    source.add(1);
    await Future<void>.delayed(Duration.zero);
    await listener.cancel();
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(cancelled, isTrue);
    expect(values, isEmpty);
    await source.close();
  });
  test('quiet interval emits only latest value', () async {
    final source = StreamController<int>();
    final values = <int>[];
    final done = Completer<void>();
    debounceStream(
      source.stream,
      const Duration(milliseconds: 10),
    ).listen(values.add, onDone: done.complete);
    source.add(1);
    source.add(2);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    expect(values, [2]);
    await source.close();
    await done.future;
    expect(values, [2]);
  });
}
