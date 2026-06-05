---
name: aegf-context-pack
description: >-
  Scaffold and validate AEGF context packs for domain agents and worker spawns.
  Use when curating repo context, preparing engineer Task prompts, or satisfying CTX-003.
---

# AEGF context pack

## When to use

- Parent spawning a **domain agent** (`explore`) for a target repository
- Validating paths before spawning **engineer** (required for `## Context pack` in prompt)
- Closing task with **Context used** evidence (CTX-002)

## Steps

1. Read issue fields: `target_repository`, `domain_agent_role`, `allowed_paths`, `required_reading`.
2. Load registry entry from `aelaron-framework-governance/templates/domain-agent-registry.yaml`.
3. Build pack using `templates/context-pack-template.yaml`.
4. Output section headed **`## Context pack`** with L0–L2 tables — paths must ⊆ issue allowed paths.
5. Before engineer spawn, confirm pack is attached to the Task prompt.

## Scaffold command

```bash
bash aelaron-framework-governance/.github/scripts/scaffold-issue-context-pack.sh --issue NNN
```

## Validation

- Every L2 path must appear in issue allowed paths
- Include verification profile and framework pins from target repo baseline
- Log validation: `python3 aelaron-framework-governance/.github/scripts/agent-log.py validate-context ...`

See `aelaron-framework-governance/docs/agents/domain-agent-and-context-pack-model.md`.
