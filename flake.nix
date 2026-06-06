{
  description = "Path Of Building - Offline build planner for Path of Exile.";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    let
      urlHandlerModule =
        {
          packageName,
          desktopFile,
          scheme,
        }:
        { pkgs, ... }:
        {
          environment.systemPackages = [ self.packages.${pkgs.system}.${packageName} ];
          xdg.mime.enable = true;
          xdg.mime.defaultApplications."x-scheme-handler/${scheme}" = desktopFile;
        };
      pobUrlHandlerModule = urlHandlerModule {
        packageName = "pob-url-handler";
        desktopFile = "path-of-building.desktop";
        scheme = "pob";
      };
      pob2UrlHandlerModule = urlHandlerModule {
        packageName = "pob2-url-handler";
        desktopFile = "path-of-building-poe2.desktop";
        scheme = "pob2";
      };
      urlHandlersModule = {
        imports = [
          pobUrlHandlerModule
          pob2UrlHandlerModule
        ];
      };
    in
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        luacurl = (import ./lua-curl-v3.nix) {
          pkgs = pkgs;
          luaPackages = pkgs.luajitPackages;
        };
        luaEnv = pkgs.luajitPackages.lua.withPackages (
          ps: with ps; [
            luacurl
            luautf8
          ]
        );
        nativeLauncher =
          packages:
          pkgs.writeShellScript "pob-native-launcher" ''
            set -e
            cd ${packages.path-of-building.out}
            source ${packages.path-of-building.env}
            exec ${packages.pobfrontend.out}/pobfrontend "$@"
          '';
        wineLauncher =
          {
            pkg,
            exe,
            prefix,
            scriptName ? "pob-wine-launcher",
          }:
          pkgs.writeShellScript scriptName ''
            set -e
            export WINEDEBUG=-all
            export WINEPREFIX="${prefix}"
            cd ${pkg.out}/runtime
            exec ${pkgs.wineWow64Packages.staging}/bin/wine "${exe}" "$@"
          '';
        urlHandlerDesktopEntry =
          {
            desktopId,
            name,
            program,
            schemes,
          }:
          let
            desktopFile = pkgs.writeText "${desktopId}.desktop" ''
              [Desktop Entry]
              Type=Application
              Name=${name}
              Exec=${program} %u
              Terminal=false
              NoDisplay=true
              MimeType=${pkgs.lib.concatMapStrings (scheme: "x-scheme-handler/${scheme};") schemes}
            '';
          in
          pkgs.stdenvNoCC.mkDerivation {
            pname = "${desktopId}-desktop-entry";
            version = "1";
            dontUnpack = true;
            installPhase = ''
              install -D -m 0644 ${desktopFile} "$out/share/applications/${desktopId}.desktop"
            '';
          };
        registerUrlHandlers =
          {
            desktopId,
            desktopEntry,
            schemes,
          }:
          pkgs.writeShellScript "register-${desktopId}-url-handlers" ''
            set -e
            data_dir="''${XDG_DATA_HOME:-$HOME/.local/share}"
            config_dir="''${XDG_CONFIG_HOME:-$HOME/.config}"
            applications_dir="$data_dir/applications"
            desktop_file="$applications_dir/${desktopId}.desktop"

            ${pkgs.coreutils}/bin/mkdir -p "$applications_dir" "$config_dir"
            ${pkgs.coreutils}/bin/install -m 0644 ${desktopEntry}/share/applications/${desktopId}.desktop "$desktop_file"
            for scheme in ${pkgs.lib.escapeShellArgs schemes}; do
              ${pkgs.xdg-utils}/bin/xdg-mime default "${desktopId}.desktop" "x-scheme-handler/$scheme"
            done

            if command -v update-desktop-database >/dev/null 2>&1; then
              update-desktop-database "$applications_dir"
            fi

            printf 'Registered %s for %s\n' "${desktopId}.desktop" "${pkgs.lib.concatStringsSep ", " schemes}"
          '';
      in
      rec {
        packages =
          let
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
          in
          {
            pobfrontend = (import ./pobfrontend.nix) { inherit pkgs luaEnv; };
            path-of-building = (import ./path-of-building.nix) { inherit pkgs luaEnv; };
            default = packages.path-of-building;
            path-of-building-poe2 = (import ./path-of-building-poe2.nix) { inherit pkgs luaEnv; };
            pob-url-handler = urlHandlerDesktopEntry {
              desktopId = "path-of-building";
              name = "Path of Building";
              program = pobWineProgram;
              schemes = [ "pob" ];
            };
            pob2-url-handler = urlHandlerDesktopEntry {
              desktopId = "path-of-building-poe2";
              name = "Path of Building PoE2";
              program = poe2WineProgram;
              schemes = [ "pob2" ];
            };
          };

        apps =
          let
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
          in
          {
            default = {
              type = "app";
              program = pobWineProgram;
              meta = {
                description = "Path of Building (default, Wine)";
              };
            };
            pob-wine = {
              type = "app";
              program = pobWineProgram;
              meta = {
                description = "Path of Building via Wine";
              };
            };
            pob-native = {
              type = "app";
              program = "${nativeLauncher packages}";
              meta = {
                description = "Path of Building native launcher";
              };
            };
            pobfrontend = {
              type = "app";
              program = "${packages.pobfrontend.out}/pobfrontend";
              meta = {
                description = "Path of Building Qt frontend";
              };
            };
            pob-url-handler = {
              type = "app";
              program = "${registerUrlHandlers {
                desktopId = "path-of-building";
                desktopEntry = packages.pob-url-handler;
                schemes = [ "pob" ];
              }}";
              meta = {
                description = "Register Path of Building as the pob:// URL handler";
              };
            };
            poe2 = {
              type = "app";
              program = poe2WineProgram;
              meta = {
                description = "Path of Building PoE2 (default, Wine)";
              };
            };
            poe2-wine = {
              type = "app";
              program = poe2WineProgram;
              meta = {
                description = "Path of Building PoE2 via Wine";
              };
            };
            pob2-url-handler = {
              type = "app";
              program = "${registerUrlHandlers {
                desktopId = "path-of-building-poe2";
                desktopEntry = packages.pob2-url-handler;
                schemes = [ "pob2" ];
              }}";
              meta = {
                description = "Register Path of Building PoE2 as the pob2:// URL handler";
              };
            };
            poe2-native = {
              type = "app";
              program =
                let
                  poe2Packages = {
                    pobfrontend = packages.pobfrontend;
                    path-of-building = packages.path-of-building-poe2;
                  };
                in
                "${nativeLauncher poe2Packages}";
              meta = {
                description = "Path of Building PoE2 native launcher";
              };
            };
          };

      }
    )
    // {
      nixosModules = {
        default = urlHandlersModule;
        pob-url-handler = pobUrlHandlerModule;
        pob2-url-handler = pob2UrlHandlerModule;
        url-handlers = urlHandlersModule;
      };
    };
}
