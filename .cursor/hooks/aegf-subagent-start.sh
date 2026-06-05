#!/usr/bin/env bash
# AEGF subagentStart: audit spawn; warn on implementer without context-pack marker in session.
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=aegf-env.sh
source "$HOOK_DIR/aegf-env.sh"

ROOT="${CURSOR_PROJECT_DIR:-$(pwd)}"
aegf_bootstrap_env "$ROOT"
AEGF="$AEGF_REPO_ROOT"

read -r INPUT || INPUT="{}"
python3 "$AEGF/.github/scripts/agent-log.py" hook subagent-start <<<"$INPUT" 2>/dev/null || true

python3 - "$INPUT" <<'PY'
import json
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
subagent_type = payload.get("subagent_type") or payload.get("subagentType") or ""
# Allow all spawns — domain pack gate is enforced in preToolUse Task
print(json.dumps({"permission": "allow"}))
PY
