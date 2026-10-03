#!/bin/sh
# Stage the public coin parameters pinned to the reference ZIP revision.
# Artwork is deliberately not copied or downloaded.
set -eu

if [ "$#" -gt 1 ]; then
  echo 'Usage: stage_coin_catalog.sh [DIRECTORY_WITH_COINS_JSON_FILES]' >&2
  exit 2
fi
root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
target="$root/sdk/packages/komodo_defi_framework/assets"
icon_dir="$target/coin_icons/png"
if find "$icon_dir" -maxdepth 1 -type f -name '*.png' -print -quit | grep -q .; then
  echo 'Remove or separately review staged coin PNGs before a public build' >&2
  exit 1
fi

if [ "$#" -eq 1 ]; then
  source_dir=$(CDPATH= cd -- "$1" && pwd)
else
  source_dir=$(mktemp -d)
  trap 'rm -rf "$source_dir"' EXIT
  base='https://raw.githubusercontent.com/ShorelineCrypto/coins/98b29f5ea53a46a701e791a565a5fab7ee83b947'
  curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
    --output "$source_dir/coins.json" "$base/coins"
  curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
    --output "$source_dir/coins_config.json" "$base/utils/coins_config_unfiltered.json"
  curl --fail --location --silent --show-error --proto '=https' --tlsv1.2 \
    --output "$source_dir/seed_nodes.json" "$base/seed-nodes.json"
fi

printf '%s  %s\n' \
  '0a4b57a86b3f25385961dba9f3b57804da8576a9c0d10073ce2b6afb3401418f' "$source_dir/coins.json" \
  '5d77f607f05dc97f488011d0800e49239faa05f44a2c6578bc90df125f0459a5' "$source_dir/coins_config.json" \
  'd880dd324f0c77017ad92147dd10ad095d37dc53fff0284abc13c9b333bc85fd' "$source_dir/seed_nodes.json" | sha256sum --check --status

install -d -m 755 "$target/config"
for name in coins.json coins_config.json seed_nodes.json; do
  install -m 644 "$source_dir/$name" "$target/config/$name"
done
printf 'Staged verified coin parameters from ShorelineCrypto/coins@98b29f5\n'
