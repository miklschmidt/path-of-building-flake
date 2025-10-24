{ pkgs, luaEnv }:

pkgs.stdenv.mkDerivation rec {
  pname = "path-of-building-poe2";
  version = "0.12.2";
  name = "path-of-building-poe2-${version}";
  outputs = [
    "out"
    "env"
  ];

  src = fetchTarball {
    url = "https://github.com/PathOfBuildingCommunity/PathOfBuilding-PoE2/archive/refs/tags/v${version}.tar.gz";
    sha256 = "0x3dv9dhg23mdzk13c77581r74xb0422v7lhsd2r4wysd18g06bi";
  };

  patches = [
    ./patches/pob2-stop-updates.patch
    ./patches/poe2-drawimagequad-no-texcoords.patch
  ];

  nativeBuildInputs = [
    luaEnv
  ];

  installPhase = ''
    mkdir -p $out/runtime
    # Install full Windows runtime (exe + dlls + fonts) for optional Wine run
    cp -r runtime/* $out/runtime/
    cp -r spec/ $out/spec
    cp -r src/ $out/src

    cp changelog.txt help.txt $out/src
    touch $out/installed.cfg

    cat >$out/manifest.xml <<EOL
    <?xml version='1.0' encoding='UTF-8'?>
    <PoBVersion>
      <Version number="${version}" branch="release" platform="nix"/>
    </PoBVersion>
    EOL

    cat >$env <<EOL
    export LUA_PATH='$out/runtime/lua/?.lua;$out/runtime/lua/?/init.lua'
    export LUA_CPATH='${luaEnv}/lib/lua/${luaEnv.lua.luaversion}/?.so'
    EOL
  '';
}
