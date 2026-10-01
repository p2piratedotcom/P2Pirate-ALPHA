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
covered by this result. Attempting to start the full app while another KDF is
active produced `UserpassIsInvalid`: the SDK still uses a fixed RPC port
(7783), so an automated instance can contact the live engine. They must remain
out of the default run until the SDK supports an isolated RPC endpoint and
test credentials. The Linux smoke test does not start KDF or access wallet
secrets.

`flutter analyze --no-pub` found no errors and no diagnostics in the changed
Dart files. It still exits nonzero because of 2,049 existing repository-wide
diagnostics (78 warnings and 1,971 info notices), mainly in shared or upstream
code. These are separate cleanup work from the test failures above.
