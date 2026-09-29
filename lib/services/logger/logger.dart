abstract class LoggerInterface {
  Future<void> init();
  Future<void> write(String logMessage, [String? path]);
}
