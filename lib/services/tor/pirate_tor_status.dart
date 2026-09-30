import 'package:flutter/foundation.dart';

enum PirateTorStatus { disabled, connecting, ready, unavailable }

final pirateTorStatus = ValueNotifier<PirateTorStatus>(
  PirateTorStatus.disabled,
);
