---
name: aegf-verification-profile
description: >-
  Execute and attest AEGF verification profiles (VP-*). Maps VP IDs to validation
  scripts and CI evidence. Use when an issue declares verification_profile,
  VP-TST-01 testing, or when the user asks what to run to verify a change.
---

# AEGF verification profile

## When to use

- Issue declares `verification_profile` (e.g. VP-GOV-01, VP-ENT-01)
- Quality engineer or engineer needs declared verification before PR
- Attest `VER-GOV-01`, `VER-TST-01`, or profile-specific checkpoints

## Steps

1. Read VP definitions: `docs/standards/agent-verification-profiles.md` in the target repo (or AEGF for governance work).
2. Match issue `verification_profile` to the repo's validation script from `repos.yaml` or repo CI.
3. Run the declared script locally when possible:

| Repo pattern | Typical script |
|---|---|
| AEGF | `.github/scripts/governance-check.sh` |
| Framework | `.github/scripts/*-validation.sh` |
| Enterprise | `.github/scripts/enterprise-application-validation.sh` |

4. Paste command output or CI link in PR **Test plan** / verification section.
5. Include VP ID in `governance-run-report.sh --profile` argument.

## Rules

- Do not substitute a different VP without issue amendment.
- If validation script is missing (`VP-AGT-01` repos), document manual verification steps in the PR.

## Related

- `aelaron-agent-workspace/repos.yaml` — `verification_profile` per repo
- `docs/standards/testing-standards.md`
- `templates/governance-firing-catalog.yaml`
