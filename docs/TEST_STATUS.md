# Test baseline (2026-10-01, Linux)

The original aggregate unit command, `flutter test test_units/main.dart`,
completed with 202 passes, 3 skips, and 4 failures. All four failures came
from `compute_wallet_total_usd_tests.dart`: its CEX quote fixture used the
Unix epoch, while production correctly rejects quotes older than ten minutes.
The fixture now uses a current timestamp.

The broader `flutter test test_units` command exposed four more failures not
included in the aggregate:

| Test | Observed cause | Resolution |
| --- | --- | --- |
| Trezor success in `wallets_manager_test.dart` | Fake analytics bloc omitted `logEvent` | Add the current no-op method to the fake |
| Two Trezor success cases in `hardware_wallets_manager_test.dart` | Same incomplete fake | Add the method to the fake |
| Custom token import success | Test expected an analytics event, although P2Pirate intentionally disables analytics | Assert that no event is queued |

After these corrections, `flutter test test_units` passed with **181 passes
and 2 skips**. Running it together with the historical aggregate,
`flutter test test_units test_units/main.dart`, passed with **387 executions
and 5 skips**; it intentionally repeats cases included by both entry points.
`lcov` and `genhtml` generated a report for this combined run:
**15.6% line coverage (3,458 of 22,180 instrumented lines)**. This is a
baseline measurement, not a release coverage threshold.

The two native Linux UI smoke tests in
`integration_test/desktop_smoke_test.dart` passed under Xvfb. They render the
P2Pirate logo, check the Tor status label,
and exercises the App Info Settings selection in the actual Flutter Linux
runner. The tests are launched
with `dart run_integration_tests.dart`, which isolates XDG data, cache, config,
Documents, display, and D-Bus state. The retired runner's routine that deleted
app data has been removed.

The upstream integration groups in `test_integration/tests/` are **not**
covered by this result. Before the port override was added, starting the full
app beside another KDF produced `UserpassIsInvalid`: the automated instance
contacted the live engine on port 7783. These tests remain outside the default
run because they still need disposable wallet and service fixtures. The Linux
smoke test does not start KDF or access wallet secrets.

`flutter analyze --no-pub` found no errors and no diagnostics in the changed
Dart files. It still exits nonzero because of 2,049 existing repository-wide
diagnostics (78 warnings and 1,971 info notices), mainly in shared or upstream
code. These are separate cleanup work from the test failures above.

## Isolated KDF and SDK suite (2026-10-02)

The SDK's local RPC port is now configurable through `LocalConfig.rpcPort` and
`KomodoDefiSdkConfig.localRpcPort`; production keeps the existing default of
7783. P2Pirate reads an override from the compile-time
`P2PIRATE_LOCAL_RPC_PORT` value for test builds. The Linux KDF integration
target passed with the verified KDF 2.7 binary on a disposable, random
loopback port: **2 passed**, including creation, sign-out, and sign-in for a
test-only wallet stored in a temporary profile and keyring. The original UI
smoke target remains **2 passed**.
`flutter build linux --release --no-pub` produced the P2Pirate bundle locally.

The complete local SDK package suites also pass: **374 tests** in
`komodo_defi_sdk`, **40** in `komodo_defi_local_auth`, and **10** in
`komodo_defi_framework`. The 26 failures found during the initial full SDK
run were stale expectations or incomplete mocks except for a real wallet
switch race in `BalanceManager`. In-flight balance requests can no longer
repopulate the prior wallet's cache or emit to its closed stream. A specific
regression test covers that case. The GUI unit aggregate remains **387 passes,
5 skips**.

The older browser-oriented wallet tests remain reference material. Their
transaction and exchange flows need desktop interaction drivers and funded
wallet/service fixtures; the current KDF target uses only a disposable wallet.
Repository-wide
analyzer notices remain a separate cleanup backlog. On this revision,
`flutter analyze --no-pub` reports **0 errors, 70 warnings, and 1,978 info
notices** across the GUI and SDK workspace. The changed GUI Dart files have
no diagnostics. Clearing unrelated upstream style notices would be a broad
change with no demonstrated effect on the desktop failures.

## CI failures observed on GUI PR #54

After PR #54 merged, its remote checks reported failures that the local Linux
suite could not expose:

| Job | Observed failure | Change prepared |
| --- | --- | --- |
| Unit tests | `dart pub get -C sdk --enforce-lockfile` rejected the SDK workspace, which does not commit a root lockfile | Resolve the SDK workspace without `--enforce-lockfile`; keep the GUI lockfile enforced |
| Linux release build | The CI image lacked `webkit2gtk-4.1` development files | Install `libwebkit2gtk-4.1-dev` in Linux setup |
| macOS release build | The SDK CocoaPods script required a bundled KDF, although this GUI uses an external KDF | Permit a binary-free GUI build and state the runtime requirement |
| OSV scan | Recursive scan attempted to resolve open Python test requirements for over 18 minutes | Scan the committed GUI `pubspec.lock` directly |

The corrected CI jobs must still run remotely after the new GUI and SDK
revisions are published. The macOS and Windows KDF runtime installation paths
also need separate platform verification; this Linux host cannot run those
apps. No macOS or Windows KDF executable was bundled by this change.
