# Desktop integration testing

The supported automated integration target is the Linux Flutter runner. Run it
from the repository root with `flutter`, `dart`, `xvfb-run`, `dbus-run-session`,
and `xdg-user-dir` installed:

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

The older files in `test_integration/tests/` were written for the upstream Web
app and depend on browser controls, a wallet fixture, live services, and KDF.
They are kept as migration reference and are not part of the desktop command.
In particular, the current SDK fixes the local RPC port at 7783. Running these
tests while a wallet is open can contact that wallet's KDF process. Full
wallet/KDF desktop tests need a configurable per-test RPC port and isolated
credentials in the SDK before they can be run safely alongside a real wallet.

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
