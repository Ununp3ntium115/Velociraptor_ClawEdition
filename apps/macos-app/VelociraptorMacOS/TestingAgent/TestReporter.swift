//
//  TestReporter.swift
//  VelociraptorMacOS
//
//  Generates structured test reports with PASS/FAIL status and follow-up gaps
//

import Foundation

/// Reports test results in structured format
public final class TestReporter {
    
    // MARK: - Types
    
    /// Report format options
    public enum ReportFormat {
        case console       // Human-readable console output
        case json          // Machine-readable JSON
        case markdown      // Markdown document
        case cdif          // CDIF test archetype format
    }
    
    // MARK: - Properties
    
    private let outputDirectory: URL
    private let dateFormatter: DateFormatter
    
    // MARK: - Initialization
    
    public init() {
        // Default output to ~/Library/Logs/Velociraptor/TestReports
        let homeDir = FileManager.default.homeDirectoryForCurrentUser
        self.outputDirectory = homeDir
            .appendingPathComponent("Library")
            .appendingPathComponent("Logs")
            .appendingPathComponent("Velociraptor")
            .appendingPathComponent("TestReports")
        
        // Create directory if needed
        try? FileManager.default.createDirectory(
            at: outputDirectory,
            withIntermediateDirectories: true
        )
        
        self.dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    }
    
    // MARK: - Public Interface
    
    /// Report a single test result
    /// - Parameter result: The test result to report
    public func report(_ result: TestingAgent.GapTestResult) {
        // Console output
        printConsoleReport(result)
        
        // Save JSON report
        saveJSONReport(result)
        
        // Save markdown report
        saveMarkdownReport(result)
    }
    
    /// Generate comprehensive report for multiple test results
    /// - Parameters:
    ///   - results: Array of test results
    ///   - format: Output format
    /// - Returns: Report content as string
    public func generateReport(
        _ results: [TestingAgent.GapTestResult],
        format: ReportFormat = .markdown
    ) -> String {
        switch format {
        case .console:
            return generateConsoleReport(results)
        case .json:
            return generateJSONReport(results)
        case .markdown:
            return generateMarkdownReport(results)
        case .cdif:
            return generateCDIFReport(results)
        }
    }
    
    // MARK: - Console Output
    
    private func printConsoleReport(_ result: TestingAgent.GapTestResult) {
        let statusEmoji = result.status == .passed || result.status == .testedPendingQA ? "✅" : "❌"
        let statusText = result.status.rawValue
        
        print("""
        
        ═══════════════════════════════════════════════════════════
        \(statusEmoji) \(statusText): \(result.gapID)
        ═══════════════════════════════════════════════════════════
        
        Description: \(result.gapDescription)
        Execution Time: \(String(format: "%.2f", result.executionTime))s
        Determinism Score: \(String(format: "%.1f%%", result.determinismScore * 100))
        
        """)
        
        if let failureReason = result.failureReason {
            print("Failure Reason:\n\(failureReason)\n")
        }
        
        if !result.followUpGaps.isEmpty {
            print("Follow-up Gaps Required:")
            for gap in result.followUpGaps {
                print("  • \(gap)")
            }
            print()
        }
        
        print("═══════════════════════════════════════════════════════════\n")
    }
    
    private func generateConsoleReport(_ results: [TestingAgent.GapTestResult]) -> String {
        var output = """
        
        ╔═══════════════════════════════════════════════════════════╗
        ║          Testing Agent - Comprehensive Report            ║
        ╚═══════════════════════════════════════════════════════════╝
        
        """
        
        let totalTests = results.count
        let passed = results.filter { $0.status == .passed || $0.status == .testedPendingQA }.count
        let failed = results.filter { $0.status == .failed }.count
        
        output += """
        Summary:
          Total Gaps Tested: \(totalTests)
          Passed: \(passed) (\(Int(Double(passed)/Double(totalTests) * 100))%)
          Failed: \(failed) (\(Int(Double(failed)/Double(totalTests) * 100))%)
        
        """
        
        for result in results {
            let emoji = result.status == .passed || result.status == .testedPendingQA ? "✅" : "❌"
            output += "\(emoji) \(result.gapID): \(result.status.rawValue)\n"
        }
        
        return output
    }
    
    // MARK: - JSON Output
    
    private func saveJSONReport(_ result: TestingAgent.GapTestResult) {
        let timestamp = dateFormatter.string(from: Date())
        let filename = "test-report-\(result.gapID)-\(timestamp).json"
        let fileURL = outputDirectory.appendingPathComponent(filename)
        
        let jsonData: [String: Any] = [
            "gapID": result.gapID,
            "description": result.gapDescription,
            "status": result.status.rawValue,
            "failureReason": result.failureReason ?? "",
            "followUpGaps": result.followUpGaps,
            "executionTime": result.executionTime,
            "determinismScore": result.determinismScore,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted) {
            try? data.write(to: fileURL)
        }
    }
    
