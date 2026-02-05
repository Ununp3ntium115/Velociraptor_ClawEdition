//
//  IncidentResponseViewModelTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for IncidentResponseViewModel
//

import XCTest
@testable import Velociraptor

final class IncidentResponseViewModelTests: XCTestCase {
    var viewModel: IncidentResponseViewModel!
    
    @MainActor
    override func setUp() async throws {
        viewModel = IncidentResponseViewModel()
    }
    
    @MainActor
    override func tearDown() async throws {
        viewModel = nil
    }
    
    // MARK: - Initial State Tests
    
    @MainActor
    func testInitialState() {
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertNil(viewModel.selectedIncident)
        XCTAssertFalse(viewModel.isBuilding)
        XCTAssertEqual(viewModel.buildProgress, 0.0)
        XCTAssertTrue(viewModel.buildStatus.isEmpty)
        XCTAssertNil(viewModel.lastError)
    }
    
    // MARK: - Category Tests
    
    func testAllCategoriesExist() {
        let categories = IncidentResponseViewModel.IncidentCategory.allCases
        
        XCTAssertEqual(categories.count, 7)
        XCTAssertTrue(categories.contains(.malwareRansomware))
        XCTAssertTrue(categories.contains(.apt))
        XCTAssertTrue(categories.contains(.insider))
        XCTAssertTrue(categories.contains(.network))
        XCTAssertTrue(categories.contains(.dataBreach))
        XCTAssertTrue(categories.contains(.industrial))
        XCTAssertTrue(categories.contains(.emerging))
    }
    
    func testCategoryProperties() {
        for category in IncidentResponseViewModel.IncidentCategory.allCases {
            XCTAssertFalse(category.rawValue.isEmpty)
            XCTAssertFalse(category.emoji.isEmpty)
            XCTAssertGreaterThan(category.scenarioCount, 0)
        }
    }
    
    // MARK: - Incident Filtering Tests
    
    @MainActor
    func testFilteredIncidentsEmpty() {
        // No category selected
        XCTAssertTrue(viewModel.filteredIncidents.isEmpty)
    }
    
    @MainActor
    func testFilteredIncidentsForCategory() {
        viewModel.selectedCategory = .malwareRansomware
        
        let filtered = viewModel.filteredIncidents
        
        XCTAssertFalse(filtered.isEmpty)
        XCTAssertTrue(filtered.allSatisfy { $0.category == .malwareRansomware })
    }
    
    // MARK: - Incident Tests
    
    @MainActor
    func testAllIncidentsHaveProperties() {
        for incident in viewModel.allIncidents {
            XCTAssertFalse(incident.name.isEmpty)
            XCTAssertFalse(incident.description.isEmpty)
            XCTAssertFalse(incident.artifacts.isEmpty)
        }
    }
    
    func testIncidentPriorityColors() {
        let priorities: [IncidentResponseViewModel.IncidentScenario.Priority] = [.critical, .high, .medium, .low]
        
        for priority in priorities {
            // Just verify color doesn't throw
            _ = priority.color
            XCTAssertFalse(priority.rawValue.isEmpty)
        }
    }
    
    func testIncidentResponseTimes() {
        let times: [IncidentResponseViewModel.IncidentScenario.ResponseTime] = [.immediate, .rapid, .standard, .extended]
        
        for time in times {
            XCTAssertFalse(time.rawValue.isEmpty)
        }
    }
    
    // MARK: - Collector Configuration Tests
    
    func testDefaultCollectorConfiguration() {
        let config = IncidentResponseViewModel.CollectorConfiguration()
        
        XCTAssertFalse(config.deploymentPath.isEmpty)
        XCTAssertTrue(config.offlineMode)
        XCTAssertTrue(config.portablePackage)
        XCTAssertFalse(config.encryptPackage)
        XCTAssertTrue(config.includeTools)
        XCTAssertTrue(config.compressOutput)
    }
    
    func testDefaultDeploymentPath() {
        let path = IncidentResponseViewModel.CollectorConfiguration.defaultDeploymentPath
        
        XCTAssertTrue(path.contains("VelociraptorCollectors"))
    }
    
    // MARK: - Build Collector Tests
    
    @MainActor
    func testBuildCollectorRequiresIncident() async {
        // No incident selected
        viewModel.selectedIncident = nil
        
        do {
            try await viewModel.buildCollector()
            XCTFail("Should throw error when no incident selected")
        } catch {
            XCTAssertTrue(error is IncidentResponseViewModel.CollectorError)
            if let collectorError = error as? IncidentResponseViewModel.CollectorError {
                if case .noIncidentSelected = collectorError {
                    // Expected
                } else {
                    XCTFail("Wrong error type")
                }
            }
        }
    }
    
    @MainActor
    func testBuildCollectorWithSelectedIncident() async {
        // Select an incident
        viewModel.selectedCategory = .malwareRansomware
        viewModel.selectedIncident = viewModel.allIncidents.first { $0.category == .malwareRansomware }
        
        // Set a temp path
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).path
        viewModel.collectorConfig.deploymentPath = tempDir
        
        do {
            try await viewModel.buildCollector()
            
            // Verify progress reached 1.0
            XCTAssertEqual(viewModel.buildProgress, 1.0, accuracy: 0.01)
            XCTAssertFalse(viewModel.buildStatus.isEmpty)
            
            // Clean up
            try? FileManager.default.removeItem(atPath: tempDir)
        } catch {
            XCTFail("Build should succeed: \(error)")
        }
    }
    
    // MARK: - Reset Tests
    
    @MainActor
    func testReset() {
        // Set some state
        viewModel.selectedCategory = .apt
        viewModel.selectedIncident = viewModel.allIncidents.first
        viewModel.buildProgress = 0.5
        viewModel.buildStatus = "Some status"
        
        // Reset
        viewModel.reset()
        
        // Verify reset
        XCTAssertNil(viewModel.selectedCategory)
        XCTAssertNil(viewModel.selectedIncident)
        XCTAssertEqual(viewModel.buildProgress, 0.0)
        XCTAssertTrue(viewModel.buildStatus.isEmpty)
        XCTAssertNil(viewModel.lastError)
    }
    
    // MARK: - Error Tests
    
    func testCollectorErrorDescriptions() {
        let errors: [IncidentResponseViewModel.CollectorError] = [
            .noIncidentSelected,
            .buildFailed("Test message")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Incident Hashable Tests
    
    @MainActor
    func testIncidentHashable() {
        guard let incident1 = viewModel.allIncidents.first,
              let incident2 = viewModel.allIncidents.dropFirst().first else {
            XCTFail("Need at least 2 incidents")
            return
        }
        
        // Same incident should be equal to itself
        XCTAssertEqual(incident1, incident1)
        
        // Different incidents should not be equal
        XCTAssertNotEqual(incident1, incident2)
    }
}
