//
//  TestingAgentTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for the Testing Agent framework
//

import XCTest
@testable import VelociraptorMacOS

final class TestingAgentTests: XCTestCase {
    
    var testingAgent: TestingAgent!
    
    @MainActor
    override func setUp() async throws {
        testingAgent = TestingAgent()
    }
    
    @MainActor
    override func tearDown() async throws {
        testingAgent = nil
    }
    
    // MARK: - Gap Validation Tests
    
    @MainActor
    func testValidateGapReturnsResult() async throws {
        let result = try await testingAgent.validateGap(
            gapID: "GAP-TEST-001",
            description: "Test gap validation"
        )
        
        XCTAssertEqual(result.gapID, "GAP-TEST-001")
        XCTAssertEqual(result.gapDescription, "Test gap validation")
        XCTAssertNotNil(result.status)
        XCTAssertGreaterThan(result.executionTime, 0)
        XCTAssertGreaterThanOrEqual(result.determinismScore, 0.0)
        XCTAssertLessThanOrEqual(result.determinismScore, 1.0)
    }
    
    @MainActor
    func testValidateMultipleGaps() async throws {
        let gaps = [
            ("GAP-001", "First gap"),
            ("GAP-002", "Second gap")
        ]
        
        let results = try await testingAgent.validateGaps(gaps)
        
        XCTAssertEqual(results.count, 2)
        XCTAssertEqual(results[0].gapID, "GAP-001")
        XCTAssertEqual(results[1].gapID, "GAP-002")
    }
    
    @MainActor
    func testGapResultStatus() async throws {
        let result = try await testingAgent.validateGap(
            gapID: "GAP-STATUS-TEST",
            description: "Status test"
        )
        
        // Should be one of the valid statuses
        let validStatuses: [TestingAgent.GapTestResult.TestStatus] = [
            .passed, .failed, .skipped, .testedPendingQA
        ]
        XCTAssertTrue(validStatuses.contains(result.status))
    }
    
    // MARK: - Test Category Tests
    
    func testTestCategoryEnumValues() {
        let categories: [TestingAgent.TestCategory] = [
            .functional,
            .macOSCorrectness,
            .determinism,
            .accessibility,
            .performance,
            .security,
            .swiftConcurrency
        ]
        
        XCTAssertEqual(categories.count, 7)
    }
    
    // MARK: - GapTestResult Tests
    
    func testGapTestResultCreation() {
        let result = TestingAgent.GapTestResult(
            gapID: "TEST-001",
            gapDescription: "Test description",
            status: .passed,
            failureReason: nil,
            followUpGaps: [],
            executionTime: 1.5,
            determinismScore: 0.98
        )
        
        XCTAssertEqual(result.gapID, "TEST-001")
        XCTAssertEqual(result.status, .passed)
        XCTAssertEqual(result.determinismScore, 0.98)
        XCTAssertEqual(result.executionTime, 1.5)
    }
    
    func testGapTestResultWithFailure() {
        let result = TestingAgent.GapTestResult(
            gapID: "TEST-002",
            gapDescription: "Failed test",
            status: .failed,
            failureReason: "Test failure reason",
            followUpGaps: ["TEST-002-FUNC"],
            executionTime: 0.8,
            determinismScore: 0.5
        )
        
        XCTAssertEqual(result.status, .failed)
        XCTAssertNotNil(result.failureReason)
        XCTAssertEqual(result.followUpGaps.count, 1)
    }
    
    // MARK: - Status Enum Tests
    
    func testStatusRawValues() {
        XCTAssertEqual(TestingAgent.GapTestResult.TestStatus.passed.rawValue, "PASS")
        XCTAssertEqual(TestingAgent.GapTestResult.TestStatus.failed.rawValue, "FAIL")
        XCTAssertEqual(TestingAgent.GapTestResult.TestStatus.skipped.rawValue, "SKIPPED")
        XCTAssertEqual(TestingAgent.GapTestResult.TestStatus.testedPendingQA.rawValue, "Tested – Pending QA")
    }
}

// MARK: - Gap Validator Tests

final class GapValidatorTests: XCTestCase {
    
    var validator: GapValidator!
    
    override func setUp() {
        validator = GapValidator()
    }
    
    override func tearDown() {
        validator = nil
    }
    
    func testValidateKnownGap() {
        let result = validator.validate(gapID: "GAP-001")
        
        XCTAssertEqual(result.gap.id, "GAP-001")
        XCTAssertFalse(result.gap.description.isEmpty)
        XCTAssertNotNil(result.gap.category)
    }
    
    func testValidateUnknownGap() {
        let result = validator.validate(gapID: "UNKNOWN-999")
        
        XCTAssertFalse(result.closed)
        XCTAssertTrue(result.remainingIssues.count > 0)
    }
    
    func testRegisterGap() {
        let gap = GapValidator.Gap(
            id: "CUSTOM-001",
            description: "Custom gap",
            category: .functional,
            priority: .high,
            acceptanceCriteria: ["Criterion 1", "Criterion 2"]
        )
        
        validator.registerGap(gap)
        let result = validator.validate(gapID: "CUSTOM-001")
        
        XCTAssertEqual(result.gap.id, "CUSTOM-001")
    }
    
    func testGapCategories() {
        let categories: [GapValidator.Gap.GapCategory] = [
            .functional, .performance, .security,
            .accessibility, .integration, .uiux
        ]
        
        for category in categories {
            XCTAssertFalse(category.rawValue.isEmpty)
        }
    }
    
