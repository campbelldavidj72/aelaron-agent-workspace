#!/usr/bin/env bash
# Print absolute path to AEGF tooling root for a workspace directory.
set -euo pipefail
ROOT="$(cd "${1:-${CURSOR_PROJECT_DIR:-$(pwd)}}" && pwd)"
if [[ -f "$ROOT/aegf-tooling/.github/scripts/governance-instruction-context.py" ]]; then
  echo "$ROOT/aegf-tooling"
elif [[ -f "$ROOT/aelaron-framework-governance/.github/scripts/governance-instruction-context.py" ]]; then
  echo "$ROOT/aelaron-framework-governance"
elif [[ -f "$ROOT/../aelaron-framework-governance/.github/scripts/governance-instruction-context.py" ]]; then
  echo "$(cd "$ROOT/.." && pwd)/aelaron-framework-governance"
else
  echo "$ROOT/aegf-tooling"
fi
