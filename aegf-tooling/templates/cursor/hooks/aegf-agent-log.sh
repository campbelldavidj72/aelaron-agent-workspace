#!/usr/bin/env bash
# AEGF agent-log: append hook events to workspace agent-log.jsonl (fire-and-forget).
set -euo pipefail

HOOK_TYPE="${1:?hook type required}"
ROOT="${AEGF_WORKSPACE_ROOT:-${CURSOR_PROJECT_DIR:-$(pwd)}}"
AEGF="${AEGF_REPO_ROOT:-$ROOT/governance/aegf}"
export AEGF_WORKSPACE_ROOT="$ROOT"
export AEGF_REPO_ROOT="$AEGF"

TRACE_DIR="$ROOT/.cursor/governance"
TRACE_FILE="$TRACE_DIR/hook-trace.jsonl"
INPUT="{}"
HOOK_EVENT=""

log_hook_trace() {
  local kind="$1"
  local detail="$2"
  local exit_code="${3:-}"
  mkdir -p "$TRACE_DIR"
  HOOK_TRACE_KIND="$kind" HOOK_TRACE_DETAIL="$detail" HOOK_TRACE_EXIT="$exit_code" \
  HOOK_TRACE_TYPE="$HOOK_TYPE" HOOK_TRACE_EVENT="$HOOK_EVENT" \
  HOOK_TRACE_ROOT="$ROOT" HOOK_TRACE_AEGF="$AEGF" HOOK_TRACE_INPUT="$INPUT" \
  python3 - <<'PY' >>"$TRACE_FILE"
import json, os
from datetime import datetime, timezone

entry = {
    "ts": datetime.now(timezone.utc).isoformat(),
    "kind": os.environ["HOOK_TRACE_KIND"],
    "hook_type": os.environ.get("HOOK_TRACE_TYPE", ""),
    "hook_event": os.environ.get("HOOK_TRACE_EVENT", ""),
    "root": os.environ.get("HOOK_TRACE_ROOT", ""),
    "aegf": os.environ.get("HOOK_TRACE_AEGF", ""),
    "exit_code": int(os.environ["HOOK_TRACE_EXIT"]) if os.environ.get("HOOK_TRACE_EXIT") else None,
    "detail": os.environ.get("HOOK_TRACE_DETAIL", ""),
}
inp = os.environ.get("HOOK_TRACE_INPUT", "")
if inp and inp != "{}":
    try:
        payload = json.loads(inp)
        entry["input_keys"] = sorted(payload.keys())
        for key in ("file_path", "path", "conversation_id", "session_id"):
            if payload.get(key):
                entry[key] = payload[key]
    except json.JSONDecodeError:
        entry["input_parse"] = "invalid_json"
print(json.dumps(entry, ensure_ascii=False, separators=(",", ":")))
PY
}

read -r INPUT || INPUT="{}"
HOOK_JSON="${ROOT}/.cursor/hooks/aegf-hook-json.py"

if [[ ! -f "$AEGF/.github/scripts/agent-log.py" ]]; then
  log_hook_trace "missing_agent_log_script" "not found: $AEGF/.github/scripts/agent-log.py"
else
  HOOK_EVENT="$(INPUT="$INPUT" python3 "$HOOK_JSON" hook_event_name 2>/dev/null || true)"

  stderr_file="$(mktemp "${TMPDIR:-/tmp}/aegf-agent-log.XXXXXX")"
  NORMALIZED="$(INPUT="$INPUT" python3 "$HOOK_JSON")"
  set +e
  python3 "$AEGF/.github/scripts/agent-log.py" hook "$HOOK_TYPE" <<<"$NORMALIZED" 2>"$stderr_file"
  rc=$?
  set -e
  if [[ "$rc" -ne 0 ]]; then
    log_hook_trace "agent_log_hook_failed" "$(cat "$stderr_file")" "$rc"
  elif [[ -s "$stderr_file" ]]; then
    log_hook_trace "agent_log_hook_stderr" "$(cat "$stderr_file")" "$rc"
  fi
  rm -f "$stderr_file"
fi

case "$HOOK_EVENT" in
  beforeReadFile|beforeTabFileRead)
    echo '{"permission":"allow"}'
    ;;
  *)
    echo "{}"
    ;;
esac
