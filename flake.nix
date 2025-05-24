{
  description = "Build and upload LuaRocks packages from Git tags";

  nixConfig = {
    extra-substituters = "https://neorocks.cachix.org";
    extra-trusted-public-keys = "neorocks.cachix.org-1:WqMESxmVTOJX7qoBC54TwrMMoVI1xAM+7yFin8NRfwk=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    git-hooks,
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
          (import ./nix/overlay.nix {inherit self;})
        ];
      };

      base-dependencies = with pkgs.lua51Packages; [
        argparse
        dkjson
        luafilesystem
      ];

      formatting = git-hooks.lib.${system}.run {
        src = self;
        hooks = {
          alejandra.enable = true;
          stylua.enable = true;
          luacheck.enable = true;
          editorconfig-checker.enable = true;
          markdownlint = {
            enable = true;
            settings.configuration = {
              MD004 = false;
              MD012 = false;
              MD013 = false;
              MD022 = false;
              MD031 = false;
              MD032 = false;
            };
          };
          lua-ls = {
            enable = true;
            settings.configuration = {
              runtime.version = "LuaJIT";
              Lua = {
                workspace = {
                  library =
                    base-dependencies
                    ++ [
                      "\${3rd}/busted/library"
                      "\${3rd}/luassert/library"
                    ];
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
            base-dependencies
            lua-language-server
            luarocks
            luaPackages.dkjson
          ])
          ++ self.checks.${system}.formatting.enabledPackages;
        shellHook = ''
          ${self.checks.${system}.formatting.shellHook}
          export LUA_PATH="lua/?.lua;$LUA_PATH"
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
        inherit
          (pkgs)
          luarocks-tag-release-action
          ;
      };
    });
}
