# Desktop integration testing

The supported automated integration target is the Linux Flutter runner. Run it
from the repository root with `flutter`, `dart`, `xvfb-run`, `dbus-run-session`,
and `xdg-user-dir` installed. The optional KDF target also needs
`gnome-keyring-daemon`:

```sh
dart run_integration_tests.dart
```

If Flutter is not on `PATH`, set `P2PIRATE_FLUTTER_BIN` to its absolute path.
The runner executes `flutter test -d linux integration_test` under Xvfb and a
private D-Bus session. It creates temporary XDG data, config, cache, and
Documents directories and removes them after the test. It never deletes an
installed P2Pirate profile. The active smoke test checks native rendering of
the P2Pirate logo, Tor status label, and Settings navigation without starting
KDF or accessing a wallet.

The SDK now supports a configurable local RPC port. To run a second desktop
target with a disposable profile and a separate KDF process, point to a
reviewed KDF 2.7 executable and opt in:

```sh
P2PIRATE_KDF_PATH=/absolute/path/to/kdf dart run_integration_tests.dart --kdf
```

The runner picks a free loopback port, injects it with
`P2PIRATE_LOCAL_RPC_PORT`, and checks the executable against the SHA-256
expected by P2Pirate. It starts a temporary Secret Service keyring in the
private D-Bus session, starts KDF, creates a disposable test wallet, signs out,
signs in again, then stops KDF and verifies the port is closed. It does not
read an existing wallet or keyring. The test profile is removed afterward.
The executable is supplied externally; it is not copied into this GUI repo.

The older files in `test_integration/tests/` were written for the upstream Web
app and depend on browser controls, a wallet fixture, and live services. They
are kept as migration reference and are not part of either desktop target.
Wallet transaction and exchange tests still need funded disposable fixtures
and service mocks before they can run unattended.

Unit and widget tests, including the older aggregate entry point, can be run
with:

```sh
flutter test test_units
flutter test test_units/main.dart
flutter test test_units test_units/main.dart
```

For coverage, run `flutter test --coverage test_units test_units/main.dart` followed by
`genhtml coverage/lcov.info -o coverage/html`. The coverage output is ignored
by Git. See [TEST_STATUS.md](TEST_STATUS.md) for the measured baseline and
resolved failures.
