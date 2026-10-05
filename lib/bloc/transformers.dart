import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

EventTransformer<T> debounce<T>([int ms = 300]) {
  return (events, mapper) {
    final duration = Duration(milliseconds: ms);
    final Stream<T> debounced = debounceStream(events, duration);
    final Stream<Stream<T>> mapped = debounced.map(mapper);

    return flattenStream(mapped);
  };
}

Stream<T> flattenStream<T>(Stream<Stream<T>> source) async* {
  await for (var stream in source) {
    yield* stream;
  }
}

Stream<T> debounceStream<T>(Stream<T> source, Duration duration) {
  late final StreamController<T> controller;
  StreamSubscription<T>? subscription;
  Timer? timer;
  T? pending;
  var hasPending = false;
  void flush() {
    if (!hasPending) return;
    hasPending = false;
    controller.add(pending as T);
  }

  controller = StreamController<T>(
    onListen: () {
      subscription = source.listen(
        (event) {
          pending = event;
          hasPending = true;
          timer?.cancel();
          timer = Timer(duration, flush);
        },
        onError: controller.addError,
        onDone: () {
          timer?.cancel();
          flush();
          controller.close();
        },
      );
    },
    onCancel: () async {
      timer?.cancel();
      hasPending = false;
      await subscription?.cancel();
    },
  );
  return controller.stream;
}
