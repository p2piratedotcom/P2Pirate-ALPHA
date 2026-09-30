import 'dart:io';

/// Sends Dart HTTP traffic to the local Tor bridge, except the KDF RPC.
class PirateTorHttpOverrides extends HttpOverrides {
  PirateTorHttpOverrides(this.proxyPort) {
    if (proxyPort < 1 || proxyPort > 65535) {
      throw ArgumentError.value(proxyPort, 'proxyPort');
    }
  }

  final int proxyPort;

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.findProxy = (uri) =>
        _isLoopback(uri.host) ? 'DIRECT' : 'PROXY 127.0.0.1:$proxyPort';
    return client;
  }

  bool _isLoopback(String host) =>
      host == 'localhost' || host == '127.0.0.1' || host == '::1';
}
