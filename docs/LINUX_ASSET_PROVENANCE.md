# Linux release asset provenance review

Reviewed 2 October 2026. This inventory covers the Tor transport in the
29 September 2026 reference ZIP and the coin assets required by a Linux GUI
package. It does not approve a public AppImage release.

## Tor and torsocks

The reference ZIP contains these Linux x86-64 files under
`source/artifacts/tor/linux-x64/`:

| File | ZIP SHA-256 | Identical Ubuntu package file |
| --- | --- | --- |
| `tor` | `110abc183ff1f82048ff88fcd54b9894c3e990c2e30706a07afc14e64f8e471f` | `tor` 0.4.9.11-0ubuntu0.24.04.1, `/usr/bin/tor` |
| `libtorsocks.so` | `d96f55211434c18e02f165f3e9fd4221e6a9cb1c18523e22a7c55c2466c0e1f4` | `torsocks` 2.4.0-1, `/usr/lib/x86_64-linux-gnu/torsocks/libtorsocks.so.0` |

Both files were compared byte for byte against the corresponding Ubuntu 24.04
amd64 `.deb` payloads. `TOR_COPYRIGHT` and `TORSOCKS_COPYRIGHT` in the ZIP
also match the packages' `usr/share/doc/*/copyright` files byte for byte.
The package archive SHA-256 digests used for this comparison were
`35818718981ab85e549c536278696f9821f84c62f9e3718dc5af174dfc37b428`
for Tor and `565f8f4f22e97107a4d511026be55d9f632e27e487b3c47bc76f842cc5fb1bda`
for torsocks. The [Tor source package](https://packages.ubuntu.com/source/noble-updates/net/tor)
and [torsocks source package](https://packages.ubuntu.com/source/noble/net/torsocks)
identify the exact source tarballs and packaging changes.

The *Ubuntu build* of `tor` is GPLv3: its `--version` output says so, and the
Ubuntu source package's `debian/rules` passes `--enable-gpl`. The general
upstream Tor BSD notice alone does not describe this binary's full terms.
`libtorsocks.so` is GPL-2-or-later according to its package copyright file.
`SOCKS5_PROXY_LICENSE` in the ZIP is MIT. These licenses are not transferred
to the P2Pirate GUI merely by bundling the files.

For a public AppImage, retain the exact package notices, identify both source
packages and make the complete corresponding source available alongside the
binary or by another distribution method compliant with their licenses. The
GUI's `LICENSE` supplies the GPLv3 text, but the local packaging recipe does
not currently add the full GPLv2 text for torsocks. Include it and document
which bundled file each license covers. Record package and executable hashes
in release notes. The byte comparison establishes the package origin; it is
not an independent reproducible-build proof.

## Coin catalog and icons

The reference ZIP's `coins.json`, `coins_config.json` and `seed_nodes.json`
are byte-identical to `coins`, `utils/coins_config_unfiltered.json` and
`seed-nodes.json` at
[`ShorelineCrypto/coins@98b29f5`](https://github.com/ShorelineCrypto/coins/tree/98b29f5ea53a46a701e791a565a5fab7ee83b947).
All 453 PNGs in the ZIP's `coin_icons/png/` match the Git blobs in that
commit's `icons/` directory, with no missing or changed images.

The current SDK build configuration instead names
[`ShorelineCrypto/coins@b8f8566`](https://github.com/ShorelineCrypto/coins/tree/b8f85666325ca1cc6306ca113e7129d73e77e0f0).
It has `fetch_at_build_enabled: false`; Git tracks only `.gitkeep` files in
the coin asset directories. A clean build therefore needs explicitly staged
catalogs and icons. The existing local Linux bundle has no coin catalog JSONs
or PNGs and cannot pass `scripts/build_local_appimage.sh`.

At the reviewed commits, neither `ShorelineCrypto/coins` nor its
`KomodoPlatform/coins` parent declares a repository license or contains a
license/copyright/attribution file. The 453 icon files also have no
file-specific license records there. Public availability and exact source
identification do not establish permission to redistribute the catalog and
artwork. The GUI's GPL-3.0 license does not grant rights over these separate
assets. Obtain an explicit redistribution grant that covers both catalog data
and each icon (including any third-party contributors), or replace them with
assets whose licenses are recorded, before publishing an AppImage containing
them. Keep the selected commit and file hashes in the release manifest.

GitHub's [repository licensing guidance](https://docs.github.com/en/repositories/managing-your-repositorys-settings-and-features/customizing-your-repository/licensing-a-repository)
explains why a public repository without a license is not an automatic grant
for reuse. The [GPLv2](https://www.gnu.org/licenses/old-licenses/gpl-2.0.html)
and [GPLv3](https://www.gnu.org/licenses/gpl-3.0.html) texts state the source
distribution conditions for their respective binaries.
