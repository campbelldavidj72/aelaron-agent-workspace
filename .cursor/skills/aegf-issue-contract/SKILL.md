---
name: aegf-issue-contract
description: >-
  Parse and enforce AEGF agent-task issue contracts — envelope, allowed_paths,
  verification profile, domain_agent_role, worker_agent_role. Use when starting
  agent work, validating scope, or when the user references an issue number or
  agent-task template fields.
---

# AEGF issue contract

## When to use

- Before any E1+ work on a linked GitHub issue
- When validating whether a path or subagent action is in scope
- When filling or reading `agent-task.yml` fields on an issue

## Required fields (agent-eligible issues)

| Field | Purpose |
|---|---|
| `target_repository` | Which repo is authoritative for the change |
| `domain_agent_role` | Key in `domain-agent-registry.yaml` |
| `allowed_paths` | Context ACL — hard boundary for reads and edits |
| `verification_profile` | VP ID (e.g. VP-GOV-01, VP-DOM-01) |
| `envelope` | E0–E4 max scope |
| `context_pack_l0` | L0 paths (defaults from registry if omitted) |
| `required_reading` | L1/L2 paths for this task |
| `worker_agent_role` | Primary worker from `agent-role-catalog.yaml` |

Fetch via `gh issue view <N> --json body,labels` or read the issue in GitHub.

## Enforcement

1. **Issue first** — `status/ready` label before coding (E0 analysis excepted).
2. **Branch** — PRs target `development`; never merge to `main`.
3. **Refuse** reads, citations, or edits outside `allowed_paths` (+ L0 index files per domain model).
4. **Escalate** if task exceeds declared envelope.

## Related

- `.github/ISSUE_TEMPLATE/agent-task.yml` (in target repo or AEGF template)
- `docs/governance/20-work-intake-and-backlog-governance.md`
- `templates/agent-skills-catalog.yaml`
