# P2Pirate ALPHA

P2Pirate is a community fork of
[ShorelineCrypto/cheetahdex-wallet-web](https://github.com/ShorelineCrypto/cheetahdex-wallet-web),
a Flutter non-custodial wallet and decentralized exchange. This repository
preserves the upstream Git history. P2Pirate behavior is being reapplied from
a source ZIP as small, reviewable pull requests. **The `cheetahdex` branch is
the upstream fork baseline; the draft PRs are not yet a complete P2Pirate
release.** See the [porting inventory](docs/P2PIRATE_PORTING_PLAN.md) and
[open PRs](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pulls).

The reference is the P2Pirate Linux x86_64 source snapshot dated 29 September
2026. It has no original commit history, so each PR records the behavior it
recreates and any intentional difference. The ZIP and its bundled AppImage
are reference material; they are not committed as a source release here.

## Repository map

| Path | Purpose | Provenance |
| --- | --- | --- |
| `lib/` | Flutter wallet, DEX screens, state and services | CheetahDEX upstream, with P2Pirate edits in separate PRs |
| `app_theme/`, `packages/` | App theme and local Flutter packages | Upstream, then reviewed P2Pirate edits |
| `sdk/` | Komodo DeFi Flutter SDK Git submodule | Upstream pin initially; [P2Pirate SDK fork](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter) and pin proposed in a separate PR |
| `assets/` | Wallet graphics, coin data, translations | Mixed; new art must carry its own source and license record |
| `android/`, `ios/`, `linux/`, `macos/`, `web/`, `windows/` | Platform runners and packaging metadata | Upstream until platform-specific branding PRs are merged |
| `docs/`, `test/`, `test_units/`, `test_integration/` | Build guidance and checks | Upstream plus P2Pirate inventory and focused additions |
| `LICENSE`, `licenses/` | Source license and component notices | Retain upstream GPL-3.0 text and third-party notices |

Build output and downloaded executables belong outside source control. The
reference ZIP's KDF, Tor, torsocks and AppImage binaries must have separately
identified versions, licenses, checksums and corresponding source before a
public binary release.

## What is being ported

The [inventory](docs/P2PIRATE_PORTING_PLAN.md) groups the work into ARRR
defaults and activation; P2Pirate identity; navigation and privacy; Swap
layout, diagnostics and order matching; history and recovery; ARRR balance
refresh; USD prices; Linux Tor transport; performance; and reproducible
packaging. A row is complete only after its PR is merged and checked against
the reference behavior. A PR does not imply that a funded swap was tested.

P2Pirate's SDK configuration uses KDF NetID `8762`. The reference ZIP uses
the official CheetahDEX KDF `2.7.0-beta_968f32a` executable from release
`v0.9.4` (SHA-256
`bd171eeee7a1e0d43b070c8ba6ba60a845a26b3db0ef57ca25a394a2b6c02129`).
The SDK source pin and the KDF binary are separate dependencies. The ZIP does
not establish that older custom Rust patches are in that executable. The
existing KDF Market Maker Bot project records the same KDF version and NetID,
but its runtime and wallet profile are distinct; shared version numbers do
not prove end-to-end trading compatibility.

## Build and run from source

Use Flutter `>=3.41.4 <4.0.0` and Dart `>=3.8.1 <4.0.0`, as declared in
`pubspec.yaml`, plus the native tools for your target platform. Clone the
desired wallet branch with the exact SDK commit recorded by that branch:

```sh
git clone --recurse-submodules https://github.com/p2piratedotcom/P2Pirate-ALPHA.git
cd P2Pirate-ALPHA
git checkout <reviewed-wallet-branch-or-commit>
git submodule sync --recursive
git submodule update --init --recursive
git ls-tree HEAD sdk
git -C sdk rev-parse HEAD
flutter pub get --enforce-lockfile
flutter run -d linux
```

The two SDK SHA outputs should match. Choose the Flutter device and build
target for your host; the upstream [setup](docs/PROJECT_SETUP.md),
[run](docs/BUILD_RUN_APP.md) and [release](docs/BUILD_RELEASE.md) guides cover
platform prerequisites. They are upstream documentation and are not evidence
that the current draft P2Pirate stack builds on every platform. Supplying and
verifying the KDF 2.7 runtime is a separate release step. Do not package the
reference ZIP's binaries as a new release solely from these commands.

## License, artwork and attribution

The wallet keeps the upstream [GPL-3.0 license](LICENSE) and Git history.
P2Pirate PRs should retain copyright notices and identify modified files.
Third-party components can have different licenses, recorded in `licenses/`
and their own repositories. The Pirate Chain P mark proposed for the UI is
from the [official media kit](https://github.com/PirateNetwork/mediakit),
with its MIT notice and precise source commit documented in the branding PR.
The [Pirate Chain branding guide](https://piratechain.com/canvas/) currently
prefers the P mark and advises against ship and skull marks. Use of a mark
does not imply official endorsement.

The inherited in-app legal text needs a separate review before a P2Pirate
release: portions describe restrictions that conflict with the repository's
GPL permissions and still attribute the product to other parties. No PR
should simply rename those statements to P2Pirate without resolving the
underlying rights and wording.

## Upstream and P2Pirate documentation

- [Porting record and source provenance](docs/P2PIRATE_PORTING_PLAN.md)
- [SDK submodule management](docs/SDK_SUBMODULE_MANAGEMENT.md)
- [Upstream project setup](docs/PROJECT_SETUP.md)
- [Upstream build and run guide](docs/BUILD_RUN_APP.md)
- [Upstream contribution guide](docs/CONTRIBUTION_GUIDE.md)
