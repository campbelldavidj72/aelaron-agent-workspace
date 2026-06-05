#!/usr/bin/env bash
# Install portable + tool-specific AEGF instruction layer into v4 workspace.
set -euo pipefail

AEGF_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WS="${1:-$(cd "$AEGF_ROOT/.." && pwd)}"

echo "Installing AEGF agent instruction layer"
echo "  AEGF: $AEGF_ROOT"
echo "  Workspace: $WS"

mkdir -p "$WS/.cursor/rules" "$WS/.cursor/hooks" "$WS/.cursor/governance" \
  "$WS/.github" "$WS/.claude/hooks"

# Portable
if [[ ! -f "$WS/AGENTS.md" ]]; then
  cp "$AEGF_ROOT/templates/AGENTS.md" "$WS/AGENTS.md"
  echo "  + AGENTS.md (from template — review pins)"
fi

cp "$AEGF_ROOT/templates/CLAUDE.md" "$WS/CLAUDE.md"
cp "$AEGF_ROOT/templates/copilot-instructions.md" "$WS/.github/copilot-instructions.md"

# Cursor
cp "$AEGF_ROOT/templates/cursor/hooks.json" "$WS/.cursor/hooks.json"
for hook in aegf-hook-json.py aegf-session-start.sh aegf-pretooluse-task.sh aegf-after-shell-report.sh aegf-session-end.sh aegf-agent-log.sh; do
  cp "$AEGF_ROOT/templates/cursor/hooks/$hook" "$WS/.cursor/hooks/$hook"
done
cp "$AEGF_ROOT/templates/cursor/governance/.gitignore" "$WS/.cursor/governance/.gitignore"
cp "$AEGF_ROOT/templates/cursor/rules/aegf-governance.mdc" "$WS/.cursor/rules/aegf-governance.mdc"
cp "$AEGF_ROOT/templates/cursor/rules/aegf-subagents.mdc" "$WS/.cursor/rules/aegf-subagents.mdc"

# Claude Code
cp "$AEGF_ROOT/templates/claude/settings.json" "$WS/.claude/settings.json"
cp "$AEGF_ROOT/templates/claude/hooks/aegf-session-start.sh" "$WS/.claude/hooks/aegf-session-start.sh"

chmod +x "$WS/.cursor/hooks/"*.sh "$WS/.claude/hooks/"*.sh 2>/dev/null || true

export AEGF_WORKSPACE_ROOT="$WS"
export AEGF_REPO_ROOT="$AEGF_ROOT"
bash "$AEGF_ROOT/.github/scripts/governance-instruction-layer-check.sh" "$WS"

echo "Done."