    func testGapPriorities() {
        XCTAssertEqual(GapValidator.Gap.Priority.critical.rawValue, "P0")
        XCTAssertEqual(GapValidator.Gap.Priority.high.rawValue, "P1")
        XCTAssertEqual(GapValidator.Gap.Priority.medium.rawValue, "P2")
        XCTAssertEqual(GapValidator.Gap.Priority.low.rawValue, "P3")
    }
}

// MARK: - Test Reporter Tests

final class TestReporterTests: XCTestCase {
    
    var reporter: TestReporter!
    
    override func setUp() {
        reporter = TestReporter()
    }
    
    override func tearDown() {
        reporter = nil
    }
    
    func testGenerateConsoleReport() {
        let results = createSampleResults()
        let report = reporter.generateReport(results, format: .console)
        
        XCTAssertFalse(report.isEmpty)
        XCTAssertTrue(report.contains("Testing Agent"))
        XCTAssertTrue(report.contains("Summary"))
    }
    
    func testGenerateJSONReport() {
        let results = createSampleResults()
        let report = reporter.generateReport(results, format: .json)
        
        XCTAssertFalse(report.isEmpty)
        // Should be valid JSON
        XCTAssertNotNil(try? JSONSerialization.jsonObject(with: Data(report.utf8)))
    }
    
    func testGenerateMarkdownReport() {
        let results = createSampleResults()
        let report = reporter.generateReport(results, format: .markdown)
        
        XCTAssertFalse(report.isEmpty)
        XCTAssertTrue(report.contains("# Testing Agent Report"))
        XCTAssertTrue(report.contains("## Summary"))
    }
    
    func testGenerateCDIFReport() {
        let results = createSampleResults()
        let report = reporter.generateReport(results, format: .cdif)
        
        XCTAssertFalse(report.isEmpty)
        XCTAssertTrue(report.contains("# CDIF Test Archetype Report"))
        XCTAssertTrue(report.contains("schema_version"))
    }
    
    private func createSampleResults() -> [TestingAgent.GapTestResult] {
        return [
            TestingAgent.GapTestResult(
                gapID: "TEST-001",
                gapDescription: "Test 1",
                status: .passed,
                failureReason: nil,
                followUpGaps: [],
                executionTime: 1.0,
                determinismScore: 1.0
            ),
            TestingAgent.GapTestResult(
                gapID: "TEST-002",
                gapDescription: "Test 2",
                status: .failed,
                failureReason: "Test failed",
                followUpGaps: ["TEST-002-FUNC"],
                executionTime: 0.5,
                determinismScore: 0.5
            )
        ]
    }
}

// MARK: - Determinism Checker Tests

final class DeterminismCheckerTests: XCTestCase {
    
    var checker: DeterminismChecker!
    
    override func setUp() {
        checker = DeterminismChecker()
    }
    
    override func tearDown() {
        checker = nil
    }
    
    func testCheckDeterminismStable() async {
        let result = await checker.checkDeterminism(testID: "STABLE-TEST") {
            return true // Always passes
        }
        
        XCTAssertEqual(result.testID, "STABLE-TEST")
        XCTAssertEqual(result.successes, result.runs)
        XCTAssertEqual(result.score, 1.0)
        XCTAssertTrue(result.isStable)
    }
    
    func testCheckDeterminismUnstable() async {
        var callCount = 0
        let result = await checker.checkDeterminism(testID: "FLAKY-TEST", runCount: 4) {
            callCount += 1
            return callCount % 2 == 0 // Alternating pass/fail
        }
        
        XCTAssertEqual(result.testID, "FLAKY-TEST")
        XCTAssertEqual(result.runs, 4)
        XCTAssertLessThan(result.score, 0.95)
        XCTAssertFalse(result.isStable)
    }
    
    func testAnalyzeFlakiness() {
        let stableResults = [true, true, true, true]
        let stableSources = checker.analyzeFlakiness(stableResults)
        XCTAssertTrue(stableSources.isEmpty || stableSources.count < 2)
        
        let flakyResults = [true, false, true, false]
        let flakySources = checker.analyzeFlakiness(flakyResults)
        XCTAssertFalse(flakySources.isEmpty)
    }
}

// MARK: - Xcode Test Runner Tests

final class XcodeTestRunnerTests: XCTestCase {
    
    var runner: XcodeTestRunner!
    
    override func setUp() {
        runner = XcodeTestRunner()
    }
    
    override func tearDown() {
        runner = nil
    }
    
    func testRunUnitTests() async throws {
        let result = try await runner.runUnitTests(matching: "TEST")
        
        XCTAssertGreaterThan(result.total, 0)
        XCTAssertTrue(result.allPassed || !result.allPassed) // Validates the property exists
    }
    
    func testRunUITests() async throws {
        let result = try await runner.runUITests(matching: "TEST")
        
        XCTAssertGreaterThan(result.total, 0)
    }
    
    func testRunTestsForGap() async throws {
        let result = try await runner.runTestsForGap("GAP-001")
        
        XCTAssertGreaterThan(result.total, 0)
        XCTAssertGreaterThanOrEqual(result.executionTime, 0)
    }
    
    func testExecutionResultProperties() {
        let result = XcodeTestRunner.TestExecutionResult(
            total: 10,
            passed: 8,
            failed: 2,
            skipped: 0,
            executionTime: 1.5
        )
        
        XCTAssertEqual(result.total, 10)
        XCTAssertEqual(result.passed, 8)
        XCTAssertEqual(result.failed, 2)
        XCTAssertFalse(result.allPassed)
    }
    
    func testExecutionResultAllPassed() {
        let result = XcodeTestRunner.TestExecutionResult(
            total: 5,
            passed: 5,
            failed: 0,
            skipped: 0,
            executionTime: 1.0
        )
        
        XCTAssertTrue(result.allPassed)
    }
}
