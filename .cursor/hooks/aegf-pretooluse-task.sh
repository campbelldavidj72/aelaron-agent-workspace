#!/usr/bin/env bash
# AEGF preToolUse: inject governance constraints into Cursor Task subagent prompts.
set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=aegf-env.sh
source "$HOOK_DIR/aegf-env.sh"

ROOT="${CURSOR_PROJECT_DIR:-$(pwd)}"
aegf_bootstrap_env "$ROOT"
AEGF="$AEGF_REPO_ROOT"

read -r INPUT || INPUT="{}"
python3 "$AEGF/.github/scripts/agent-log.py" hook pretooluse-task <<<"$INPUT" 2>/dev/null || true

python3 - "$INPUT" <<'PY'
import json
import os
import sys

def parse_hook_input(raw: str) -> dict:
    text = raw.strip()
    if not text:
        return {}
    try:
        parsed = json.loads(text)
        return parsed if isinstance(parsed, dict) else {}
    except json.JSONDecodeError:
        obj, _end = json.JSONDecoder().raw_decode(text)
        return obj if isinstance(obj, dict) else {}

raw = sys.argv[1]
payload = parse_hook_input(raw or "")
if payload.get("tool_name") != "Task":
    print("{}")
    sys.exit(0)

tool_input = payload.get("tool_input") or {}
subagent_type = tool_input.get("subagent_type") or tool_input.get("subagentType") or "generalPurpose"
prompt = tool_input.get("prompt") or tool_input.get("task") or tool_input.get("description") or ""

aegf = os.environ.get("AEGF_REPO_ROOT") or os.path.join(os.environ.get("AEGF_WORKSPACE_ROOT", "."), "aelaron-framework-governance")
suffix = __import__("subprocess").check_output(
    ["python3", f"{aegf}/.github/scripts/governance-instruction-context.py", "subagent-suffix", subagent_type],
    text=True,
)
if "---\n**AEGF subagent constraints" in prompt:
    print("{}")
    sys.exit(0)

updated = dict(tool_input)
if "prompt" in tool_input:
    updated["prompt"] = prompt + suffix
elif "task" in tool_input:
    updated["task"] = prompt + suffix
elif "description" in tool_input:
    updated["description"] = prompt + suffix
else:
    updated["prompt"] = (prompt or "Execute the assigned task.") + suffix

print(json.dumps({"permission": "allow", "updated_input": updated}))
PY
