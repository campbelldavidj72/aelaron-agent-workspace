---
name: aegf-governance-run-report
description: >-
  Generate AEGF governance run reports for PRs and releases. Use before opening PRs
  or when completing agent-executed work on a linked issue.
---

# AEGF governance run report

## When to use

- Before opening a PR in an L2 repo (or this tooling repo)
- After CI passes locally
- When filling **Governance coverage (cumulative)** in PR template

## Command

From program workspace (adjust paths if cwd is L2 repo):

```bash
bash aelaron-framework-governance/.github/scripts/governance-run-report.sh \
  --run-type standard \
  --issue NNN \
  --profile <VP-ID> \
  --fire INT-001,INT-002,INT-003,INT-004,INT-005,INT-006,EXE-001,EXE-002,EXE-003,EXE-004,EXE-005,VER-TST-01,BRN-001 \
  --ci-pass <check-name> \
  --for-pr \
  --append-log governance/metrics/runs.jsonl
```

## Rules

- Fire only checkpoints you actually satisfied (`--fire` is attestation)
- Include `--ci-pass` matching the CI context that passed
- Commit `governance/metrics/runs.jsonl` on the feature branch
- Paste markdown output into PR body — local chat sessions do not require end-of-turn paste

Catalog: `aelaron-framework-governance/templates/governance-firing-catalog.yaml`
