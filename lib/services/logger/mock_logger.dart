// ignore_for_file: avoid_print

import 'package:web_dex/services/logger/logger.dart';

class MockLogger implements LoggerInterface {
  const MockLogger();

  @override
  Future<void> write(String logMessage, [String? path]) async {
    print('path: $path, $logMessage');
  }

  @override
  Future<void> init() async {
    print('initialized');
  }
}
