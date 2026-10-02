# Tor transport on Linux desktop

Tor is enabled by default for Linux desktop installations, including migrated settings that do not have a Tor preference. **Settings > General > Tor network** stores the desired state; restart the app to apply it. The wallet header shows Tor active, connecting, unavailable, or off. The active label means Tor bootstrapped, a KDF seed resolved, and the local proxy started; it is not proof that every remote service is reachable.

At startup the GUI launches a Tor client with a loopback SOCKS port and confirms that a bundled KDF seed hostname resolves through Tor. It then configures a loopback HTTP bridge for Dart `HttpClient` and the Linux WebKit view. KDF RPC on loopback stays direct. The Flutter SDK resolves KDF seed hostnames using Tor SOCKS RESOLVE, and the KDF child process uses `libtorsocks.so` through `LD_PRELOAD`. If Tor cannot start, the wallet asks whether to retry Tor after restart, use a direct connection after restart, or close. KDF startup errors under Tor and a Tor process exit while the wallet is open show the same choice. The current session never switches to a direct connection. Only an explicit choice to use a direct connection changes the saved Tor preference, and the change takes effect on the next launch.

Tor bootstrap can stall temporarily while connecting to a relay or loading
directory information. The GUI now waits for progress rather than applying a
single two-minute deadline: it restarts Tor once if progress stops for 75
seconds, a Tor process exits early, or the seed lookup fails. Each attempt is
capped at three minutes. The error screen reports the last bootstrap percentage
or failed stage if both attempts fail. No direct connection is attempted during
either retry. This helps transient failures; a blocked Tor network still
requires a network remedy or an explicit user choice to turn Tor off.

GUI and Flutter SDK remain in separate repositories. This GUI branch needs a matching `komodo-defi-sdk-flutter` commit that exports `KdfTorConfig` and routes KDF seed lookup and executable traffic through Tor. A GUI-only release cannot claim KDF Tor coverage.

## Local Linux build

```sh
flutter pub get
flutter build linux --release --no-pub
scripts/prepare_tor_bundle.sh build/linux/x64/release/bundle /path/to/tor-artifacts/linux-x64 /path/to/ubuntu-tor-source-packages
P2PIRATE_KDF_PATH=/path/to/separate/kdf-2.7 build/linux/x64/release/bundle/P2Pirate
```

The Tor artifact directory must contain the pinned Ubuntu 24.04 Tor `0.4.9.11-0ubuntu0.24.04.1` executable, torsocks `2.4.0-1` shared library, and the three notices named by the script. The source directory must contain the six corresponding Ubuntu source package files. The script checks binary, notice and source hashes and includes all source files plus the full torsocks GPLv2 text in the bundle. KDF 2.7 is installed or downloaded separately; it is not part of the GUI Git tree. The local Flutter build directory is ignored by Git.

The GUI source carries a modified MIT-licensed `webview_all_linux` 1.4.1 plugin under `packages/` and its change note in `PIRATE_PATCH.md`. The Tor and torsocks binaries are **not** committed. The reviewed Ubuntu Tor build is GPLv3 because it uses `--enable-gpl`; torsocks is GPL-2-or-later. Both source packages and notices are staged locally for AppImage packaging and independently rechecked by `verify_tor_bundle.sh`. See [provenance review](LINUX_ASSET_PROVENANCE.md).

## Checks and limits

Run `flutter test --no-pub test_units/pirate_tor_http_test.dart test_units/pirate_tor_settings_test.dart`. The tests cover proxy routing, loopback KDF RPC, POST, image loading, outage handling, preference persistence, and Tor seed resolution. A live Tor exit test is skipped unless `PIRATE_TOR_SOCKS_PORT` is set. For a live run, also inspect process sockets: the GUI and KDF should connect only to loopback, while Tor owns external sockets. Check actual wallet activation and transactions separately with a test wallet before any privacy claim.

This implementation covers the Dart HTTP client, the patched Linux WebView, and the KDF process. Native plugins or external programs can have independent networking. The embedded browser handles HTTP(S) links while Tor is enabled; opening a separate system browser would use that browser's network settings. There is no tested blanket guarantee that all possible GUI or KDF traffic is anonymized. If a Tor exit or requested service is unreachable, the startup may fail closed or a feature may remain unavailable.

## Legacy GLEEC services

The unreachable geo-blocking client and its URLs were removed. Faucet and fiat endpoints are unset by default and can only be provided explicitly at build time with `P2PIRATE_FAUCET_BASE_URL`, `P2PIRATE_FIAT_API_URL`, `P2PIRATE_FIAT_LOGO_URL`, and `P2PIRATE_APP_ORIGIN`. Without a configured faucet, the faucet button is hidden. The old maker-bot settings no longer write a GLEEC price URL.

Ethereum transaction history still defaults to a GLEEC Etherscan-compatible URL in the SDK and may be used when ETH assets are activated. NFT RPC paths also retain GLEEC URLs, although the current GUI does not expose the NFT flow. Removing these without a verified replacement would break transaction history or NFT metadata; they remain explicitly listed for a separate migration. `GLEECT` is an asset identifier, so removing it would change coin support. Historical upstream links are preserved for attribution.
