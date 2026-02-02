# macOS QA Quality Gate - Quick Reference

## Purpose

The macOS QA Agent validates **holistic quality** beyond functional correctness for features that have already passed testing.

## Quick Start

### Using the Agent (Claude)

```
Prompt: "The Emergency Mode feature has passed all unit and UI tests. 
Can you perform QA validation to check if it's ready for UAT?"

Agent: macos-qa-agent
```

The agent will:
1. Review the feature/change
2. Execute quality checks across 5 dimensions
3. Provide approve/reject decision with detailed rationale

### Running Tests Manually

```bash
cd apps/macos-legacy

# Run only QA validation tests
swift test --filter QAValidationTests

# Run with parallel execution
swift test --filter QAValidationTests --parallel

# Generate XML output
swift test --filter QAValidationTests --xunit-output qa-results.xml
```

### CI/CD Integration

QA validation runs automatically in GitHub Actions after tests pass:

```
Build → Unit Tests → UI Tests → Lint → QA Validation → Release
                                          ↑
                                    Quality Gate
```

See `.github/workflows/macos-build.yml`

## Quality Dimensions

| Dimension | Focus | Critical Checks |
|-----------|-------|-----------------|
| **Workflow Integrity** | No regressions | End-to-end workflows complete |
| **UI Consistency** | SwiftUI patterns | Visual consistency, HIG adherence |
| **Performance** | DFIR workflows | Launch < 2s, UI responsive |
| **Error Handling** | Operator-friendly | Clear states, no silent failures |
| **macOS Integration** | Platform conventions | Window lifecycle, focus, accessibility |

## QA Test Coverage

The `QAValidationTests.swift` includes 20 quality validation tests:

### Workflow Integrity (3 tests)
- ✅ Complete wizard workflow integrity
- ✅ Emergency mode no regressions
- ✅ Incident response workflow integrity

### UI Consistency (2 tests)
- ✅ SwiftUI view hierarchy consistency
- ✅ Visual consistency across deployment types

### Performance (3 tests)
- ✅ App launch performance
- ✅ Configuration validation performance
- ✅ Memory usage reasonable

### Error Handling (3 tests)
- ✅ Error states clear and actionable
- ✅ Validation errors operator-friendly
- ✅ No silent failures in deployment

### macOS Integration (5 tests)
- ✅ Keyboard navigation support
- ✅ Accessibility identifiers present
- ✅ Window state management
- ✅ Focus management
- ✅ Keychain integration structure

### Data Consistency (2 tests)
- ✅ Configuration data consistency
- ✅ Workflow recovery from invalid states

### Integration Quality (2 tests)
- ✅ Deployment progress tracking
- ✅ Incident response integration

## Approval Criteria

**Feature is APPROVED when:**
- All QA validation tests pass
- No regressions in related workflows
- UI is consistent with design system
- Performance meets targets
- Error handling is clear
- macOS integration works correctly

**Feature is REJECTED when:**
- Critical (P0) issues found
- Accessibility failures
- Silent failures detected
- Poor error handling
- Performance below targets

## Common Issues & Resolutions

### Issue: Silent Validation Failure
**Severity**: P0 (Critical)  
**Fix**: Display error message with clear guidance

### Issue: Keyboard Navigation Missing
**Severity**: P1 (High)  
**Fix**: Add to tab order, test with keyboard

### Issue: Slow Launch Time
**Severity**: P1 (High)  
**Fix**: Profile and optimize initialization

### Issue: Inconsistent Button Style
**Severity**: P2 (Medium)  
**Fix**: Apply design system consistently

## Output Examples

### Approved
```
✅ QA VALIDATION APPROVED
Status: QA-Validated – Pending UAT
All quality dimensions validated
Ready for User Acceptance Testing
```

### Rejected
```
❌ QA VALIDATION REJECTED
Status: Requires Remediation

Issues Found:
- P0: Silent error in configuration (Error Handling)
- P1: Missing keyboard navigation (macOS Integration)

New Gaps Created:
- Fix error display in config validation
- Add keyboard access to all controls

Cannot proceed to UAT until P0/P1 issues resolved
```

## Resources

- **Agent Definition**: `.claude/agents/macos-qa-agent.md`
- **Test Suite**: `VelociraptorMacOS/VelociraptorMacOSTests/QAValidationTests.swift`
- **Full Documentation**: `docs/QA_QUALITY_GATE.md`
- **CI Workflow**: `.github/workflows/macos-build.yml`
- **Test Plan**: `steering/MACOS_QA_TEST_PLAN.md`

## Tips

1. **Run QA early**: Don't wait until feature is "complete"
2. **Fix issues immediately**: Don't accumulate QA debt
3. **Use automated tests**: CI catches issues before manual review
4. **Be thorough**: QA is the last gate before UAT
5. **Document findings**: Help prevent similar issues

---

**Remember**: QA validates quality beyond correctness. We're ensuring a professional, polished, accessible macOS application that meets the high standards expected of DFIR tools.
