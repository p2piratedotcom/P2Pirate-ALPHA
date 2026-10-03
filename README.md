# P2Pirate ALPHA

P2Pirate is a community fork of
[ShorelineCrypto/cheetahdex-wallet-web](https://github.com/ShorelineCrypto/cheetahdex-wallet-web),
a Flutter non-custodial wallet and decentralized exchange. This repository
preserves the upstream Git history. P2Pirate behavior is being reapplied from
a source ZIP as small, reviewable pull requests. The merged PR ledger is in
the porting status. **This source is not yet a validated P2Pirate release.** See the
[porting inventory](docs/P2PIRATE_PORTING_PLAN.md). The
[PR ledger](docs/P2PIRATE_PORTING_STATUS.md) records the merged changes and
the gaps that remain before a release.

The [automated review disposition](docs/CODEX_REVIEW_DISPOSITION.md) tracks
findings from already merged GUI and SDK pull requests.

The reference is the P2Pirate Linux x86_64 source snapshot dated 29 September
2026. It has no original commit history, so each PR records the behavior it
recreates and any intentional difference. The ZIP and its bundled AppImage
are reference material; they are not committed as a source release here.

The current build and release target is Linux x86-64. macOS and Windows desktop
releases are deferred until they can be tested. The Android and
Web runners and deployment workflows have been removed; the unused iOS runner
remains pending a separate review. See [desktop-only cleanup](docs/DESKTOP_ONLY_SCOPE.md).
Only Linux has been built locally for the P2Pirate port so far.

## Repository map

| Path | Purpose | Provenance |
| --- | --- | --- |
| `lib/` | Flutter wallet, DEX screens, state and services | CheetahDEX upstream with traced P2Pirate edits |
| `app_theme/`, `packages/` | App theme and local Flutter packages | Upstream, then reviewed P2Pirate edits |
| `sdk/` | Komodo DeFi Flutter SDK Git submodule, without a bundled Linux KDF | Pinned [P2Pirate SDK fork](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter) |
| `assets/` | Wallet graphics, coin data, translations | Mixed; new art must carry its own source and license record |
| `linux/`, `macos/`, `windows/` | Intended desktop runners and packaging metadata | Upstream plus P2Pirate branding changes |
| `ios/` | Legacy mobile runner, not a supported P2Pirate target | Upstream |
| `docs/`, `test/`, `test_units/`, `test_integration/`, `integration_test/` | Build guidance, unit tests, historical tests and Linux desktop smoke tests | Upstream plus P2Pirate inventory and focused additions |
| `LICENSE`, `licenses/` | Source license and component notices | Retain upstream GPL-3.0 text and third-party notices |

Build output and downloaded executables belong outside source control. The
separate [MM_Engine integration](docs/P2PIRATE_MM_ENGINE.md) explains the
verified Linux download, KDF/Tor ownership and live trading safeguards. The
reference ZIP's Tor, torsocks and AppImage binaries need separately identified
versions, licenses, checksums and corresponding source before a public binary
release. KDF's upstream release artifact has been identified; see
[external KDF](docs/P2PIRATE_EXTERNAL_KDF.md).

## What is being ported

The [inventory](docs/P2PIRATE_PORTING_PLAN.md) groups the work into ARRR
defaults and activation; P2Pirate identity; navigation and privacy; Swap
layout, diagnostics and order matching; history and recovery; ARRR balance
refresh; USD prices; Linux Tor transport; performance; and reproducible
packaging. A row is complete only after its PR is merged and checked against
the reference behavior. A PR does not imply that a funded swap was tested.

P2Pirate's SDK configuration uses KDF NetID `8762`. The reference ZIP uses
the [ShorelineCrypto KDF `v2.7.0-beta` release](https://github.com/ShorelineCrypto/komodo-defi-framework/releases/tag/v2.7.0-beta),
whose source tag points to Rust commit `968f32a6bccf20f286d1b8e2520b62ebe769522b`.
The Linux x86-64 archive SHA-256 is
`cf80e5d5ae78605d6f0f6a806aa9ae5b83bbee0ef79ccd5ad85022ae2a5d7d27`;
its `kdf` executable SHA-256 is
`bd171eeee7a1e0d43b070c8ba6ba60a845a26b3db0ef57ca25a394a2b6c02129`,
matching the reference ZIP. Matching hashes identify the upstream artifact,
but do not prove a reproducible build from source.
The SDK source pin and the KDF binary are separate dependencies. The ZIP does
not establish that older custom Rust patches are in that executable. The
existing KDF Market Maker Bot project records the same KDF version and NetID,
but its runtime and wallet profile are distinct; shared version numbers do
not prove end-to-end trading compatibility.

## Build and run from source

Use Flutter `>=3.47.5 <4.0.0` and Dart `>=3.11.0 <4.0.0`, as declared in
`pubspec.yaml`, plus the native tools for your target platform. Clone the
`cheetahdex` branch with its exact SDK commit:

```sh
git clone --recurse-submodules https://github.com/p2piratedotcom/P2Pirate-ALPHA.git
cd P2Pirate-ALPHA
git checkout cheetahdex
git submodule sync --recursive
git submodule update --init --recursive
git ls-tree HEAD sdk
git -C sdk rev-parse HEAD
dart pub get -C sdk --enforce-lockfile
flutter pub get --enforce-lockfile
flutter run -d linux
```

The two SDK SHA outputs should match. The [desktop installation guide](INSTALL.md)
lists the supported target commands. The older upstream setup and release
documents are retained as historical reference and may mention removed Web or
mobile targets. On Linux, install a
verified KDF 2.7 executable separately before launching, or use the GUI's
first-run installer for the pinned upstream release. Verified coin parameters must also be staged as described in
[external KDF](docs/P2PIRATE_EXTERNAL_KDF.md). The [Linux asset provenance review](docs/LINUX_ASSET_PROVENANCE.md)
records Tor, torsocks and catalog sources; coin artwork is excluded from the local release recipe. Do not package the
reference ZIP's binaries as a new release solely from these commands. The
[downloadable coin assets guide](docs/P2PIRATE_ASSETS.md) explains the first-run
prompt, restored coin icons, manual updates, and the pinned fallback catalog.

The Linux release bundle runs as `build/linux/x64/release/bundle/P2Pirate`.
Its GTK application ID is `com.p2pirate.wallet`. Existing wallet data and
keyring entries retain their legacy storage names for compatibility; see
[Linux branding and migration](docs/P2PIRATE_BRANDING.md).

Linux Tor design, local assembly and limits are documented in [Tor transport](docs/P2PIRATE_TOR_LINUX.md).

## License, artwork and attribution

The wallet keeps the upstream [GPL-3.0 license](LICENSE) and Git history.
P2Pirate PRs should retain copyright notices and identify modified files.
Third-party components can have different licenses, recorded in `licenses/`
and their own repositories. The Pirate Chain P mark used in the UI is
from the [official media kit](https://github.com/PirateNetwork/mediakit),
with its MIT notice and precise source commit documented in the branding PR.
The [Pirate Chain branding guide](https://piratechain.com/canvas/) currently
prefers the P mark and advises against ship and skull marks. Use of a mark
does not imply official endorsement.

The reference ZIP includes in-app EULA-style text that restricts copying and
modification while the repository declares GPL-3.0. That text is not present
in this fork baseline. Do not import it by simply renaming the product;
review legal copy and attribution separately before a P2Pirate release.

## Upstream and P2Pirate documentation

- [Porting record and source provenance](docs/P2PIRATE_PORTING_PLAN.md)
- [SDK submodule management](docs/SDK_SUBMODULE_MANAGEMENT.md)
- [Test results and known limits](docs/TEST_STATUS.md)
- [Linux desktop integration tests](docs/INTEGRATION_TESTING.md)
- [Upstream project setup](docs/PROJECT_SETUP.md)
- [Upstream build and run guide](docs/BUILD_RUN_APP.md)
- [Upstream contribution guide](docs/CONTRIBUTION_GUIDE.md)
