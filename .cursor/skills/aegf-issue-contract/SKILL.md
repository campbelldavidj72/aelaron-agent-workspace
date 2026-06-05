---
name: aegf-issue-contract
description: >-
  Validate GitHub issue contract fields before implementation. Use at task start,
  before spawning workers, or when checking status/ready eligibility.
---

# AEGF issue contract

## Required fields (agent-eligible issues)

- Objective and testable acceptance criteria
- Labels: `status/ready`, risk tier, change class
- Scope envelope (E0–E4) and **allowed paths**
- Verification profile ID (VP-*)
- `target_repository`, `domain_agent_role`, `worker_agent_role` (when known)
- `required_reading` for L2 context paths

## Checklist

1. Confirm issue is `status/ready` — do not implement on draft issues.
2. Confirm your work stays within **allowed paths** and envelope.
3. Confirm VP profile matches the repository you will change (see L0 AGENTS path table).
4. For E2+ implementation: ensure context pack workflow is planned (CTX-003).

## Source

L1: `aelaron-platform-specifications/modules/governance/docs/governance/20-work-intake-and-backlog-governance.md`

Tooling: `aelaron-framework-governance/docs/agents/context-pack-issue-convention.md`
