# Aelaron agent workspace

GitHub: [campbelldavidj72/aelaron-agent-workspace](https://github.com/campbelldavidj72/aelaron-agent-workspace)

**L0 program workspace** — agent hooks, skills, and program policy. AEGF executable tooling lives in sibling **`aelaron-framework-governance/`**.

## Three-layer model

| Layer | Clone in this workspace | Purpose |
|---|---|---|
| **L0** | *(this repo root)* | `AGENTS.md`, `.cursor/hooks`, `agent-log.jsonl` |
| **L1** | `aelaron-platform-specifications/` @ **v2.0.0** | Modular platform specs (no executable code) |
| **AEGF** | `aelaron-framework-governance/` | Scripts, templates, catalogs (VP-GOV-01) |
| **L2** | Application siblings below | Runnable services and applications |

## Clone

```bash
git clone git@github.com:campbelldavidj72/aelaron-agent-workspace.git aelaron-agent-workspace
cd aelaron-agent-workspace
bash setup-v4-repos.sh
cursor .
```

## First-time setup (existing checkout)

```bash
cd /path/to/aelaron-agent-workspace
bash setup-v4-repos.sh
cursor .
```

`setup-v4-repos.sh` reads `repos.yaml` and will:

1. Clone any missing **active** sibling repositories
2. Sync them to `development`
3. Install the L0 AEGF instruction layer from `aelaron-framework-governance/`
4. Run validation scripts where defined

## Active sibling repositories

| Path | Role |
|---|---|
| `aelaron-platform-specifications/` | L1 platform specifications |
| `aelaron-framework-governance/` | AEGF tooling (scripts, templates, catalogs) |
| `aelaron-enterprise-application/` | Enterprise application (pins L1 tag in `governance/baseline.yaml`) |
| `aelaron-gateway-superstream/` | Gateway adapter |
| `aelaron-infrastructure/` | Infrastructure docs and web assets |

Full manifest: `repos.yaml`

Legacy `aelaron-framework-*` discipline repos and reserved L2 apps are **not** cloned by default — see comments in `repos.yaml`.

## Why these sibling repos?

They are **program components**, not folders inside `aelaron-enterprise-application/`. Each repo answers a different architecture question and has its own CI, security boundary, and agent envelope.

| Repo | Architecture type | Question it answers |
|---|---|---|
| `aelaron-enterprise-application/` | Application (modular monolith) | What does the platform *do* with domain events? |
| `aelaron-gateway-superstream/` | Integration stream | How do external interfaces (SuperStream, ATO, bank feeds) get normalised before domain handling? |
| `aelaron-infrastructure/` | Infrastructure | Where does it run at scale (Azure, DR, cells) and what is the local dev data plane? |

### Enterprise vs gateway

The enterprise app owns bounded contexts (`platform-contribution`, event store, projections, MCP) and a **gateway ingestion port** (`NormalisedGatewayEvent`). It does **not** contain SuperStream XML parsing, conformance harnesses, or production external adapters.

Gateway code lives separately per [ADR-0003 — Gateway Repository Boundary](https://github.com/campbelldavidj72/aelaron-enterprise-application/blob/development/docs/adrs/adr-0003-gateway-repository-boundary.md):

- **Security** — external boundary code is isolatable for change control and penetration testing
- **Conformance** — GW-PROFILE scenario endpoints must not ship inside the domain monolith
- **Contract** — repos align via shared event schemas (L1 specs + enterprise contract tests), not Maven dependencies

```text
SuperStream / ATO / bank feeds
        │
        ▼
aelaron-gateway-superstream     ← AEL-IF-* adapters + conformance CI
        │  NormalisedGatewayEvent
        ▼
aelaron-enterprise-application  ← domain BCs consume via ingestion port
```

### Enterprise vs infrastructure

Infrastructure is **not application code**. It holds the signed infrastructure charter, INFRA programme docs, Docker Compose for local S0 stacks, and (later) cloud IaC. The enterprise app **references** infra for local compose (`AELARON_INFRA_DIR=../aelaron-infrastructure`) but does not own Azure provisioning or DR topology.

See [infrastructure architecture charter](https://github.com/campbelldavidj72/aelaron-infrastructure/blob/main/docs/architecture/infrastructure-architecture-charter.md) and enterprise [architecture types and baselines](https://github.com/campbelldavidj72/aelaron-enterprise-application/blob/development/docs/architecture/technical/architecture-types-and-baselines.md).

### Optional clones

You only need gateway or infra locally when working on P3 integration or infrastructure design. For core domain work, enterprise + L1 specs + governance is enough.

## Agent activity log

```bash
./tail-agent-log.sh              # follow new entries
./tail-agent-log.sh --from-start # replay then follow
```

Log file: `agent-log.jsonl` (gitignored). See `aelaron-framework-governance/docs/agents/agent-activity-log.md`.

## Agent configuration

| File | Purpose |
|---|---|
| `AGENTS.md` | Program-wide agent policy (Cursor workspace root) |
| `.cursor/` | Cursor hooks and AEGF project skills |
| `CLAUDE.md` | Claude Code adapter |
| `.github/copilot-instructions.md` | Copilot adapter |

Each child repo carries a stub `AGENTS.md` for standalone use. When this folder is the Cursor root, **`AGENTS.md` here is authoritative**.

## Commits

- **This meta repo** — L0 config only: `AGENTS.md`, `README.md`, `repos.yaml`, `setup-v4-repos.sh`, `.cursor/`, `.gitignore`
- **`aelaron-framework-governance/`** — AEGF scripts, templates, and catalogs
- **Other child repos** — specifications and application code; commit inside that repo's git root

Child repos are listed in `.gitignore` and are not tracked by this meta repository.
