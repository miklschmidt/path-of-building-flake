# Repository Guidelines

## Project Structure & Module Organization
- `flake.nix`: Flake entry; defines packages and apps.
- `path-of-building.nix`: Builds PoB runtime and exports env.
- `pobfrontend.nix`: Builds the Qt frontend binary.
- `lua-curl-v3.nix`: Lua cURL dependency.
- `patches/`: Nix-applied patches (e.g., `pob-stop-updates.patch`).
- `flake.lock`, `README.md`, `LICENSE`: Pinning, usage, licensing.

## Build, Test, and Development Commands
- Run app: `nix run` (launches PoB via `apps.default`).
- Run frontend only: `nix run .#pobfrontend`.
- Build default package: `nix build` or `nix build .#path-of-building`.
- Update inputs: `nix flake update` (refreshes `flake.lock`).

## Coding Style & Naming Conventions
- Nix files: 2‑space indent, no tabs; hyphenated filenames (`*.nix`).
- Prefer clear attribute names; keep derivation fields grouped (`pname`, `version`, `src`, `buildInputs`, phases).
- Use pinned sources (`rev`, `sha256`) and explicit `pkgs.*` references.
- Format: use `nixfmt` or `nix pkgs-fmt` if available.

## Testing Guidelines
- This repo has no unit tests; validation is via builds and local runs.
- Build checks: `nix build` must succeed for changed systems.
- Smoke test: `nix run` should start the GUI and load data.
- Platform note: currently verified on macOS; please report Linux status in PRs.

## Commit & Pull Request Guidelines
- Commits: concise, imperative summary (e.g., "Update PoB to 2.55.4", "Update nixpkgs").
- Version bumps:
  - Edit `version` in `path-of-building.nix` and update `sha256`.
  - For `pobfrontend.nix`, update `rev` and `sha256` together.
  - Tip: use `nix-prefetch-url --unpack <url>` (or build to get the expected hash) to refresh hashes.
- PRs should include:
  - Short description, motivation, and affected files.
  - Build results (`nix build` output) and tested platform(s).
  - Notes on patches under `patches/` when modified or added.

## Security & Configuration Tips
- Keep `flake.lock` updated but committed to ensure reproducible builds.
- Avoid network access at runtime in patched PoB (see `pob-stop-updates.patch`).
- Prefer upstream tags/releases over branches for source stability.
