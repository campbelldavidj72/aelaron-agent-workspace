#!/usr/bin/env bash
# Tail agent-log.jsonl with human-readable summaries.
# Usage:
#   ./tail-agent-log.sh              # last 20 entries, then follow new ones
#   ./tail-agent-log.sh -n 0         # follow new entries only (no replay)
#   ./tail-agent-log.sh --from-start # full replay then follow
#   AGENT_LOG_TRACE=1 — also writes .cursor/governance/hook-trace.jsonl
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AEGF="${ROOT}/aelaron-framework-governance"
export AEGF_WORKSPACE_ROOT="$ROOT"

if [[ ! -f "$AEGF/.github/scripts/agent-log.py" ]]; then
  echo "ERROR: missing $AEGF/.github/scripts/agent-log.py" >&2
  exit 1
fi

exec python3 "$AEGF/.github/scripts/agent-log.py" follow "$@"
