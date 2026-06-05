---
name: aegf-agent-log
description: >-
  Append structured events to agent-log.jsonl at L0 workspace root. Use during
  domain curation, worker analysis, or when hooks request validate-context logging.
---

# AEGF agent activity log

## Location

Append-only **`agent-log.jsonl`** at L0 program workspace root.

## Common commands

```bash
# Domain agent: after L0/L1 reads
python3 aelaron-framework-governance/.github/scripts/agent-log.py validate-context \
  --domain-agent-role <role> --target-repository <repo> --issue <N> --clear-active

# Thinking / decisions
python3 aelaron-framework-governance/.github/scripts/agent-log.py think \
  --agent-kind domain --domain-agent-role <role> --message "..."

# Worker analysis
python3 aelaron-framework-governance/.github/scripts/agent-log.py think \
  --agent-kind worker --worker-agent-role engineer --message "..."
```

## When to log

- Domain agent: after validating context tiers; before handing pack to parent
- Worker: major analysis decisions (not every tool call)
- Optional for E0 quick lookups

Schema: `aelaron-framework-governance/docs/agents/agent-activity-log.md`
