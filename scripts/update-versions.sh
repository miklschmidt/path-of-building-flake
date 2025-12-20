#!/usr/bin/env bash
set -euo pipefail

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    echo "error: missing required command '$1'" >&2
    exit 1
  fi
}

require_cmd curl
require_cmd nix-prefetch-url

repo_latest_tag() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | \
    sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | \
    head -n 1
}

prefetch_sha256() {
  local url="$1"
  nix-prefetch-url --unpack "$url" | tail -n 1
}

update_nix_file() {
  local file="$1"
  local version="$2"
  local sha256="$3"
  local version_count
  local sha_count

  version_count=$(grep -c 'version = "' "$file" || true)
  sha_count=$(grep -c 'sha256 = "' "$file" || true)

  if [ "$version_count" -ne 1 ]; then
    echo "error: expected 1 version field in ${file}" >&2
    exit 1
  fi
  if [ "$sha_count" -ne 1 ]; then
    echo "error: expected 1 sha256 field in ${file}" >&2
    exit 1
  fi

  sed -i "0,/version = \"[^\"]*\";/s//version = \"${version}\";/" "$file"
  sed -i "0,/sha256 = \"[^\"]*\";/s//sha256 = \"${sha256}\";/" "$file"
}

update_repo() {
  local file="$1"
  local repo="$2"

  echo "Updating ${file} from ${repo}..."
  local tag
  tag="$(repo_latest_tag "$repo")"
  if [ -z "$tag" ]; then
    echo "error: failed to read latest tag for ${repo}" >&2
    exit 1
  fi

  local version="${tag#v}"
  local url="https://github.com/${repo}/archive/refs/tags/${tag}.tar.gz"
  local sha256
  sha256="$(prefetch_sha256 "$url")"

  update_nix_file "$file" "$version" "$sha256"
  echo "- ${file}: version=${version} sha256=${sha256}"
}

update_repo path-of-building.nix PathOfBuildingCommunity/PathOfBuilding
update_repo path-of-building-poe2.nix PathOfBuildingCommunity/PathOfBuilding-PoE2
