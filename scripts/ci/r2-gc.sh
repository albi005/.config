#!/usr/bin/env bash
# Safe garbage collector for the Cloudflare R2 Nix binary cache.
#
# Keeps:
#   1. Every store path hash referenced by the current flake's 5 host closures.
#   2. Any object in R2 newer than MAX_AGE_DAYS (default: 30).
# Deletes orphaned older .narinfo files and unreferenced nar/ blobs so R2 stays
# comfortably inside its 10 GB free tier.
set -euo pipefail

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
  DRY_RUN=true
fi

: "${R2_BUCKET:?R2_BUCKET is required}"
: "${R2_ENDPOINT:?R2_ENDPOINT is required}"
: "${AWS_ACCESS_KEY_ID:?AWS_ACCESS_KEY_ID is required}"
: "${AWS_SECRET_ACCESS_KEY:?AWS_SECRET_ACCESS_KEY is required}"

MAX_AGE_DAYS="${MAX_AGE_DAYS:-30}"
HOSTS=(iron slime redstone netherite water)

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

live_hashes="$work/live_hashes.txt"
: > "$live_hashes"

echo "Collecting live store-path hashes across hosts: ${HOSTS[*]}..."
for host in "${HOSTS[@]}"; do
  drv=$(nix eval --raw "./nixos#nixosConfigurations.${host}.config.system.build.toplevel.drvPath")
  # Extract every /nix/store/<32-char-hash>-... output path from the derivation closure
  nix derivation show --recursive "$drv" \
    | jq -r '.[].outputs[]?.path // empty' \
    | sed -n 's|^/nix/store/\([a-z0-9]\{32\}\)-.*|\1|p' >> "$live_hashes" || true
done

sort -u -o "$live_hashes" "$live_hashes"
echo "Found $(wc -l < "$live_hashes") live store-path hashes."

cutoff=$(date -u -d "${MAX_AGE_DAYS} days ago" +"%Y-%m-%dT%H:%M:%SZ")
echo "Cutoff timestamp (${MAX_AGE_DAYS} days ago): ${cutoff}"

# List all objects in the R2 bucket
aws s3api list-objects-v2 \
  --bucket "$R2_BUCKET" \
  --endpoint-url "$R2_ENDPOINT" \
  --region auto \
  --output json > "$work/objects.json"

keep_nars="$work/keep_nars.txt"
delete_keys="$work/delete_keys.txt"
: > "$keep_nars"
: > "$delete_keys"

# Step 1: Decide which .narinfo files to keep vs delete
while IFS=$'\t' read -r key last_mod; do
  hash="${key%.narinfo}"
  if grep -qx "$hash" "$live_hashes" || [[ "$last_mod" > "$cutoff" ]]; then
    # Fetch the narinfo to record its referenced NAR URL so we keep that blob
    aws s3 cp "s3://${R2_BUCKET}/${key}" - \
      --endpoint-url "$R2_ENDPOINT" \
      --region auto 2>/dev/null \
      | awk '/^URL: / { print $2 }' >> "$keep_nars" || true
  else
    echo "$key" >> "$delete_keys"
  fi
done < <(
  jq -r '.Contents[]? | select(.Key | endswith(".narinfo")) | "\(.Key)\t\(.LastModified)"' "$work/objects.json"
)

sort -u -o "$keep_nars" "$keep_nars"

# Step 2: Any nar/* object older than cutoff and not referenced by a kept .narinfo is garbage
while IFS=$'\t' read -r key last_mod; do
  if ! grep -qx "$key" "$keep_nars" && [[ "$last_mod" < "$cutoff" ]]; then
    echo "$key" >> "$delete_keys"
  fi
done < <(
  jq -r '.Contents[]? | select(.Key | startswith("nar/")) | "\(.Key)\t\(.LastModified)"' "$work/objects.json"
)

count=$(wc -l < "$delete_keys")
echo "Objects eligible for deletion: ${count}"

if [ "$count" -eq 0 ]; then
  echo "R2 cache is already clean."
  exit 0
fi

if [ "$DRY_RUN" = true ]; then
  echo "[DRY RUN] Would delete:"
  head -n 50 "$delete_keys"
  exit 0
fi

while IFS= read -r key; do
  aws s3 rm "s3://${R2_BUCKET}/${key}" --endpoint-url "$R2_ENDPOINT" --region auto
done < "$delete_keys"

echo "Deleted ${count} expired R2 objects."
