#!/usr/bin/env bash
# AEGF sessionStart: validate instruction layer and inject governance context.
set -euo pipefail

ROOT="${CURSOR_PROJECT_DIR:-$(pwd)}"
AEGF="${ROOT}/aelaron-framework-governance"
export AEGF_WORKSPACE_ROOT="$ROOT"
export AEGF_REPO_ROOT="$AEGF"

read -r INPUT
SESSION_ID="$(echo "$INPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("session_id") or d.get("conversation_id") or "unknown")')"
COMPOSER_MODE="$(echo "$INPUT" | python3 -c 'import json,sys; d=json.load(sys.stdin); print(d.get("composer_mode") or "agent")')"

STATE_DIR="${ROOT}/.cursor/governance/sessions"
mkdir -p "$STATE_DIR"
STATE_PATH="${STATE_DIR}/${SESSION_ID}.json"

VALIDATION="$(python3 "$AEGF/.github/scripts/governance-instruction-context.py" validate-json)"
CONTEXT="$(python3 "$AEGF/.github/scripts/governance-instruction-context.py" context-md cursor)"

python3 - "$STATE_PATH" "$SESSION_ID" "$COMPOSER_MODE" "$VALIDATION" <<'PY'
import json, sys
from datetime import datetime, timezone
from pathlib import Path
state_path, session_id, composer_mode, validation = sys.argv[1:5]
v = json.loads(validation)
state = {
    "session_id": session_id,
    "composer_mode": composer_mode,
    "started_at": datetime.now(timezone.utc).isoformat(),
    "instruction_layer_ok": v.get("ok", False),
    "missing_files": v.get("gaps", []),
    "report_logged": False,
    "report_logged_at": None,
}
Path(state_path).write_text(json.dumps(state, indent=2), encoding="utf-8")
PY

python3 "$AEGF/.github/scripts/agent-log.py" hook session-start <<<"$INPUT" 2>/dev/null || true

python3 - "$CONTEXT" "$STATE_PATH" "$COMPOSER_MODE" <<'PY'
import json, sys
context, state_path, composer_mode = sys.argv[1:4]
print(json.dumps({
    "env": {
        "AEGF_SESSION_ID": json.loads(open(state_path).read())["session_id"],
        "AEGF_SESSION_STATE": state_path,
        "AEGF_WORKSPACE_ROOT": __import__("os").environ.get("AEGF_WORKSPACE_ROOT", ""),
        "AEGF_REPO_ROOT": __import__("os").environ.get("AEGF_REPO_ROOT", ""),
        "AEGF_COMPOSER_MODE": composer_mode,
    },
    "additional_context": context,
}))
PY
