#!/usr/bin/env bash
# Clone, sync, and validate Aelaron v4 program repositories.
# L0 agent hooks live in this workspace; AEGF scripts live in aelaron-framework-governance sibling.
# Repository list: repos.yaml
set -euo pipefail

V4="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG=campbelldavidj72
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
elif mode == "validate":
    for r in repos:
        script = r.get("validation") or ""
        if script:
            print(f"{r['path']}\t{script}")
else:
    raise SystemExit(f"unknown mode: {mode}")
PY
}

run_validation() {
  local root="$1"
  local script="$2"
  [[ -n "$script" ]] || return 0
  if [[ -x "$root/$script" ]]; then
    bash "$root/$script"
  elif [[ -f "$root/$script" ]]; then
    bash "$root/$script"
  else
    echo "  SKIP validation (no script): $script"
  fi
}

clone_repo() {
  local repo="$1"
  local url="git@github.com:${ORG}/${repo}.git"
  if grep -qx "$repo" <<<"$(read_manifest clone_submodules)"; then
    git clone --recurse-submodules "$url" "$V4/$repo"
  else
    git clone "$url" "$V4/$repo"
  fi
}

install_program_workspace() {
  echo "=== L0 program workspace (AEGF from governance sibling) ==="
  if [[ -x "$V4/aelaron-framework-governance/bin/install-program-workspace.sh" ]]; then
    bash "$V4/aelaron-framework-governance/bin/install-program-workspace.sh" "$V4"
  else
    echo "  WARN: aelaron-framework-governance not cloned — skipping instruction layer install"
  fi
}

echo "=== Clone missing repos (from repos.yaml) ==="
while IFS= read -r repo; do
  [[ -z "$repo" ]] && continue
  if [[ ! -d "$V4/$repo/.git" ]]; then
    echo "-- cloning $repo"
    clone_repo "$repo" || echo "  WARN: clone failed for $repo"
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
  git -C "$V4/$repo" checkout development 2>/dev/null \
    || git -C "$V4/$repo" checkout -b development origin/development 2>/dev/null || true
  git -C "$V4/$repo" pull origin development 2>/dev/null || true
  if grep -qx "$repo" <<<"$(read_manifest clone_submodules)"; then
    git -C "$V4/$repo" submodule update --init --recursive 2>/dev/null || true
  fi
done < <(read_manifest paths)

install_program_workspace

echo "=== Optional repo validation (from repos.yaml) ==="
while IFS=$'\t' read -r repo script; do
  [[ -z "$repo" ]] && continue
  if [[ ! -d "$V4/$repo/.git" ]]; then
    continue
  fi
  echo "-- validate $repo"
  run_validation "$V4/$repo" "$script" || echo "  WARN: validation failed for $repo"
done < <(read_manifest validate)

echo "=== DONE ==="
echo "Open program workspace in Cursor: cursor $V4"
echo "L1 specifications: aelaron-platform-specifications @ v2.0.0"
echo "AEGF tooling: aelaron-framework-governance/ (VERSION $(cat "$V4/aelaron-framework-governance/VERSION" 2>/dev/null || echo '?'))"
