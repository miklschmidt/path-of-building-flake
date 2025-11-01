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
        nativeLauncher = packages: pkgs.writeShellScript "pob-native-launcher" ''
          set -e
          cd ${packages.path-of-building.out}
          source ${packages.path-of-building.env}
          exec ${packages.pobfrontend.out}/pobfrontend $@
        '';
        wineLauncher = { pkg, exe, prefix, scriptName ? "pob-wine-launcher" }:
          pkgs.writeShellScript scriptName ''
          set -e
          export WINEDEBUG=-all
          export WINEPREFIX="${prefix}"
          cd ${pkg.out}/runtime
          exec ${pkgs.wineWowPackages.staging}/bin/wine "${exe}"
        '';
      in
      rec {
        packages = {
          pobfrontend = (import ./pobfrontend.nix) { inherit pkgs luaEnv; };
          path-of-building = (import ./path-of-building.nix) { inherit pkgs luaEnv; };
          path-of-building-poe2 = (import ./path-of-building-poe2.nix) { inherit pkgs luaEnv; };
        };

        apps = let
          pobWineProgram = "${wineLauncher {
            pkg = packages.path-of-building;
            exe = "Path{space}of{space}Building.exe";
            prefix = "$HOME/.local/share/pob-wine";
            scriptName = "pob-wine-launcher";
          }}";
          poe2WineProgram = "${wineLauncher {
            pkg = packages.path-of-building-poe2;
            exe = "Path{space}of{space}Building-PoE2.exe";
            prefix = "$HOME/.local/share/pob-poe2-wine";
            scriptName = "poe2-wine-launcher";
          }}";
        in {
          default = {
            type = "app";
            program = pobWineProgram;
          };
          pob-wine = {
            type = "app";
            program = pobWineProgram;
          };
          pob-native = {
            type = "app";
            program = "${nativeLauncher packages}";
          };
          pobfrontend = {
            type = "app";
            program = "${packages.pobfrontend.out}/pobfrontend";
          };
          poe2 = {
            type = "app";
            program = poe2WineProgram;
          };
          poe2-wine = {
            type = "app";
            program = poe2WineProgram;
          };
          poe2-native = {
            type = "app";
            program = let
              poe2Packages = {
                pobfrontend = packages.pobfrontend;
                path-of-building = packages.path-of-building-poe2;
              };
            in "${nativeLauncher poe2Packages}";
          };
        };

        defaultPackage = packages.path-of-building;
      });
}
