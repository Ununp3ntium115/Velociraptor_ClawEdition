//
//  TestingAgentCLI.swift
//  VelociraptorMacOS
//
//  Command-line interface for the Testing Agent
//

import Foundation

/// Command-line interface for the Testing Agent
/// Note: Not the main entry point - use VelociraptorMacOSApp instead
struct TestingAgentCLI {
    /// Run the CLI agent with provided arguments
    @MainActor
    static func run() async {
        print("""
        ╔═══════════════════════════════════════════════════════════╗
        ║          macOS Testing Agent - HiQ Swarm                  ║
        ║          Xcode Test Runner + Deterministic Verification   ║
        ╚═══════════════════════════════════════════════════════════╝
        
        """)
        
        let args = CommandLine.arguments
        
        // Parse arguments
        var validateAll = false
        var specificGap: String?
        var format: TestReporter.ReportFormat = .console
        var runs = 3
        
        var i = 1
        while i < args.count {
            switch args[i] {
            case "--validate-all":
                validateAll = true
            case "--gap":
                if i + 1 < args.count {
                    specificGap = args[i + 1]
                    i += 1
                }
            case "--format":
                if i + 1 < args.count {
                    switch args[i + 1] {
                    case "json":
                        format = .json
                    case "markdown", "md":
                        format = .markdown
                    case "cdif":
                        format = .cdif
                    default:
                        format = .console
                    }
                    i += 1
                }
            case "--runs":
                if i + 1 < args.count, let runCount = Int(args[i + 1]) {
                    runs = runCount
                    i += 1
                }
            case "--help", "-h":
                printHelp()
                return
            default:
                break
            }
            i += 1
        }
        
        let agent = TestingAgent()
        
        do {
            var results: [TestingAgent.GapTestResult] = []
            
            if validateAll {
                // Validate all known gaps
                let gaps = [
                    ("GAP-001", "No Xcode Project"),
                    ("GAP-002", "App Icons Missing"),
                    ("GAP-003", "Accessibility Identifiers Not Applied"),
                    ("GAP-004", "Localization Not Wired"),
                    ("GAP-005", "No Compilation Verification")
                ]
                
                results = try await agent.validateGaps(gaps)
            } else if let gapID = specificGap {
                let result = try await agent.validateGap(
                    gapID: gapID,
                    description: "Gap \(gapID) validation"
                )
                results = [result]
            } else {
                printHelp()
                return
            }
            
            // Generate report in requested format
            let reporter = TestReporter()
            let report = reporter.generateReport(results, format: format)
            print(report)
            
            // Summary
            let passed = results.filter { $0.status == .passed || $0.status == .testedPendingQA }.count
            let total = results.count
            
            if passed == total {
                print("\n✅ All \(total) gap(s) validated successfully!")
                exit(0)
            } else {
                print("\n❌ \(total - passed) of \(total) gap(s) failed validation")
                exit(1)
            }
            
        } catch {
            print("\n❌ Error: \(error)")
            exit(1)
        }
    }
    
    static func printHelp() {
        print("""
        Usage: TestingAgentCLI [OPTIONS]
        
        Options:
          --validate-all          Validate all known gaps
          --gap GAP-ID            Validate specific gap (e.g., GAP-001)
          --format FORMAT         Output format: console, json, markdown, cdif
          --runs N                Number of determinism test runs (default: 3)
          --help, -h              Show this help message
        
        Examples:
          # Validate all gaps
          TestingAgentCLI --validate-all
          
          # Validate specific gap with JSON output
          TestingAgentCLI --gap GAP-003 --format json
          
          # Validate with CDIF format
          TestingAgentCLI --validate-all --format cdif
          
          # Run with 5 determinism checks
          TestingAgentCLI --gap GAP-001 --runs 5
        
        Gap Validation:
          The Testing Agent validates that Development work properly closes gaps by:
          • Running functional correctness tests
          • Validating macOS platform integration
          • Checking test determinism (repeatability)
          • Validating Swift concurrency patterns
          • Ensuring accessibility requirements
        
        Output Status:
          PASS                  - Tests passed, adequate determinism
          Tested – Pending QA   - Tests passed, high determinism (≥95%)
          FAIL                  - One or more test categories failed
          SKIPPED               - Test validation skipped
        
        Reports Location:
          ~/Library/Logs/Velociraptor/TestReports/
        
        For more information, see:
          VelociraptorMacOS/TestingAgent/README.md
          CDIF_TEST_ARCHETYPES.md
        """)
    }
}
