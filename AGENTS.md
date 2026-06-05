# AGENTS.md — Aelaron v4 program workspace

This folder is the **L0 program workspace root**. Open it in Cursor for agent hooks, skills, and program policy. Repository: `campbelldavidj72/aelaron-agent-workspace`.

> Tool-specific adapters: `aelaron-platform-specifications/modules/governance/docs/agents/agent-instruction-layer.md`

## Three-layer model

| Layer | Location | Purpose |
|---|---|---|
| **L0** | This workspace | `AGENTS.md`, `.cursor/hooks`, `.cursor/skills/aegf-*`, `agent-log.jsonl` |
| **L1** | `aelaron-platform-specifications/` @ **`v2.0.0`** | Modular specs (domain, architecture, governance policy, trust, experience, interfaces) |
| **L2** | Application sibling repos | Executable code (`aelaron-enterprise-application`, `aelaron-gateway-superstream`, …) |
| **AEGF tooling** | `aelaron-framework-governance/` sibling | Scripts, templates, catalogs (VP-GOV-01) |

Legacy `aelaron-framework-*` discipline repos are **superseded** by L1 and are not part of the default local workspace.

## Canonical sources

| Topic | Location |
|---|---|
| Platform specifications | `aelaron-platform-specifications/` — tag `v2.0.0` |
| AEGF tooling (scripts, catalogs) | `aelaron-framework-governance/` |
| Enterprise application | `aelaron-enterprise-application/` — L1 pin in `governance/baseline.yaml` |
| Work intake | `aelaron-platform-specifications/modules/governance/docs/governance/20-work-intake-and-backlog-governance.md` |
| Agent specification model | `aelaron-framework-governance/docs/agents/agent-specification-model.md` |
| Agent roles & envelopes | `aelaron-framework-governance/templates/agent-role-catalog.yaml` |
| Program workspace setup | `aelaron-framework-governance/docs/agents/program-workspace-setup.md` |
| Program backlog | GitHub Project **Aelaron v4 Program** |
| Repo manifest | `repos.yaml` |

## Required behaviour (all agents)

1. **Issue first** — no implementation without a linked `status/ready` GitHub issue (except E0 analysis).
2. **Branch** — PRs target `development`; never merge to `main` (human only).
3. **Envelope** — stay within issue allowed paths and scope envelope (E0–E4).
4. **Verification** — run the declared VP profile for the **repository you are changing**; paste evidence in that repo's PR.
5. **Subagents** — inherit these rules; respect max envelope in role catalog.
6. **Activity log** — append to **`agent-log.jsonl`** (hooks + `aelaron-framework-governance/.github/scripts/agent-log.py`).
7. **Commit in the correct repo** — this meta repo tracks L0 config (`.cursor/`, `setup-v4-repos.sh`). AEGF script edits → `aelaron-framework-governance`. Spec edits → `aelaron-platform-specifications`. Code → L2 app repos.

## Spawn order (E2+ implementation)

1. Read linked issue contract (`status/ready`).
2. Spawn **domain agent** (`explore`) with `domain-agent-registry` brief → obtain **`## Context pack`**.
3. Spawn **advisory workers** (architect, CISO, risk) in **separate Task sessions** when tier ≥ 2.
4. Spawn **implementer** (`engineer`) only with context pack attached — hook blocks otherwise.
5. Open PR in the **target L2 repo** with VP evidence and governance run report.

## Path → repository rules

| Path prefix | GitHub repo | VP profile |
|---|---|---|
| `aelaron-framework-governance/` | aelaron-framework-governance | VP-GOV-01 |
| `aelaron-platform-specifications/` | aelaron-platform-specifications | VP-SPEC-01 |
| `aelaron-enterprise-application/` | aelaron-enterprise-application | VP-ENT-01 |
| `aelaron-gateway-superstream/` | aelaron-gateway-superstream | per repo CI |
| `aelaron-infrastructure/` | aelaron-infrastructure | per repo CI |

Child repos opened standalone carry stub `AGENTS.md` pointing here — **do not** install hooks into child repos.

## Setup

```bash
bash setup-v4-repos.sh
```

Validates L0 instruction layer via `aelaron-framework-governance/bin/install-program-workspace.sh`.

## Migration program

| Phase | Status |
|---|---|
| A — L1 pilot (`modules/domain/`) | Done — tag `v1.0.0-migration` |
| B — full L1 modules | Done — tag `v2.0.0` |
| C — L0 `aegf-tooling/` | Superseded — tooling consolidated into `aelaron-framework-governance` |
| D — L2 app pin + legacy archive | Done — [AEGF #110](https://github.com/campbelldavidj72/aelaron-framework-governance/issues/110) |

## End-of-run report (PRs in child repos)

```bash
bash aelaron-framework-governance/.github/scripts/governance-run-report.sh \
  --run-type standard \
  --issue NNN \
  --profile <VP-ID> \
  --fire INT-001,INT-002,INT-003,INT-004,INT-005,INT-006,EXE-001,EXE-002,EXE-003,EXE-004,EXE-005,BRN-001 \
  --ci-pass <check-name> \
  --append-log governance/metrics/runs.jsonl
```

(Run from program workspace root, or adjust path to `aelaron-framework-governance/`.)
