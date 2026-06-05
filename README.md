# Aelaron v4 program workspace

Local **meta repository** for agent configuration and multi-repo setup. Child frameworks and applications live as **sibling git clones** in this folder.

**Open this folder in Cursor** as your workspace root:

```bash
cursor /Users/dc/src/Aelaron/v4
```

## First-time setup

```bash
cd /Users/dc/src/Aelaron/v4
bash setup-v4-repos.sh
```

This will:

1. Clone any missing child repositories
2. Sync all repos to `development`
3. Install the AEGF instruction layer on this workspace root and each child repo
4. Run validation scripts where defined

## Repositories

See `repos.yaml` for the full manifest. Sibling clones under this folder:

| Path | Role |
|---|---|
| `aelaron-framework-governance/` | AEGF |
| `aelaron-framework-architecture/` | AAPF |
| `aelaron-framework-registry/` | Domain registry |
| `aelaron-framework-compliance/` | ACRF |
| `aelaron-framework-experience/` | AEXF |
| `aelaron-framework-security/` | Security framework |
| `aelaron-framework-user-interface/` | UI framework |
| `aelaron-enterprise-application/` | Enterprise application consumer |
| `aelaron-gateway-superstream/` | Service repo |
| `aelaron-infrastructure/` | Platform repo |

## Agent configuration

| File | Purpose |
|---|---|
| `AGENTS.md` | Program-wide agent policy (Cursor workspace root) |
| `.cursor/` | Cursor hooks → `aelaron-framework-governance/` |
| `CLAUDE.md` | Claude Code adapter |
| `.github/copilot-instructions.md` | Copilot adapter |

Each child repo may also have its own `AGENTS.md` for standalone use. When this folder is the Cursor root, **`v4/AGENTS.md` is authoritative**.

## Commits

- **This meta repo** — only `AGENTS.md`, `README.md`, `repos.yaml`, `setup-v4-repos.sh`, `.cursor/`, `.gitignore`
- **Child repos** — all framework and application changes; commit inside that repo's git root

Child repos are listed in `.gitignore` and are not tracked by this meta repository.

## Enterprise application submodule paths

Inside `aelaron-enterprise-application/` only:

```text
governance/aegf/          → AEGF (mount name)
architecture/aapf/        → AAPF
domain/aelaron-framework-registry/
compliance/…
experience/…
```

Author changes in the **sibling clone** at `v4/aelaron-framework-*`, then bump submodule pins in the enterprise application.
