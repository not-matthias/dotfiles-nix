#!/usr/bin/env nix-shell
#!nix-shell -i bash -p curl jq
# shellcheck shell=bash
# Vendor agent-browser skill files from upstream.
# Usage: ./vendor.sh
#
# Source: https://github.com/vercel-labs/agent-browser/tree/main/skills/agent-browser
set -euo pipefail

REPO="vercel-labs/agent-browser"
BRANCH="main"
UPSTREAM_DIR="skills/agent-browser"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

BASE_URL="https://raw.githubusercontent.com/${REPO}/refs/heads/${BRANCH}/${UPSTREAM_DIR}"

echo "Fetching file list from GitHub API..."
FILES=$(curl -sf "https://api.github.com/repos/${REPO}/git/trees/${BRANCH}?recursive=1" \
  | jq -r ".tree[] | select(.path | startswith(\"${UPSTREAM_DIR}/\")) | select(.type == \"blob\") | .path" \
  | sed "s|^${UPSTREAM_DIR}/||")

if [ -z "$FILES" ]; then
  echo "Error: no files found upstream." >&2
  exit 1
fi

echo "Downloading files..."
while IFS= read -r file; do
  dest="${SCRIPT_DIR}/${file}"
  mkdir -p "$(dirname "$dest")"
  curl -sf "${BASE_URL}/${file}" -o "$dest"
  echo "  ${file}"
done <<< "$FILES"

echo "Fixing shebangs..."
find "$SCRIPT_DIR" -name '*.sh' ! -name 'vendor.sh' -exec \
  sed -i 's|^#!/bin/bash|#!/usr/bin/env bash|' {} +

echo "Done. Vendored $(echo "$FILES" | wc -l | tr -d ' ') files."
