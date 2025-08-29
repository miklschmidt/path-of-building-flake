{
  description = "Path Of Building - Offline build planner for Path of Exile.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        luacurl = (import ./lua-curl-v3.nix) { pkgs = pkgs; luaPackages = pkgs.luajitPackages; };
        luaEnv = pkgs.luajitPackages.lua.withPackages (ps: with ps; [
          luacurl
          luautf8
        ]);
        launcher = packages: pkgs.writeShellScript "launcher" ''
          set -e
          cd ${packages.path-of-building.out}
          source ${packages.path-of-building.env}
          exec ${packages.pobfrontend.out}/pobfrontend $@
        '';
        wineLauncher = poe2pkg: pkgs.writeShellScript "poe2-wine-launcher" ''
          set -e
          export WINEDEBUG=-all
          export WINEPREFIX="$HOME/.local/share/pob-poe2-wine"
          cd ${poe2pkg.out}/runtime
          exec ${pkgs.wineWowPackages.staging}/bin/wine "Path{space}of{space}Building-PoE2.exe"
        '';
      in
      rec {
        packages = {
          pobfrontend = (import ./pobfrontend.nix) { inherit pkgs luaEnv; };
          path-of-building = (import ./path-of-building.nix) { inherit pkgs luaEnv; };
          path-of-building-poe2 = (import ./path-of-building-poe2.nix) { inherit pkgs luaEnv; };
        };

        apps = {
          default = {
            type = "app";
            program = "${launcher packages}";
          };
          pobfrontend = {
            type = "app";
            program = "${packages.pobfrontend.out}/pobfrontend";
          };
          poe2 = {
            type = "app";
            program = "${wineLauncher packages.path-of-building-poe2}";
          };
          poe2-wine = {
            type = "app";
            program = "${wineLauncher packages.path-of-building-poe2}";
          };
          poe2-native = {
            type = "app";
            program = let
              poe2Packages = {
                pobfrontend = packages.pobfrontend;
                path-of-building = packages.path-of-building-poe2;
              };
            in "${launcher poe2Packages}";
          };
        };

        defaultPackage = packages.path-of-building;
      });
}
