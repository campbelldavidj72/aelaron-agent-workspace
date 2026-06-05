#!/usr/bin/env bash
# Diagnostic: append a line on every hook invocation (workspaceOpen / debug).
set -euo pipefail

ROOT="${AEGF_WORKSPACE_ROOT:-${CURSOR_PROJECT_DIR:-$(pwd)}}"
TRACE_DIR="$ROOT/.cursor/governance"
mkdir -p "$TRACE_DIR"

read -r INPUT || INPUT="{}"
HOOK_JSON="${ROOT}/.cursor/hooks/aegf-hook-json.py"

HOOK_EVENT="$(INPUT="$INPUT" python3 "$HOOK_JSON" hook_event_name 2>/dev/null || echo unknown)"
CURSOR_VER="$(INPUT="$INPUT" python3 "$HOOK_JSON" cursor_version 2>/dev/null || true)"

python3 - <<PY >>"$TRACE_DIR/hook-trace.jsonl"
import json
from datetime import datetime, timezone
print(json.dumps({
    "ts": datetime.now(timezone.utc).isoformat(),
    "kind": "hook_ping",
    "hook_event": "$HOOK_EVENT",
    "cursor_version": "$CURSOR_VER",
    "root": "$ROOT",
}, separators=(",", ":")))
PY

echo "{}"
