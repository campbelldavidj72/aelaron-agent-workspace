# AEGF tooling (L0)

Executable agent governance tooling for the **aelaron-agent-workspace** program root. Policy specifications live in `aelaron-platform-specifications/modules/governance/`; this directory holds scripts, templates, and catalogs consumed by Cursor hooks.

## Sync from source

When `aelaron-framework-governance` sibling is updated:

```bash
bash aegf-tooling/bin/sync-from-governance-sibling.sh
```

## Validate workspace

```bash
bash aegf-tooling/bin/install-program-workspace.sh .
```

Or via setup:

```bash
bash setup-v4-repos.sh
```

## Version

See [`VERSION`](VERSION) (pinned AEGF release).

## Key paths

| Path | Purpose |
|---|---|
| `.github/scripts/agent-log.py` | Activity log append |
| `.github/scripts/governance-run-report.sh` | PR governance coverage |
| `.github/scripts/governance-instruction-context.py` | Hook context + validation |
| `templates/agent-role-catalog.yaml` | Agent envelopes |
| `templates/governance-firing-catalog.yaml` | Firing checkpoints |

Migration: [AEGF #109](https://github.com/campbelldavidj72/aelaron-framework-governance/issues/109)
