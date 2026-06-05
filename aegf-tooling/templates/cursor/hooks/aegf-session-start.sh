#!/usr/bin/env bash
# AEGF sessionStart: validate instruction layer and inject governance context.
set -euo pipefail

ROOT="${CURSOR_PROJECT_DIR:-$(pwd)}"
AEGF="${ROOT}/aelaron-framework-governance"
export AEGF_WORKSPACE_ROOT="$ROOT"
export AEGF_REPO_ROOT="$AEGF"

TRACE_DIR="$ROOT/.cursor/governance"
TRACE_FILE="$TRACE_DIR/hook-trace.jsonl"

log_hook_trace() {
  local kind="$1"
  local detail="$2"
  mkdir -p "$TRACE_DIR"
  HOOK_TRACE_KIND="$kind" HOOK_TRACE_DETAIL="$detail" \
  python3 - <<'PY' >>"$TRACE_FILE"
import json, os
from datetime import datetime, timezone
print(json.dumps({
    "ts": datetime.now(timezone.utc).isoformat(),
    "kind": os.environ["HOOK_TRACE_KIND"],
    "hook_type": "session-start",
    "detail": os.environ.get("HOOK_TRACE_DETAIL", ""),
}, separators=(",", ":")))
PY
}

read -r INPUT || INPUT="{}"
HOOK_JSON="${ROOT}/.cursor/hooks/aegf-hook-json.py"
SESSION_ID="$(INPUT="$INPUT" python3 "$HOOK_JSON" session_id)"
COMPOSER_MODE="$(INPUT="$INPUT" python3 "$HOOK_JSON" composer_mode)"

STATE_DIR="${ROOT}/.cursor/governance/sessions"
mkdir -p "$STATE_DIR"
STATE_PATH="${STATE_DIR}/${SESSION_ID}.json"

if [[ ! -f "$AEGF/.github/scripts/governance-instruction-context.py" ]]; then
  log_hook_trace "missing_governance_context_script" "not found: $AEGF/.github/scripts/governance-instruction-context.py"
  echo '{"continue":true}'
  exit 0
fi


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

stderr_file="$(mktemp "${TMPDIR:-/tmp}/aegf-session-start.XXXXXX")"
NORMALIZED="$(INPUT="$INPUT" python3 "$HOOK_JSON")"
set +e
python3 "$AEGF/.github/scripts/agent-log.py" hook session-start <<<"$NORMALIZED" 2>"$stderr_file"
rc=$?
set -e
if [[ "$rc" -ne 0 ]] || [[ -s "$stderr_file" ]]; then
  log_hook_trace "session_start_agent_log_failed" "$(cat "$stderr_file")"
else
  log_hook_trace "session_start_ok" "session_id=${SESSION_ID} logged to agent-log.jsonl"
fi
rm -f "$stderr_file"

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
