# AGENTS.md — template for AEGF consumer repositories

Copy to workspace or application repo root. Replace `<REPO>` and pin versions.

## Governance pin

- AEGF: `governance/aegf` @ `<AEGF_VERSION>`
- Follow `governance/aegf/docs/agents/agent-approval-model.md`
- Cross-tool instructions: `governance/aegf/docs/agents/agent-instruction-layer.md`

## Cursor (if used)

Install hooks from `governance/aegf/templates/cursor/` into workspace `.cursor/`.

## End-of-run report

```bash
bash governance/aegf/.github/scripts/governance-run-report.sh \
  --run-type standard \
  --issue NNN \
  --profile VP-GOV-01 \
  --fire ... \
  --ci-pass governance-check \
  --append-log governance/metrics/runs.jsonl
```

See `governance/aegf/docs/metrics/governance-firing-model.md`.
