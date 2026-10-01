# P2Pirate desktop build and installation

P2Pirate targets Linux, macOS and Windows desktop. Android and Web app runners
are no longer in this repository. The iOS runner is retained as upstream
reference, but is not a supported P2Pirate target. Linux is the only target
built locally for this port so far; macOS and Windows need builds and wallet
checks on their own hosts before distribution.

## Prerequisites

Use Flutter `>=3.47.5 <4.0.0` with Dart `>=3.11.0 <4.0.0`, as required by
`pubspec.yaml`. Install the native build tools for your desktop host. Flutter's
[desktop setup guide](https://docs.flutter.dev/platform-integration/desktop)
lists those tools; missing Android SDK or Chrome support does not prevent a
desktop build. Keep the SDK submodule at the revision recorded by this repo.

The Linux GUI needs a separate, compatible KDF 2.7 executable. See
[external KDF](docs/P2PIRATE_EXTERNAL_KDF.md) for the reviewed release,
checksum, first-run installer and coin catalog inputs. Tor is enabled by
default on Linux; its local packaging and limits are documented in
[Tor transport](docs/P2PIRATE_TOR_LINUX.md).

## Linux build

```sh
git clone --recurse-submodules https://github.com/p2piratedotcom/P2Pirate-ALPHA.git
cd P2Pirate-ALPHA
git checkout cheetahdex
git submodule update --init --recursive
flutter pub get --enforce-lockfile
# Stage the reviewed coin catalog and icons as described in the external KDF guide.
flutter build linux --release --no-pub
P2PIRATE_KDF_PATH=/absolute/path/to/kdf build/linux/x64/release/bundle/P2Pirate
```

For a distributable local Linux package, follow
[the AppImage recipe](docs/P2PIRATE_APPIMAGE.md). Do not publish an AppImage
until its coin, Tor/torsocks and KDF source and license requirements are
satisfied.

## macOS and Windows

Use `flutter build macos --release` on macOS or
`flutter build windows --release` on Windows after resolving the same pinned
SDK and build assets. These commands describe the intended desktop targets;
they are not a claim that either build or its KDF/Tor integration has passed
native-host verification. macOS distribution also needs the P2Pirate team's
own signing credentials and an app-data migration review because its bundle
ID is now `com.p2pirate.wallet`.

The older upstream setup and release documents under `docs/` are retained for
historical reference. Their Web/Android commands do not apply to P2Pirate.
