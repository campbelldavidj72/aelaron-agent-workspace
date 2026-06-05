#!/usr/bin/env bash
# AEGF afterAgentResponse: mark session when governance report appears in agent output.
set -euo pipefail

read -r INPUT
python3 - "$INPUT" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

payload = json.loads(sys.argv[1] or "{}")
text = payload.get("text") or payload.get("response") or payload.get("content") or ""
if "## Governance run report" not in text:
    print("{}")
    sys.exit(0)

state_path = os.environ.get("AEGF_SESSION_STATE")
if not state_path or not Path(state_path).is_file():
    print("{}")
    sys.exit(0)

state = json.loads(Path(state_path).read_text(encoding="utf-8"))
state["report_logged"] = True
state["report_logged_at"] = datetime.now(timezone.utc).isoformat()
state["report_detected_via"] = "afterAgentResponse"
Path(state_path).write_text(json.dumps(state, indent=2), encoding="utf-8")
print("{}")
PY
