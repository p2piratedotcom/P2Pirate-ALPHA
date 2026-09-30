#!/bin/sh
set -eu

# Install a per-user GNOME launcher for a local Flutter Linux bundle.
# An optional second argument may point to a launcher that sets up KDF.
if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
  echo 'Usage: install_linux_desktop.sh BUNDLE_DIR [LAUNCHER]' >&2
  exit 2
fi

bundle=$(CDPATH= cd -- "$1" && pwd)
if [ "$#" -eq 2 ]; then
  launcher_dir=$(CDPATH= cd -- "$(dirname -- "$2")" && pwd)
  launcher="$launcher_dir/$(basename -- "$2")"
else
  launcher="$bundle/CheetahDEX"
fi
if [ ! -x "$launcher" ] || [ ! -f "$bundle/PirateWallet.png" ]; then
  echo 'Bundle executable, launcher, or PirateWallet.png is missing' >&2
  exit 1
fi

data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
applications="$data_home/applications"
icons="$data_home/icons/hicolor/512x512/apps"
mkdir -p "$applications" "$icons"
install -m 644 "$bundle/PirateWallet.png" "$icons/PirateWallet.png"
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$data_home/icons/hicolor"
fi

# GTK's application ID remains com.shorelinecrypto.CheetahDEX, so the desktop
# file has the same basename. GNOME uses this match for the running dock icon.
desktop="$applications/com.shorelinecrypto.CheetahDEX.desktop"
cat > "$desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=P2Pirate
Exec="$launcher"
Icon=PirateWallet
Categories=Office;Finance;
Terminal=false
StartupNotify=true
StartupWMClass=CheetahDEX
EOF
desktop-file-validate "$desktop"
echo "$desktop"
