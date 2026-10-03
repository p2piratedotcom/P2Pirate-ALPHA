#!/bin/sh
# Check the exact Ubuntu binaries, notices and corresponding source packages.
set -eu

if [ "$#" -ne 1 ]; then
  echo 'Usage: verify_tor_bundle.sh FLUTTER_LINUX_BUNDLE' >&2
  exit 2
fi
bundle=$(CDPATH= cd -- "$1" && pwd)
script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
root=$(CDPATH= cd -- "$script_dir/.." && pwd)
lib="$bundle/lib"

for name in tor libtorsocks.so TOR_COPYRIGHT TORSOCKS_COPYRIGHT SOCKS5_PROXY_LICENSE GPL-2.0.txt TOR_SOURCE_README.txt; do
  [ -f "$lib/$name" ] || { echo "Missing Tor file: $name" >&2; exit 1; }
done
[ -x "$lib/tor" ] || { echo 'Tor is not executable' >&2; exit 1; }
cmp -s "$root/licenses/tor/GPL-2.0.txt" "$lib/GPL-2.0.txt" || {
  echo 'The torsocks GPL-2.0 license text differs from the reviewed copy' >&2
  exit 1
}
cmp -s "$root/licenses/tor/TOR_SOURCE_README.txt" "$lib/TOR_SOURCE_README.txt" || {
  echo 'The Tor source notice differs from the reviewed copy' >&2
  exit 1
}

source_dir="$lib/tor-source"
[ -d "$source_dir" ] && [ ! -L "$source_dir" ] || {
  echo 'Tor source directory is missing or is a symbolic link' >&2
  exit 1
}
for source_file in "$source_dir"/* "$source_dir"/.[!.]* "$source_dir"/..?*; do
  [ -e "$source_file" ] || [ -L "$source_file" ] || continue
  case "${source_file##*/}" in
    tor_0.4.9.11.orig.tar.gz|tor_0.4.9.11-0ubuntu0.24.04.1.diff.gz|tor_0.4.9.11-0ubuntu0.24.04.1.dsc|torsocks_2.4.0.orig.tar.bz2|torsocks_2.4.0-1.debian.tar.xz|torsocks_2.4.0-1.dsc) ;;
    *) echo "Unexpected Tor source entry: ${source_file##*/}" >&2; exit 1 ;;
  esac
  [ -f "$source_file" ] && [ ! -L "$source_file" ] || {
    echo "Tor source must be a regular file: ${source_file##*/}" >&2
    exit 1
  }
done
for name in \
  tor_0.4.9.11.orig.tar.gz \
  tor_0.4.9.11-0ubuntu0.24.04.1.diff.gz \
  tor_0.4.9.11-0ubuntu0.24.04.1.dsc \
  torsocks_2.4.0.orig.tar.bz2 \
  torsocks_2.4.0-1.debian.tar.xz \
  torsocks_2.4.0-1.dsc; do
  [ -f "$source_dir/$name" ] || { echo "Missing Tor source: $name" >&2; exit 1; }
done

printf '%s  %s\n' \
  '110abc183ff1f82048ff88fcd54b9894c3e990c2e30706a07afc14e64f8e471f' "$lib/tor" \
  'd96f55211434c18e02f165f3e9fd4221e6a9cb1c18523e22a7c55c2466c0e1f4' "$lib/libtorsocks.so" \
  '90dd3a291395f77fdff828186b4b12077c1b68417aa1ec750450e621c7741b3f' "$lib/TOR_COPYRIGHT" \
  'aa819b52346d167fa6ffa91e307bb14c36412fbf7ed04414677293ed6cc44ba3' "$lib/TORSOCKS_COPYRIGHT" \
  '5d7a3887cd15df1daab8f4f5ac7460d4d2df7219f7ede20e79df70121dfa0c3e' "$lib/SOCKS5_PROXY_LICENSE" \
  '2e6c1720118c812acf0079fd47cf91b6bfaba5d766c321c4d3d2a28d6a11a8ed' "$source_dir/tor_0.4.9.11.orig.tar.gz" \
  '55050ee9245fd316093b4205a247af6a973cd523ab60cd29996e395fe2113f24' "$source_dir/tor_0.4.9.11-0ubuntu0.24.04.1.diff.gz" \
  'db9e25593c3d43db1778548f26bfac2f1bf85bb00449fd11ab696e6f7e21f739' "$source_dir/tor_0.4.9.11-0ubuntu0.24.04.1.dsc" \
  '54b2e3255b697fb69bb92388376419bcef1f94d511da3980f9ed5cd8a41df3a8' "$source_dir/torsocks_2.4.0.orig.tar.bz2" \
  '3d81f8f905372da5cca00b69251f6ca9281f45a898dd74b1decf660f79d9ef13' "$source_dir/torsocks_2.4.0-1.debian.tar.xz" \
  '73f72cb3521d3c330a735f64e35c63eb8b00984a9fecb39fc630122a3c3c5095' "$source_dir/torsocks_2.4.0-1.dsc" | sha256sum --check --status

printf 'Verified Tor binaries, notices and corresponding sources in %s\n' "$bundle"
