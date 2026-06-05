---
name: aegf-context-pack
description: >-
  Produce or validate AEGF context packs for domain agents. Loads
  domain-agent-registry.yaml, context-pack-template.yaml, and issue ACL fields.
  Use when spawning domain agents, curating L0-L2 context, CTX-001/CTX-003,
  or when the user mentions context pack, domain agent, or required_reading.
---

# AEGF context pack

## When to use

- Parent spawns a **domain agent** (`explore`, E0–E1) before E2+ work
- Issue declares `target_repository`, `domain_agent_role`, `context_pack_l0`, `required_reading`
- Attest **CTX-001** (pack on issue) or **CTX-003** (domain consulted before implementation)

## Steps

1. Read issue contract: `allowed_paths`, `required_reading`, `domain_agent_role`, `target_repository`.
2. Load registry entry from `aelaron-framework-governance/templates/domain-agent-registry.yaml` (key = `domain_agent_role`).
3. Build tiers:
   - **L0** — registry defaults or issue `context_pack_l0` (`AGENTS.md`, `MANIFEST.md`, `governance/baseline.yaml`)
   - **L1** — VP doc + registry L1 paths
   - **L2** — `required_reading` ∩ `allowed_paths` only
   - **L3** — cross-repo pins from enterprise `governance/baseline.yaml` when needed
4. Copy `templates/context-pack-template.yaml`; fill `framework_pins` from consumer baseline.
5. List **excluded** paths with reasons (outside ACL, too broad).
6. Output YAML or markdown table on the issue comment or worker spawn brief.

## Rules

- Domain agents **curate only** — no commits, no implementation (max envelope E1).
- Never add L2 paths outside issue `allowed_paths`.
- Do not instruct workers to load entire repositories.

## Related

- `docs/agents/domain-agent-and-context-pack-model.md`
- `docs/agents/context-pack-issue-convention.md`
- `templates/agent-skills-catalog.yaml`
