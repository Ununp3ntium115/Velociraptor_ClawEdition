---
name: Gap Issue
about: Track implementation of a feature gap from macOS Implementation Guide
title: '[GAP-0x##] '
labels: gap, enhancement
assignees: ''
---

## Gap Information

**Gap ID**: gap-0x##
**Priority**: P0/P1/P2
**Estimated Effort**: X-Y hours
**Phase**: 1/2/3/4
**Status**: 🔴 Open

---

## Current State

**BRUTAL HONESTY**: [Describe current state - be honest, no false information]

- ❌ **Missing**: [What is completely missing]
- ⚠️ **Partial**: [What exists but is incomplete]
- ✅ **Complete**: [What already works]

**Parity**: X% (Electron has Y%, macOS has Z%)

---

## Electron Equivalent

**File**: `path/to/electron/file.js` (X lines)
**Features**:
- Feature 1
- Feature 2
- Feature 3

---

## Required Implementation

### Files to Create/Modify

- [ ] `Path/To/File.swift` (~X lines)
  - Feature 1
  - Feature 2
- [ ] `Path/To/Service.swift` (~Y lines)
  - Service functionality

### Features Required

- [ ] Feature 1
- [ ] Feature 2
- [ ] Feature 3

---

## Closure Criteria

A gap is **CLOSED** when ALL of the following are met:

- [ ] All implementation tasks completed
- [ ] All closure criteria met
- [ ] Verification code passes (see below)
- [ ] Unit tests passing (>80% coverage)
- [ ] UI tests passing (if applicable)
- [ ] Code review approved
- [ ] Documentation updated
- [ ] GitHub issue closed with evidence

---

## Verification Code

```swift
// Test: [What this test verifies]
let service = ServiceName()
let result = try await service.method()
assert(result.expectedProperty == expectedValue)

// Test: [Another verification]
let view = ViewName()
let data = try await view.loadData()
assert(data.count >= 0)
```

**Expected Results**:
- Test 1: [Expected outcome]
- Test 2: [Expected outcome]

---

## Dependencies

**Depends on**:
- gap-0x## (Feature Name) - [Why]

**Blocks**:
- gap-0x## (Feature Name) - [Why]

---

## Implementation Notes

- [Note 1]
- [Note 2]

---

## Related Documentation

- Master Iteration Document: `steering/macos-app/macOS-Implementation-Guide.md`
- Gap Analysis: `docs/GAP-ANALYSIS-EXECUTIVE-SUMMARY.md`
- Detailed Analysis: `docs/MASSIVE-GAP-ANALYSIS-MACOS-VS-ELECTRON-2026-01-31.md`

---

## Acceptance Criteria

- [ ] Feature works as specified
- [ ] No regressions introduced
- [ ] Code follows Swift 6 concurrency rules
- [ ] Accessibility identifiers added (if UI)
- [ ] Documentation updated
