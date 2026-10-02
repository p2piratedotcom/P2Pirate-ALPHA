import 'package:flutter_test/flutter_test.dart';
import 'package:web_dex/services/tor/pirate_tor_service.dart';

void main() {
  test('app shutdown prevents Tor from restarting', () async {
    final tor = PirateTorService.instance;

    await tor.shutdown();
    await tor.shutdown();

    await expectLater(tor.start(), throwsStateError);
  });
}
