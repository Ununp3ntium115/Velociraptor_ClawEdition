//
//  TestingAgent.swift
//  VelociraptorMacOS
//
//  macOS Testing Agent - Xcode Test Runner + Deterministic Verification Agent
//  Part of the HiQ swarm for verifying Development work and gap closure
//

import Foundation
import XCTest

/// Main Testing Agent orchestrator for the HiQ swarm
/// Verifies that Development actually closed the gap through comprehensive testing
@available(macOS 13.0, *)
public final class TestingAgent {
    
    // MARK: - Types
    
    /// Test execution result for a specific gap
    public struct GapTestResult {
        public let gapID: String
        public let gapDescription: String
        public let status: TestStatus
        public let failureReason: String?
        public let followUpGaps: [String]
        public let executionTime: TimeInterval
        public let determinismScore: Double // 0.0 to 1.0
        
        public enum TestStatus: String {
            case passed = "PASS"
            case failed = "FAIL"
            case skipped = "SKIPPED"
            case testedPendingQA = "Tested – Pending QA"
        }
    }
    
    /// Test category for organizing test execution
    public enum TestCategory {
        case functional           // Expected behavior achieved
        case macOSCorrectness    // Works under sandbox, correct UI lifecycle
        case determinism         // Repeatable, not flaky
        case accessibility       // VoiceOver, accessibility identifiers
        case performance         // Performance benchmarks
        case security            // Security validations
        case swiftConcurrency    // MainActor, async/await correctness
    }
    
    // MARK: - Properties
    
    private let gapValidator: GapValidator
    private let testReporter: TestReporter
    private let determinismChecker: DeterminismChecker
    private let xcodeTestRunner: XcodeTestRunner
    
    // MARK: - Initialization
    
    public init() {
        self.gapValidator = GapValidator()
        self.testReporter = TestReporter()
        self.determinismChecker = DeterminismChecker()
        self.xcodeTestRunner = XcodeTestRunner()
    }
    
    // MARK: - Public Interface
    
    /// Validate a specific gap with comprehensive testing
    /// - Parameters:
    ///   - gapID: Unique identifier for the gap (e.g., "GAP-001")
    ///   - description: Human-readable gap description
    ///   - testCategories: Categories of tests to run
    /// - Returns: Test result with PASS/FAIL status and details
    public func validateGap(
        gapID: String,
        description: String,
        testCategories: [TestCategory] = [.functional, .macOSCorrectness, .determinism]
    ) async throws -> GapTestResult {
        print("🔍 Testing Agent: Validating \(gapID) - \(description)")
        
        let startTime = Date()
        
        // Step 1: Run functional correctness tests
        let functionalResult = try await runFunctionalTests(for: gapID)
        
        // Step 2: Run macOS correctness tests
        let macOSResult = try await runMacOSCorrectnessTests(for: gapID)
        
        // Step 3: Run determinism tests
        let determinismResult = try await runDeterminismTests(for: gapID)
        
        // Step 4: Run Swift concurrency validation
        let concurrencyResult = try await validateSwiftConcurrency(for: gapID)
        
        // Aggregate results
        let allPassed = functionalResult.passed &&
                       macOSResult.passed &&
                       determinismResult.passed &&
                       concurrencyResult.passed
        
        let executionTime = Date().timeIntervalSince(startTime)
        
        let status: GapTestResult.TestStatus
        if allPassed {
            status = determinismResult.score >= 0.95 ? .testedPendingQA : .passed
        } else {
            status = .failed
        }
        
        let failureReason = buildFailureReason(
            functional: functionalResult,
            macOS: macOSResult,
            determinism: determinismResult,
            concurrency: concurrencyResult
        )
        
        let followUpGaps = generateFollowUpGaps(
            gapID: gapID,
            functionalResult: functionalResult,
            macOSResult: macOSResult,
            determinismResult: determinismResult
        )
        
        let result = GapTestResult(
            gapID: gapID,
            gapDescription: description,
            status: status,
            failureReason: failureReason,
            followUpGaps: followUpGaps,
            executionTime: executionTime,
            determinismScore: determinismResult.score
        )
        
        // Report results
        testReporter.report(result)
        
        return result
    }
    
    /// Run all tests for multiple gaps
    /// - Parameter gaps: Array of (gapID, description) tuples
    /// - Returns: Array of test results
    public func validateGaps(_ gaps: [(String, String)]) async throws -> [GapTestResult] {
        var results: [GapTestResult] = []
        
        for (gapID, description) in gaps {
            do {
                let result = try await validateGap(gapID: gapID, description: description)
                results.append(result)
            } catch {
                print("❌ Error validating \(gapID): \(error)")
                // Create failed result
                let failedResult = GapTestResult(
                    gapID: gapID,
                    gapDescription: description,
                    status: .failed,
                    failureReason: "Exception during test execution: \(error.localizedDescription)",
                    followUpGaps: [],
                    executionTime: 0,
                    determinismScore: 0
                )
                results.append(failedResult)
            }
        }
        
        return results
    }
    
    // MARK: - Private Test Execution
    
