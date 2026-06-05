#!/usr/bin/env bash
# Install / validate L0 agent instruction layer at program workspace root.
set -euo pipefail

V4="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WS="${1:-$V4}"
AEGF="$V4/aegf-tooling"

if [[ ! -f "$AEGF/.github/scripts/governance-instruction-context.py" ]]; then
  echo "ERROR: missing $AEGF — run aegf-tooling/bin/sync-from-governance-sibling.sh"
  exit 1
fi

echo "Installing L0 agent instruction layer"
echo "  Workspace: $WS"
echo "  AEGF tooling: $AEGF"

mkdir -p "$WS/.github" "$WS/.cursor/rules" "$WS/.cursor/hooks" "$WS/.cursor/governance" "$WS/.claude/hooks"

# Portable adapters (do not overwrite program AGENTS.md)
cp "$AEGF/templates/CLAUDE.md" "$WS/CLAUDE.md"
cp "$AEGF/templates/copilot-instructions.md" "$WS/.github/copilot-instructions.md"
cp "$AEGF/templates/claude/settings.json" "$WS/.claude/settings.json"
cp "$AEGF/templates/claude/hooks/aegf-session-start.sh" "$WS/.claude/hooks/aegf-session-start.sh"
chmod +x "$WS/.claude/hooks/"*.sh 2>/dev/null || true

export AEGF_WORKSPACE_ROOT="$WS"
export AEGF_REPO_ROOT="$AEGF"
bash "$AEGF/.github/scripts/governance-instruction-layer-check.sh" "$WS"
echo "L0 instruction layer OK"
