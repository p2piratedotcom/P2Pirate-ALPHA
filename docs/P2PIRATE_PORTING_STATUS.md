# P2Pirate porting status — 29 September 2026

This is a review ledger for the source archive described in
[P2PIRATE_PORTING_PLAN.md](P2PIRATE_PORTING_PLAN.md). The links below point to
**draft proposals**. None of these proposals is counted as delivered behavior
until it is merged and checked in a build against the reference. The ZIP is
reference material, not the source of this Git history.

## Published proposals

| Change | Wallet PR | SDK PR | Review dependency |
| --- | --- | --- | --- |
| Source provenance, license and porting plan | [#1](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/1) | — | Base fork |
| ARRR default and activation flow | [#2](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/2) | — | Base fork |
| Hide fiat and NFT entry points | [#3](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/3) | — | Base fork |
| Stop upstream update polling | [#4](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/4) | — | Base fork |
| Limit Swap asset selector to active wallet assets | [#5](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/5) | — | Base fork |
| Horizontal Swap pair reversal icon | [#6](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/6) | — | Base fork |
| KDF NetID 8762 guard | — | [#1](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/1) | SDK base fork |
| Disable telemetry providers and events | [#7](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/7) | — | Base fork |
| Remove automatic log export and attachment | [#8](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/8) | — | Wallet #7 |
| Visible P2Pirate name and P logo, with artwork attribution | [#9](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/9) | — | Wallet #2 |
| Pin the SDK fork with NetID guard | [#10](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/10) | — | SDK #1 |
| Repository README, build outline and component inventory | [#11](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/11) | — | Wallet #1 |
| Trading Engine navigation label | [#12](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/12) | — | Base fork |
| Remove default GLEEC price endpoint | — | [#2](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/2) | SDK #1 |
| Pin SDK with revised price source | [#13](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/13) | — | Wallet #10, SDK #2 |
| Desktop Swap panels and scrolling | [#14](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/14) | — | Base fork |
| Order-book USD estimates and copyable maker UUID | [#15](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/15) | — | Wallet #14 |
| Optional exact maker UUID matching | [#16](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/16) | — | Wallet #15 |
| Missing USD quotes and partial wallet totals | [#17](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/17) | — | Base fork |

Review stacked proposals in order within each chain. Merge independent
proposals only after checking that they still apply cleanly to the target
branch. Wallet #10 and #13 pin SDK commits proposed in the corresponding SDK
PRs; merge those SDK PRs before merging the wallet pins. GitHub's draft or
mergeability indicator is not evidence of a successful Flutter build.

## Still required for functional parity

- Swap startup progress, error and timeout behavior, including verification
  after an uncertain submit result.
- Per-wallet swap history, outcome classification and recovery status.
- ARRR address-detail balance refresh and remaining wallet list layout.
- Configurable HTTPS price endpoint and USD visibility setting; robust
  Binance/CoinGecko/CoinPaprika fallback, throttling and cache behavior.
- Linux Tor transport for KDF, Dart HTTP, images and WebView, with visible
  status and documented coverage limits.
- Remaining native platform identity, icons, data-directory migration review,
  UI performance changes and reproducible AppImage packaging.
- Provenance and distribution review for KDF 2.7.0-beta_968f32a, Tor and
  other bundled executables. The older Rust patch record must not be
  attributed to the ZIP's KDF binary without corresponding source evidence.

No funded swap, Flutter build or Dart static analysis has been performed for
this PR series in the current workspace: the Flutter/Dart toolchain is absent.
The current state is a reviewable source port in progress, not a release or a
claim that the fork matches the ZIP in full.
