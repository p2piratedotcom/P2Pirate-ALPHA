import 'dart:io';
import 'dart:async';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:komodo_defi_framework/komodo_defi_framework.dart';
import 'package:komodo_defi_types/komodo_defi_types.dart';
import 'package:web_dex/mm2/mm2.dart';
import 'package:web_dex/services/kdf_install/kdf_install_service.dart';

const _testPort = int.fromEnvironment('P2PIRATE_LOCAL_RPC_PORT');

Future<void> expectTestPortClosed() async {
  for (var attempt = 0; attempt < 20; attempt++) {
    try {
      final socket = await Socket.connect(
        InternetAddress.loopbackIPv4,
        _testPort,
      ).timeout(const Duration(seconds: 1));
      socket.destroy();
    } on SocketException {
      return;
    } on TimeoutException {
      // Try again briefly before reporting a process that did not stop.
    }
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  fail('Isolated KDF is still listening after cleanup');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('KDF 2.7 starts and answers on an isolated local RPC port', (
    tester,
  ) async {
    final binaryPath = Platform.environment['P2PIRATE_KDF_PATH'];
    expect(binaryPath, isNotNull);
    expect(_testPort, greaterThan(0));
    expect(_testPort, isNot(7783));

    final binary = File(binaryPath!);
    expect(await binary.exists(), isTrue);
    expect(
      sha256.convert(await binary.readAsBytes()).toString(),
      KdfInstallService.executableSha256,
    );

    final framework = KomodoDefiFramework.create(
      hostConfig: LocalConfig(
        https: false,
        rpcPassword: 'p2pirate-isolated-kdf-test',
        rpcPort: _testPort,
      ),
    );
    var started = false;
    addTearDown(() async {
      if (started) await framework.kdfStop();
      await framework.dispose();
      await expectTestPortClosed();
    });

    final startup = await KdfStartupConfig.noAuthStartup(
      rpcPassword: 'p2pirate-isolated-kdf-test',
      rpcPort: _testPort,
    );
    expect(startup.rpcPort, _testPort);
    final result = await framework.startKdf(startup);
    expect(result, KdfStartupResult.ok);
    started = true;
    expect(await framework.version(), isNotNull);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('P2Pirate SDK creates and reopens an isolated test wallet', (
    tester,
  ) async {
    expect(_testPort, isNot(7783));
    addTearDown(() async {
      await mm2.dispose();
      await expectTestPortClosed();
    });
    final sdk = await mm2.initialize();
    expect(sdk, isNotNull);
    expect(await mm2.version(), isNotEmpty);

    const options = AuthOptions(derivationMethod: DerivationMethod.hdWallet);
    const name = 'p2pirate-disposable-test-wallet';
    const password = 'P2Pirate-Isolated-Test-Only-2026!';
    final created = await sdk.auth.register(
      walletName: name,
      password: password,
      options: options,
    );
    expect(created.walletId.name, name);
    expect(await sdk.auth.isSignedIn(), isTrue);

    await sdk.auth.signOut();
    expect(await sdk.auth.isSignedIn(), isFalse);
    final reopened = await sdk.auth.signIn(
      walletName: name,
      password: password,
      options: options,
    );
    expect(reopened.walletId.name, name);
    expect(await sdk.auth.isSignedIn(), isTrue);
  }, timeout: const Timeout(Duration(minutes: 5)));
}
