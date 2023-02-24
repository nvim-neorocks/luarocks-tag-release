{
  description = "Build and upload LuaRocks packages from Git tags";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    pre-commit-hooks,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
    ];
    perSystem = nixpkgs.lib.genAttrs supportedSystems;
    pkgsFor = system: import nixpkgs {inherit system;};

    luarocks-tag-release-for = system: let
      pkgs = pkgsFor system;
      luarocks-tag-release-wrapped = pkgs.lua51Packages.buildLuaApplication {
        pname = "luarocks-tag-release";
        version = "scm-1";

        src = self;

        propagatedBuildInputs = with pkgs; [
          lua51Packages.dkjson
        ];
      };
    in
      pkgs.writeShellApplication {
        name = "luarocks-tag-release";
        runtimeInputs = with pkgs; [
          curl
          gnumake
          lua51Packages.dkjson # Used by luarocks
          lua51Packages.luarocks
          luarocks-tag-release-wrapped
          unzip
          zip
        ];

        text = ''
          luarocks-tag-release.lua "$@"
        '';
      };
  in {
    packages = perSystem (system: let
      luarocks-tag-release = luarocks-tag-release-for system;
    in {
      default = luarocks-tag-release;
      inherit luarocks-tag-release;
    });
  };
}
