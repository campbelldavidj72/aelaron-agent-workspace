#!/usr/bin/env bash
# Shared AEGF path resolution for Cursor hooks (L0 program workspace).
aegf_resolve_root() {
  local root="${1:-${CURSOR_PROJECT_DIR:-$(pwd)}}"
  if [[ -f "$root/aelaron-framework-governance/.github/scripts/governance-instruction-context.py" ]]; then
    echo "$root/aelaron-framework-governance"
  elif [[ -f "$root/../aelaron-framework-governance/.github/scripts/governance-instruction-context.py" ]]; then
    echo "$root/../aelaron-framework-governance"
  else
    echo "$root/aelaron-framework-governance"
  fi
}

aegf_bootstrap_env() {
  local root="${1:-${CURSOR_PROJECT_DIR:-$(pwd)}}"
  export AEGF_WORKSPACE_ROOT="$root"
  export AEGF_REPO_ROOT="$(aegf_resolve_root "$root")"
}
