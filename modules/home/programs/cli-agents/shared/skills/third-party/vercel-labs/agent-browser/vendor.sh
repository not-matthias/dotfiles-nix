#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
# shellcheck shell=bash
# Vendor agent-browser skill files from upstream.
# Usage: ./vendor.sh
#
# Source: https://github.com/vercel-labs/agent-browser/tree/548b159b30eef119ccf6846c8bc807d0eaa3f6f8/skills/agent-browser
set -euo pipefail

REPO="vercel-labs/agent-browser"
REVISION="548b159b30eef119ccf6846c8bc807d0eaa3f6f8"
UPSTREAM_DIR="skills/agent-browser"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_URL="https://raw.githubusercontent.com/${REPO}/${REVISION}/${UPSTREAM_DIR}"
STAGE_DIR="$(mktemp -d "${SCRIPT_DIR}.tmp.XXXXXX")"
trap 'rm -rf "$STAGE_DIR"' EXIT

echo "Fetching file list from GitHub API..."
FILES=$(
  curl -sf "https://api.github.com/repos/${REPO}/git/trees/${REVISION}?recursive=1" |
    jq -er --arg prefix "${UPSTREAM_DIR}/" '
      [.tree[] | select(.type == "blob" and (.path | startswith($prefix))) |
       .path | ltrimstr($prefix)]
      | if length == 0 then error("no files found upstream") else .[] end
    '
)

echo "Downloading files..."
while IFS= read -r file; do
  dest="${STAGE_DIR}/${file}"
  mkdir -p "$(dirname "$dest")"
  curl -sf "${BASE_URL}/${file}" -o "$dest"
  echo "  ${file}"
done <<< "$FILES"

if [ ! -f "${STAGE_DIR}/SKILL.md" ]; then
  echo "Error: upstream skill is missing SKILL.md." >&2
  exit 1
fi
printf '\n<!-- Source: https://github.com/%s/blob/%s/%s/SKILL.md -->\n' \
  "$REPO" "$REVISION" "$UPSTREAM_DIR" >> "${STAGE_DIR}/SKILL.md"

# Keep local tooling and attribution while pruning files no longer upstream.
find "$SCRIPT_DIR" -mindepth 1 -maxdepth 1 ! -name vendor.sh ! -name NOTICE.md -exec rm -rf -- {} +
cp -a "${STAGE_DIR}/." "$SCRIPT_DIR/"

echo "Done. Vendored $(printf '%s\n' "$FILES" | wc -l | tr -d ' ') files."
