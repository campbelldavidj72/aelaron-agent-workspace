---
name: aegf-agent-log
description: >-
  Append timestamped activity to agent-log.jsonl — context validation, freshness,
  domain/worker thinking, governed work. Use when reading files for context,
  after pin bumps, validate-context, think, or monitoring agent activity.
---

# AEGF agent activity log

## Log file

`<workspace-root>/agent-log.jsonl` — append-only, gitignored.

## Governed work

Any task that impacts **code, specifications, or baselines**:

1. **Domain agent** curates context → `validate-context` → worker executes
2. Both log **thinking** incrementally

## Domain agent — context validation

After reading L0/L1 (and before worker handoff):

```bash
python3 aelaron-framework-governance/.github/scripts/agent-log.py validate-context \
  --domain-agent-role governance \
  --target-repository aelaron-framework-governance \
  --issue 106 \
  --read AGENTS.md:L0 \
  --read templates/domain-agent-registry.yaml:L0 \
  --framework-pin aegf:v1.0.9 \
  --clear-active
```

Produces `context_validation` with `status` (`ok` | `incomplete` | `stale`), `reads[]`, and `framework_pins`.

## Thinking (domain or worker)

```bash
python3 aelaron-framework-governance/.github/scripts/agent-log.py think \
  --agent-kind domain \
  --domain-agent-role governance \
  --message "Excluded specs/events — outside allowed_paths"
```

Hooks also capture `agent_thinking` when `afterAgentThought` fires.

## Worker — freshness

```bash
python3 aelaron-framework-governance/.github/scripts/agent-log.py append \
  --event freshness_validated \
  --agent-kind worker \
  --worker-agent-role engineer \
  --path governance/baseline.yaml \
  --pin-ref v1.0.9 \
  --summary "Pins confirmed before implementation"
```

## Monitor

```bash
./tail-agent-log.sh
```

## Related

- `docs/agents/agent-activity-log.md`
- `docs/agents/domain-agent-and-context-pack-model.md`
