# Path Of Building Nix Flake

This repository provides a [Nix Flake](https://nixos.wiki/wiki/Flakes) for building and
running [PoBFrontend](https://github.com/ernstp/pobfrontend), a cross-platform driver
for both [Path Of Building](https://github.com/PathOfBuildingCommunity/PathOfBuilding)
and [PathOfBuilding-PoE2](https://github.com/PathOfBuildingCommunity/PathOfBuilding-PoE2).

## Usage

In Nix environment with [enabled flakes](https://nixos.wiki/wiki/Flakes#Enable_flakes), you
can use the flake with the following command:

```sh
# Path of Building (PoE1)
nix run github:ciiol/path-of-building-flake

# Path of Building – PoE2 (default uses Wine)
nix run github:ciiol/path-of-building-flake#poe2

# Path of Building – PoE2 via Wine (explicit)
nix run github:ciiol/path-of-building-flake#poe2-wine
```

### Local development

```sh
# Run PoE1 from local checkout
nix run

# Run PoE2 (Wine) from local checkout
nix run .#poe2

# Run PoE2 (Wine) explicitly
nix run .#poe2-wine

# Run PoE2 (native Qt) — experimental/known-broken
nix run .#poe2-native

# Build packages
nix build .#path-of-building
nix build .#path-of-building-poe2
```

## Contributions and fixes

This Flake has been tested on macOS and NixOS. Contributions and fixes for other platforms are welcome.
PoE2 on Linux currently renders incorrectly in the native frontend; use the Wine app (#poe2) until upstream fixes it. Automatic update checks are disabled in both (PoE1 and PoE2) for reproducibility.
Feel free to open issues and submit pull requests.
