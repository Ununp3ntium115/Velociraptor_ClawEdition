//
//  DeterminismChecker.swift
//  VelociraptorMacOS
//
//  Ensures tests are repeatable and not flaky
//

import Foundation

/// Checks test determinism and stability
public final class DeterminismChecker {
    
    // MARK: - Types
    
    /// Determinism check result
    public struct DeterminismResult {
        public let testID: String
        public let runs: Int
        public let successes: Int
        public let failures: Int
        public let score: Double // 0.0 to 1.0
        public let isStable: Bool // true if score >= 0.95
        public let flakinessSources: [FlakinessSource]
    }
    
    /// Sources of test flakiness
    public enum FlakinessSource: String {
        case timing = "Timing-dependent behavior"
        case randomData = "Random data generation"
        case networkDependency = "Network dependency"
        case racecondition = "Race condition"
        case environmentState = "Environment state dependency"
        case asyncTiming = "Async/await timing issues"
    }
    
    // MARK: - Properties
    
    private let minimumRuns = 3
    private let stabilityThreshold = 0.95
    
    // MARK: - Public Interface
    
    /// Check if a test is deterministic by running it multiple times
    /// - Parameters:
    ///   - testID: Identifier for the test
    ///   - runCount: Number of times to run the test
    ///   - testClosure: The test to execute
    /// - Returns: Determinism result with stability score
    public func checkDeterminism(
        testID: String,
        runCount: Int = 3,
        testClosure: () async throws -> Bool
    ) async -> DeterminismResult {
        print("🔄 Checking determinism for \(testID) (\(runCount) runs)...")
        
        var results: [Bool] = []
        var detectedSources: Set<FlakinessSource> = []
        
        for run in 1...runCount {
            do {
                let result = try await testClosure()
                results.append(result)
                
                // Analyze for flakiness sources
                if !result {
                    detectedSources.formUnion(analyzeFlakinessSource())
                }
            } catch {
                results.append(false)
                detectedSources.insert(.environmentState)
            }
            
            // Small delay between runs to avoid cache effects
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
        
        let successes = results.filter { $0 }.count
        let failures = results.filter { !$0 }.count
        let score = Double(successes) / Double(runCount)
        let isStable = score >= stabilityThreshold
        
        return DeterminismResult(
            testID: testID,
            runs: runCount,
            successes: successes,
            failures: failures,
            score: score,
            isStable: isStable,
            flakinessSources: Array(detectedSources)
        )
    }
    
    /// Analyze test results for common flakiness patterns
    /// - Parameter results: Array of test run results
    /// - Returns: Identified flakiness sources
    public func analyzeFlakiness(_ results: [Bool]) -> [FlakinessSource] {
        var sources: [FlakinessSource] = []
        
        // Pattern: alternating pass/fail suggests timing issues
        let alternating = zip(results.dropLast(), results.dropFirst())
            .filter { $0 != $1 }
            .count
        
        if alternating > results.count / 2 {
            sources.append(.timing)
            sources.append(.racecondition)
        }
        
        // Pattern: consistent failures suggest environment issues
        let consecutiveFailures = findLongestConsecutiveFailures(results)
        if consecutiveFailures >= 2 {
            sources.append(.environmentState)
        }
        
        // Pattern: random pass/fail suggests non-deterministic data
        let passRate = Double(results.filter { $0 }.count) / Double(results.count)
        if passRate > 0.2 && passRate < 0.8 {
            sources.append(.randomData)
        }
        
        return sources
    }
    
    // MARK: - Private Helpers
    
    private func analyzeFlakinessSource() -> Set<FlakinessSource> {
        // This would analyze the specific failure for common patterns
        // For now, return a basic set
        return []
    }
    
    private func findLongestConsecutiveFailures(_ results: [Bool]) -> Int {
        var maxConsecutive = 0
        var currentConsecutive = 0
        
        for result in results {
            if !result {
                currentConsecutive += 1
                maxConsecutive = max(maxConsecutive, currentConsecutive)
            } else {
                currentConsecutive = 0
            }
        }
        
        return maxConsecutive
    }
}
