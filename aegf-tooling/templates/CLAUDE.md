# CLAUDE.md — AEGF consumer template

Claude Code reads this file at session start. **Do not duplicate AEGF policy here.**

## Canonical instructions

Read and follow workspace **`AGENTS.md`** for all required behaviour, verification profiles, and end-of-run governance reports.

## AEGF baseline

- Governance submodule: `governance/aegf` @ `<AEGF_VERSION>`
- Agent approval: `governance/aegf/docs/agents/agent-approval-model.md`
- Firing model: `governance/aegf/docs/metrics/governance-firing-model.md`

## End-of-run report (mandatory)

```bash
bash governance/aegf/.github/scripts/governance-run-report.sh \
  --run-type standard \
  --issue NNN \
  --profile VP-GOV-01 \
  --fire INT-001,INT-002,INT-003,INT-004,INT-005,INT-006,EXE-001,EXE-002,EXE-003,EXE-004,EXE-005,BRN-001 \
  --ci-pass governance-check \
  --append-log governance/metrics/runs.jsonl
```

Include the markdown output in your final message. See `governance/aegf/docs/agents/agent-instruction-layer.md` for Claude hook parity with Cursor.
