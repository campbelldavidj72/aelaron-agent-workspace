#!/usr/bin/env bash
# Setup or sync the Aelaron v4 Program GitHub Project.
# Requires: gh CLI with project + read:project scopes
#   gh auth refresh -h github.com -s project,read:project
#
# Usage:
#   bash .github/scripts/setup-v4-program-project.sh           # create project + fields + link repos
#   bash .github/scripts/setup-v4-program-project.sh --sync-issues   # also add open issues from v4 repos
set -euo pipefail

OWNER="${AELARON_GH_OWNER:-campbelldavidj72}"
PROJECT_TITLE="${AELARON_V4_PROJECT_TITLE:-Aelaron v4 Program}"
SYNC_ISSUES=false

for arg in "$@"; do
  case "$arg" in
    --sync-issues) SYNC_ISSUES=true ;;
    -h|--help)
      echo "Usage: $0 [--sync-issues]"
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      exit 1
      ;;
  esac
done

if ! gh auth status 2>&1 | grep -q "project"; then
  echo "ERROR: gh token missing 'project' scope." >&2
  echo "Run: gh auth refresh -h github.com -s project,read:project" >&2
  exit 1
fi

V4_REPOS=(
  aelaron-framework-governance
  aelaron-framework-architecture
  aelaron-framework-registry
  aelaron-framework-compliance
  aelaron-framework-experience
  aelaron-enterprise-application
  aelaron-registry
  aelaron-agentic-platform
  aelaron-infrastructure
  aelaron-developer-platform
  aelaron-gateway-superstream
  aelaron-analytics
  aelaron-member-online
  aelaron-csr-console
)

find_project_number() {
  gh project list --owner "$OWNER" --format json --jq ".projects[] | select(.title==\"$PROJECT_TITLE\") | .number" | head -1
}

create_or_get_project() {
  local existing
  existing="$(find_project_number || true)"
  if [[ -n "$existing" ]]; then
    echo "Using existing project #$existing ($PROJECT_TITLE)" >&2
    echo "$existing"
    return
  fi
  echo "Creating project: $PROJECT_TITLE" >&2
  gh project create --owner "$OWNER" --title "$PROJECT_TITLE" --format json --jq '.number'
}

field_exists() {
  local project_number="$1"
  local field_name="$2"
  gh project field-list "$project_number" --owner "$OWNER" --format json \
    --jq ".fields[] | select(.name==\"$field_name\") | .name" | grep -qx "$field_name"
}

create_field_if_missing() {
  local project_number="$1"
  local name="$2"
  local data_type="$3"
  local options="${4:-}"

  if field_exists "$project_number" "$name"; then
    echo "  field exists: $name" >&2
    return
  fi
  echo "  creating field: $name ($data_type)" >&2
  if [[ "$data_type" == "SINGLE_SELECT" ]]; then
    gh project field-create "$project_number" --owner "$OWNER" \
      --name "$name" --data-type SINGLE_SELECT --single-select-options "$options"
  else
    gh project field-create "$project_number" --owner "$OWNER" \
      --name "$name" --data-type "$data_type"
  fi
}

link_repos() {
  local project_number="$1"
  local repo
  for repo in "${V4_REPOS[@]}"; do
    if gh project link "$project_number" --owner "$OWNER" --repo "$OWNER/$repo" 2>/dev/null; then
      echo "  linked: $repo" >&2
    else
      echo "  link skipped (exists or repo missing): $repo" >&2
    fi
  done
}

create_fields() {
  local project_number="$1"
  echo "Ensuring custom fields..." >&2
  create_field_if_missing "$project_number" "Status" SINGLE_SELECT \
    "Todo,In Progress,In review,Done"
  create_field_if_missing "$project_number" "Stream" SINGLE_SELECT \
    "Framework,Domain,Platform,Experience,Infrastructure,Integration,Analytics"
  create_field_if_missing "$project_number" "Risk tier" SINGLE_SELECT \
    "0,1,2,3,4"
  create_field_if_missing "$project_number" "Change class" SINGLE_SELECT \
    "minor,standard,material,emergency"
  create_field_if_missing "$project_number" "Envelope" SINGLE_SELECT \
    "E0,E1,E2,E3,E4"
  create_field_if_missing "$project_number" "Verification profile" TEXT ""
  create_field_if_missing "$project_number" "Estimate (days)" NUMBER ""
  create_field_if_missing "$project_number" "Start date" DATE ""
  create_field_if_missing "$project_number" "Target date" DATE ""
  create_field_if_missing "$project_number" "Release train" SINGLE_SELECT \
    "framework-maint,domain-v1.1,platform-alpha,experience-alpha,infra-foundation"
  create_field_if_missing "$project_number" "Blocked reason" TEXT ""
}

sync_open_issues() {
  local project_number="$1"
  local repo issue_url
  echo "Syncing open issues into project #$project_number..." >&2
  for repo in "${V4_REPOS[@]}"; do
    while IFS= read -r issue_url; do
      [[ -z "$issue_url" ]] && continue
      if gh project item-add "$project_number" --owner "$OWNER" --url "$issue_url" 2>/dev/null; then
        echo "  added: $issue_url" >&2
      else
        echo "  skip (exists or failed): $issue_url" >&2
      fi
    done < <(gh issue list -R "$OWNER/$repo" --state open --json url --jq '.[].url' 2>/dev/null || true)
  done
}

PROJECT_NUMBER="$(create_or_get_project)"
echo "Project number: $PROJECT_NUMBER" >&2
link_repos "$PROJECT_NUMBER"
create_fields "$PROJECT_NUMBER"

if [[ "$SYNC_ISSUES" == true ]]; then
  sync_open_issues "$PROJECT_NUMBER"
fi

PROJECT_URL="$(gh project view "$PROJECT_NUMBER" --owner "$OWNER" --format json --jq '.url' 2>/dev/null || echo "")"
echo ""
echo "Setup complete."
echo "Project: $PROJECT_TITLE (#$PROJECT_NUMBER)"
[[ -n "$PROJECT_URL" ]] && echo "URL: $PROJECT_URL"
echo ""
echo "Manual steps (Projects UI):"
echo "  1. Create views listed in docs/governance/22-github-projects-backlog-model.md"
echo "  2. Enable workflows: auto-add issues, sync Status from status/* labels"
echo "  3. Open Roadmap view; set Target date on ready items"
echo ""
echo "Re-run with --sync-issues after opening new backlog items."
