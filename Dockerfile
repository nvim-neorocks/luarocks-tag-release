FROM nixpkgs/nix-flakes:nixos-22.11 AS luarocks-tag-release


COPY bin /pkg/bin
COPY nix /pkg/nix
COPY luarocks-tag-release-scm-1.rockspec /pkg/
COPY flake.nix /pkg/flake.nix
COPY flake.lock /pkg/flake.lock
COPY entrypoint.sh /entrypoint.sh
COPY rockspec.template /rockspec.template

ENTRYPOINT ["/entrypoint.sh"]
