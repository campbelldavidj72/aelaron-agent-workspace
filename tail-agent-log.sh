#!/usr/bin/env bash
# Tail agent-log.jsonl with human-readable summaries.
# Usage:
#   ./tail-agent-log.sh              # new entries only
#   ./tail-agent-log.sh --from-start # replay then follow
#   ./tail-agent-log.sh --from-start --no-follow  # replay only
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AEGF="${ROOT}/aelaron-framework-governance"
export AEGF_WORKSPACE_ROOT="$ROOT"

if [[ ! -f "$AEGF/.github/scripts/agent-log.py" ]]; then
  echo "ERROR: missing $AEGF/.github/scripts/agent-log.py" >&2
  exit 1
fi

exec python3 "$AEGF/.github/scripts/agent-log.py" follow "$@"
