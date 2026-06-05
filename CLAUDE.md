# CLAUDE.md — Aelaron v4 program workspace

Claude Code reads this file at session start. **Do not duplicate AEGF policy here.**

## Canonical instructions

Read and follow workspace **`AGENTS.md`** for all required behaviour, verification profiles, and end-of-run governance reports.

## AEGF baseline

- Governance sibling: `aelaron-framework-governance/` @ pin in `VERSION`
- Agent approval: `aelaron-framework-governance/docs/agents/agent-approval-model.md`
- Firing model: `aelaron-framework-governance/docs/metrics/governance-firing-model.md`

## End-of-run report (PRs in child repos)

```bash
bash aelaron-framework-governance/.github/scripts/governance-run-report.sh \
  --run-type standard \
  --issue NNN \
  --profile <VP-ID> \
  --fire INT-001,INT-002,INT-003,INT-004,INT-005,INT-006,EXE-001,EXE-002,EXE-003,EXE-004,EXE-005,BRN-001 \
  --ci-pass <check-name> \
  --append-log governance/metrics/runs.jsonl
```

Include the markdown output in your final message. See `aelaron-platform-specifications/modules/governance/docs/agents/agent-instruction-layer.md` for Claude hook parity with Cursor.
