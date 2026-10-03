#!/usr/bin/env bash
# Package a reviewed local Linux bundle. KDF remains an external prerequisite.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
OUTPUT="${P2PIRATE_APPIMAGE_OUTPUT:-$ROOT/dist/P2Pirate-x86_64.AppImage}"
SOURCE_OUTPUT="${P2PIRATE_TOR_SOURCE_OUTPUT:-$ROOT/dist/P2Pirate-Tor-torsocks-sources.tar.gz}"
: "${APPIMAGE_TOOL:?Set APPIMAGE_TOOL to a trusted local appimagetool executable}"
APPIMAGE_TOOL="$(realpath "$APPIMAGE_TOOL")"
: "${APPIMAGE_RUNTIME_FILE:?Set APPIMAGE_RUNTIME_FILE to the pinned Linux x86_64 AppImage runtime}"
APPIMAGE_RUNTIME_FILE="$(realpath "$APPIMAGE_RUNTIME_FILE")"
[[ "$(uname -m)" == x86_64 ]] || { echo 'Linux x86_64 is required' >&2; exit 1; }
[[ -x "$APPIMAGE_TOOL" ]] || { echo 'APPIMAGE_TOOL is not executable' >&2; exit 1; }
printf '%s  %s\n' \
  '156f4bdbde9c52d01814600013e0a273f0118dc2de98975f3c8c63427ec79074' \
  "$APPIMAGE_RUNTIME_FILE" | sha256sum --check --status
[[ -x "$BUNDLE/P2Pirate" ]] || { echo 'Build the Linux release bundle first' >&2; exit 1; }
[[ -s "$BUNDLE/P2Pirate.svg" ]] || { echo 'Missing vector window icon in Linux bundle' >&2; exit 1; }
[[ -s "$BUNDLE/data/flutter_assets/assets/logo/p2pirate_mark.svg" ]] || {
  echo 'Missing vector wallet logo in Flutter assets' >&2
  exit 1
}
COIN_ASSETS="$BUNDLE/data/flutter_assets/packages/komodo_defi_framework/assets"
for name in coins.json coins_config.json seed_nodes.json; do
  [[ -s "$COIN_ASSETS/config/$name" ]] || {
    echo "Missing coin catalog in Flutter bundle: $name" >&2
    exit 1
  }
done
printf '%s  %s\n' \
  '0a4b57a86b3f25385961dba9f3b57804da8576a9c0d10073ce2b6afb3401418f' "$COIN_ASSETS/config/coins.json" \
  '5d77f607f05dc97f488011d0800e49239faa05f44a2c6578bc90df125f0459a5' "$COIN_ASSETS/config/coins_config.json" \
  'd880dd324f0c77017ad92147dd10ad095d37dc53fff0284abc13c9b333bc85fd' "$COIN_ASSETS/config/seed_nodes.json" | sha256sum --check --status
if find "$COIN_ASSETS/coin_icons/png" -maxdepth 1 -type f -name '*.png' -print -quit | grep -q .; then
  echo 'Coin artwork without documented redistribution rights is not accepted' >&2
  exit 1
fi
"$ROOT/scripts/verify_tor_bundle.sh" "$BUNDLE"
[[ ! -e "$BUNDLE/lib/kdf" ]] || { echo 'KDF must not be bundled with the GUI' >&2; exit 1; }

mkdir -p "$ROOT/dist" "$(dirname "$OUTPUT")" "$(dirname "$SOURCE_OUTPUT")"
APPDIR="$(mktemp -d "$ROOT/dist/P2Pirate.XXXXXX.AppDir")"
STAGED="$(mktemp "$ROOT/dist/P2Pirate.XXXXXX.AppImage")"
SOURCE_STAGED="$(mktemp "$ROOT/dist/P2Pirate.TorSources.XXXXXX.tar.gz")"
trap 'rm -rf "$APPDIR"; rm -f "$STAGED" "$SOURCE_STAGED"' EXIT
cp -a "$BUNDLE/." "$APPDIR/"
install -m 644 "$ROOT/LICENSE" "$APPDIR/LICENSE"
install -m 644 "$ROOT/packages/webview_all_linux/LICENSE" "$APPDIR/WEBVIEW_ALL_LINUX_LICENSE"
install -m 644 "$ROOT/licenses/coin-data/SOURCE.txt" "$APPDIR/COIN_DATA_SOURCE.txt"
install -m 644 "$ROOT/linux/com.p2pirate.wallet.desktop" "$APPDIR/com.p2pirate.wallet.desktop"
install -m 644 "$ROOT/linux/P2Pirate.png" "$APPDIR/P2Pirate.png"
cat > "$APPDIR/AppRun" <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
cd "$HERE"
exec ./P2Pirate "$@"
RUN
chmod +x "$APPDIR/AppRun"
# SquashFS records mtimes. Use the source commit timestamp unless the caller
# explicitly supplies a release epoch, then normalize every staged entry.
if [[ -z "${SOURCE_DATE_EPOCH:-}" ]]; then
  SOURCE_DATE_EPOCH="$(git -C "$ROOT" log -1 --format=%ct)"
fi
[[ "$SOURCE_DATE_EPOCH" =~ ^[0-9]+$ ]] || {
  echo 'SOURCE_DATE_EPOCH must be a Unix timestamp' >&2
  exit 1
}
export SOURCE_DATE_EPOCH
find "$APPDIR" -exec touch -h -d "@$SOURCE_DATE_EPOCH" {} +
APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 "$APPIMAGE_TOOL" \
  --runtime-file "$APPIMAGE_RUNTIME_FILE" "$APPDIR" "$STAGED"
chmod +x "$STAGED"
# Offer the corresponding source at the same download location as the AppImage.
tar --sort=name --mtime="@$SOURCE_DATE_EPOCH" --owner=0 --group=0 \
  --numeric-owner -cf - -C "$APPDIR" \
  lib/tor-source lib/TOR_COPYRIGHT lib/TORSOCKS_COPYRIGHT \
  lib/SOCKS5_PROXY_LICENSE lib/GPL-2.0.txt lib/TOR_SOURCE_README.txt LICENSE \
  | gzip -n > "$SOURCE_STAGED"
mv -f "$STAGED" "$OUTPUT"
mv -f "$SOURCE_STAGED" "$SOURCE_OUTPUT"
sha256sum "$OUTPUT" "$SOURCE_OUTPUT"
