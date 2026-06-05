# Material Change — Multi-Agent Checklist

Copy this checklist into the issue body or link from the issue and tick items as phases complete.

Replace placeholders: `#NNN`, `ADR-XXXX`, profile IDs, paths.

---

## Issue contract

- [ ] Objective stated
- [ ] Change class: `material` (or `emergency` with justification)
- [ ] Risk tier: `3` or `4`
- [ ] Scope envelope declared per phase
- [ ] Allowed paths explicit
- [ ] Verification profile ID declared (`VP-GOV-01`, `VP-ARCH-01`, etc.)
- [ ] Controls impacted listed (if any)
- [ ] Human merge to `development` required: **yes** for tier 3+

---

## Phase 1 — Architecture analysis (E0)

**Actor:** architect agent or human  
**Output:** issue comment (do not implement in this phase)

- [ ] Context and problem statement recorded
- [ ] At least two options considered with strengths and weaknesses
- [ ] Recommendation stated with reversibility note
- [ ] Scale, security, operability, and compliance dimensions addressed
- [ ] Link to source material (prior ADR, IDR, spec) if porting existing decisions
- [ ] Rubric self-check: no score 0 on architecture conformance or hallucination avoidance

**Evidence link:** _paste issue comment URL_

---

## Phase 2 — Security / compliance review (E0)

**Skip if:** no security boundary, identity, data, or control mapping change.

**Actor:** security or compliance agent or human  
**Output:** issue comment

- [ ] Threat or control impact summarised
- [ ] Identity, tenant isolation, secrets, or agent boundary impacts stated
- [ ] Residual risks and mitigations listed
- [ ] Rubric self-check: no score 0 on security posture or compliance evidence

**Evidence link:** _paste issue comment URL_

---

## Phase 3 — Readiness gate (human)

- [ ] Phase 1 complete
- [ ] Phase 2 complete or explicitly waived with reason
- [ ] Acceptance criteria testable and unchanged or updated with rationale
- [ ] Label `status/ready` applied
- [ ] Implementer and verification profile confirmed

---

## Phase 4 — Implementation (E1–E3)

**Actor:** implementer agent or human  
**Output:** PR to `development`

- [ ] Branch from `development`
- [ ] Changes only in allowed paths
- [ ] ADR uses `templates/adr-template.md` sections including alternatives and evidence required
- [ ] Verification profile executed locally or in CI
- [ ] PR description includes evidence block (see below)
- [ ] Issue linked: `Closes #NNN` or `Refs #NNN`
- [ ] Label `status/in-review`

### PR evidence block (paste in PR)

```markdown
Verification profile: VP-____-__
- [ ] `<command>` — pass
Issue: Closes #NNN
Envelope: E_
Allowed paths:
Phase 1 analysis: <url>
Phase 2 review: <url or n/a>
```

---

## Phase 5 — Development merge

- [ ] Required CI checks pass
- [ ] Envelope and allowed paths verified in diff
- [ ] Tier 3+ / material: **human merge only**
- [ ] Issue closed with merge PR link

---

## Phase 6 — Main promotion (releases only, human)

- [ ] `VERSION` and release notes updated if baseline release
- [ ] VP-REL-01 satisfied
- [ ] Promotion PR `development` → `main` opened
- [ ] Human merge
- [ ] Tag on `main` if releasing

---

## Example (abbreviated): material ADR for workflow runtime

| Item | Example value |
|---|---|
| Issue | `[MAT] ADR-0003 native Action Request workflow` |
| Phase 1 | Compare native SM vs Temporal vs inline; recommend native for evidence alignment |
| Phase 2 | Confirm AI/MCP parity and tenant scope on workflow APIs |
| Phase 4 | PR updating `adr/adr-0003-*.md`, `specs/workflow/*` |
| VP | `VP-ARCH-01` |
| Merge | Human (tier 3) to `development` |

See closed AAPF issues #8 and #10 for historical single-agent execution; future material ADRs should follow this phased checklist.
