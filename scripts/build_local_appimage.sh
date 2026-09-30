#!/usr/bin/env bash
# Package a reviewed local Linux bundle. KDF remains an external prerequisite.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUNDLE="$ROOT/build/linux/x64/release/bundle"
OUTPUT="${P2PIRATE_APPIMAGE_OUTPUT:-$ROOT/dist/P2Pirate-x86_64.AppImage}"
: "${APPIMAGE_TOOL:?Set APPIMAGE_TOOL to a trusted local appimagetool executable}"
APPIMAGE_TOOL="$(realpath "$APPIMAGE_TOOL")"
[[ "$(uname -m)" == x86_64 ]] || { echo 'Linux x86_64 is required' >&2; exit 1; }
[[ -x "$APPIMAGE_TOOL" ]] || { echo 'APPIMAGE_TOOL is not executable' >&2; exit 1; }
[[ -x "$BUNDLE/CheetahDEX" ]] || { echo 'Build the Linux release bundle first' >&2; exit 1; }
[[ -x "$BUNDLE/lib/tor" && -f "$BUNDLE/lib/libtorsocks.so" ]] || {
  echo 'Stage the reviewed Tor transport with scripts/prepare_tor_bundle.sh first' >&2
  exit 1
}
[[ ! -e "$BUNDLE/lib/kdf" ]] || { echo 'KDF must not be bundled with the GUI' >&2; exit 1; }
for notice in TOR_COPYRIGHT TORSOCKS_COPYRIGHT SOCKS5_PROXY_LICENSE; do
  [[ -f "$BUNDLE/lib/$notice" ]] || { echo "Missing $notice" >&2; exit 1; }
done

mkdir -p "$ROOT/dist" "$(dirname "$OUTPUT")"
APPDIR="$(mktemp -d "$ROOT/dist/P2Pirate.XXXXXX.AppDir")"
STAGED="$(mktemp "$ROOT/dist/P2Pirate.XXXXXX.AppImage")"
trap 'rm -rf "$APPDIR"; rm -f "$STAGED"' EXIT
cp -a "$BUNDLE/." "$APPDIR/"
install -m 644 "$ROOT/LICENSE" "$APPDIR/LICENSE"
install -m 644 "$ROOT/packages/webview_all_linux/LICENSE" "$APPDIR/WEBVIEW_ALL_LINUX_LICENSE"
install -m 644 "$ROOT/linux/CheetahDEX.desktop" "$APPDIR/com.shorelinecrypto.CheetahDEX.desktop"
install -m 644 "$ROOT/linux/PirateWallet.png" "$APPDIR/PirateWallet.png"
cat > "$APPDIR/AppRun" <<'RUN'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0")")"
cd "$HERE"
exec ./CheetahDEX "$@"
RUN
chmod +x "$APPDIR/AppRun"
APPIMAGE_EXTRACT_AND_RUN=1 ARCH=x86_64 "$APPIMAGE_TOOL" "$APPDIR" "$STAGED"
chmod +x "$STAGED"
mv -f "$STAGED" "$OUTPUT"
printf '%s\n' "$OUTPUT"
