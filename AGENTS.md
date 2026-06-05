# AGENTS.md — Aelaron v4 program workspace

This folder is the **program workspace root** for local development across all Aelaron v4 repositories. Repository: `campbelldavidj72/aelaron-agent-workspace`. Open this folder in Cursor as the workspace root.

> Tool-specific adapters: `aelaron-framework-governance/docs/agents/agent-instruction-layer.md`

## Canonical sources

| Topic | Location |
|---|---|
| Governance baseline (AEGF) | `aelaron-framework-governance/` (pin: **v1.0.9** on `main`) |
| Architecture baseline (AAPF) | `aelaron-framework-architecture/` (pin: **v1.2.4**) |
| Domain registry | `aelaron-framework-registry/` (pin: **v1.4.2**) |
| Compliance (ACRF) | `aelaron-framework-compliance/` (pin: **v1.0.1**) |
| Experience (AEXF) | `aelaron-framework-experience/` (pin: **v1.0.1**) |
| Security framework | `aelaron-framework-security/` (pin: **v1.2.0**) |
| User interface framework | `aelaron-framework-user-interface/` (pin: **v1.2.0**) |
| Enterprise application | `aelaron-enterprise-application/` (consumer + submodule pins) |
| Work intake | `aelaron-framework-governance/docs/governance/20-work-intake-and-backlog-governance.md` |
| Agent merge rules | `aelaron-framework-governance/docs/agents/agent-approval-model.md` |
| Agent roles & envelopes | `aelaron-framework-governance/templates/agent-role-catalog.yaml` |
| Program backlog | GitHub Project **Aelaron v4 Program** |
| Repo manifest | `repos.yaml` |

## Required behaviour (all agents)

1. **Issue first** — no implementation without a linked `status/ready` GitHub issue (except E0 analysis).
2. **Branch** — PRs target `development`; never merge to `main` (human only).
3. **Envelope** — stay within issue allowed paths and scope envelope (E0–E4).
4. **Verification** — run the declared VP profile for the **repository you are changing**; paste evidence in that repo's PR.
5. **Program development phase** — agents may merge tier 0–3 to `development` when rules pass.
6. **Subagents** — inherit these rules; respect max envelope in role catalog.
7. **Activity log** — append timestamped events to **`agent-log.jsonl`** at this workspace root (hooks + `aelaron-framework-governance/.github/scripts/agent-log.py`). Log context reads, freshness after pin bumps, and domain/worker thinking. See `aelaron-framework-governance/docs/agents/agent-activity-log.md`.
8. **Commit in the correct repo** — this meta repo tracks workspace config only (`AGENTS.md`, `setup-v4-repos.sh`, `.cursor/`). Framework and application commits happen in the child repository under the path you edited.

## Path → repository rules

When editing files under a child folder, follow that repository's issue contract and verification profile:

| Path prefix | GitHub repo | VP profile |
|---|---|---|
| `aelaron-framework-governance/` | aelaron-framework-governance | VP-GOV-01 |
| `aelaron-platform-specifications/` | aelaron-platform-specifications | VP-SPEC-01 |
| `aelaron-framework-architecture/` | aelaron-framework-architecture | VP-ARCH-01 |
| `aelaron-framework-registry/` | aelaron-framework-registry | VP-DOM-01 |
| `aelaron-framework-compliance/` | aelaron-framework-compliance | VP-CMP-01 |
| `aelaron-framework-experience/` | aelaron-framework-experience | VP-EXP-01 |
| `aelaron-framework-security/` | aelaron-framework-security | VP-SEC-01 |
| `aelaron-framework-user-interface/` | aelaron-framework-user-interface | VP-UIF-01 |
| `aelaron-enterprise-application/` | aelaron-enterprise-application | VP-ENT-01 |
| `aelaron-registry/` | aelaron-registry | per repo CI |
| `aelaron-agentic-platform/` | aelaron-agentic-platform | per repo CI |
| `aelaron-infrastructure/` | aelaron-infrastructure | per repo CI |
| `aelaron-developer-platform/` | aelaron-developer-platform | per repo CI |
| `aelaron-gateway-superstream/` | aelaron-gateway-superstream | per repo CI |
| `aelaron-analytics/` | aelaron-analytics | per repo CI |
| `aelaron-member-online/` | aelaron-member-online | per repo CI |
| `aelaron-csr-console/` | aelaron-csr-console | per repo CI |

Do not edit framework content inside `aelaron-enterprise-application/*/submodule/` trees in place — change the sibling clone, then bump pins in the enterprise application.

## Submodule mount names (enterprise app only)

Inside `aelaron-enterprise-application/`, short paths are intentional: `governance/aegf`, `architecture/aapf`, etc. Those are not separate repos.

## Instruction layer

Install or refresh for this workspace root and all child repos:

```bash
bash setup-v4-repos.sh
```

Verify this root only:

```bash
bash aelaron-framework-governance/.github/scripts/governance-instruction-layer-check.sh .
```

## End-of-run report (PRs in child repos)

Run from the repository you changed, using AEGF from the sibling governance clone:

```bash
bash ../aelaron-framework-governance/.github/scripts/governance-run-report.sh \
  --run-type standard \
  --issue NNN \
  --profile <VP-ID> \
  --fire INT-001,INT-002,INT-003,INT-004,INT-005,INT-006,EXE-001,EXE-002,EXE-003,EXE-004,EXE-005,BRN-001 \
  --ci-pass <check-name> \
  --append-log governance/metrics/runs.jsonl
```

(Adjust `../aelaron-framework-governance` if your cwd is not a direct sibling.)
