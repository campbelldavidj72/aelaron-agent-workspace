#!/usr/bin/env bash
# AEGF agent-log: append hook events to workspace agent-log.jsonl (fire-and-forget).
set -euo pipefail

HOOK_TYPE="${1:?hook type required}"
ROOT="${AEGF_WORKSPACE_ROOT:-${CURSOR_PROJECT_DIR:-$(pwd)}}"
AEGF="${AEGF_REPO_ROOT:-$ROOT/aelaron-framework-governance}"
export AEGF_WORKSPACE_ROOT="$ROOT"
export AEGF_REPO_ROOT="$AEGF"

read -r INPUT || INPUT="{}"

HOOK_EVENT="$(printf '%s' "$INPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("hook_event_name",""))' 2>/dev/null || true)"

python3 "$AEGF/.github/scripts/agent-log.py" hook "$HOOK_TYPE" <<<"$INPUT" 2>/dev/null || true

case "$HOOK_EVENT" in
  beforeReadFile|beforeTabFileRead)
    echo '{"permission":"allow"}'
    ;;
  *)
    echo "{}"
    ;;
esac
