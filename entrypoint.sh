#!/usr/bin/env bash

nix build ".#luarocks-tag-release"

./result/bin/luarocks-tag-release "$@"
