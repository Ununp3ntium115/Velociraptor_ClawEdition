# macOS Testing Agent

## Overview

The **macOS Testing Agent** is an Xcode Test Runner + Deterministic Verification Agent that is part of the HiQ swarm. It verifies that Development work actually closed identified gaps through comprehensive, repeatable testing.

## Purpose

As stated in the system prompt:

> You are a macOS Testing Agent in the HiQ swarm. You verify that Development actually closed the gap.

The Testing Agent validates:
- **Functional correctness** - Expected behavior achieved
- **macOS correctness** - Works under sandbox, correct UI lifecycle
- **Determinism** - Repeatable, not flaky
- **Accessibility** - Proper accessibility identifiers and VoiceOver support
- **Swift concurrency** - UI updates on MainActor, background tasks correctly isolated

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Testing Agent                             │
│                                                             │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │     Gap      │  │    Test      │  │  Determinism  │     │
│  │  Validator   │  │   Reporter   │  │   Checker     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                             │
│  ┌──────────────────────────────────────────────────┐      │
│  │          Xcode Test Runner                        │      │
│  │  • Unit Tests (Services/Models)                  │      │
│  │  • UI Tests (SwiftUI/AppKit flows)               │      │
│  │  • Accessibility validation                       │      │
│  │  • Concurrency checks (MainActor, isolation)     │      │
│  └──────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────┘
```

## Components

### 1. TestingAgent.swift

Main orchestrator that coordinates gap validation:

- Runs functional correctness tests
- Validates macOS platform integration
- Checks test determinism
- Validates Swift concurrency patterns
- Aggregates results into structured reports

### 2. GapValidator.swift

Validates that Development work properly closes identified gaps:

- Maintains catalog of known gaps from gap analysis
- Checks acceptance criteria for each gap
- Reports gap closure status
- Identifies remaining issues

### 3. TestReporter.swift

Generates structured test reports:

- Console output (human-readable)
- JSON format (machine-readable)
- Markdown reports
- CDIF format (test archetype format)

### 4. DeterminismChecker.swift

Ensures tests are repeatable and not flaky:

- Runs tests multiple times (default: 3 runs)
- Calculates stability score
- Identifies flakiness sources (timing, random data, race conditions)
- Enforces 95% success threshold

### 5. XcodeTestRunner.swift

Executes Xcode tests and collects results:

- Runs unit tests via xcodebuild
- Runs UI tests with accessibility validation
- Parses .xcresult bundles
- Reports test execution metrics

## Usage

### Basic Gap Validation

```swift
import TestingAgent

let agent = TestingAgent()

// Validate a specific gap
let result = try await agent.validateGap(
    gapID: "GAP-003",
    description: "Accessibility Identifiers Not Applied"
)

// Check result
switch result.status {
case .passed, .testedPendingQA:
    print("✅ Gap closed successfully")
case .failed:
    print("❌ Gap not closed: \(result.failureReason ?? "Unknown")")
case .skipped:
    print("⏭️ Gap validation skipped")
}
```

### Batch Gap Validation

```swift
let gaps = [
    ("GAP-001", "No Xcode Project"),
    ("GAP-002", "App Icons Missing"),
    ("GAP-003", "Accessibility Identifiers Not Applied"),
    ("GAP-004", "Localization Not Wired"),
    ("GAP-005", "No Compilation Verification")
]

let results = try await agent.validateGaps(gaps)

// Generate comprehensive report
let reporter = TestReporter()
let markdownReport = reporter.generateReport(results, format: .markdown)
print(markdownReport)
```

### Command-Line Usage

Run from terminal:

```bash
# Navigate to project
cd apps/macos-legacy

# Run Testing Agent for all gaps
swift run TestingAgentCLI --validate-all

# Run for specific gap
swift run TestingAgentCLI --gap GAP-003

# Generate CDIF report
swift run TestingAgentCLI --validate-all --format cdif

# Run with determinism checking (5 runs)
swift run TestingAgentCLI --gap GAP-001 --runs 5
```

## Test Categories

The agent validates multiple test categories:

### 1. Functional Correctness

- Unit tests for services and models
- Integration tests for workflows
- Edge case coverage
- Error handling validation

**Criteria:** All tests pass, no regressions introduced

### 2. macOS Correctness

- **Sandbox compatibility** - Works within App Sandbox restrictions
- **UI lifecycle** - Proper window management, state restoration
- **Platform integration** - Keychain, launchd, Notifications

**Criteria:** Follows macOS platform conventions and APIs

### 3. Determinism

- Runs tests 3+ times
- Calculates stability score
- Identifies flakiness sources
- Enforces 95% success threshold

**Criteria:** Tests are repeatable and not flaky

### 4. Accessibility

- All interactive elements have identifiers
- VoiceOver navigation works correctly
- Keyboard navigation is logical
- Follows accessibility best practices

**Criteria:** App is fully accessible to users with disabilities

### 5. Swift Concurrency

- UI updates happen on MainActor
- Background tasks are correctly isolated
- No data races detected
- Proper async/await usage

**Criteria:** Concurrent code is safe and correct

## Output Format

### PASS/FAIL Result

For each gap, the agent reports:

```
✅ PASS: GAP-003
Description: Accessibility Identifiers Not Applied
Status: Tested – Pending QA
Execution Time: 2.35s
Determinism Score: 100.0%
```

### Failure Reason

If a test fails, detailed reason is provided:

```
❌ FAIL: GAP-001
Description: No Xcode Project
Status: FAIL
Execution Time: 1.12s
Determinism Score: 66.7%

