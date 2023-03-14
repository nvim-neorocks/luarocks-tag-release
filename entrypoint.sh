#!/usr/bin/env bash

set -e

EXTRA_PACKAGES="$1"

while read -r nixpkg; do
  NIXPKG="$(echo "$nixpkg" | tr -d '"')" # (why, Bash?)
  if [[ "$NIXPKG" != "" ]]; then
    echo "Adding extra package: $NIXPKG"
    nix run "nixpkgs#gnused" -- "-i" "s/#PLACEHOLDER/$NIXPKG\n    #PLACEHOLDER/" "/pkg/nix/extraRuntimeInputs.nix"
  fi
done <<<"$EXTRA_PACKAGES"

nix build "/pkg#luarocks-tag-release"

./result/bin/luarocks-tag-release "${@:2}"
