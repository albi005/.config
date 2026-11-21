#!/usr/bin/env bash
# Push ONLY non-upstream Nix store paths in the closure of the given paths
# to Cloudflare R2 (or any S3-compatible Nix binary cache).
#
# Paths already signed by cache.nixos.org / nix-community / nvf are skipped so
# the 10 GB R2 free tier only stores your custom apps, packages, and NixOS
# system activation scripts (~5-80 MB per host instead of ~3 GB).
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <store-path-or-symlink> [...]" >&2
  exit 1
fi

: "${R2_BUCKET:?R2_BUCKET is required}"
: "${R2_ENDPOINT:?R2_ENDPOINT is required (e.g. https://<account-id>.r2.cloudflarestorage.com)}"
: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is required}"
: "${NIX_SIGNING_KEY_FILE:?NIX_SIGNING_KEY_FILE is required}"

UPSTREAM_PREFIXES="${UPSTREAM_KEY_PREFIXES:-cache.nixos.org-1: nix-community.cachix.org-1: nvf.cachix.org-1:}"

# Convert space-separated prefixes into a JSON array for jq
prefixes_json=$(printf '%s\n' $UPSTREAM_PREFIXES | jq -R . | jq -s .)

total_paths=$(nix path-info --recursive "$@" | wc -l)

mapfile -t custom_paths < <(
  nix path-info --recursive --json "$@" \
    | jq -r --argjson prefixes "$prefixes_json" '
        def is_upstream($sigs):
          ($sigs // []) | any(. as $s | $prefixes | any(. as $p | $s | startswith($p)));
        # Support both Nix <=2.24 array format and Nix >=2.25 object format
        if type == "array" then
          .[] | select((.signatures | is_upstream(.)) | not) | .path
        else
          to_entries[] | select((.value.signatures | is_upstream(.)) | not) | .key
        end
      '
)

echo "Closure has ${total_paths} store paths; ${#custom_paths[@]} are custom (not on upstream caches)."

if [ "${#custom_paths[@]}" -eq 0 ]; then
  echo "Nothing custom to upload."
  exit 0
fi

echo "Signing ${#custom_paths[@]} store paths..."
nix store sign --key-file "$NIX_SIGNING_KEY_FILE" "${custom_paths[@]}"

# Strip https:// if someone passed a full URL or keep full URL?
# Nix s3:// expects endpoint=<host-or-url> (endpoint without scheme or with https:// both work in Nix 2.24+,
# using full https:// URL is explicit and unambiguous for R2).
cache_uri="s3://${R2_BUCKET}?endpoint=${R2_ENDPOINT}&region=auto&compression=zstd"

echo "Uploading ${#custom_paths[@]} store paths to ${R2_BUCKET}..."
nix copy --no-recursive --to "$cache_uri" "${custom_paths[@]}"
echo "Done uploading to R2."
