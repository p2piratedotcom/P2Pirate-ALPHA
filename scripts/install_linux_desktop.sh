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
  launcher="$bundle/P2Pirate"
fi
if [ ! -x "$launcher" ] || [ ! -f "$bundle/P2Pirate.png" ] \
   || [ ! -f "$bundle/P2Pirate.svg" ]; then
  echo 'Bundle executable, launcher, or P2Pirate icons are missing' >&2
  exit 1
fi

data_home=${XDG_DATA_HOME:-"$HOME/.local/share"}
applications="$data_home/applications"
icons="$data_home/icons/hicolor/512x512/apps"
scalable_icons="$data_home/icons/hicolor/scalable/apps"
mkdir -p "$applications" "$icons" "$scalable_icons"
install -m 644 "$bundle/P2Pirate.png" "$icons/P2Pirate.png"
install -m 644 "$bundle/P2Pirate.svg" "$scalable_icons/P2Pirate.svg"
if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  gtk-update-icon-cache -f -t "$data_home/icons/hicolor"
fi

# The desktop filename matches the GTK application ID so GNOME associates the
# launcher and running window with the same P2Pirate icon.
desktop="$applications/com.p2pirate.wallet.desktop"
cat > "$desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=P2Pirate
Exec="$launcher"
Icon=P2Pirate
Categories=Office;Finance;
Terminal=false
StartupNotify=true
StartupWMClass=P2Pirate
EOF
desktop-file-validate "$desktop"
# Remove only the old P2Pirate launcher installed under the upstream ID.
# Leave unrelated or user-customized desktop entries untouched.
legacy_desktop="$applications/com.shorelinecrypto.CheetahDEX.desktop"
if [ -f "$legacy_desktop" ] \
   && grep -qx 'Name=P2Pirate' "$legacy_desktop" \
   && grep -qx 'Icon=PirateWallet' "$legacy_desktop" \
   && grep -qx 'StartupWMClass=CheetahDEX' "$legacy_desktop"; then
  rm -- "$legacy_desktop"
fi
echo "$desktop"
