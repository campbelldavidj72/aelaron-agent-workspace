# Aelaron agent workspace

GitHub: [campbelldavidj72/aelaron-agent-workspace](https://github.com/campbelldavidj72/aelaron-agent-workspace)

**L0 program workspace** — agent hooks, skills, and AEGF tooling. Child repositories are **sibling git clones** in this folder (gitignored by this meta repo).

## Three-layer model

| Layer | Clone in this workspace | Purpose |
|---|---|---|
| **L0** | *(this repo root)* | `AGENTS.md`, `.cursor/hooks`, `aegf-tooling/`, `agent-log.jsonl` |
| **L1** | `aelaron-platform-specifications/` @ **v2.0.0** | Modular platform specs (no executable code) |
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
3. Install the L0 AEGF instruction layer (`aegf-tooling/`)
4. Run validation scripts where defined

## Active sibling repositories

| Path | Role |
|---|---|
| `aelaron-platform-specifications/` | L1 platform specifications |
| `aelaron-framework-governance/` | AEGF source for `aegf-tooling/` sync |
| `aelaron-enterprise-application/` | Enterprise application (pins L1 tag in `governance/baseline.yaml`) |
| `aelaron-gateway-superstream/` | Gateway adapter |
| `aelaron-infrastructure/` | Infrastructure docs and web assets |

Full manifest: `repos.yaml`

Legacy `aelaron-framework-*` discipline repos and reserved L2 apps are **not** cloned by default — see comments in `repos.yaml`.

## Why five sibling clones (not six)?

| What you see | Git repo? | Role |
|---|---|---|
| This workspace root + `aegf-tooling/` | **One repo** (`aelaron-agent-workspace`) | L0 — hooks and runnable AEGF scripts |
| `aelaron-platform-specifications/` | Yes | L1 — platform specs |
| `aelaron-framework-governance/` | Yes | **Upstream** home for AEGF script development |
| `aelaron-enterprise-application/` | Yes | L2 application |
| `aelaron-gateway-superstream/` | Yes | L2 gateway |
| `aelaron-infrastructure/` | Yes | L2 infrastructure |

**`aegf-tooling/` was not merged into `aelaron-framework-governance`.** Phase C did the opposite for local agents: it **copied** scripts and templates from governance into L0 `aegf-tooling/` so hooks resolve one path at the workspace root. Governance policy text lives in L1 (`aelaron-platform-specifications/modules/governance/`); executable tooling lives in L0 (`aegf-tooling/`).

When AEGF scripts change in `aelaron-framework-governance`, refresh L0 with:

```bash
bash aegf-tooling/bin/sync-from-governance-sibling.sh
```

If you are not editing AEGF itself, you can omit the governance sibling clone — `setup-v4-repos.sh` skips sync when that folder is missing. The governance repo stays in `repos.yaml` for maintainers and VP-GOV-01 validation.

## Agent activity log

```bash
./tail-agent-log.sh              # follow new entries
./tail-agent-log.sh --from-start # replay then follow
```

Log file: `agent-log.jsonl` (gitignored). See `aegf-tooling/docs/agents/agent-activity-log.md`.

## Agent configuration

| File | Purpose |
|---|---|
| `AGENTS.md` | Program-wide agent policy (Cursor workspace root) |
| `.cursor/` | Cursor hooks and AEGF project skills |
| `CLAUDE.md` | Claude Code adapter |
| `.github/copilot-instructions.md` | Copilot adapter |

Each child repo carries a stub `AGENTS.md` for standalone use. When this folder is the Cursor root, **`AGENTS.md` here is authoritative**.

## Commits

- **This meta repo** — L0 config only: `AGENTS.md`, `README.md`, `repos.yaml`, `setup-v4-repos.sh`, `aegf-tooling/`, `.cursor/`, `.gitignore`
- **Child repos** — all specification and application changes; commit inside that repo's git root

Child repos are listed in `.gitignore` and are not tracked by this meta repository.
