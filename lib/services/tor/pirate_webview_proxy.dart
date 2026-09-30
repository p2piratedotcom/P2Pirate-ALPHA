import 'package:flutter/services.dart';

class PirateWebViewProxy {
  const PirateWebViewProxy._();

  static const MethodChannel _channel = MethodChannel(
    'pirate_wallet/webview_proxy',
  );

  static Future<void> configure(int httpProxyPort) async {
    if (httpProxyPort < 1 || httpProxyPort > 65535) {
      throw ArgumentError.value(httpProxyPort, 'httpProxyPort');
    }
    await _channel.invokeMethod<void>('setProxyPort', httpProxyPort);
  }
}
