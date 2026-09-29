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
| Recover the Swap form from pre-submit validation errors | [#19](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/19) | — | Base fork |
| Linux window, launcher and icon branding | [#20](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/20) | — | Wallet #9 |
| Show loaded order and swap counts when History opens | [#21](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/21) | — | Base fork |
| Clear and isolate trading history when the active wallet changes | [#22](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/22) | — | Wallet #21 |
| Flutter 3.47.5 and Dart 3.13.4 dependency compatibility for Linux desktop | [#23](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/23) | — | Base fork |
| Encrypted per-wallet cache of completed swaps | [#24](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/24) | — | Wallet #22; wallet #23 for Flutter 3.47.5 |
| Classify swap success and failure consistently from KDF events | [#25](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/25) | — | Wallet #24 |

Review stacked proposals in order within each chain. Merge independent
proposals only after checking that they still apply cleanly to the target
branch. Wallet #10 and #13 pin SDK commits proposed in the corresponding SDK
PRs; merge those SDK PRs before merging the wallet pins. GitHub's draft or
mergeability indicator is not evidence of a successful Flutter build.

## Still required for functional parity

- Remaining Swap startup progress, timeout and diagnostic behavior, including
  verification after an uncertain submit result.
- Recovery request status and on-chain confirmation. The local cache in #24
  retains completed swaps only and does not replace live KDF history.
- ARRR address-detail balance refresh and remaining wallet list layout.
- Configurable HTTPS price endpoint and USD visibility setting; robust
  Binance/CoinGecko/CoinPaprika fallback, throttling and cache behavior.
- Linux Tor transport for KDF, Dart HTTP, images and WebView, with visible
  status and documented coverage limits.
- Remaining native platform identity and icons, Linux executable/application
  ID and data-directory migration review, UI performance changes and
  reproducible AppImage packaging.
- Provenance and distribution review for KDF 2.7.0-beta_968f32a, Tor and
  other bundled executables. The older Rust patch record must not be
  attributed to the ZIP's KDF binary without corresponding source evidence.

Flutter 3.47.5 and Dart 3.13.4 are installed locally. An offline locked
dependency resolution passed on wallet #23. Targeted Dart static analysis
found no errors in wallet #16, #17, #19, #21, #22, #24 and #25; it reported only
style suggestions in #16, #17 and #25. No funded swap or integrated Linux desktop build
has been performed for this PR series.
The current state is a reviewable source port in progress, not a release or a
claim that the fork matches the ZIP in full.
