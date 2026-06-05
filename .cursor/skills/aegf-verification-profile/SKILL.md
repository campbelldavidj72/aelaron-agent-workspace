---
name: aegf-verification-profile
description: >-
  Select and document the correct VP profile for a repository change. Use before
  PRs, when declaring CI evidence, or when spawning quality-engineer subagents.
---

# AEGF verification profile

## Select profile by target repo

| Repository | Profile | Check |
|---|---|---|
| aelaron-framework-governance | VP-GOV-01 | `governance-check.sh` |
| aelaron-platform-specifications | VP-SPEC-01 | specifications-check |
| aelaron-enterprise-application | VP-ENT-01 + VP-APP-* | enterprise-application-validation + `mvn verify` |

See L0 `AGENTS.md` path → repository table and target repo `docs/standards/agent-verification-profiles.md`.

## Evidence block (paste in PR)

```markdown
Verification profile: VP-ENT-01
- [x] ./mvnw -B verify — pass
- [x] bash .github/scripts/enterprise-application-validation.sh — pass
Issue: Closes #NNN
Envelope: E3
Allowed paths: platform-kernel/
```

## Governance report

Include `--fire VER-TST-01` (or repo-specific VER-*) with `--ci-pass` matching the workflow job name.

Baseline VP list: L1 governance module or AEGF `docs/standards/agent-verification-profiles.md` for tooling repo work.