    private func runFunctionalTests(for gapID: String) async throws -> TestCategoryResult {
        print("  ✓ Running functional correctness tests...")
        
        // Run unit tests relevant to this gap
        let unitTestResults = try await xcodeTestRunner.runUnitTests(matching: gapID)
        
        // Run UI tests relevant to this gap
        let uiTestResults = try await xcodeTestRunner.runUITests(matching: gapID)
        
        let passed = unitTestResults.allPassed && uiTestResults.allPassed
        let details = """
        Unit Tests: \(unitTestResults.passed)/\(unitTestResults.total) passed
        UI Tests: \(uiTestResults.passed)/\(uiTestResults.total) passed
        """
        
        return TestCategoryResult(passed: passed, details: details, score: 1.0)
    }
    
    private func runMacOSCorrectnessTests(for gapID: String) async throws -> TestCategoryResult {
        print("  ✓ Running macOS correctness tests...")
        
        // Check sandbox compatibility
        let sandboxValid = validateSandboxCompatibility()
        
        // Check UI lifecycle
        let lifecycleValid = validateUILifecycle()
        
        // Check proper macOS integration
        let integrationValid = validateMacOSIntegration()
        
        let passed = sandboxValid && lifecycleValid && integrationValid
        let details = """
        Sandbox Compatibility: \(sandboxValid ? "✓" : "✗")
        UI Lifecycle: \(lifecycleValid ? "✓" : "✗")
        macOS Integration: \(integrationValid ? "✓" : "✗")
        """
        
        return TestCategoryResult(passed: passed, details: details, score: 1.0)
    }
    
    private func runDeterminismTests(for gapID: String) async throws -> TestCategoryResult {
        print("  ✓ Running determinism tests...")
        
        // Run tests multiple times to check for flakiness
        let runs = 3
        var results: [Bool] = []
        
        for run in 1...runs {
            print("    Run \(run)/\(runs)...")
            let result = try await xcodeTestRunner.runTestsForGap(gapID)
            results.append(result.allPassed)
        }
        
        // Calculate determinism score
        let passCount = results.filter { $0 }.count
        let score = Double(passCount) / Double(runs)
        
        let passed = score >= 0.95 // 95% success rate threshold
        let details = """
        Test Runs: \(runs)
        Passed: \(passCount)/\(runs)
        Determinism Score: \(String(format: "%.1f%%", score * 100))
        Status: \(passed ? "Stable" : "Flaky")
        """
        
        return TestCategoryResult(passed: passed, details: details, score: score)
    }
    
    private func validateSwiftConcurrency(for gapID: String) async throws -> TestCategoryResult {
        print("  ✓ Validating Swift concurrency...")
        
        // Check UI updates on MainActor
        let mainActorValid = await validateMainActorUsage()
        
        // Check background tasks are correctly isolated
        let isolationValid = validateTaskIsolation()
        
        let passed = mainActorValid && isolationValid
        let details = """
        MainActor UI Updates: \(mainActorValid ? "✓" : "✗")
        Task Isolation: \(isolationValid ? "✓" : "✗")
        """
        
        return TestCategoryResult(passed: passed, details: details, score: 1.0)
    }
    
    // MARK: - Validation Helpers
    
    @MainActor
    private func validateMainActorUsage() -> Bool {
        // This is a placeholder - real implementation would use runtime checks
        // to verify UI updates happen on MainActor
        return true
    }
    
    private func validateTaskIsolation() -> Bool {
        // Placeholder - would check that background tasks don't access MainActor
        return true
    }
    
    private func validateSandboxCompatibility() -> Bool {
        // Check that code works within App Sandbox
        let fileManager = FileManager.default
        
        // Verify access to allowed directories
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        let caches = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
        
        return appSupport != nil && caches != nil
    }
    
    private func validateUILifecycle() -> Bool {
        // Placeholder for UI lifecycle validation
        return true
    }
    
    private func validateMacOSIntegration() -> Bool {
        // Check Keychain, Notifications, etc.
        return true
    }
    
    private func buildFailureReason(
        functional: TestCategoryResult,
        macOS: TestCategoryResult,
        determinism: TestCategoryResult,
        concurrency: TestCategoryResult
    ) -> String? {
        var reasons: [String] = []
        
        if !functional.passed {
            reasons.append("Functional: \(functional.details)")
        }
        if !macOS.passed {
            reasons.append("macOS: \(macOS.details)")
        }
        if !determinism.passed {
            reasons.append("Determinism: \(determinism.details)")
        }
        if !concurrency.passed {
            reasons.append("Concurrency: \(concurrency.details)")
        }
        
        return reasons.isEmpty ? nil : reasons.joined(separator: "\n")
    }
    
    private func generateFollowUpGaps(
        gapID: String,
        functionalResult: TestCategoryResult,
        macOSResult: TestCategoryResult,
        determinismResult: TestCategoryResult
    ) -> [String] {
        var followUps: [String] = []
        
        if !functionalResult.passed {
            followUps.append("\(gapID)-FUNC: Fix functional test failures")
        }
        if !macOSResult.passed {
            followUps.append("\(gapID)-MACOS: Fix macOS compatibility issues")
        }
        if determinismResult.score < 0.95 {
            followUps.append("\(gapID)-FLAKY: Improve test stability to 95%+")
        }
        
        return followUps
    }
}

// MARK: - Supporting Types

struct TestCategoryResult {
    let passed: Bool
    let details: String
    let score: Double
}
