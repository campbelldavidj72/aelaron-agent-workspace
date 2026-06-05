# GitHub Copilot instructions — Aelaron v4 workspace

Read **`AGENTS.md`** at the repository root for full AEGF governance. This file is the Copilot-specific adapter.

## Required behaviour

1. **Issue first** — no implementation without a linked `status/ready` GitHub issue (except E0 analysis).
2. **Branch** — PRs target `development`; never merge to `main` (human only).
3. **Envelope** — stay within issue allowed paths and scope envelope (E0–E4).
4. **Verification** — run declared VP profile; paste evidence in PR.
5. **End-of-run report** — run `aelaron-framework-governance/.github/scripts/governance-run-report.sh` and include output in PR.

## Canonical paths

- Governance: `aelaron-framework-governance/`
- Instruction layer: `aelaron-framework-governance/docs/agents/agent-instruction-layer.md`
- Agent roles: `aelaron-framework-governance/templates/agent-role-catalog.yaml`
