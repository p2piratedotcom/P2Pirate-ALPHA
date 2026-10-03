#!/bin/sh
set -eu

if [ "$#" -ne 3 ]; then
  echo 'Usage: prepare_tor_bundle.sh FLUTTER_LINUX_BUNDLE TOR_ARTIFACT_DIR TOR_SOURCE_DIR' >&2
  exit 2
fi
bundle=$(CDPATH= cd -- "$1" && pwd)
source_dir=$(CDPATH= cd -- "$2" && pwd)
package_sources=$(CDPATH= cd -- "$3" && pwd)
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
if [ ! -x "$bundle/P2Pirate" ]; then
  echo 'Build the Linux GUI first' >&2
  exit 1
fi
for name in tor libtorsocks.so TOR_COPYRIGHT TORSOCKS_COPYRIGHT SOCKS5_PROXY_LICENSE; do
  if [ ! -f "$source_dir/$name" ]; then
    echo "Missing Tor artifact: $name" >&2
    exit 1
  fi
done
install -d -m 755 "$bundle/lib"
source_staging=$(mktemp -d "$bundle/lib/.tor-source.XXXXXX")
trap 'rm -rf -- "$source_staging"' EXIT
chmod 755 "$source_staging"
install -m 755 "$source_dir/tor" "$bundle/lib/tor"
install -m 644 "$source_dir/libtorsocks.so" "$bundle/lib/libtorsocks.so"
for name in TOR_COPYRIGHT TORSOCKS_COPYRIGHT SOCKS5_PROXY_LICENSE; do
  install -m 644 "$source_dir/$name" "$bundle/lib/$name"
done
install -m 644 "$root/licenses/tor/GPL-2.0.txt" "$bundle/lib/GPL-2.0.txt"
install -m 644 "$root/licenses/tor/TOR_SOURCE_README.txt" "$bundle/lib/TOR_SOURCE_README.txt"
for name in \
  tor_0.4.9.11.orig.tar.gz \
  tor_0.4.9.11-0ubuntu0.24.04.1.diff.gz \
  tor_0.4.9.11-0ubuntu0.24.04.1.dsc \
  torsocks_2.4.0.orig.tar.bz2 \
  torsocks_2.4.0-1.debian.tar.xz \
  torsocks_2.4.0-1.dsc; do
  install -m 644 "$package_sources/$name" "$source_staging/$name"
done
# Copy first so an input source directory inside the existing bundle is safe.
# Replacing it removes stale entries from repeated packaging runs.
rm -rf -- "$bundle/lib/tor-source"
mv -- "$source_staging" "$bundle/lib/tor-source"
"$script_dir/verify_tor_bundle.sh" "$bundle"
printf 'Tor transport prepared in %s/lib\n' "$bundle"
