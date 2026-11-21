#!/usr/bin/env bash
# Update nixos/apps/<app>/pin.json (and regenerate deps.json if supported).
#
# Usage (nix app):
#   update-app-pin.sh nix <app> <rev> <version> <sri-hash>
#
# Usage (dockerfile app):
#   update-app-pin.sh dockerfile <app> <rev> <version> <image-tag> <tarball-url> <sri-hash>
set -euo pipefail

kind="${1:?kind ('nix' or 'dockerfile') required}"
app="${2:?app name required}"
pin_file="nixos/apps/${app}/pin.json"

if [ ! -f "$pin_file" ]; then
  echo "Error: ${pin_file} does not exist. Create the app scaffold in nixos/apps/${app}/ first." >&2
  exit 1
fi

old_rev=$(jq -r '.rev // ""' "$pin_file")
echo "OLD_REV=${old_rev}"

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT

case "$kind" in
  nix)
    rev="${3:?rev required}"
    version="${4:?version required}"
    hash="${5:?sri hash required}"
    jq \
      --arg rev "$rev" \
      --arg version "$version" \
      --arg hash "$hash" \
      '.rev = $rev | .version = $version | .hash = $hash' \
      "$pin_file" > "$tmp"
    mv "$tmp" "$pin_file"

    # If this Nix package exposes a fetch-deps helper (e.g. buildDotnetModule),
    # automatically refresh deps.json so NuGet updates never break PR builds.
    if [ -f "nixos/apps/${app}/deps.json" ]; then
      if fetch_deps=$(nix build --no-link --print-out-paths "./nixos#${app}.fetch-deps" 2>/dev/null); then
        echo "Regenerating nixos/apps/${app}/deps.json..." >&2
        "$fetch_deps" "nixos/apps/${app}/deps.json"
      fi
    fi
    ;;

  dockerfile)
    rev="${3:?rev required}"
    version="${4:?version required}"
    image="${5:?image tag required}"
    url="${6:?tarball url required}"
    hash="${7:?sri hash required}"
    jq \
      --arg rev "$rev" \
      --arg version "$version" \
      --arg image "$image" \
      --arg url "$url" \
      --arg hash "$hash" \
      '.rev = $rev | .version = $version | .image = $image | .url = $url | .hash = $hash' \
      "$pin_file" > "$tmp"
    mv "$tmp" "$pin_file"
    ;;

  *)
    echo "Error: unsupported kind '${kind}' (expected 'nix' or 'dockerfile')" >&2
    exit 1
    ;;
esac
