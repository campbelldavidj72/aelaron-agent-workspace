#!/usr/bin/env bash
# Scaffold governance/issue-context-packs/<issue>.yaml from domain-agent-registry L0 defaults.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

ISSUE="${1:-}"
ROLE="${2:-}"

if [[ -z "$ISSUE" || -z "$ROLE" ]]; then
  echo "Usage: $0 <issue-number> <domain-agent-role>" >&2
  echo "Example: $0 95 governance" >&2
  exit 1
fi

OUT_DIR="governance/issue-context-packs"
OUT_FILE="${OUT_DIR}/${ISSUE}.yaml"
REGISTRY="governance/aegf/templates/domain-agent-registry.yaml"
[[ -f "$REGISTRY" ]] || REGISTRY="templates/domain-agent-registry.yaml"

if [[ ! -f "$REGISTRY" ]]; then
  echo "ERROR: domain-agent-registry.yaml not found" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
if [[ -f "$OUT_FILE" ]]; then
  echo "ERROR: $OUT_FILE already exists" >&2
  exit 1
fi

python3 - "$ISSUE" "$ROLE" "$REGISTRY" "$OUT_FILE" <<'PY'
import sys
from datetime import datetime, timezone
from pathlib import Path

issue, role, registry_path, out_path = sys.argv[1:5]

try:
    import yaml
except ImportError:
    raise SystemExit("PyYAML required")

data = yaml.safe_load(Path(registry_path).read_text()) or {}
entry = (data.get("domain_agents") or {}).get(role)
if not entry:
    raise SystemExit(f"unknown domain_agent_role: {role}")

repo = entry.get("repository", "")
tiers = entry.get("context_tiers") or data.get("defaults", {}).get("context_tiers") or {}
l0 = tiers.get("L0") or []

pack = {
    "version": 1,
    "context_pack": {
        "issue": int(issue) if issue.isdigit() else issue,
        "target_repository": repo,
        "domain_agent_role": role,
        "worker_agent_role": None,
        "framework_pins": {"aegf": "v1.0.9"},
        "tiers": {
            "L0": [{"path": p, "purpose": "domain agent L0 default"} for p in l0],
            "L1": [],
            "L2": [],
        },
        "excluded": [],
        "produced_by": "scaffold-issue-context-pack.sh",
        "produced_at": datetime.now(timezone.utc).isoformat(),
    },
}

Path(out_path).write_text(
    "# Copy from templates/context-pack-template.yaml — edit L1/L2 before worker spawn\n"
    + yaml.dump(pack, sort_keys=False, default_flow_style=False),
    encoding="utf-8",
)
print(f"Created {out_path}")
PY
