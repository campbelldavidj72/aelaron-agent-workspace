---
name: aegf-governance-run-report
description: >-
  Run AEGF governance-run-report.sh with correct --fire IDs and paste cumulative
  coverage in PRs. Use when opening pull requests, release promotion, or when
  the user asks for governance coverage, firing checkpoints, or run evidence.
---

# AEGF governance run report

## When to use

- Before opening or updating a PR (mandatory for implementer agents)
- After CI passes locally or on the branch
- Material changes (tier 3–4): use `--run-type material` and MAT-* IDs

## Standard command

From the repo you changed (or `aelaron-framework-governance` for governance-only work):

```bash
bash .github/scripts/governance-run-report.sh \
  --run-type standard \
  --issue <NNN> \
  --profile <VP-ID> \
  --fire INT-001,INT-002,INT-003,INT-004,INT-005,INT-006,EXE-001,EXE-002,EXE-003,EXE-004,EXE-005,BRN-001 \
  --ci-pass <ci-context-if-passed> \
  --append-log governance/metrics/runs.jsonl
```

Add context checkpoints when applicable: `CTX-001,CTX-002,CTX-003`.

## PR body

```bash
bash .github/scripts/governance-run-report.sh --for-pr
```

Paste output under **Governance coverage (cumulative)** in the PR template.

## Rules

- Commit `governance/metrics/runs.jsonl` on the feature branch when the repo tracks it.
- Local chat sessions: advisory only — do not block user on missing report.
- Catalog: `templates/governance-firing-catalog.yaml`

## Related

- `docs/metrics/governance-firing-model.md`
- `AGENTS.md` end-of-run section
