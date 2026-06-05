#!/usr/bin/env bash
# AEGF beforeShellExecution: ask before destructive git or rm -rf.
set -euo pipefail

read -r INPUT || INPUT="{}"

python3 - "$INPUT" <<'PY'
import json
import re
import sys

def parse_hook_input(raw: str) -> dict:
    text = (raw or "").strip()
    if not text:
        return {}
    try:
        parsed = json.loads(text)
        return parsed if isinstance(parsed, dict) else {}
    except json.JSONDecodeError:
        obj, _end = json.JSONDecoder().raw_decode(text)
        return obj if isinstance(obj, dict) else {}

payload = parse_hook_input(sys.argv[1])
command = payload.get("command") or payload.get("shellCommand") or ""

destructive = [
    r"git\s+push\s+.*--force",
    r"git\s+push\s+-f\b",
    r"git\s+reset\s+--hard",
    r"rm\s+-rf\s+",
]

for pat in destructive:
    if re.search(pat, command):
        print(json.dumps({
            "permission": "ask",
            "user_message": "AEGF flagged a potentially destructive shell command. Confirm before proceeding.",
            "agent_message": "This command may rewrite history or delete files. Verify it matches the issue envelope and allowed paths.",
        }))
        sys.exit(0)

print(json.dumps({"permission": "allow"}))
PY
