#!/usr/bin/env bash
# Apply consistent development-branch rulesets across Aelaron v4 repositories.
# Allows agent merge to development (0 required reviews) while keeping main human-gated.
#
# Usage:
#   bash .github/scripts/setup-v4-development-rulesets.sh
#   bash .github/scripts/setup-v4-development-rulesets.sh --create-branches
set -euo pipefail

OWNER="${AELARON_GH_OWNER:-campbelldavidj72}"
CREATE_BRANCHES=false

for arg in "$@"; do
  case "$arg" in
    --create-branches) CREATE_BRANCHES=true ;;
    -h|--help)
      echo "Usage: $0 [--create-branches]"
      exit 0
      ;;
  esac
done

# repo|status_check (empty check = none required on development yet)
V4_REPOS=(
  "aelaron-framework-governance|governance-check"
  "aelaron-framework-architecture|architecture-validation"
  "aelaron-framework-registry|domain-validation"
  "aelaron-framework-compliance|compliance-validation"
  "aelaron-framework-experience|experience-validation"
  "aelaron-enterprise-application|enterprise-application-validation"
  "aelaron-registry|"
  "aelaron-agentic-platform|"
  "aelaron-infrastructure|"
  "aelaron-developer-platform|"
  "aelaron-gateway-superstream|"
  "aelaron-analytics|"
  "aelaron-member-online|"
  "aelaron-csr-console|"
)

repo_main_sha() {
  local repo="$1"
  gh api "repos/$OWNER/$repo/git/ref/heads/main" --jq .object.sha 2>/dev/null || true
}

branch_exists() {
  local repo="$1" branch="$2"
  gh api "repos/$OWNER/$repo/branches/$branch" --jq .name >/dev/null 2>&1
}

create_development_branch() {
  local repo="$1"
  if branch_exists "$repo" development; then
    echo "  development branch exists" >&2
    return
  fi
  local empty
  empty="$(gh repo view "$OWNER/$repo" --json isEmpty --jq .isEmpty 2>/dev/null || echo true)"
  if [[ "$empty" == "true" ]]; then
    echo "  skip branch create (empty repo): $repo" >&2
    return
  fi
  local sha
  sha="$(repo_main_sha "$repo")"
  if [[ -z "$sha" ]]; then
    echo "  skip branch create (no main): $repo" >&2
    return
  fi
  if ! gh api "repos/$OWNER/$repo/git/refs" -f ref=refs/heads/development -f sha="$sha" >/dev/null 2>&1; then
    echo "  failed to create development branch: $repo" >&2
    return
  fi
  echo "  created development from main" >&2
}

find_dev_ruleset_id() {
  local repo="$1"
  gh api "repos/$OWNER/$repo/rulesets" --jq \
    '.[] | select(.name | test("Development")) | .id' | head -1
}

upsert_development_ruleset() {
  local repo="$1"
  local check="$2"
  local ruleset_id
  ruleset_id="$(find_dev_ruleset_id "$repo" || true)"

  local payload
  if [[ -n "$check" ]]; then
    payload=$(cat <<JSON
{
  "name": "Aelaron v4 Development Ruleset",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/development"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["merge", "squash", "rebase"]
      }
    },
    {
      "type": "required_status_checks",
      "parameters": {
        "strict_required_status_checks_policy": false,
        "do_not_enforce_on_create": false,
        "required_status_checks": [{"context": "$check"}]
      }
    }
  ]
}
JSON
)
  else
    payload=$(cat <<JSON
{
  "name": "Aelaron v4 Development Ruleset",
  "target": "branch",
  "enforcement": "active",
  "conditions": {
    "ref_name": {
      "include": ["refs/heads/development"],
      "exclude": []
    }
  },
  "rules": [
    {
      "type": "pull_request",
      "parameters": {
        "required_approving_review_count": 0,
        "dismiss_stale_reviews_on_push": false,
        "require_code_owner_review": false,
        "require_last_push_approval": false,
        "required_review_thread_resolution": false,
        "allowed_merge_methods": ["merge", "squash", "rebase"]
      }
    }
  ]
}
JSON
)
  fi

  if [[ -n "$ruleset_id" ]]; then
    gh api -X PUT "repos/$OWNER/$repo/rulesets/$ruleset_id" --input - <<<"$payload" >/dev/null
    echo "  updated development ruleset #$ruleset_id" >&2
  else
    gh api -X POST "repos/$OWNER/$repo/rulesets" --input - <<<"$payload" >/dev/null
    echo "  created development ruleset" >&2
  fi
}

ensure_main_not_global() {
  local repo="$1"
  gh api "repos/$OWNER/$repo/rulesets" --jq '.[] | select(.conditions.ref_name.include[]? == "~ALL") | .id' | while read -r id; do
    [[ -z "$id" ]] && continue
    echo "  WARNING: $repo ruleset #$id still targets ~ALL — narrow to refs/heads/main in UI" >&2
  done
}

echo "Configuring v4 development rulesets for owner $OWNER..." >&2

for entry in "${V4_REPOS[@]}"; do
  repo="${entry%%|*}"
  check="${entry#*|}"
  echo "=== $repo ===" >&2
  if ! gh repo view "$OWNER/$repo" >/dev/null 2>&1; then
    echo "  skip (repo not found)" >&2
    continue
  fi
  if [[ "$CREATE_BRANCHES" == true ]]; then
    create_development_branch "$repo"
  elif ! branch_exists "$repo" development; then
    echo "  no development branch (use --create-branches)" >&2
  fi
  if branch_exists "$repo" development; then
    upsert_development_ruleset "$repo" "$check"
  fi
  ensure_main_not_global "$repo"
done

echo ""
echo "Done. Agent merge to development is permitted when AEGF agent-approval-model program development phase rules are satisfied."
echo "Merges to main remain human-only."
