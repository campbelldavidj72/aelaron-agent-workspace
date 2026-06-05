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