Failure Reason:
Functional: UI Tests: 0/5 passed
Determinism: Test Runs: 3, Passed: 2/3, Status: Flaky
```

### Follow-up Gaps

Automatically generates new gaps if needed:

```
Follow-up Gaps Required:
• GAP-001-FUNC: Fix functional test failures
• GAP-001-FLAKY: Improve test stability to 95%+
```

### Status Codes

- **PASS** - All tests passed, determinism adequate (< 95%)
- **Tested – Pending QA** - All tests passed, highly deterministic (≥ 95%)
- **FAIL** - One or more test categories failed
- **SKIPPED** - Test validation was skipped

## CDIF Integration

The Testing Agent integrates with CDIF (Common Definition of Issue Format) for test archetype management.

### Test Archetypes

Predefined test patterns stored in `CDIF_TEST_ARCHETYPES.md`:

- **FC-001**: Basic Feature Validation
- **FC-002**: UI Flow Validation
- **MAC-001**: Sandbox Compatibility
- **MAC-002**: Keychain Integration
- **MAC-003**: launchd Service Management
- **MAC-004**: macOS UI Lifecycle
- **DET-001**: Repeatability Validation
- **DET-002**: Concurrency Safety
- **ACC-001**: Accessibility Identifier Coverage
- **ACC-002**: VoiceOver Navigation
- **PERF-001**: Response Time Validation
- **SEC-001**: Credential Security

### Using Archetypes

```swift
// Validator automatically applies relevant archetypes
let result = try await agent.validateGap(
    gapID: "GAP-003",
    description: "Accessibility Identifiers Not Applied",
    testCategories: [.functional, .accessibility, .determinism]
)

// Archetypes applied:
// - FC-002: UI Flow Validation
// - ACC-001: Accessibility Identifier Coverage
// - ACC-002: VoiceOver Navigation
// - DET-001: Repeatability Validation
```

### Creating New Archetypes

To suggest a new archetype for CDIF update:

1. Identify the test pattern
2. Define requirements and validation criteria
3. Document in CDIF format
4. Submit to CDIF catalog

## Integration with Existing Tests

The Testing Agent works with existing XCTest infrastructure:

### Unit Tests

Located in `VelociraptorMacOSTests/`:
- AppStateTests.swift
- ConfigurationDataTests.swift
- KeychainManagerTests.swift
- DeploymentManagerTests.swift
- And 5 more test files

### UI Tests

Located in `VelociraptorMacOSUITests/`:
- ConfigurationWizardUITests.swift
- EmergencyModeUITests.swift
- IncidentResponseUITests.swift
- SettingsUITests.swift
- And 4 more test files

### Running Tests

```bash
# Unit tests
swift test

# UI tests (requires Xcode project)
xcodegen generate
xcodebuild test -scheme VelociraptorMacOS \
  -destination 'platform=macOS' \
  -only-testing:VelociraptorMacOSUITests

# All tests via Testing Agent
swift run TestingAgentCLI --validate-all
```

## CI/CD Integration

Add to GitHub Actions workflow:

```yaml
- name: Run Testing Agent
  run: |
    cd apps/macos-legacy
    swift run TestingAgentCLI --validate-all --format json > test-results.json

- name: Upload Test Results
  uses: actions/upload-artifact@v4
  with:
    name: testing-agent-results
    path: apps/macos-legacy/test-results.json
```

## Reports Location

All reports are saved to:

```
~/Library/Logs/Velociraptor/TestReports/
├── test-report-GAP-001-2026-01-30_14-30-00.json
├── test-report-GAP-001-2026-01-30_14-30-00.md
├── test-report-GAP-002-2026-01-30_14-30-15.json
└── test-report-GAP-002-2026-01-30_14-30-15.md
```

## Best Practices

### 1. Use Accessibility Identifiers

All interactive UI elements must have identifiers:

```swift
Button("Next") {
    // action
}
.accessibilityIdentifier(AccessibilityIdentifiers.Navigation.nextButton)
```

### 2. Use MainActor for UI Updates

```swift
@MainActor
func updateUI() {
    // UI updates here
}
```

### 3. Isolate Background Tasks

```swift
Task {
    await performBackgroundWork()
}

func performBackgroundWork() async {
    // Background work here - not on MainActor
}
```

### 4. Write Deterministic Tests

```swift
// ❌ Bad: Timing-dependent
sleep(1)
XCTAssertTrue(someCondition)

// ✅ Good: Event-driven
await waitForCondition { someCondition }
```

### 5. Use Test Archetypes

Reference CDIF archetypes in test documentation:

```swift
/// Tests GAP-003 closure using archetype ACC-001
func testAccessibilityIdentifierCoverage() {
    // ...
}
```

## Troubleshooting

### Tests Fail Inconsistently

- Check determinism score in report
- Review flakiness sources
- Look for timing dependencies
- Verify no random data

### macOS Correctness Failures

- Check entitlements configuration
- Verify sandbox restrictions
- Review file access patterns
- Check Keychain permissions

### Slow Test Execution

- Profile test execution time
- Check for synchronous network calls
- Review database operations
- Consider mocking external dependencies

## References

- [CDIF Test Archetypes](../CDIF_TEST_ARCHETYPES.md)
- [macOS QA Test Plan](../steering/MACOS_QA_TEST_PLAN.md)
- [Gap Analysis](../steering/MACOS_GAP_ANALYSIS_ITERATION_2.md)
- [Project README](../README.md)

## License

Part of Velociraptor macOS - Free for all first responders.