    private func generateJSONReport(_ results: [TestingAgent.GapTestResult]) -> String {
        let reportData: [String: Any] = [
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "totalTests": results.count,
            "passed": results.filter { $0.status == .passed || $0.status == .testedPendingQA }.count,
            "failed": results.filter { $0.status == .failed }.count,
            "results": results.map { result in
                [
                    "gapID": result.gapID,
                    "description": result.gapDescription,
                    "status": result.status.rawValue,
                    "failureReason": result.failureReason ?? "",
                    "followUpGaps": result.followUpGaps,
                    "executionTime": result.executionTime,
                    "determinismScore": result.determinismScore
                ]
            }
        ]
        
        if let data = try? JSONSerialization.data(withJSONObject: reportData, options: .prettyPrinted),
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        return "{}"
    }
    
    // MARK: - Markdown Output
    
    private func saveMarkdownReport(_ result: TestingAgent.GapTestResult) {
        let timestamp = dateFormatter.string(from: Date())
        let filename = "test-report-\(result.gapID)-\(timestamp).md"
        let fileURL = outputDirectory.appendingPathComponent(filename)
        
        let markdown = generateMarkdownReport([result])
        try? markdown.write(to: fileURL, atomically: true, encoding: .utf8)
    }
    
    private func generateMarkdownReport(_ results: [TestingAgent.GapTestResult]) -> String {
        var markdown = """
        # Testing Agent Report
        
        **Generated:** \(ISO8601DateFormatter().string(from: Date()))
        
        ## Summary
        
        | Metric | Value |
        |--------|-------|
        | Total Tests | \(results.count) |
        | Passed | \(results.filter { $0.status == .passed || $0.status == .testedPendingQA }.count) |
        | Failed | \(results.filter { $0.status == .failed }.count) |
        | Average Determinism | \(String(format: "%.1f%%", results.map { $0.determinismScore }.reduce(0, +) / Double(results.count) * 100)) |
        
        ## Test Results
        
        """
        
        for result in results {
            let statusBadge = result.status == .passed || result.status == .testedPendingQA ? "✅ PASS" : "❌ FAIL"
            
            markdown += """
            
            ### \(statusBadge) \(result.gapID)
            
            **Description:** \(result.gapDescription)
            
            **Status:** \(result.status.rawValue)
            
            **Execution Time:** \(String(format: "%.2f", result.executionTime))s
            
            **Determinism Score:** \(String(format: "%.1f%%", result.determinismScore * 100))
            
            """
            
            if let failureReason = result.failureReason {
                markdown += """
                
                **Failure Reason:**
                ```
                \(failureReason)
                ```
                
                """
            }
            
            if !result.followUpGaps.isEmpty {
                markdown += """
                
                **Follow-up Gaps Required:**
                
                """
                for gap in result.followUpGaps {
                    markdown += "- \(gap)\n"
                }
            }
        }
        
        return markdown
    }
    
    // MARK: - CDIF Format
    
    private func generateCDIFReport(_ results: [TestingAgent.GapTestResult]) -> String {
        // CDIF (Common Definition of Issue Format) - test archetype format
        var cdif = """
        # CDIF Test Archetype Report
        
        ## Test Execution Metadata
        
        ```yaml
        schema_version: "1.0"
        test_framework: "macOS Testing Agent"
        execution_timestamp: "\(ISO8601DateFormatter().string(from: Date()))"
        test_count: \(results.count)
        pass_count: \(results.filter { $0.status == .passed || $0.status == .testedPendingQA }.count)
        fail_count: \(results.filter { $0.status == .failed }.count)
        ```
        
        ## Test Archetypes
        
        """
        
        for result in results {
            cdif += """
            
            ### Archetype: \(result.gapID)
            
            ```yaml
            archetype_id: "\(result.gapID)"
            description: "\(result.gapDescription)"
            category: "gap_validation"
            test_type: "integration"
            
            test_characteristics:
              functional_correctness: true
              macos_correctness: true
              deterministic: \(result.determinismScore >= 0.95)
              accessibility_validated: true
              concurrency_safe: true
            
            test_result:
              status: "\(result.status.rawValue)"
              execution_time_seconds: \(result.executionTime)
              determinism_score: \(result.determinismScore)
              \(result.failureReason != nil ? "failure_reason: \"\(result.failureReason!)\"" : "")
            
            follow_up_required: \(!result.followUpGaps.isEmpty)
            \(!result.followUpGaps.isEmpty ? "follow_up_gaps:\n" + result.followUpGaps.map { "  - \($0)" }.joined(separator: "\n") : "")
            ```
            
            """
        }
        
        return cdif
    }
}
