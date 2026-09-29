# Linux desktop: GUI and KDF as separate components

P2Pirate-ALPHA contains the Flutter GUI. Its `sdk/` submodule points to
[`p2piratedotcom/komodo-defi-sdk-flutter`](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter),
which is the Dart/Flutter adapter used to communicate with KDF. The adapter
does **not** contain KDF's Rust source. The upstream Rust project is
[`ShorelineCrypto/komodo-defi-framework`](https://github.com/ShorelineCrypto/komodo-defi-framework).
The SDK fork is the intended P2Pirate release location for a separately
installed Linux KDF executable. It has no KDF release asset as of 29 September
2026, so automatic installation is not yet available.

## Current behavior

The Linux SDK revision in [SDK PR #4](https://github.com/p2piratedotcom/komodo-defi-sdk-flutter/pull/4)
uses an external executable and does not bundle, copy, or chmod one during the
GUI build or startup. [GUI PR #27](https://github.com/p2piratedotcom/P2Pirate-ALPHA/pull/27)
pins that SDK revision. The Linux search order is:

1. `P2PIRATE_KDF_PATH`, if set to an absolute path. An invalid configured path
   fails instead of silently selecting another executable.
2. `$HOME/.local/share/p2pirate/kdf/current/kdf`.
3. `/usr/local/bin/kdf`, `/usr/bin/kdf`, then `$HOME/.local/bin/kdf`.

The GUI does not run KDF initialization successfully if none of these paths
contains an executable. Old copies in the checkout or Flutter bundle are
deliberately excluded on Linux.

For a development installation, set `P2PIRATE_KDF_PATH` to the absolute path of
an independently obtained, executable, compatible KDF 2.7 binary before
launching the GUI. The ZIP reference's asset preparation script copied an
external KDF into the SDK *at build time*; that explains why the older GUI
worked on a machine with KDF supplied separately, despite the final bundle
containing KDF.

## Release contract needed for first-run installation

Before enabling a GUI download button, publish a Linux x86-64 KDF 2.7 release
in the SDK fork with:

- the exact Rust source repository URL and commit, build instructions, license,
  and any corresponding source distribution obligations;
- the Linux executable as a GitHub Release asset, its SHA-256 digest, its
  architecture, and a documented KDF/SDK compatibility version;
- a stable release tag and an explicit indication whether it is suitable for
  P2Pirate's NetID 8762 configuration.

The GUI should show the latest **compatible** published release on first run,
ask before downloading, verify HTTPS origin and a digest recorded in a reviewed
GUI compatibility manifest, then place the verified binary in a per-user,
versioned directory under `$HOME/.local/share/p2pirate/kdf/`. It should switch
`current` only after download, verification, and an executable check succeed.
An existing working KDF should remain available for rollback. A failed or
declined download must leave the GUI in a clear setup state; it must never run
an unchecked file or change the active binary silently.

Fetching GitHub's unfiltered `latest` release would permit a future
incompatible KDF version to replace 2.7. The GUI compatibility manifest must
select a reviewed release tag and SHA-256, and can be updated by a separate
reviewable GUI change when another version is approved. The SDK repository is
the release host; it is not a substitute for the Rust source provenance.

The CheetahDEX `v0.9.4` source tag pins SDK commit `50d0cb8`, whose build
configuration points to Rust commit `968f32a6bccf20f286d1b8e2520b62ebe769522b`
and the [official KDF `v2.7.0-beta` Linux x86-64 ZIP](https://github.com/ShorelineCrypto/komodo-defi-framework/releases/tag/v2.7.0-beta).
The downloaded archive has SHA-256
`cf80e5d5ae78605d6f0f6a806aa9ae5b83bbee0ef79ccd5ad85022ae2a5d7d27`;
its `kdf` executable has SHA-256
`bd171eeee7a1e0d43b070c8ba6ba60a845a26b3db0ef57ca25a394a2b6c02129`.
That executable is byte-identical to the one in the ZIP reference. The local
KDF build notes also cite `cf7e95b9d5170dca2b16baf7f9b5a215b916806af17cb891ad6b9aef2bf1d568`:
that is a different artifact and should not be described as the bundled one.
The matching hashes identify the published upstream artifact; they do not by
themselves prove a reproducible build from Rust source.

## Build inputs and remaining work

With SDK PR #4, build-time KDF and coin downloads are disabled. KDF is a
runtime prerequisite. Coin metadata and icons are a different build input:
stage the reviewed `coins.json`, `coins_config.json`, `seed_nodes.json`, and
`coin_icons/png/` beneath `sdk/packages/komodo_defi_framework/assets/` before
building. Those paths are ignored by Git. The ZIP snapshot's coin files can be
used locally for comparison; their distribution terms still need review before
they are republished. The project has not yet produced a verified Linux release
build with this split, and no automatic first-run KDF installer has been merged.
