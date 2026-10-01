#!/bin/sh
set -eu

if [ "$#" -ne 2 ]; then
  echo 'Usage: prepare_tor_bundle.sh FLUTTER_LINUX_BUNDLE TOR_ARTIFACT_DIR' >&2
  exit 2
fi
bundle=$(CDPATH= cd -- "$1" && pwd)
source_dir=$(CDPATH= cd -- "$2" && pwd)
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
printf '%s  %s\n' \
  '110abc183ff1f82048ff88fcd54b9894c3e990c2e30706a07afc14e64f8e471f' "$source_dir/tor" \
  'd96f55211434c18e02f165f3e9fd4221e6a9cb1c18523e22a7c55c2466c0e1f4' "$source_dir/libtorsocks.so" | sha256sum --check --status
install -m 755 "$source_dir/tor" "$bundle/lib/tor"
install -m 644 "$source_dir/libtorsocks.so" "$bundle/lib/libtorsocks.so"
for name in TOR_COPYRIGHT TORSOCKS_COPYRIGHT SOCKS5_PROXY_LICENSE; do
  install -m 644 "$source_dir/$name" "$bundle/lib/$name"
done
printf 'Tor transport prepared in %s/lib\n' "$bundle"
