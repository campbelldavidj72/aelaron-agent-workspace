#!/usr/bin/env bash
set -euo pipefail

V4="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ORG=campbelldavidj72
AEGF_TAG=v1.0.6

ALL_REPOS=(
  aelaron-framework-governance
  aelaron-framework-architecture
  aelaron-framework-registry
  aelaron-framework-compliance
  aelaron-framework-experience
  aelaron-framework-security
  aelaron-framework-user-interface
  aelaron-enterprise-application
  aelaron-gateway-superstream
  aelaron-infrastructure
)

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
  if [[ -x "$root/$script" ]]; then
    bash "$root/$script"
  else
    echo "  SKIP validation (no script): $script"
  fi
}

echo "=== Clone missing repos ==="
for repo in "${ALL_REPOS[@]}"; do
  if [[ ! -d "$V4/$repo/.git" ]]; then
    echo "-- cloning $repo"
    if [[ "$repo" == "aelaron-enterprise-application" ]] || [[ "$repo" == "aelaron-framework-architecture" ]] || [[ "$repo" == "aelaron-framework-registry" ]] || [[ "$repo" == "aelaron-framework-security" ]] || [[ "$repo" == "aelaron-framework-user-interface" ]]; then
      git clone --recurse-submodules "git@github.com:${ORG}/${repo}.git" "$V4/$repo"
    else
      git clone "git@github.com:${ORG}/${repo}.git" "$V4/$repo"
    fi
  fi
done

echo "=== Sync all repos to development ==="
for repo in "${ALL_REPOS[@]}"; do
  if [[ ! -d "$V4/$repo/.git" ]]; then
    echo "-- SKIP sync (not cloned): $repo"
    continue
  fi
  echo "-- $repo"
  git -C "$V4/$repo" fetch origin
  git -C "$V4/$repo" checkout development 2>/dev/null || git -C "$V4/$repo" checkout -b development origin/development 2>/dev/null || true
  git -C "$V4/$repo" pull origin development 2>/dev/null || true
done

echo "=== Setup governance (AEGF source) ==="
cd "$V4/aelaron-framework-governance"
[[ -e aelaron-framework-governance ]] || ln -sf . aelaron-framework-governance
bash .github/scripts/install-v4-agent-instruction-layer.sh .
patch_hooks_governance_self "$V4/aelaron-framework-governance"
rm -f aelaron-framework-governance
run_validation "$V4/aelaron-framework-governance" ".github/scripts/governance-check.sh"

install_program_workspace

echo "=== Setup architecture ==="
install_with_aegf_submodule "$V4/aelaron-framework-architecture"
run_validation "$V4/aelaron-framework-architecture" ".github/scripts/architecture-validation.sh"

echo "=== Setup registry ==="
install_with_aegf_submodule "$V4/aelaron-framework-registry"
run_validation "$V4/aelaron-framework-registry" ".github/scripts/domain-validation.sh"

echo "=== Setup compliance ==="
install_with_sibling_governance "$V4/aelaron-framework-compliance"
run_validation "$V4/aelaron-framework-compliance" ".github/scripts/compliance-validation.sh"

echo "=== Setup experience ==="
install_with_sibling_governance "$V4/aelaron-framework-experience"
run_validation "$V4/aelaron-framework-experience" ".github/scripts/experience-validation.sh"

echo "=== Setup security ==="
if [[ -d "$V4/aelaron-framework-security/.git" ]]; then
  install_with_aegf_submodule "$V4/aelaron-framework-security"
  run_validation "$V4/aelaron-framework-security" ".github/scripts/security-validation.sh"
fi

echo "=== Setup user-interface ==="
if [[ -d "$V4/aelaron-framework-user-interface/.git" ]]; then
  install_with_aegf_submodule "$V4/aelaron-framework-user-interface"
  run_validation "$V4/aelaron-framework-user-interface" ".github/scripts/user-interface-validation.sh"
fi

echo "=== Setup enterprise application ==="
if [[ -d "$V4/aelaron-enterprise-application/.git" ]]; then
  cd "$V4/aelaron-enterprise-application"
  git submodule update --init --recursive
  ln -sf governance/aegf aelaron-framework-governance
  bash governance/aegf/.github/scripts/install-v4-agent-instruction-layer.sh .
  rm -f aelaron-framework-governance
  patch_hooks_governance_aegf "$V4/aelaron-enterprise-application"
  run_validation "$V4/aelaron-enterprise-application" ".github/scripts/enterprise-application-validation.sh"
fi

echo "=== DONE ==="
echo "Open in Cursor: cursor $V4"
ls -la "$V4"
