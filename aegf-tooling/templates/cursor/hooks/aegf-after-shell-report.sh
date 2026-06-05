#!/usr/bin/env bash
# AEGF afterShellExecution: mark governance run report when script executes.
set -euo pipefail

read -r INPUT
python3 - "$INPUT" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

payload = json.loads(sys.argv[1] or "{}")
command = payload.get("command") or payload.get("shell_command") or ""
exit_code = payload.get("exit_code", payload.get("exitCode", 0))

if "governance-run-report" not in command or exit_code != 0:
    print("{}")
    sys.exit(0)

state_path = os.environ.get("AEGF_SESSION_STATE")
if not state_path:
    print("{}")
    sys.exit(0)

p = Path(state_path)
if p.is_file():
    state = json.loads(p.read_text(encoding="utf-8"))
    state["report_logged"] = True
    state["report_logged_at"] = datetime.now(timezone.utc).isoformat()
    state["report_command"] = command[:500]
    p.write_text(json.dumps(state, indent=2), encoding="utf-8")
print("{}")
PY
