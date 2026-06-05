#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

failures=0

require_file() {
  local path="$1"
  if [[ ! -f "$path" ]]; then
    echo "MISSING required file: $path"
    failures=$((failures + 1))
  fi
}

require_heading() {
  local path="$1"
  local heading="$2"
  if [[ ! -f "$path" ]]; then
    return
  fi
  if ! grep -q "^# ${heading}" "$path"; then
    echo "MISSING heading '${heading}' in ${path}"
    failures=$((failures + 1))
  fi
}

echo "Checking AEGF repository structure..."

chmod +x "$ROOT/.github/scripts/governance-instruction-layer-check.sh" \
  "$ROOT/.github/scripts/install-v4-agent-instruction-layer.sh" \
  "$ROOT/.github/scripts/governance-instruction-context.py" \
  "$ROOT/.github/scripts/agent-log.py" 2>/dev/null || true

for file in \
  README.md \
  VERSION \
  GITHUB-OPERATING-MODEL.md \
  IMPLEMENTATION-COMMANDS.md \
  INSTANTIATION-GUIDE.md \
  docs/README.md \
  docs/agents/agent-instruction-layer.md \
  docs/controls/control-register.yaml \
  docs/agents/agent-scope-envelope-model.md \
  docs/agents/domain-agent-and-context-pack-model.md \
  docs/agents/context-pack-issue-convention.md \
  docs/agents/agent-activity-log.md \
  docs/standards/agent-verification-profiles.md \
  templates/agent-role-catalog.yaml \
  templates/agent-skills-catalog.yaml \
  templates/domain-agent-registry.yaml \
  templates/context-pack-template.yaml \
  templates/copilot-instructions.md \
  templates/cursor/hooks.json \
  templates/claude/settings.json \
  .github/CODEOWNERS \
  .github/pull_request_template.md \
  .github/ISSUE_TEMPLATE/governance-change.yml \
  .github/ISSUE_TEMPLATE/agent-task.yml \
  .github/ISSUE_TEMPLATE/material-change-agent-workflow.yml; do
  require_file "$file"
done

for i in $(seq -w 0 22); do
  matches=(docs/governance/${i}-*.md)
  if [[ ! -f "${matches[0]}" ]]; then
    echo "MISSING governance domain doc for index ${i}"
    failures=$((failures + 1))
  fi
done

if [[ -f VERSION ]] && ! grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+$' VERSION; then
  echo "INVALID VERSION format in VERSION (expected semver, e.g. 1.0.0)"
  failures=$((failures + 1))
fi

require_heading "docs/governance/00-governance-charter.md" "Governance Charter"
require_heading "docs/governance/12-policy-hierarchy.md" "Policy Hierarchy"
require_heading "docs/governance/13-evidence-governance.md" "Evidence Governance"
require_heading "docs/governance/20-work-intake-and-backlog-governance.md" "Work Intake And Backlog Governance"
require_heading "docs/governance/22-github-projects-backlog-model.md" "GitHub Projects Backlog Model"
require_heading "docs/agents/agent-scope-envelope-model.md" "Agent Scope Envelope Model"
require_heading "docs/standards/agent-verification-profiles.md" "Agent Verification Profiles"

if command -v python3 >/dev/null 2>&1; then
  python3 - <<'PY'
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("SKIP control-register.yaml parse (PyYAML unavailable)")
    sys.exit(0)

path = Path("docs/controls/control-register.yaml")
data = yaml.safe_load(path.read_text())
controls = data.get("controls") or []
if not controls:
    raise SystemExit("control-register.yaml must define at least one control")
ids = [c.get("id") for c in controls]
if len(ids) != len(set(ids)):
    raise SystemExit("control-register.yaml contains duplicate control IDs")
print(f"Validated {len(controls)} controls in control-register.yaml")
PY
else
  echo "SKIP control-register.yaml parse (python3 unavailable)"
fi

if find . -path ./.git -prune -o -name '.DS_Store' -print | grep -q .; then
  echo "FOUND .DS_Store files (remove before release)"
  find . -path ./.git -prune -o -name '.DS_Store' -print
  failures=$((failures + 1))
fi

if [[ "$failures" -gt 0 ]]; then
  echo "Governance check failed with ${failures} issue(s)."
  exit 1
fi

echo "Governance check passed."
