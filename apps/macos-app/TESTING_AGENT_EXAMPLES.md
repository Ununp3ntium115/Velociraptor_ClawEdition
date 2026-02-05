# Testing Agent Usage Examples

This document provides practical examples of using the macOS Testing Agent in various scenarios.

## Table of Contents

1. [Basic Usage](#basic-usage)
2. [Programmatic Usage](#programmatic-usage)
3. [CI/CD Integration](#cicd-integration)
4. [Custom Gap Validation](#custom-gap-validation)
5. [CDIF Integration](#cdif-integration)
6. [Troubleshooting Examples](#troubleshooting-examples)

## Basic Usage

### Validate All Known Gaps

```bash
cd apps/macos-app
swift run TestingAgentCLI --validate-all
```

**Expected Output:**
```
╔═══════════════════════════════════════════════════════════╗
║          macOS Testing Agent - HiQ Swarm                  ║
║          Xcode Test Runner + Deterministic Verification   ║
╚═══════════════════════════════════════════════════════════╝

🔍 Testing Agent: Validating GAP-001 - No Xcode Project
  ✓ Running functional correctness tests...
  ✓ Running macOS correctness tests...
  ✓ Running determinism tests...
  ✓ Validating Swift concurrency...

✅ PASS: GAP-001
Execution Time: 2.35s
Determinism Score: 100.0%

...

✅ All 5 gap(s) validated successfully!
```

### Validate Specific Gap

```bash
swift run TestingAgentCLI --gap GAP-003
```

**Example Output:**
```
═══════════════════════════════════════════════════════════
✅ Tested – Pending QA: GAP-003
═══════════════════════════════════════════════════════════

Description: Accessibility Identifiers Not Applied
Execution Time: 3.47s
Determinism Score: 100.0%

═══════════════════════════════════════════════════════════
```

### Generate JSON Report

```bash
swift run TestingAgentCLI --validate-all --format json > report.json
```

**Example JSON Output:**
```json
{
  "timestamp": "2026-01-30T14:30:00Z",
  "totalTests": 5,
  "passed": 4,
  "failed": 1,
  "results": [
    {
      "gapID": "GAP-001",
      "description": "No Xcode Project",
      "status": "PASS",
      "failureReason": "",
      "followUpGaps": [],
      "executionTime": 2.35,
      "determinismScore": 1.0
    },
    ...
  ]
}
```

### Generate CDIF Report

```bash
swift run TestingAgentCLI --validate-all --format cdif
```

**Example CDIF Output:**
```yaml
# CDIF Test Archetype Report

## Test Execution Metadata

schema_version: "1.0"
test_framework: "macOS Testing Agent"
execution_timestamp: "2026-01-30T14:30:00Z"
test_count: 5
pass_count: 4
fail_count: 1

## Test Archetypes

### Archetype: GAP-003

archetype_id: "GAP-003"
description: "Accessibility Identifiers Not Applied"
category: "gap_validation"
test_type: "integration"

test_characteristics:
  functional_correctness: true
  macos_correctness: true
  deterministic: true
  accessibility_validated: true
  concurrency_safe: true

test_result:
  status: "Tested – Pending QA"
  execution_time_seconds: 3.47
  determinism_score: 1.0
```

## Programmatic Usage

### Swift Code Example

```swift
import TestingAgent

// Example 1: Validate a single gap
func validateAccessibilityGap() async throws {
    let agent = TestingAgent()
    
    let result = try await agent.validateGap(
        gapID: "GAP-003",
        description: "Accessibility Identifiers Not Applied",
        testCategories: [.functional, .accessibility, .determinism]
    )
    
    print("Gap ID: \(result.gapID)")
    print("Status: \(result.status.rawValue)")
    print("Determinism: \(String(format: "%.1f%%", result.determinismScore * 100))")
    
    if result.status == .failed, let reason = result.failureReason {
        print("Failure Reason:\n\(reason)")
    }
    
    if !result.followUpGaps.isEmpty {
        print("\nFollow-up Gaps:")
        for gap in result.followUpGaps {
            print("  • \(gap)")
        }
    }
}

// Example 2: Batch validation
func validateAllGaps() async throws {
    let agent = TestingAgent()
    
    let gaps = [
        ("GAP-001", "No Xcode Project"),
        ("GAP-002", "App Icons Missing"),
        ("GAP-003", "Accessibility Identifiers Not Applied"),
        ("GAP-004", "Localization Not Wired"),
        ("GAP-005", "No Compilation Verification")
    ]
    
    let results = try await agent.validateGaps(gaps)
    
    let passed = results.filter { $0.status == .passed || $0.status == .testedPendingQA }
    let failed = results.filter { $0.status == .failed }
    
    print("Summary:")
    print("  Total: \(results.count)")
    print("  Passed: \(passed.count)")
    print("  Failed: \(failed.count)")
    
    // Generate report
    let reporter = TestReporter()
    let report = reporter.generateReport(results, format: .markdown)
    
    // Save to file
    let url = URL(fileURLWithPath: "gap-validation-report.md")
    try report.write(to: url, atomically: true, encoding: .utf8)
    
    print("Report saved to: \(url.path)")
}

// Example 3: Using with custom test categories
func validateWithSpecificCategories() async throws {
    let agent = TestingAgent()
    
    let result = try await agent.validateGap(
        gapID: "GAP-002",
        description: "App Icons Missing",
        testCategories: [.functional, .accessibility, .performance]
    )
    
    // Check specific status
    switch result.status {
    case .testedPendingQA:
        print("✅ Ready for QA - highly deterministic")
    case .passed:
        print("✅ Passed - adequate determinism")
    case .failed:
        print("❌ Failed - needs fixes")
    case .skipped:
        print("⏭️ Skipped")
    }
}
```

### Integration with SwiftUI App

```swift
import SwiftUI
import TestingAgent

struct GapValidationView: View {
    @State private var isValidating = false
    @State private var results: [TestingAgent.GapTestResult] = []
    @State private var error: String?
    
    var body: some View {
        VStack {
            if isValidating {
                ProgressView("Validating gaps...")
            } else {
                List(results, id: \.gapID) { result in
                    HStack {
                        statusIcon(for: result.status)
                        VStack(alignment: .leading) {
                            Text(result.gapID)
                                .font(.headline)
                            Text(result.gapDescription)
                                .font(.subheadline)
                            Text("Determinism: \(String(format: "%.1f%%", result.determinismScore * 100))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Button("Validate All Gaps") {
                    Task {
                        await validateGaps()
                    }
                }
                .disabled(isValidating)
            }
            
            if let error = error {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            }
        }
        .padding()
    }
    
    private func statusIcon(for status: TestingAgent.GapTestResult.TestStatus) -> some View {
        switch status {
        case .passed, .testedPendingQA:
            return Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        case .failed:
            return Image(systemName: "xmark.circle.fill")
                .foregroundColor(.red)
        case .skipped:
            return Image(systemName: "minus.circle.fill")
                .foregroundColor(.gray)
        }
    }
    
    private func validateGaps() async {
        isValidating = true
        error = nil
        
        do {
            let agent = TestingAgent()
            let gaps = [
                ("GAP-001", "No Xcode Project"),
                ("GAP-002", "App Icons Missing"),
                ("GAP-003", "Accessibility Identifiers Not Applied"),
                ("GAP-004", "Localization Not Wired"),
                ("GAP-005", "No Compilation Verification")
            ]
            
            results = try await agent.validateGaps(gaps)
        } catch {
            self.error = error.localizedDescription
        }
        
        isValidating = false
    }
}
```

## CI/CD Integration

### GitHub Actions Example

```yaml
# In your workflow file
- name: Validate Gaps
  run: |
    cd apps/macos-app
    swift run TestingAgentCLI --validate-all --format json > results.json
    
    # Parse results
    FAILED=$(cat results.json | grep -o '"failed":[0-9]*' | grep -o '[0-9]*')
    if [ "$FAILED" -gt "0" ]; then
      echo "❌ $FAILED gaps failed"
      exit 1
    fi
```

### GitLab CI Example

```yaml
validate-gaps:
  script:
    - cd apps/macos-app
    - swift run TestingAgentCLI --validate-all --format json | tee results.json
  artifacts:
    reports:
      junit: results.json
```

## Custom Gap Validation

### Register and Validate Custom Gap

```swift
import TestingAgent

func validateCustomGap() async throws {
    let agent = TestingAgent()
    let validator = GapValidator()
    
    // Register custom gap
    let customGap = GapValidator.Gap(
        id: "CUSTOM-001",
        description: "Custom feature validation",
        category: .functional,
        priority: .high,
        acceptanceCriteria: [
            "Feature works as expected",
            "No regressions introduced",
            "Performance meets requirements"
        ]
    )
    
    validator.registerGap(customGap)
    
    // Validate it
    let result = try await agent.validateGap(
        gapID: "CUSTOM-001",
        description: "Custom feature validation"
    )
    
    print("Custom gap status: \(result.status.rawValue)")
}
```

## CDIF Integration

### Generate CDIF-Compliant Report

```swift
func generateCDIFReport() async throws {
    let agent = TestingAgent()
    let reporter = TestReporter()
    
    let gaps = [
        ("GAP-001", "No Xcode Project"),
        ("GAP-002", "App Icons Missing")
    ]
    
    let results = try await agent.validateGaps(gaps)
    let cdifReport = reporter.generateReport(results, format: .cdif)
    
    // Save CDIF report
    let url = URL(fileURLWithPath: "cdif-report.yaml")
    try cdifReport.write(to: url, atomically: true, encoding: .utf8)
    
    print("CDIF report generated: \(url.path)")
}
```

### Apply Test Archetype

```swift
// Testing Agent automatically applies relevant archetypes
// based on gap category and test requirements

func validateWithArchetype() async throws {
    let agent = TestingAgent()
    
    // This will automatically apply:
    // - FC-002: UI Flow Validation
    // - ACC-001: Accessibility Identifier Coverage
    // - DET-001: Repeatability Validation
    let result = try await agent.validateGap(
        gapID: "GAP-003",
        description: "Accessibility Identifiers Not Applied",
        testCategories: [.functional, .accessibility, .determinism]
    )
    
    print("Archetypes applied automatically")
    print("Result: \(result.status.rawValue)")
}
```

## Troubleshooting Examples

### Example 1: Debugging Failed Gap

```swift
func debugFailedGap() async throws {
    let agent = TestingAgent()
    
    let result = try await agent.validateGap(
        gapID: "GAP-004",
        description: "Localization Not Wired"
    )
    
    if result.status == .failed {
        print("Gap failed validation")
        
        if let reason = result.failureReason {
            print("\nFailure Reason:")
            print(reason)
        }
        
        if !result.followUpGaps.isEmpty {
            print("\nFollow-up Gaps Required:")
            for gap in result.followUpGaps {
                print("  • \(gap)")
            }
        }
        
        print("\nDeterminism Score: \(result.determinismScore)")
        if result.determinismScore < 0.95 {
            print("⚠️ Tests are flaky - improve stability")
        }
    }
}
```

### Example 2: Checking Determinism

```swift
func checkTestDeterminism() async {
    let checker = DeterminismChecker()
    
    // Run test 10 times to thoroughly check stability
    let result = await checker.checkDeterminism(
        testID: "MyFlakyTest",
        runCount: 10
    ) {
        // Your test logic here
        return true // Replace with actual test
    }
    
    print("Runs: \(result.runs)")
    print("Successes: \(result.successes)")
    print("Failures: \(result.failures)")
    print("Score: \(String(format: "%.1f%%", result.score * 100))")
    print("Stable: \(result.isStable ? "Yes" : "No")")
    
    if !result.flakinessSources.isEmpty {
        print("\nFlakiness Sources Detected:")
        for source in result.flakinessSources {
            print("  • \(source.rawValue)")
        }
    }
}
```

### Example 3: Monitoring Gap Status Over Time

```swift
import Foundation

func monitorGapStatus() async throws {
    let agent = TestingAgent()
    let gaps = [
        ("GAP-001", "No Xcode Project"),
        ("GAP-002", "App Icons Missing")
    ]
    
    // Run validation periodically
    for iteration in 1...5 {
        print("\n--- Iteration \(iteration) ---")
        
        let results = try await agent.validateGaps(gaps)
        
        for result in results {
            print("\(result.gapID): \(result.status.rawValue) (Determinism: \(String(format: "%.1f%%", result.determinismScore * 100)))")
        }
        
        // Wait 1 minute between runs
        try await Task.sleep(nanoseconds: 60_000_000_000)
    }
}
```

## Advanced Scenarios

### Parallel Gap Validation

```swift
func parallelValidation() async throws {
    let agent = TestingAgent()
    
    let gaps = [
        ("GAP-001", "No Xcode Project"),
        ("GAP-002", "App Icons Missing"),
        ("GAP-003", "Accessibility Identifiers Not Applied"),
        ("GAP-004", "Localization Not Wired"),
        ("GAP-005", "No Compilation Verification")
    ]
    
    // Validate all gaps in parallel
    await withTaskGroup(of: TestingAgent.GapTestResult.self) { group in
        for (gapID, description) in gaps {
            group.addTask {
                try! await agent.validateGap(gapID: gapID, description: description)
            }
        }
        
        for await result in group {
            print("\(result.gapID): \(result.status.rawValue)")
        }
    }
}
```

### Custom Report Format

```swift
func generateCustomReport() async throws {
    let agent = TestingAgent()
    let results = try await agent.validateGaps([
        ("GAP-001", "Test Gap 1"),
        ("GAP-002", "Test Gap 2")
    ])
    
    // Create custom HTML report
    var html = """
    <!DOCTYPE html>
    <html>
    <head>
        <title>Gap Validation Report</title>
        <style>
            body { font-family: Arial, sans-serif; }
            .pass { color: green; }
            .fail { color: red; }
        </style>
    </head>
    <body>
        <h1>Gap Validation Report</h1>
    """
    
    for result in results {
        let statusClass = result.status == .passed || result.status == .testedPendingQA ? "pass" : "fail"
        html += """
        <div class="\(statusClass)">
            <h2>\(result.gapID): \(result.status.rawValue)</h2>
            <p>\(result.gapDescription)</p>
            <p>Execution Time: \(String(format: "%.2f", result.executionTime))s</p>
            <p>Determinism: \(String(format: "%.1f%%", result.determinismScore * 100))</p>
        </div>
        """
    }
    
    html += """
    </body>
    </html>
    """
    
    let url = URL(fileURLWithPath: "report.html")
    try html.write(to: url, atomically: true, encoding: .utf8)
}
```

## See Also

- [Testing Agent README](TestingAgent/README.md)
- [CDIF Test Archetypes](CDIF_TEST_ARCHETYPES.md)
- [CI/CD Integration Guide](TESTING_AGENT_CI_CD_GUIDE.md)
- [macOS QA Test Plan](steering/MACOS_QA_TEST_PLAN.md)
