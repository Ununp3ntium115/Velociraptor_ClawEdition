# Issue Close-Out Governance Policy

**Document ID**: `ISSUE_CLOSEOUT_GOVERNANCE`  
**Path**: `steering/ISSUE_CLOSEOUT_GOVERNANCE.md`  
**Category**: Governance, Close-Out, Production Readiness  
**Status**: Authoritative  
**Last Updated**: January 23, 2026

---

## Purpose

This document defines the governance policy for closing GitHub issues in the Velociraptor Claw Edition repository. It ensures issues are only closed after verifiable, auditable, and policy-compliant completion.

---

## Authoritative Documents

| Document | Path | Purpose |
|----------|------|---------|
| Close-Out Checklist | `steering/ISSUE_CLOSEOUT_TODO.md` | Canonical execution plan |
| Evidence Status Index | `steering/GITHUB_ISSUES_STATUS.md` | Verification evidence |
| This Policy | `steering/ISSUE_CLOSEOUT_GOVERNANCE.md` | Governance rules |

---

## Close-Out Requirements

### NO ISSUE MAY BE CLOSED UNLESS:

1. **Listed in Checklist**: Issue appears in `steering/ISSUE_CLOSEOUT_TODO.md`
2. **Verification Passed**: Per-issue block verification commands succeed
3. **Evidence Valid**: Evidence links are present and accessible
4. **Standard Comment**: Close-out comment is exactly: `"Verified as implemented"`

---

## Automation Boundaries (STRICT)

### Agents MAY:
- Generate verification commands
- Confirm files touched exist
- Confirm grep/find evidence matches expectations
- Summarize readiness status
- Update tracking documents

### Agents MUST NOT:
- Execute `gh issue close`
- Close issues via API
- Modify issue state without explicit maintainer instruction
- Imply an issue has been closed unless confirmed by maintainer

---

## Batch Close Policy

### Rules:
- Batch close commands are **maintainer-only**
- Documented for convenience, never executed by automation
- Canonical batch close reference: `steering/ISSUE_CLOSEOUT_TODO.md`

### Canonical Batch Close Command:
```bash
# MAINTAINER-ONLY - Do not execute via automation
for i in {33..40} {23..32}; do
  gh issue close $i -c "Verified as implemented"
done
```

---

## Post-Close Hygiene Requirements

After all issues are closed:

- [ ] **CI Green**: Default branch CI passing
- [ ] **No Follow-ups**: No additional issues required
- [ ] **Doc Sync**: Documentation verified for drift
- [ ] **Archive**: Tracking documents archived if complete

---

## Status Reporting Requirements

When asked about issue status or closure readiness, agents must:

1. **Cite** the relevant per-issue block from `ISSUE_CLOSEOUT_TODO.md`
2. **State** whether verification commands have been run
3. **Declare** status explicitly:
   - `"Ready to close (manual)"` — All criteria met
   - `"Not ready to close"` — Criteria incomplete
4. **Never imply** an issue has been closed unless confirmed by maintainer

### Example Response Format:

```
## Issue #XX Status

**Per-Issue Block**: steering/ISSUE_CLOSEOUT_TODO.md#issue-xx
**Verification Commands**: [Passed/Not Run/Failed]
**Evidence Links**: [Valid/Invalid/Missing]
**Status**: Ready to close (manual)

Close command (maintainer-only):
gh issue close XX -c "Verified as implemented"
```

---

## KB Integration

### Index Entry (steering/CDIF_KB_INDEX.md)

```markdown
- ISSUE CLOSE-OUT & PRODUCTION READINESS
  - steering/ISSUE_CLOSEOUT_TODO.md (authoritative close-out checklist)
  - steering/GITHUB_ISSUES_STATUS.md (evidence/status index)
  - steering/ISSUE_CLOSEOUT_GOVERNANCE.md (governance policy)
```

### Manifest Entry (CDIF_KB_MANIFEST.yaml)

```yaml
documents:
  - id: ISSUE_CLOSEOUT_TODO
    path: steering/ISSUE_CLOSEOUT_TODO.md
    category: [governance, closeout, production-readiness]
    authoritative: true
    
  - id: GITHUB_ISSUES_STATUS
    path: steering/GITHUB_ISSUES_STATUS.md
    category: [evidence, status, tracking]
    authoritative: true
    
  - id: ISSUE_CLOSEOUT_GOVERNANCE
    path: steering/ISSUE_CLOSEOUT_GOVERNANCE.md
    category: [governance, policy, sdlc]
    authoritative: true
```

---

## Release Candidate Close-Out Gate

Before any release candidate can be declared:

### Gate Criteria:

| Criterion | Check | Pass/Fail |
|-----------|-------|-----------|
| All tracked issues closed | `gh issue list --state open` returns 0 | |
| CI green on release branch | `gh run list --branch <release>` all success | |
| Close-out checklist complete | All boxes checked in `ISSUE_CLOSEOUT_TODO.md` | |
| Evidence document current | `GITHUB_ISSUES_STATUS.md` last updated within 24h | |
| No P0/P1 open issues | No critical issues remain | |
| Documentation complete | All feature docs updated | |

### Gate Command:

```bash
# Verify release candidate readiness
echo "=== Release Candidate Gate Check ==="

# Check open issues
OPEN=$(gh issue list --state open --json number | jq length)
echo "Open issues: $OPEN"

# Check CI status
gh run list --branch main --limit 3

# Check last commit
git log -1 --oneline

echo "=== Gate check complete ==="
```

---

## Production Readiness Declaration Template

```markdown
# Production Readiness Declaration

**Product**: Velociraptor Claw Edition - macOS Application  
**Version**: X.Y.Z  
**Date**: YYYY-MM-DD  
**Declared By**: [Maintainer Name]

## Close-Out Summary

| Category | Issues | Status |
|----------|--------|--------|
| GAP Issues (#33-40) | 8 | ✅ Closed |
| Feature Issues (#23-32) | 10 | ✅ Closed |
| **Total** | 18 | ✅ All Closed |

## Evidence References

- Close-Out Checklist: steering/ISSUE_CLOSEOUT_TODO.md
- Evidence Index: steering/GITHUB_ISSUES_STATUS.md
- Governance Policy: steering/ISSUE_CLOSEOUT_GOVERNANCE.md

## Verification

- [ ] All close-out checklist items complete
- [ ] All evidence links verified
- [ ] CI green on release branch
- [ ] No P0/P1 issues remaining
- [ ] Documentation complete

## Declaration

I declare that all acceptance criteria have been met and this release
candidate is ready for production deployment.

Signed: _______________________
Date: _______________________
```

---

## Document Maintenance

| Action | Frequency | Owner |
|--------|-----------|-------|
| Review governance rules | Per release | Release Manager |
| Update close-out checklist | Per issue batch | SDLC Coordinator |
| Verify evidence links | Pre-release | QA Lead |
| Archive completed checklists | Post-release | Documentation |

---

## Related Documents

- `steering/MACOS_PRODUCTION_COMPLETE.md` - Production status
- `steering/MACOS_CODE_REVIEW_ANALYSIS.md` - Code review findings
- `steering/MACOS_MASTER_ITERATION_PLAN.md` - Implementation plan
- `.github/workflows/macos-build.yml` - CI/CD workflow

---

*This document is authoritative for all issue close-out operations.*
