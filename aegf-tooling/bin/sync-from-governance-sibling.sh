#!/usr/bin/env bash
# Refresh aegf-tooling from sibling aelaron-framework-governance clone.
set -euo pipefail

V4="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SRC="$V4/aelaron-framework-governance"
DST="$V4/aegf-tooling"

if [[ ! -d "$SRC/.git" ]]; then
  echo "WARN: $SRC not found — skipping aegf-tooling sync"
  exit 0
fi

echo "Syncing aegf-tooling from $SRC"
rsync -a --delete \
  --exclude='bin/' \
  --exclude='README.md' \
  --exclude='governance-instruction-context.py' \
  "$SRC/.github/scripts/" "$DST/.github/scripts/"
rsync -a --delete \
  "$SRC/templates/" "$DST/templates/"
cp "$SRC/VERSION" "$DST/VERSION"
echo "Done. VERSION=$(cat "$DST/VERSION")"
