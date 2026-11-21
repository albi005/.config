#!/usr/bin/env bash
# Check all 3rd-party OCI images in nixos/pins/images.json via skopeo and update
# any changed digests in place. Prints a Markdown summary of changes to stdout.
set -euo pipefail

PINS_FILE="${1:-nixos/pins/images.json}"
if [ ! -f "$PINS_FILE" ]; then
  echo "Error: $PINS_FILE not found" >&2
  exit 1
fi

tmp=$(mktemp)
trap 'rm -f "$tmp"' EXIT
cp "$PINS_FILE" "$tmp"

changed=0
summary=""

while IFS= read -r name; do
  repo=$(jq -r --arg n "$name" '.[$n].repository' "$PINS_FILE")
  tag=$(jq -r --arg n "$name" '.[$n].tag' "$PINS_FILE")
  old_digest=$(jq -r --arg n "$name" '.[$n].digest' "$PINS_FILE")

  echo "Inspecting ${name} (${repo}:${tag})..." >&2
  new_digest=$(skopeo inspect --override-os linux --override-arch amd64 "docker://${repo}:${tag}" | jq -r '.Digest')

  if [ -z "$new_digest" ] || [ "$new_digest" = "null" ]; then
    echo "Warning: could not resolve digest for ${name}" >&2
    continue
  fi

  if [ "$new_digest" != "$old_digest" ]; then
    echo "  Updated ${name}: ${old_digest:0:19}... -> ${new_digest:0:19}..." >&2
    jq --arg n "$name" --arg d "$new_digest" '.[$n].digest = $d' "$tmp" > "${tmp}.next"
    mv "${tmp}.next" "$tmp"
    changed=$((changed + 1))
    summary="${summary}- **${name}** (\`${repo}:${tag}\`): \`${old_digest:0:19}\` → \`${new_digest:0:19}\`\n"
  else
    echo "  Up to date." >&2
  fi
done < <(jq -r 'keys[]' "$PINS_FILE")

if [ "$changed" -gt 0 ]; then
  mv "$tmp" "$PINS_FILE"
  printf '%b' "$summary"
fi
