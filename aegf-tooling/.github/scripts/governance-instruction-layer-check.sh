#!/usr/bin/env bash
# Validate AEGF agent instruction layer for a workspace (VP-GOV-01 extension).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WS="${1:-${AEGF_WORKSPACE_ROOT:-$(pwd)}}"

export AEGF_WORKSPACE_ROOT="$WS"
export AEGF_REPO_ROOT="$ROOT"

echo "Checking AEGF agent instruction layer in: $WS"

result="$(python3 "$ROOT/.github/scripts/governance-instruction-context.py" validate-json)"
ok="$(echo "$result" | python3 -c 'import json,sys; print(json.load(sys.stdin)["ok"])')"

echo "$result" | python3 -c '
import json, sys
data = json.load(sys.stdin)
print("\nRequired / recommended files:")
for name, present in sorted(data.get("present", {}).items()):
    mark = "OK" if present else "MISSING"
    print(f"  [{mark}] {name}")
if data.get("gaps"):
    print("\nGaps:")
    for g in data["gaps"]:
        print(f"  - {g}")
'

if [[ "$ok" != "True" ]]; then
  echo "FAIL: instruction layer incomplete"
  exit 1
fi

echo "PASS: instruction layer complete"
exit 0
