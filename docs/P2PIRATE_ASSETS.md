# Downloadable coin assets

The P2Pirate desktop GUI uses the independent [Assets repository](https://github.com/p2piratedotcom/Assets) for coin configuration and the 453 restored coin PNGs. The repository also records seed-node data; the current Tor-mode KDF path continues to use its bundled seed-node fallback. The artwork has a separate provenance notice; the repository's Unlicense applies only to P2Pirate-authored tooling. The JSON input is attributed to its documented source commit in the Assets README.

On a Linux profile without installed assets, the wallet asks whether to download them. Choosing the bundled catalog stores the skip choice; Settings → General → **Check updates** can still download later. When Tor is enabled, the GitHub request uses the wallet's Tor HTTP proxy. A Tor failure does not authorize a direct fallback.

The downloader requests the current commit SHA from the GitHub API and fetches the archive at that immutable SHA. It accepts only the expected coin files and `icons/*.png`, enforces compressed and uncompressed size limits, checks every SHA-256 against `manifest.json`, and switches the local pointer only after verification. A failed update leaves the previous snapshot in place. The app parses the verified catalog into the SDK store before KDF startup; restored icons load from the verified snapshot directory. Updates downloaded while the wallet is running are activated on the next launch.

The Linux package still carries the pinned 2026-09-29 JSON configuration as a fallback. It does not include third-party coin artwork. The former automatic SDK coin updater is disabled, so an Assets update requires the user's action in Settings.
