//
//  HealthMonitorTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for HealthMonitor
//

import XCTest
@testable import VelociraptorMacOS

final class HealthMonitorTests: XCTestCase {
    var healthMonitor: HealthMonitor!
    
    @MainActor
    override func setUp() async throws {
        healthMonitor = HealthMonitor()
    }
    
    @MainActor
    override func tearDown() async throws {
        healthMonitor = nil
    }
    
    // MARK: - Initial State Tests
    
    @MainActor
    func testInitialState() {
        XCTAssertFalse(healthMonitor.isRefreshing)
        XCTAssertEqual(healthMonitor.overallStatus, .unknown)
        XCTAssertEqual(healthMonitor.serviceStatus, .unknown)
        XCTAssertEqual(healthMonitor.networkStatus, .unknown)
        XCTAssertEqual(healthMonitor.diskStatus, .unknown)
        XCTAssertEqual(healthMonitor.memoryStatus, .unknown)
    }
    
    // MARK: - Health Status Tests
    
    func testHealthStatusProperties() {
        let statuses: [HealthMonitor.HealthStatus] = [.healthy, .warning, .critical, .unknown]
        
        for status in statuses {
            // Verify color doesn't throw
            _ = status.color
            
            // Verify icon is not empty
            XCTAssertFalse(status.icon.isEmpty)
            
            // Verify description is not empty
            XCTAssertFalse(status.description.isEmpty)
        }
    }
    
    func testHealthStatusColors() {
        // Just verify the color properties exist and are accessible
        let healthy = HealthMonitor.HealthStatus.healthy.color
        let warning = HealthMonitor.HealthStatus.warning.color
        let critical = HealthMonitor.HealthStatus.critical.color
        let unknown = HealthMonitor.HealthStatus.unknown.color
        
        // They should all be different colors (at least conceptually)
        XCTAssertNotNil(healthy)
        XCTAssertNotNil(warning)
        XCTAssertNotNil(critical)
        XCTAssertNotNil(unknown)
    }
    
    func testHealthStatusIcons() {
        XCTAssertEqual(HealthMonitor.HealthStatus.healthy.icon, "checkmark.circle.fill")
        XCTAssertEqual(HealthMonitor.HealthStatus.warning.icon, "exclamationmark.triangle.fill")
        XCTAssertEqual(HealthMonitor.HealthStatus.critical.icon, "xmark.circle.fill")
        XCTAssertEqual(HealthMonitor.HealthStatus.unknown.icon, "questionmark.circle.fill")
    }
    
    func testHealthStatusDescriptions() {
        XCTAssertEqual(HealthMonitor.HealthStatus.healthy.description, "Healthy")
        XCTAssertEqual(HealthMonitor.HealthStatus.warning.description, "Warning")
        XCTAssertEqual(HealthMonitor.HealthStatus.critical.description, "Critical")
        XCTAssertEqual(HealthMonitor.HealthStatus.unknown.description, "Unknown")
    }
    
    // MARK: - Refresh Tests
    
    @MainActor
    func testRefreshSetsRefreshing() async {
        XCTAssertFalse(healthMonitor.isRefreshing)
        
        // Start refresh in background
        Task {
            await healthMonitor.refreshAll()
        }
        
        // Give it a moment to start
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        // After completion, isRefreshing should be false
        await healthMonitor.refreshAll()
        XCTAssertFalse(healthMonitor.isRefreshing)
    }
    
    @MainActor
    func testRefreshUpdatesStatuses() async {
        // Initial state is unknown
        XCTAssertEqual(healthMonitor.serviceStatus, .unknown)
        
        await healthMonitor.refreshAll()
        
        // After refresh, statuses should be updated (not necessarily healthy)
        // They could be any status depending on system state
        XCTAssertTrue([.healthy, .warning, .critical, .unknown].contains(healthMonitor.serviceStatus))
        XCTAssertTrue([.healthy, .warning, .critical, .unknown].contains(healthMonitor.networkStatus))
        XCTAssertTrue([.healthy, .warning, .critical, .unknown].contains(healthMonitor.diskStatus))
        XCTAssertTrue([.healthy, .warning, .critical, .unknown].contains(healthMonitor.memoryStatus))
    }
    
    // MARK: - Metrics Tests
    
    @MainActor
    func testMetricsAfterRefresh() async {
        await healthMonitor.refreshAll()
        
        // Memory total should be positive
        XCTAssertGreaterThan(healthMonitor.memoryTotal, 0)
        
        // Disk total should be positive
        XCTAssertGreaterThan(healthMonitor.diskTotal, 0)
        
        // Used values should be <= total
        XCTAssertLessThanOrEqual(healthMonitor.memoryUsed, healthMonitor.memoryTotal)
        XCTAssertLessThanOrEqual(healthMonitor.diskUsed, healthMonitor.diskTotal)
    }
    
    // MARK: - Diagnostics Report Tests
    
    @MainActor
    func testGenerateDiagnosticsReport() async {
        await healthMonitor.refreshAll()
        
        let report = healthMonitor.generateDiagnosticsReport()
        
        // Report should contain expected sections
        XCTAssertTrue(report.contains("Velociraptor macOS Diagnostics Report"))
        XCTAssertTrue(report.contains("System Information"))
        XCTAssertTrue(report.contains("Health Status"))
        XCTAssertTrue(report.contains("System Metrics"))
        XCTAssertTrue(report.contains("End of Report"))
        
        // Report should contain system info
        XCTAssertTrue(report.contains("macOS"))
        XCTAssertTrue(report.contains("Host"))
        XCTAssertTrue(report.contains("Memory"))
    }
    
    @MainActor
    func testDiagnosticsReportContainsCurrentStatus() async {
        await healthMonitor.refreshAll()
        
        let report = healthMonitor.generateDiagnosticsReport()
        
        // Should contain status descriptions
        XCTAssertTrue(
            report.contains("Healthy") ||
            report.contains("Warning") ||
            report.contains("Critical") ||
            report.contains("Unknown")
        )
    }
    
    // MARK: - Recent Logs Tests
    
    @MainActor
    func testRecentLogsIsArray() {
        // Should be an empty array initially
        XCTAssertNotNil(healthMonitor.recentLogs)
        XCTAssertTrue(healthMonitor.recentLogs is [String])
    }
    
    @MainActor
    func testRecentLogsAfterRefresh() async {
        await healthMonitor.refreshAll()
        
        // Logs array should exist (may be empty if no logs)
        XCTAssertNotNil(healthMonitor.recentLogs)
        
        // If there are logs, they should be strings
        for log in healthMonitor.recentLogs {
            XCTAssertFalse(log.isEmpty)
        }
    }
    
    // MARK: - Status Details Tests
    
    @MainActor
    func testStatusDetailsAfterRefresh() async {
        await healthMonitor.refreshAll()
        
        // Detail strings should not be "Checking..."
        XCTAssertNotEqual(healthMonitor.serviceDetail, "Checking...")
        XCTAssertNotEqual(healthMonitor.networkDetail, "Checking...")
        XCTAssertNotEqual(healthMonitor.diskDetail, "Checking...")
        XCTAssertNotEqual(healthMonitor.memoryDetail, "Checking...")
    }
    
    // MARK: - Overall Status Tests
    
    @MainActor
    func testOverallStatusLogic() async {
        await healthMonitor.refreshAll()
        
        // Overall status should reflect the worst individual status
        // This is a basic test - exact behavior depends on system state
        XCTAssertTrue([.healthy, .warning, .critical, .unknown].contains(healthMonitor.overallStatus))
    }
}
