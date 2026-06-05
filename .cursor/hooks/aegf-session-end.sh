#!/usr/bin/env bash
# AEGF sessionEnd: append session audit line (fire-and-forget).
set -euo pipefail

read -r INPUT
python3 - "$INPUT" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

end_payload = json.loads(sys.argv[1] or "{}")
state_path = os.environ.get("AEGF_SESSION_STATE")
state = {}
if state_path and Path(state_path).is_file():
    state = json.loads(Path(state_path).read_text(encoding="utf-8"))

root = Path(os.environ.get("AEGF_WORKSPACE_ROOT", "."))
audit_log = root / ".cursor/governance/session-audit.jsonl"
audit_log.parent.mkdir(parents=True, exist_ok=True)

entry = {
    "timestamp": datetime.now(timezone.utc).isoformat(),
    "session_id": state.get("session_id") or end_payload.get("session_id"),
    "reason": end_payload.get("reason"),
    "duration_ms": end_payload.get("duration_ms"),
    "composer_mode": state.get("composer_mode"),
    "instruction_layer_ok": state.get("instruction_layer_ok"),
    "report_logged": state.get("report_logged"),
    "report_logged_at": state.get("report_logged_at"),
}
with audit_log.open("a", encoding="utf-8") as f:
    f.write(json.dumps(entry, separators=(",", ":")) + "\n")
print("{}")
PY
