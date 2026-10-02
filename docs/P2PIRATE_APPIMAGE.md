# Local Linux AppImage

The GUI can be packaged as an AppImage after a Linux x86-64 Flutter release build. The executable is `P2Pirate` and the GTK application ID and desktop file are `com.p2pirate.wallet`. KDF 2.7 stays outside the GUI package and must be installed separately according to [P2PIRATE_EXTERNAL_KDF.md](P2PIRATE_EXTERNAL_KDF.md). The existing wallet data directory and Linux keyring namespace remain compatible; see [branding and migration](P2PIRATE_BRANDING.md).

From the repository root:

```sh
flutter pub get --enforce-lockfile
scripts/stage_coin_catalog.sh
flutter build linux --release --no-pub
scripts/prepare_tor_bundle.sh build/linux/x64/release/bundle /path/to/reviewed/tor-artifacts/linux-x64 /path/to/ubuntu-tor-source-packages
APPIMAGE_TOOL=/path/to/trusted/appimagetool APPIMAGE_RUNTIME_FILE=/path/to/runtime-x86_64 scripts/build_local_appimage.sh
```

The packager needs a local `appimagetool` executable and the pinned [type2 Linux x86-64 runtime](https://github.com/AppImage/type2-runtime/releases) with SHA-256 `156f4bdbde9c52d01814600013e0a273f0118dc2de98975f3c8c63427ec79074`; it does not download build tools or KDF and refuses a bundle containing `lib/kdf`. Stage the three pinned coin parameter files **before** building Flutter, using `stage_coin_catalog.sh` with no argument to download from the fixed source commit or with a directory containing verified `coins.json`, `coins_config.json` and `seed_nodes.json`. The packager checks their hashes. Coin PNGs are excluded because the public coin repository does not document rights to redistribute its graphics; the SDK renders a local ticker badge instead. The output is `dist/P2Pirate-x86_64.AppImage` unless `P2PIRATE_APPIMAGE_OUTPUT` is set.

The Tor source directory must contain the three files of the [Ubuntu Tor 0.4.9.11-0ubuntu0.24.04.1 source package](https://packages.ubuntu.com/source/noble-updates/net/tor) and the three files of the [Ubuntu torsocks 2.4.0-1 source package](https://packages.ubuntu.com/source/noble/net/torsocks). `prepare_tor_bundle.sh` checks their fixed hashes, copies them into `lib/tor-source/`, and includes the package copyright notices plus the full GPLv2 text for torsocks. The AppImage also contains the GUI's GPLv3 text, which covers the Ubuntu Tor build, the modified WebView plugin license and `COIN_DATA_SOURCE.txt`. `build_local_appimage.sh` rechecks all Tor/source hashes before packaging. See [provenance review](LINUX_ASSET_PROVENANCE.md). Record the final AppImage SHA-256 and GUI source commit in release notes; a local build is not automatically a public release.
