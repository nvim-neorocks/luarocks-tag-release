#!/usr/bin/env bash

nix build "/pkg#luarocks-tag-release"

./result/bin/luarocks-tag-release "$@"
