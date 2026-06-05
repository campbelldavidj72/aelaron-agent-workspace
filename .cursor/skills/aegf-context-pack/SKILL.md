---
name: aegf-context-pack
description: >-
  Produce or validate AEGF context packs for domain agents. Loads
  domain-agent-registry.yaml, context-pack-template.yaml, and issue ACL fields.
  Use when spawning domain agents, curating L0-L2 context, CTX-001/CTX-003,
  governed work, validate-context, or when the user mentions context pack.
---

# AEGF context pack

## When to use

- **Governed work** — any task impacting code, specifications, or baselines
- Parent spawns a **domain agent** (`explore`, E0–E1) before E2+ worker work
- Issue declares `target_repository`, `domain_agent_role`, `context_pack_l0`, `required_reading`

## Steps

1. Read issue contract: `allowed_paths`, `required_reading`, `domain_agent_role`, `target_repository`.
2. Load registry entry from `aelaron-framework-governance/templates/domain-agent-registry.yaml`.
3. Read L0 → L1 → L2 (ACL only); log thinking as you curate.
4. Build context pack from `templates/context-pack-template.yaml`.
5. **Validate context** before handoff (mandatory):

```bash
python3 aelaron-framework-governance/.github/scripts/agent-log.py think \
  --agent-kind domain \
  --domain-agent-role <role> \
  --message "L2 limited to ACL; excluded install scripts"

python3 aelaron-framework-governance/.github/scripts/agent-log.py validate-context \
  --domain-agent-role <role> \
  --target-repository <repo> \
  --issue <N> \
  --read AGENTS.md:L0 \
  --read docs/standards/agent-verification-profiles.md:L1 \
  --framework-pin aegf:v1.0.9 \
  --clear-active
```

`validate-context` merges hook-tracked reads with explicit `--read` lines and records **framework_pins**.

## Rules

- Domain agents **curate only** — no commits (max E1).
- Never add L2 paths outside issue `allowed_paths`.
- Log **thinking** after each major curation decision (`agent-log.py think`).

## Related

- `docs/agents/domain-agent-and-context-pack-model.md`
- `docs/agents/agent-activity-log.md`
- `.cursor/skills/aegf-agent-log/SKILL.md`
