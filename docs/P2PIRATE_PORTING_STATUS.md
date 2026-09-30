# P2Pirate porting status — 29 September 2026

This is a change ledger for the source archive described in
[P2PIRATE_PORTING_PLAN.md](P2PIRATE_PORTING_PLAN.md). All 28 GUI PRs and four
SDK PRs listed below were merged on 29 September 2026. Merged source is not a
validated release: an integrated Linux build and comparison with the reference
are still required. The ZIP is reference material, not the source of this Git
history.

## Merged changes

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
| Keep a non-null Trezor task ID across an asynchronous SDK status call | — | [#3](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/3) | SDK #2 |
| Pin the SDK commit with the Dart 3.13 Trezor fix | [#26](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/26) | — | Wallet #13, SDK #3 |
| Use a separately installed Linux KDF; stop bundling and build-time KDF downloads | — | [#4](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/4) | SDK #3 |
| Pin the SDK revision that uses external Linux KDF | [#27](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/27) | — | Wallet #26, SDK #4 |
| Document the KDF release and first-run installation contract | [#28](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/28) | — | Wallet #27 |

Stacked proposals were merged in dependency order. Wallet #10, #13, #26 and
#27 pin the corresponding SDK commits. GitHub's mergeability indicator is not
evidence of a successful Flutter build.

## Open proposals from the 30 September comparison

These proposals are **not merged**. GUI PRs are stacked in the order shown,
so review each PR against its parent branch and merge in that order only after
local approval. The SDK change is a separate prerequisite of GUI #38.

| Area | PR | Scope |
| --- | --- | --- |
| Swap progress and uncertain transport result | [GUI #33](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/33) | Diagnostics, wait messages, duplicate-submit guard |
| ARRR address details | [GUI #34](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/34) | Refresh address pubkeys with balances |
| UI responsiveness | [GUI #35](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/35) | Animation lifecycle and local CPU diagnostics |
| Price controls | [GUI #36](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/36) | USD visibility and custom HTTPS API |
| Uncertain-swap recovery | [GUI #37](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/37) | Encrypted receipts and confirmation checks |
| Price provider reliability | [SDK #6](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/6) | Timeouts, fallback, throttling and cache |
| SDK revision | [GUI #38](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/38) | Pin SDK #6 commit |
| Active-market price freshness | [GUI #39](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/39) | Selected quote refresh and stale USD expiry |
| GUI-only AppImage | [GUI #40](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/40) | Local packaging script and instructions |
| First-run KDF setup | [GUI #41](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/41) | Pinned upstream KDF 2.7 download and SHA-256 verification |
| Linux startup | [GUI #42](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/42) | Renderer, locale and price SDK initialization fixes |

A Linux release GUI build with these branches succeeded on 30 September. The
rebuilt GUI and separate official KDF 2.7 executable reached the dashboard in
an isolated profile with Tor disabled. The fresh-profile Tor startup and
network behavior remain under local verification; no funded swap was made.
The AppImage packaging script has not been run because `appimagetool` is not
installed. The first-run KDF downloader has not been exercised end to end.

## Remaining release work

- Complete Tor-on first-run verification, including KDF, Dart HTTP, images and
  WebView traffic. Document the observed limits; do not assume coverage from
  a successful desktop build.
- Review Linux application ID, data-directory migration, remaining native
  icons and wallet list layout against the ZIP reference.
- Publish a reviewed KDF 2.7 release in the SDK fork with source revision,
  build method, license and hashes. That fork currently has no KDF executable
  release; GUI #41 pins the reviewed ShorelineCrypto release meanwhile.
- Pin and document coin assets for reproducible offline release builds.
- Perform wallet-level checks with Tor enabled, then a swap/recovery exercise
  using an appropriate low-risk environment and the user's approval.

The CheetahDEX `v0.9.4` tag pins SDK commit `50d0cb8`, which points to Rust
commit `968f32a`. Its Linux KDF archive SHA-256 is `cf80e5d5…`; the reviewed
archive contains executable SHA-256 `bd171eee…`, matching the ZIP reference.
That identifies the release artifact, not a reproducible source build.
