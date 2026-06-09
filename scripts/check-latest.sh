#!/usr/bin/env bash
# Check the latest published Claude Desktop version against the version pinned
# in pkgs/claude-desktop.nix.
#
# The download URL in the flake always serves whatever the GCS bucket currently
# holds (the `?v=` query is only a cache-buster, not a version selector). The
# bucket exposes a Squirrel RELEASES manifest; the last `-full` entry is latest.

set -euo pipefail

RELEASES_URL="https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest-win-x64/RELEASES"
NIX_FILE="$(dirname "$0")/../pkgs/claude-desktop.nix"

latest="$(curl -fsSL "$RELEASES_URL" \
  | grep -o 'AnthropicClaude-[0-9.]*-full' \
  | sed 's/AnthropicClaude-//; s/-full//' \
  | tail -1)"

if [ -z "$latest" ]; then
  echo "error: could not determine latest version from RELEASES manifest" >&2
  exit 1
fi

pinned="$(grep -oP 'version = "\K[0-9.]+' "$NIX_FILE" | head -1)"

echo "latest published: $latest"
echo "flake pins:       $pinned"

if [ "$latest" = "$pinned" ]; then
  echo "=> up to date"
else
  echo "=> update available: $pinned -> $latest"
  echo
  echo "To update, set version = \"$latest\" in pkgs/claude-desktop.nix and refresh the hash:"
  echo "  nix store prefetch-file --hash-type sha256 \\"
  echo "    \"https://storage.googleapis.com/osprey-downloads-c02f6a0d-347c-492b-a752-3e0651722e97/nest-win-x64/Claude-Setup-x64.exe?v=$latest\""
  exit 1
fi
