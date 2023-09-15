{
  description = "Build and upload LuaRocks packages from Git tags";

  nixConfig = {
    extra-substituters = "https://neorocks.cachix.org";
    extra-trusted-public-keys = "neorocks.cachix.org-1:WqMESxmVTOJX7qoBC54TwrMMoVI1xAM+7yFin8NRfwk=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";

    neorocks-nix.url = "github:mrcjkb/neorocks-nix";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    pre-commit-hooks,
    neorocks-nix,
    ...
  }: let
    supportedSystems = [
      "x86_64-linux"
    ];
  in
    flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          neorocks-nix.overlays.default
          (import ./nix/overlay.nix {inherit self;})
        ];
      };

      base-dependencies = with pkgs.lua51Packages; [
        dkjson
        luafilesystem
      ];

      formatting = pre-commit-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
          luacheck.enable = true;
          editorconfig-checker.enable = true;
          markdownlint.enable = true;
          lua-ls.enable = true;
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
          lua-ls = {
            config = {
              runtime.version = "LuaJIT";
              Lua = {
                workspace = {
                  library = base-dependencies;
                  checkThirdParty = false;
                  ignoreDir = [
                    ".git"
                    ".github"
                    ".direnv"
                    "result"
                    "nix"
                    "resources"
                    "spec"
                  ];
                };
                diagnostics.libraryFiles = "Disable";
              };
            };
          };
        };
      };

      shell = pkgs.mkShell {
        name = "luarocks-tag-release-devShell";
        buildInputs =
          (with pkgs; [
            sumneko-lua-language-server
            luarocks
          ])
          ++ (with pre-commit-hooks.packages.${system}; [
            alejandra
            stylua
            luacheck
            editorconfig-checker
            markdownlint-cli
          ]);
        shellHook = ''
          ${self.checks.${system}.formatting.shellHook}
        '';
      };
    in {
      packages = {
        default = pkgs.luarocks-tag-release-action;
        inherit
          (pkgs)
          luarocks-tag-release-action
          ;
      };
      devShells.default = shell;
      checks = {
        inherit formatting;
      };
    });
}
