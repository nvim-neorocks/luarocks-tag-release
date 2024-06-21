{self}: final: prev:
with final.pkgs;
with final.lib;
with final.stdenv; let
  luarocks-tag-release-action-wrapped = pkgs.lua51Packages.buildLuaApplication {
    pname = "luarocks-tag-release";
    version = "scm-1";

    src = self;

    nativeCheckInputs = with pkgs; [
      curl
    ];

    propagatedBuildInputs = with pkgs.lua51Packages; [
      dkjson
      luafilesystem
      luarocks-build-rust-mlua
      luarocks-build-treesitter-parser
    ];

    meta = {
      description = "Publish Lua packages to LuaRocks";
      homepage = "https://github.com/nvim-neorocks/luarocks-tag-release";
      license = licenses.agpl3Only;
    };

    # doCheck = true;
  };

  luarocks-tag-release-action = pkgs.writeShellApplication {
    name = "luarocks-tag-release-action";
    runtimeInputs = with pkgs; [
      luarocks
      curl
      luarocks-tag-release-action-wrapped
      unzip
      zip
    ];

    text = ''
      luarocks-tag-release-action.lua "$@"
    '';

    # The default checkPhase depends on ShellCheck, which depends on GHC
    checkPhase = "";
  };
in {
  inherit
    luarocks-tag-release-action
    ;
}
