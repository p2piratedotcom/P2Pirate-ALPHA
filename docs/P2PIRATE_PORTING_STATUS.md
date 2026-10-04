# P2Pirate porting status — 30 September 2026

This is a change ledger for the source archive described in
[P2PIRATE_PORTING_PLAN.md](P2PIRATE_PORTING_PLAN.md). The first 28 GUI PRs
and four SDK PRs listed below were merged on 29 September 2026. Further PRs
were merged on 30 September, as recorded below. Merged source is not by
itself a validated release. The ZIP is reference material, not the source of
this Git history.

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

## Changes merged on 30 September

These were verified as merged on GitHub on 30 September. The SDK Tor and price
changes are in the pinned SDK history. This table records merge state, not an
end-to-end wallet or swap test.

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
| Porting snapshot | [GUI #43](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/43) | Earlier comparison record |
| Tor transport | [SDK #5](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/5) | KDF startup and seed lookup through Tor |
| Tor startup retry | [GUI #44](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/44) | Retry stalled bootstrap without direct fallback |
| Tor failure choice | [GUI #45](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/45) | Ask before using a direct connection |
| ARRR wallet state | [GUI #46](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/46) | Finish ARRR activation in Wallet UI |
| KDF activation completion | [SDK #7](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/7) | Report completed ZHTLC task correctly |
| App Info | [GUI #47](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/47) | Move build details out of General |
| ZHTLC reconciliation | [GUI #48](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/48) | Match UI activation to KDF result |

The merged GUI and separate official KDF 2.7 executable reached the dashboard
in an isolated profile with Tor disabled. A later local Tor-on launch stopped
at `Tor seed lookup failed` and correctly waited for the user's choice. No
funded swap was made. The first-run KDF downloader has not been exercised end
to end.

## Local changes awaiting review

- Swap Buy now uses the same active Wallet coin list as Sell, including coins
  without public offers. Selecting a coin with an offer retains the existing
  taker order behavior; selecting one without an offer shows a no-offer message
  and does not enable swap submission. This supersedes the earlier
  `best_orders`-only filter in local commit `e2d609d`.
- Linux executable and GTK ID are being changed to `P2Pirate` and
  `com.p2pirate.wallet`. The existing Documents folder and Linux Secret
  Service namespace remain compatible so saved wallets stay discoverable. The
  launcher uses `StartupWMClass=P2Pirate`, matching the observed window class.
- The stale alpha warning falsely claimed Firebase Analytics data collection;
  its English text now matches the ZIP reference without that claim.
  These local changes are not yet a PR or release.

## Local Linux release checks — 30 September

- Flutter release build succeeded with executable `P2Pirate`. The compiled
  runner contains GTK ID `com.p2pirate.wallet`; the secure-storage plugin
  still contains the old account ID for wallet compatibility.
- `desktop-file-validate`, shell syntax checks, and static analysis of the
  changed Swap Dart file passed. Full `flutter analyze` reports 3,108
  diagnostics, mainly from SDK examples/tests in the submodule; it reports no
  errors in the GUI outside `sdk/`. This is not a clean whole-tree analysis.
- The first build succeeded with an empty coin catalog. The packaging script
  now rejects that state. The final local build uses the ZIP reference's
  `coins.json` (`0a4b57a8…`), `coins_config.json` (`5d77f607…`),
  `seed_nodes.json` (`d880dd32…`) and 453 PNG icons. These ignored inputs
  are local build material, not a reviewed redistributable asset release.
- A local AppImage was built and extracted. It has the P2Pirate executable,
  icon and desktop entry, Tor and torsocks, licenses and coin assets. It has no
  KDF executable. The separate official KDF 2.7 file matches the recorded
  ZIP SHA-256 `bd171eee…`.
- The AppImage opened a `P2Pirate` window, started Tor and KDF and reached the
  wallet screen. The per-user desktop launcher was migrated from the legacy
  CheetahDEX ID. After wallet login, the local GUI showed six active Wallet
  assets: ARRR, BNB, LTC native, LTC SegWit, DASH and USDT-BEP20. Swap Sell
  listed those assets (grouping both LTC networks); Buy listed USDT-BEP20,
  DASH and LTC native, all present in Wallet. Buy is further limited by
  available public offers. No transaction was made.
- On 1 October, a follow-up local Linux build changed Buy to the same active
  Wallet coin list used by Sell. Targeted Flutter analysis passed. The build
  reached the wallet screen through Tor after a stale Tor process was stopped;
  the new selector still needs visual confirmation after wallet login.

## Remaining release work

- Publish the prepared, hash-verified Ubuntu Tor and torsocks source packages,
  licenses and notices with a future reviewed GUI release. The local AppImage
  already contains them; see [asset provenance](LINUX_ASSET_PROVENANCE.md).
- Review remaining public GUI source and license obligations before publishing
  desktop binaries. The local release recipe excludes coin PNG artwork and
  renders ticker badges instead; it pins the factual coin parameter JSONs.
- Complete Tor-on first-run verification, including KDF, Dart HTTP, images and
  WebView traffic. Document the observed limits; do not assume coverage from
  a successful desktop build.
- Review native icons on non-Linux platforms and wallet list layout against
  the ZIP reference. Linux app identity migration and wallet-login check are
  handled in the local change above.
- Publish a reviewed KDF 2.7 release in the SDK fork with source revision,
  build method, license and hashes. That fork currently has no KDF executable
  release; GUI #41 pins the reviewed ShorelineCrypto release meanwhile.
- Preserve the pinned coin parameter files and their source hash manifest for
  reproducible offline release builds.
- Perform wallet-level checks with Tor enabled, then a swap/recovery exercise
  using an appropriate low-risk environment and the user's approval.

The CheetahDEX `v0.9.4` tag pins SDK commit `50d0cb8`, which points to Rust
commit `968f32a`. Its Linux KDF archive SHA-256 is `cf80e5d5…`; the reviewed
archive contains executable SHA-256 `bd171eee…`, matching the ZIP reference.
That identifies the release artifact, not a reproducible source build.


## Wallet balances after swap settlement (4 October 2026)

A fresh KDF swap snapshot now requests balances for the active maker/taker
assets when a swap becomes terminal. Matching uses the complete KDF configuration
ID, including network/SegWit suffixes, rather than the grouped base ticker.
Newly observed payment refunds also
request a refresh. For tokens, the active platform coin is included to update
network fees. Historical completed swaps at login do not trigger a refresh
storm; the initial baseline is marked loaded only after a successful RPC
snapshot (a null failure response is not treated as an empty snapshot). Known in-progress swaps retain the 10-second status poll outside the
Swap/Bridge page so settlement can update Wallet promptly.

The SDK exposes `refreshPubkeys` and `refreshBalance` to fetch current KDF
address/balance data, bypassing persisted and memory pubkey caches. Address
and balance watchers are notified. Failed refreshes preserve the last valid
balance. The GUI requests an immediate refresh and follow-ups at 5, 15, 30 and
60 seconds. Completions share one bounded sequence; requests arriving during
an existing settlement refresh are coalesced rather than accumulating a queue.
Settlement dispatch is independent of bulk/previous-session handlers, with
coalescing retaining one batch per wallet session. Forced asset reads have a
15-second local deadline; SDK work that completes later remains wallet-guarded
and can still update valid watchers. Bulk refreshes retain their original
droppable behavior. Login,
logout and disposal cancel pending work and reject previous-session results.

This changes refresh scheduling, not blockchain finality: balances remain
KDF-reported and can require confirmations or shielded-wallet synchronization.
No transaction, trade or balance is inferred from swap amounts.

Verification: Linux release compilation and local AppImage packaging succeeded;
static analysis reported zero errors (existing repository diagnostics remain).
After restarting the local build, the user completed a real swap and confirmed
that Wallet balances updated immediately on completion. This observation is
not a timing guarantee for every asset/network. No additional funded swap was
initiated by the agent.
