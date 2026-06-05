---
name: aegf-agent-log
description: >-
  Append timestamped activity to agent-log.jsonl at the workspace root — context
  reads, freshness validation, domain/worker thinking, context packs. Use when
  reading files for context, after pin bumps, when engaging subagents, or when
  the user asks about agent activity logging.
---

# AEGF agent activity log

## Log file

`<workspace-root>/agent-log.jsonl` — append-only, gitignored.

## When to use

- After **curating a context pack** (domain agent) — log `context_pack` with paths
- After **confirming pins** post bump — log `freshness_validated` with `--pin-ref`
- When **thinking** is not captured by hooks — log `agent_thinking` with `--thinking`
- After **manual reads** outside hook coverage — log `context_read` with `--path` and `--context-tier`

## Commands

```bash
python3 aelaron-framework-governance/.github/scripts/agent-log.py append \
  --event context_read \
  --agent-kind domain \
  --domain-agent-role governance \
  --path AGENTS.md \
  --context-tier L0 \
  --pin-ref "$(git -C aelaron-framework-governance rev-parse --short HEAD)" \
  --summary "L0 contract loaded"

python3 aelaron-framework-governance/.github/scripts/agent-log.py append \
  --event freshness_validated \
  --agent-kind worker \
  --worker-agent-role engineer \
  --path governance/baseline.yaml \
  --pin-ref v1.0.9 \
  --summary "Baseline pins match after submodule bump"
```

## Automatic hooks

Cursor hooks log `session_start`, `session_end`, `context_read`, `subagent_engaged`, `agent_thinking`, and `freshness_check` — see `docs/agents/agent-activity-log.md` in AEGF.

## Rules

- Domain and worker agents log major reasoning when hooks miss it
- Re-read L0/L1 after `freshness_check` events; log `freshness_validated` when confirmed
- Never delete or rewrite `agent-log.jsonl` — append only
