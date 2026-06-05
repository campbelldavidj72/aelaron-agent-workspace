#!/usr/bin/env bash
# AEGF Claude SessionStart: validate instruction layer and inject governance context.
set -euo pipefail

ROOT="$(pwd)"
AEGF="${ROOT}/aelaron-framework-governance"
export AEGF_WORKSPACE_ROOT="$ROOT"
export AEGF_REPO_ROOT="$AEGF"

read -r INPUT || true
SESSION_ID="$(echo "${INPUT:-{}}" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("session_id") or "unknown")')"

STATE_DIR="${ROOT}/.claude/governance/sessions"
mkdir -p "$STATE_DIR"
STATE_PATH="${STATE_DIR}/${SESSION_ID}.json"

VALIDATION="$(python3 "$AEGF/.github/scripts/governance-instruction-context.py" validate-json)"
CONTEXT="$(python3 "$AEGF/.github/scripts/governance-instruction-context.py" context-md claude_code)"

python3 - "$STATE_PATH" "$SESSION_ID" "$VALIDATION" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path
state_path, session_id, validation = sys.argv[1:4]
v = json.loads(validation)
Path(state_path).write_text(json.dumps({
    "session_id": session_id,
    "started_at": datetime.now(timezone.utc).isoformat(),
    "instruction_layer_ok": v.get("ok", False),
    "report_logged": False,
}, indent=2), encoding="utf-8")
PY

export AEGF_SESSION_STATE="$STATE_PATH"

python3 - "$CONTEXT" <<'PY'
import json, sys
context = sys.argv[1]
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": context,
    }
}))
PY
