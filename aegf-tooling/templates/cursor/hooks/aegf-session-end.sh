#!/usr/bin/env bash
# AEGF sessionEnd: append session summary to agent-log.jsonl (fire-and-forget).
set -euo pipefail

ROOT="${AEGF_WORKSPACE_ROOT:-${CURSOR_PROJECT_DIR:-$(pwd)}}"
AEGF="${AEGF_REPO_ROOT:-$ROOT/aelaron-framework-governance}"
export AEGF_WORKSPACE_ROOT="$ROOT"
export AEGF_REPO_ROOT="$AEGF"

read -r INPUT || INPUT="{}"
python3 "$AEGF/.github/scripts/agent-log.py" hook session-end <<<"$INPUT" 2>/dev/null || true
echo "{}"
