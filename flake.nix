{
  description = "Build and upload LuaRocks packages from Git tags";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
    ];
  in
    flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {inherit system;};
      inherit (pkgs) lib;

      luarocks-tag-release-wrapped = pkgs.lua51Packages.buildLuaApplication {
        pname = "luarocks-tag-release";
        version = "scm-1";

        src = self;

        propagatedBuildInputs = with pkgs.lua51Packages; [
          dkjson
          luafilesystem
        ];
      };

      luarocks-tag-release-action = pkgs.writeShellApplication {
        name = "luarocks-tag-release-action";
        runtimeInputs = with pkgs; [
          curl
          lua51Packages.dkjson # Used by luarocks
          lua51Packages.luarocks
          luarocks-tag-release-wrapped
          unzip
          zip
        ];

        text = ''
          luarocks-tag-release-action.lua "$@"
        '';

        # The default checkPhase depends on ShellCheck, which depends on GHC
        checkPhase = "";
      };

      formatting = pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
          luacheck.enable = true;
          editorconfig-checker.enable = true;
          markdownlint.enable = true;
        };
        settings = {
          markdownlint.config = {
            MD004 = false;
            MD012 = false;
            MD013 = false;
            MD022 = false;
            MD031 = false;
            MD032 = false;
          };
        };
      };
    in {
      packages = {
        default = luarocks-tag-release-action;
        inherit luarocks-tag-release-action;
      };
      checks = {
        inherit formatting;
      };
    });
}
