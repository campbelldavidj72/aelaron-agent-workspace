#!/usr/bin/env bash
# Clone, sync, and install AEGF instruction layer for all program repositories.
# Repository list: repos.yaml (single source of truth)
set -euo pipefail

V4="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG=campbelldavidj72
AEGF_TAG=v1.0.8
MANIFEST="${V4}/repos.yaml"

if [[ ! -f "$MANIFEST" ]]; then
  echo "ERROR: missing $MANIFEST"
  exit 1
fi

read_manifest() {
  python3 - "$MANIFEST" "$1" <<'PY'
import sys
import yaml
from pathlib import Path

data = yaml.safe_load(Path(sys.argv[1]).read_text()) or {}
repos = data.get("repositories") or []
mode = sys.argv[2]

if mode == "paths":
    for r in repos:
        print(r["path"])
elif mode == "clone_submodules":
    for r in repos:
        if r.get("clone_submodules"):
            print(r["path"])
elif mode == "install":
    for r in repos:
        print(f"{r['path']}\t{r.get('install', 'none')}\t{r.get('validation', '')}")
else:
    raise SystemExit(f"unknown mode: {mode}")
PY
}

patch_hooks_governance_aegf() {
  local root="$1"
  local f
  for f in "$root"/.cursor/hooks/*.sh "$root"/.claude/hooks/*.sh; do
    [[ -f "$f" ]] || continue
    sed -i '' 's|${ROOT}/aelaron-framework-governance|${ROOT}/governance/aegf|g' "$f"
    sed -i '' 's|aelaron-framework-governance|governance/aegf|g' "$f"
  done
  for f in "$root"/.cursor/rules/*.mdc; do
    [[ -f "$f" ]] || continue
    sed -i '' 's|aelaron-framework-governance|governance/aegf|g' "$f"
  done
}

patch_hooks_governance_self() {
  local root="$1"
  local f
  for f in "$root"/.cursor/hooks/*.sh "$root"/.claude/hooks/*.sh; do
    [[ -f "$f" ]] || continue
    sed -i '' 's|${ROOT}/aelaron-framework-governance|${ROOT}|g' "$f"
    sed -i '' 's|\${ROOT}/governance/aegf|\${ROOT}|g' "$f"
  done
  for f in "$root"/.cursor/rules/*.mdc; do
    [[ -f "$f" ]] || continue
    sed -i '' 's|aelaron-framework-governance/|.github/|g' "$f"
    sed -i '' 's|governance/aegf/|.github/|g' "$f"
  done
}

patch_hooks_governance_sibling() {
  local root="$1"
  local f
  for f in "$root"/.cursor/hooks/*.sh "$root"/.claude/hooks/*.sh; do
    [[ -f "$f" ]] || continue
    sed -i '' 's|${ROOT}/aelaron-framework-governance|${ROOT}/../aelaron-framework-governance|g' "$f"
    sed -i '' 's|aelaron-framework-governance|../aelaron-framework-governance|g' "$f"
  done
  for f in "$root"/.cursor/rules/*.mdc; do
    [[ -f "$f" ]] || continue
    sed -i '' 's|aelaron-framework-governance|../aelaron-framework-governance|g' "$f"
  done
}

install_with_aegf_submodule() {
  local root="$1"
  cd "$root"
  git submodule update --init --recursive
  if [[ -e governance/aegf/.git ]]; then
    git -C governance/aegf fetch --tags origin 2>/dev/null || true
    git -C governance/aegf checkout "$AEGF_TAG" 2>/dev/null || git -C governance/aegf checkout development 2>/dev/null || true
  fi
  ln -sf governance/aegf aelaron-framework-governance
  if [[ -x governance/aegf/.github/scripts/install-v4-agent-instruction-layer.sh ]]; then
    bash governance/aegf/.github/scripts/install-v4-agent-instruction-layer.sh .
  else
    bash "$V4/aelaron-framework-governance/.github/scripts/install-v4-agent-instruction-layer.sh" .
  fi
  rm -f aelaron-framework-governance
  patch_hooks_governance_aegf "$root"
}

install_with_sibling_governance() {
  local root="$1"
  cd "$root"
  ln -sf ../aelaron-framework-governance aelaron-framework-governance
  bash "$V4/aelaron-framework-governance/.github/scripts/install-v4-agent-instruction-layer.sh" .
  rm -f aelaron-framework-governance
  patch_hooks_governance_sibling "$root"
}

install_governance_self() {
  local root="$1"
  cd "$root"
  [[ -e aelaron-framework-governance ]] || ln -sf . aelaron-framework-governance
  bash .github/scripts/install-v4-agent-instruction-layer.sh .
  patch_hooks_governance_self "$root"
  rm -f aelaron-framework-governance
}

install_enterprise_application() {
  local root="$1"
  cd "$root"
  git submodule update --init --recursive
  ln -sf governance/aegf aelaron-framework-governance
  bash governance/aegf/.github/scripts/install-v4-agent-instruction-layer.sh .
  rm -f aelaron-framework-governance
  patch_hooks_governance_aegf "$root"
}

install_program_workspace() {
  echo "=== Setup program workspace root ==="
  if [[ ! -d "$V4/aelaron-framework-governance/.git" ]]; then
    echo "ERROR: clone aelaron-framework-governance first"
    exit 1
  fi
  bash "$V4/aelaron-framework-governance/.github/scripts/install-v4-agent-instruction-layer.sh" "$V4"
  bash "$V4/aelaron-framework-governance/.github/scripts/governance-instruction-layer-check.sh" "$V4"
}

run_validation() {
  local root="$1"
  local script="$2"
  [[ -n "$script" ]] || return 0
  if [[ -x "$root/$script" ]]; then
    bash "$root/$script"
  else
    echo "  SKIP validation (no script): $script"
  fi
}

clone_repo() {
  local repo="$1"
  local url="git@github.com:${ORG}/${repo}.git"
  local submodules
  submodules="$(read_manifest clone_submodules)"
  if grep -qx "$repo" <<<"$submodules"; then
    git clone --recurse-submodules "$url" "$V4/$repo"
  else
    git clone "$url" "$V4/$repo"
  fi
}

echo "=== Clone missing repos (from repos.yaml) ==="
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  if [[ ! -d "$V4/$repo/.git" ]]; then
    echo "-- cloning $repo"
    if clone_repo "$repo"; then
      :
    else
      echo "  WARN: clone failed for $repo (repo may be empty or private)"
    fi
  else
    echo "-- exists: $repo"
  fi
done < <(read_manifest paths)

echo "=== Sync all repos to development ==="
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  if [[ ! -d "$V4/$repo/.git" ]]; then
    echo "-- SKIP sync (not cloned): $repo"
    continue
  fi
  echo "-- $repo"
  git -C "$V4/$repo" fetch origin 2>/dev/null || true
  git -C "$V4/$repo" checkout development 2>/dev/null || git -C "$V4/$repo" checkout -b development origin/development 2>/dev/null || true
  git -C "$V4/$repo" pull origin development 2>/dev/null || true
  if grep -qx "$repo" <<<"$(read_manifest clone_submodules)"; then
    git -C "$V4/$repo" submodule update --init --recursive 2>/dev/null || true
  fi
done < <(read_manifest paths)

PROGRAM_WORKSPACE_DONE=false

while IFS=$'\t' read -r repo install validation; do
  [[ -z "$repo" ]] && continue
  if [[ ! -d "$V4/$repo/.git" ]]; then
    echo "=== SKIP $repo (not cloned) ==="
    continue
  fi

  echo "=== Setup $repo (install=$install) ==="
  case "$install" in
    governance_self)
      install_governance_self "$V4/$repo"
      run_validation "$V4/$repo" "$validation"
      install_program_workspace
      PROGRAM_WORKSPACE_DONE=true
      ;;
    aegf_submodule)
      install_with_aegf_submodule "$V4/$repo"
      run_validation "$V4/$repo" "$validation"
      ;;
    sibling_governance)
      install_with_sibling_governance "$V4/$repo"
      run_validation "$V4/$repo" "$validation"
      ;;
    enterprise)
      install_enterprise_application "$V4/$repo"
      run_validation "$V4/$repo" "$validation"
      ;;
    none)
      echo "  clone/sync only"
      ;;
    *)
      echo "  WARN: unknown install type: $install"
      ;;
  esac
done < <(read_manifest install)

if [[ "$PROGRAM_WORKSPACE_DONE" != true ]] && [[ -d "$V4/aelaron-framework-governance/.git" ]]; then
  install_program_workspace
fi

echo "=== DONE ==="
echo "Repositories in $(read_manifest paths | wc -l | tr -d ' ') manifest entries"
echo "Cloned under: $V4"
echo "Open in Cursor: cursor $V4"
ls -1 "$V4" | grep '^aelaron-' || true
