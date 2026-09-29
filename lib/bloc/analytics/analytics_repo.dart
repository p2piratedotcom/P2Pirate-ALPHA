import 'package:get_it/get_it.dart';
import 'package:web_dex/model/settings/analytics_settings.dart';

// Existing event call sites remain source-compatible, but Pirate Wallet does
// not collect, queue, persist, or transmit analytics events.
abstract class AnalyticsEventData {
  const AnalyticsEventData();

  String get name;
  Map<String, dynamic> get parameters;

  MapEntry<String, dynamic>? get primaryParameter {
    final iterator = parameters.entries.iterator;
    return iterator.moveNext() ? iterator.current : null;
  }
}

class PersistedAnalyticsEventData extends AnalyticsEventData {
  PersistedAnalyticsEventData({required this.name, required this.parameters});

  @override
  final String name;

  @override
  final Map<String, dynamic> parameters;
}

abstract class AnalyticsRepo {
  Future<void> sendData(AnalyticsEventData data);
  Future<void> queueEvent(AnalyticsEventData event);
  Future<void> activate();
  Future<void> deactivate();
  Future<void> retryInitialization(AnalyticsSettings settings);
  Future<void> persistQueue();
  Future<void> loadPersistedQueue();
  Future<void> dispose();
  bool get isInitialized;
  bool get isEnabled;
}

/// P2Pirate keeps the API but never collects, stores, or sends events.
class AnalyticsRepository implements AnalyticsRepo {
  AnalyticsRepository([AnalyticsSettings? settings]);

  static void register([AnalyticsSettings? settings]) {
    if (!GetIt.I.isRegistered<AnalyticsRepo>()) {
      GetIt.I.registerSingleton<AnalyticsRepo>(AnalyticsRepository());
    }
  }

  @override
  bool get isInitialized => false;

  @override
  bool get isEnabled => false;

  @override
  Future<void> sendData(AnalyticsEventData data) async {}

  @override
  Future<void> queueEvent(AnalyticsEventData event) async {}

  @override
  Future<void> activate() async {}

  @override
  Future<void> deactivate() async {}

  @override
  Future<void> retryInitialization(AnalyticsSettings settings) async {}

  @override
  Future<void> persistQueue() async {}

  @override
  Future<void> loadPersistedQueue() async {}

  @override
  Future<void> dispose() async {}
}
