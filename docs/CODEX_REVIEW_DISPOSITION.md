# Codex bot review disposition

This ledger covers the 24 inline comments on merged GUI pull requests through
#56, two on GUI #57, five on SDK pull requests #5–#6, and one on SDK #9. The links point to
the original review comments. “Fixed here” describes the local remediation
branch; it is not a release verification or a claim that the fix is merged.

## GUI

| Review | Finding | Disposition |
| --- | --- | --- |
| [#32](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/32#discussion_r4144965907) | Normal close leaves Tor running | Fixed earlier in #56. The remaining failure-screen path is covered by the #56 row below. |
| [#34](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/34#discussion_r4146964784) | Concurrent ARRR pubkey notifications are dropped | Fixed here: coalesce a trailing forced refresh. |
| [#36](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/36#discussion_r4146970969) | SDK created twice; `late final` startup crash | Crash was fixed in #42. Fixed here more completely: construct one SDK lazily after price configuration. |
| [#36](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/36#discussion_r4146970977) | Wallet USD visibility incomplete | Mostly addressed in #52. Fixed remaining fiat row and narrow-layout column here. |
| [#33](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/33#discussion_r4146972808) | Back clears uncertain swap lock | Fixed here: Back and Clear preserve the lock; explicit acknowledgement requires checking history. |
| [#33](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/33#discussion_r4146972814) | Quote timer begins too late | Fixed here with a 30-second preimage RPC deadline while still on the form. This avoids moving an unvalidated swap into confirmation. |
| [#41](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/41#discussion_r4146985965) | Verified KDF may lose executable mode | Fixed here: restore execute permission before activating the verified binary. |
| [#41](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/41#discussion_r4146985972) | Incomplete KDF version directory blocks reinstall | Fixed here: after verifying a replacement download, remove an invalid managed version directory. Reject symlink paths. |
| [#37](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/37#discussion_r4146992446) | Recovery can run before receipts load | Fixed here: recovery waits for the wallet's receipt load and fails closed if it fails. |
| [#37](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/37#discussion_r4146992454) | Recovery receipt can stay pending forever | Fixed here: after 24 hours, a user may request a status review. Unlock requires explicit confirmation and an available KDF history check in which the transaction is absent; no automatic retry occurs. Older receipts can also be reviewed. |
| [#37](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/37#discussion_r4146992462) | Success shown during recovery RPC | Fixed here: success text appears only after an accepted response is stored. |
| [#39](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/39#discussion_r4147002099) | Amount conversion ignores quote age | Fixed here: conversion uses the freshness-aware lookup. |
| [#39](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/39#discussion_r4147002109) | Expired quote stays visible without a state change | Fixed here: a periodic event removes old quotes and clears the cached coin price. |
| [#39](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/39#discussion_r4147002117) | Standard orderbook ignores targeted quote updates | Fixed here: spot price observes `CoinsBloc` and its freshness-aware quotes. |
| [#40](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/40#discussion_r4147012863) | AppImage timestamps vary | Fixed here: set `SOURCE_DATE_EPOCH` from the source commit by default and normalize staged mtimes. Reproducibility of the entire toolchain still requires a pinned appimagetool and matching inputs. |
| [#43](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/43#discussion_r4147093850) | Release checklist omits distribution reviews | Fixed here: restore explicit source, license, Tor/torsocks and coin-asset review gates. Those reviews remain release tasks. |
| [#44](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/44#discussion_r4147584078) | Three-minute cap omits seed lookup | Fixed here: cap each complete Tor start attempt, clean up its process, and prevent a timed-out attempt from activating its bridge. |
| [#48](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/48#discussion_r4149376305) | ARRR activation can succeed after cancellation | Fixed here: recheck cancellation after KDF reconciliation. |
| [#49](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/49#discussion_r4153179060) | Buy selector hides best-orders error | Fixed here: show error and retry in both the selector and selected Buy panel; clear any stale selected order during refresh. |
| [#49](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/49#discussion_r4153179074) | Flip requires an offer despite a selected Buy coin | Fixed here: flip uses the selected Buy coin even without an offer. |
| [#52](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/52#discussion_r4155488635) | USD label remains without value | Fixed here: hide the enclosing fiat row. |
| [#52](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/52#discussion_r4155488652) | Hidden USD column consumes width | Fixed here: omit its enclosing narrow-layout column. Narrow desktop windows still use this responsive layout. |
| [#53](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/53#discussion_r4155895436) | Linux CI excludes PRs targeting `main` | Fixed here: include `main`. The current default branch is `cheetahdex`, but the workflow can also cover `main`. |
| [#56](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/56#discussion_r4164581525) | Tor failure roots lose window close handler | Fixed here: wrap failure and restart roots so window close still shuts Tor down. |
| [#57](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/57#discussion_r4165409236) | Recovery review sees only the first transaction page | Fixed here: inspect every reported page before unlocking; the SDK now fetches explicit pages from KDF rather than treating a partial local cache as complete history. |
| [#57](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/57#discussion_r4165409242) | Expired quote returns from repository cache | Fixed here: expire the repository cache on reads, refreshes, and the periodic expiry event; filter stale quotes when combining prices in the bloc. |

## SDK

| Review | Finding | Disposition |
| --- | --- | --- |
| [#5](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/5#discussion_r4144919450) | Invalid `LD_PRELOAD` silently starts KDF directly | Fixed here: ask KDF's ELF interpreter to resolve the exact executable under the launch environment and require the torsocks library before starting KDF. |
| [#5](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/5#discussion_r4144919467) | Tor mode lacks emergency seed fallback | Fixed here: resolve the emergency hostname through Tor SOCKS if bundled seeds fail; retain the Pirate NetID. |
| [#5](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/5#discussion_r4144919484) | SOCKS timeout leaves a live socket | Fixed here: close the socket from an internal handshake deadline. |
| [#6](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/6#discussion_r4146991270) | Binance cooldown blocks fallback host | Fixed here: cooldown is keyed by host. |
| [#6](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/6#discussion_r4146991278) | CoinGecko chunk timeouts add up | Fixed here: the whole queued batch shares a 12-second deadline. |
| [#9](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/9#discussion_r4165398135) | Preload probe checks `/bin/cat` rather than KDF | Fixed here: inspect KDF's ELF interpreter and reject static, privileged, or incompatible executables when Tor is required. |

## Local verification (2 October 2026)

- Linux release bundle compiled successfully.
- GUI unit suites: 388 passed, five skipped after the #57 follow-up fixes.
- Isolated Linux desktop smoke run under Xvfb: two passed.
- SDK seed and startup tests: four passed; transaction strategy tests: 17 passed.
  Binance/CoinGecko provider tests: 48 passed
  after updating three tests that still mocked the old price API.
- `flutter analyze --no-pub`: zero errors; 70 warnings and 1,966 informational
  diagnostics across this fork and its SDK/examples. These are existing
  repository-wide diagnostics, not a clean analysis result.

The Tor/KDF path, swap submission, recovery broadcasts, and AppImage artifact
hashes were not exercised against a live wallet or published binary. They
still require isolated end-to-end verification before release.
