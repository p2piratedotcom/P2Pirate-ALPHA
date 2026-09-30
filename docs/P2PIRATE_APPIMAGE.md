# Local Linux AppImage

The GUI can be packaged as an AppImage after a Linux x86-64 Flutter release build. The AppImage keeps the technical executable name `CheetahDEX` for compatibility with the existing GTK application ID, while the desktop name and icon are P2Pirate. KDF 2.7 stays outside the GUI package and must be installed separately according to [P2PIRATE_EXTERNAL_KDF.md](P2PIRATE_EXTERNAL_KDF.md).

From the repository root:

```sh
flutter pub get --enforce-lockfile
flutter build linux --release --no-pub
scripts/prepare_tor_bundle.sh build/linux/x64/release/bundle /path/to/reviewed/tor-artifacts/linux-x64
APPIMAGE_TOOL=/path/to/trusted/appimagetool scripts/build_local_appimage.sh
```

The packager needs a local `appimagetool` executable. It does not download build tools or KDF, refuses a bundle containing `lib/kdf`, and checks for the Tor and torsocks notices. The output is `dist/P2Pirate-x86_64.AppImage` unless `P2PIRATE_APPIMAGE_OUTPUT` is set. The package includes the GUI license and the modified WebView plugin license.

This recipe is for a local build. Before publishing an AppImage, provide and review the corresponding source for the exact Tor and torsocks binaries, their licenses and notices, the asset provenance, and the Flutter build inputs. The reference ZIP binaries alone are not sufficient for a public release. Record artifact hashes and the source commit in the release notes.
