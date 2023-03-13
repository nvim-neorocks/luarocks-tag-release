#!/usr/bin/env bash

nix build "/pkg#luarocks-tag-release"

echo "GITHUB_EVENT_NAME: $1"
IS_PR=0
if [ IS_PR =~ "pull_request" ]; then
  echo "THIS IS a PULL_REQUEST"
else
  echo "not a PULL_REQUEST"
fi

shift
./result/bin/luarocks-tag-release "$@"
