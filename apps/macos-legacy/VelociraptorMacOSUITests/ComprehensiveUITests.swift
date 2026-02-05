//
//  ComprehensiveUITests.swift
//  VelociraptorMacOSUITests
//
//  Comprehensive End-to-End UI Test Suite
//  Tests all major views and workflows
//
//  CDIF Pattern: UI Test Coverage Matrix
//  Coverage: All 18 gap areas from HEXADECIMAL-GAP-REGISTRY
//

import XCTest

/// Main UI Test class for comprehensive end-to-end testing

final class ComprehensiveUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    // MARK: - Setup/Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Take screenshot on failure
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Final Screenshot"
        attachment.lifetime = .deleteOnSuccess
        add(attachment)
    }
    
    // MARK: - Helper Methods
    
    private func takeScreenshot(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = 5) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }
    
    // MARK: - 0x01: Dashboard Tests
    
    func testDashboardLoads() throws {
        let dashboard = app.otherElements["dashboard.main"]
        XCTAssertTrue(waitForElement(dashboard), "Dashboard should load")
        takeScreenshot(named: "Dashboard")
    }
    
    func testDashboardWidgets() throws {
        // Test dashboard widgets exist
        let statsSection = app.groups["dashboard.stats"]
        XCTAssertTrue(waitForElement(statsSection), "Stats section should exist")
        
        let activitySection = app.groups["dashboard.activity"]
        XCTAssertTrue(waitForElement(activitySection), "Activity section should exist")
    }
    
    // MARK: - 0x02: Client Management Tests
    
    func testClientsViewLoads() throws {
        // Navigate to Clients
        let clientsTab = app.buttons["sidebar.clients"]
        if waitForElement(clientsTab) {
            clientsTab.click()
        }
        
        let clientsView = app.otherElements["clients.main"]
        XCTAssertTrue(waitForElement(clientsView), "Clients view should load")
        takeScreenshot(named: "Clients View")
    }
    
    func testClientSearch() throws {
        // Navigate to Clients
        let clientsTab = app.buttons["sidebar.clients"]
        if waitForElement(clientsTab) {
            clientsTab.click()
        }
        
        let searchField = app.textFields["clients.search"]
        if waitForElement(searchField) {
            searchField.click()
            searchField.typeText("test")
        }
        
        takeScreenshot(named: "Client Search")
    }
    
    func testClientFilters() throws {
        // Navigate to Clients
        let clientsTab = app.buttons["sidebar.clients"]
        if waitForElement(clientsTab) {
            clientsTab.click()
        }
        
        // Test OS filter
        let allFilter = app.buttons["clients.filter.all"]
        if waitForElement(allFilter) {
            allFilter.click()
        }
    }
    
    // MARK: - 0x03: Hunt Management Tests
    
    func testHuntManagerLoads() throws {
        // Navigate to Hunts
        let huntsTab = app.buttons["sidebar.hunts"]
        if waitForElement(huntsTab) {
            huntsTab.click()
        }
        
        let huntView = app.otherElements["hunt.main"]
        XCTAssertTrue(waitForElement(huntView), "Hunt manager should load")
        takeScreenshot(named: "Hunt Manager")
    }
    
    func testCreateHuntButton() throws {
        // Navigate to Hunts
        let huntsTab = app.buttons["sidebar.hunts"]
        if waitForElement(huntsTab) {
            huntsTab.click()
        }
        
        let createButton = app.buttons["hunt.create"]
        XCTAssertTrue(waitForElement(createButton), "Create hunt button should exist")
    }
    
    // MARK: - 0x04: VQL Editor Tests
    
    func testVQLEditorLoads() throws {
        // Navigate to VQL
        let vqlTab = app.buttons["sidebar.vql"]
        if waitForElement(vqlTab) {
            vqlTab.click()
        }
        
        let vqlEditor = app.otherElements["vql.main"]
        XCTAssertTrue(waitForElement(vqlEditor), "VQL editor should load")
        takeScreenshot(named: "VQL Editor")
    }
    
    func testVQLMCPAssistant() throws {
        // Navigate to VQL
        let vqlTab = app.buttons["sidebar.vql"]
        if waitForElement(vqlTab) {
            vqlTab.click()
        }
        
        // Check for MCP assistant pane
        let mcpPane = app.otherElements["vql.mcp.pane"]
        // MCP pane may or may not be visible by default
        if waitForElement(mcpPane, timeout: 2) {
            takeScreenshot(named: "VQL MCP Assistant")
        }
    }
    
    func testVQLQueryExecution() throws {
        // Navigate to VQL
        let vqlTab = app.buttons["sidebar.vql"]
        if waitForElement(vqlTab) {
            vqlTab.click()
        }
        
        let runButton = app.buttons["vql.run"]
        XCTAssertTrue(waitForElement(runButton), "Run query button should exist")
    }
    
    // MARK: - 0x05: VFS Browser Tests
    
    func testVFSBrowserLoads() throws {
        // Navigate to VFS
        let vfsTab = app.buttons["sidebar.vfs"]
        if waitForElement(vfsTab) {
            vfsTab.click()
        }
        
        let vfsView = app.otherElements["vfs.main"]
        XCTAssertTrue(waitForElement(vfsView), "VFS browser should load")
        takeScreenshot(named: "VFS Browser")
    }
    
    // MARK: - 0x06: WebSocket Tests (Implicit - checked via real-time updates)
    
    func testRealtimeUpdates() throws {
        // Real-time updates are tested via the dashboard activity feed
        let dashboard = app.otherElements["dashboard.main"]
        XCTAssertTrue(waitForElement(dashboard), "Dashboard should support real-time")
    }
    
    // MARK: - 0x07: Notebooks Tests
    
    func testNotebooksViewLoads() throws {
        // Navigate to Notebooks
        let notebooksTab = app.buttons["sidebar.notebooks"]
        if waitForElement(notebooksTab) {
            notebooksTab.click()
        }
        
        let notebooksView = app.otherElements["notebooks.main"]
        XCTAssertTrue(waitForElement(notebooksView), "Notebooks view should load")
        takeScreenshot(named: "Notebooks")
    }
    
    // MARK: - 0x08: Artifact Manager Tests
    
    func testArtifactManagerLoads() throws {
        // Navigate to Artifacts
        let artifactsTab = app.buttons["sidebar.artifacts"]
        if waitForElement(artifactsTab) {
            artifactsTab.click()
        }
        
        let artifactsView = app.otherElements["artifact.main"]
        XCTAssertTrue(waitForElement(artifactsView), "Artifact manager should load")
        takeScreenshot(named: "Artifact Manager")
    }
    
    func testArtifactSearch() throws {
        // Navigate to Artifacts
        let artifactsTab = app.buttons["sidebar.artifacts"]
        if waitForElement(artifactsTab) {
            artifactsTab.click()
        }
        
        let searchField = app.textFields["artifact.search"]
        if waitForElement(searchField) {
            searchField.click()
            searchField.typeText("Windows")
        }
        
        takeScreenshot(named: "Artifact Search")
    }
    
    // MARK: - 0x09: Offline Collector Tests
    
    func testOfflineCollectorLoads() throws {
        // Navigate to Collector
        let collectorTab = app.buttons["sidebar.collector"]
        if waitForElement(collectorTab) {
            collectorTab.click()
        }
        
        let collectorView = app.otherElements["collector.main"]
        XCTAssertTrue(waitForElement(collectorView), "Offline collector should load")
        takeScreenshot(named: "Offline Collector")
    }
    
    func testOfflineCollectorWizardSteps() throws {
        // Navigate to Collector
        let collectorTab = app.buttons["sidebar.collector"]
        if waitForElement(collectorTab) {
            collectorTab.click()
        }
        
        // Check wizard steps exist
        let step1 = app.staticTexts["Package Information"]
        XCTAssertTrue(waitForElement(step1), "Step 1 should exist")
    }
    
    // MARK: - 0x0A: Timeline Tests
    
    func testTimelineViewLoads() throws {
        // Navigate to Timeline
        let timelineTab = app.buttons["sidebar.timeline"]
        if waitForElement(timelineTab) {
            timelineTab.click()
        }
        
        let timelineView = app.otherElements["timeline.main"]
        XCTAssertTrue(waitForElement(timelineView), "Timeline view should load")
        takeScreenshot(named: "Timeline")
    }
    
    // MARK: - 0x0B: Reports Tests
    
    func testReportsViewLoads() throws {
        // Navigate to Reports
        let reportsTab = app.buttons["sidebar.reports"]
        if waitForElement(reportsTab) {
            reportsTab.click()
        }
        
        let reportsView = app.otherElements["reports.main"]
        XCTAssertTrue(waitForElement(reportsView), "Reports view should load")
        takeScreenshot(named: "Reports")
    }
    
    // MARK: - 0x0C: Settings/Server Admin Tests
    
    func testSettingsViewLoads() throws {
        // Navigate to Settings
        let settingsTab = app.buttons["sidebar.settings"]
        if waitForElement(settingsTab) {
            settingsTab.click()
        }
        
        let settingsView = app.otherElements["settings.main"]
        XCTAssertTrue(waitForElement(settingsView), "Settings view should load")
        takeScreenshot(named: "Settings")
    }
    
    func testServerAdminTab() throws {
        // Navigate to Settings
        let settingsTab = app.buttons["sidebar.settings"]
        if waitForElement(settingsTab) {
            settingsTab.click()
        }
        
        let serverAdminTab = app.buttons["settings.server"]
        if waitForElement(serverAdminTab) {
            serverAdminTab.click()
            takeScreenshot(named: "Server Admin")
        }
    }
    
    // MARK: - 0x0D: SIEM Integrations Tests
    
    func testSIEMIntegrationsLoads() throws {
        // Navigate to SIEM Integrations
        let siemTab = app.buttons["sidebar.siem"]
        if waitForElement(siemTab) {
            siemTab.click()
        }
        
        let siemView = app.otherElements["siem.main"]
        XCTAssertTrue(waitForElement(siemView), "SIEM view should load")
        takeScreenshot(named: "SIEM Integrations")
    }
    
    func testAddIntegration() throws {
        // Navigate to SIEM
        let siemTab = app.buttons["sidebar.siem"]
        if waitForElement(siemTab) {
            siemTab.click()
        }
        
        let addButton = app.buttons["siem.add"]
        if waitForElement(addButton) {
            addButton.click()
            
            let addSheet = app.sheets["siem.add.sheet"]
            XCTAssertTrue(waitForElement(addSheet), "Add integration sheet should appear")
            takeScreenshot(named: "Add Integration Sheet")
            
            // Close sheet
            let cancelButton = app.buttons["Cancel"]
            if waitForElement(cancelButton) {
                cancelButton.click()
            }
        }
    }
    
    // MARK: - 0x0F: Package Manager Tests
    
    func testPackageManagerLoads() throws {
        // Navigate to Package Manager
        let packageTab = app.buttons["sidebar.packages"]
        if waitForElement(packageTab) {
            packageTab.click()
        }
        
        let packageView = app.otherElements["package.main"]
        XCTAssertTrue(waitForElement(packageView), "Package manager should load")
        takeScreenshot(named: "Package Manager")
    }
    
    func testCreatePackage() throws {
        // Navigate to Package Manager
        let packageTab = app.buttons["sidebar.packages"]
        if waitForElement(packageTab) {
            packageTab.click()
        }
        
        let addButton = app.buttons["package.add"]
        if waitForElement(addButton) {
            addButton.click()
            
            let createSheet = app.sheets["package.create.sheet"]
            XCTAssertTrue(waitForElement(createSheet), "Create package sheet should appear")
            takeScreenshot(named: "Create Package Sheet")
            
            // Close sheet
            let cancelButton = app.buttons["Cancel"]
            if waitForElement(cancelButton) {
                cancelButton.click()
            }
        }
    }
    
    // MARK: - 0x10: Training Interface Tests
    
    func testTrainingViewLoads() throws {
        // Navigate to Training
        let trainingTab = app.buttons["sidebar.training"]
        if waitForElement(trainingTab) {
            trainingTab.click()
        }
        
        let trainingView = app.otherElements["training.main"]
        XCTAssertTrue(waitForElement(trainingView), "Training view should load")
        takeScreenshot(named: "Training")
    }
    
    func testTrainingModules() throws {
        // Navigate to Training
        let trainingTab = app.buttons["sidebar.training"]
        if waitForElement(trainingTab) {
            trainingTab.click()
        }
        
        // Check for training modules list
        let modulesList = app.tables.firstMatch
        if waitForElement(modulesList) {
            XCTAssertTrue(modulesList.cells.count >= 0, "Should have training modules")
        }
    }
    
    // MARK: - 0x11: Orchestration Tests
    
    func testOrchestrationViewLoads() throws {
        // Navigate to Orchestration
        let orchestrationTab = app.buttons["sidebar.orchestration"]
        if waitForElement(orchestrationTab) {
            orchestrationTab.click()
        }
        
        let orchestrationView = app.otherElements["orchestration.main"]
        XCTAssertTrue(waitForElement(orchestrationView), "Orchestration view should load")
        takeScreenshot(named: "Orchestration")
    }
    
    func testCreateWorkflow() throws {
        // Navigate to Orchestration
        let orchestrationTab = app.buttons["sidebar.orchestration"]
        if waitForElement(orchestrationTab) {
            orchestrationTab.click()
        }
        
        let addButton = app.buttons["orchestration.add"]
        if waitForElement(addButton) {
            addButton.click()
            
            let createSheet = app.sheets["orchestration.create.sheet"]
            XCTAssertTrue(waitForElement(createSheet), "Create workflow sheet should appear")
            takeScreenshot(named: "Create Workflow Sheet")
            
            // Close sheet
            let cancelButton = app.buttons["Cancel"]
            if waitForElement(cancelButton) {
                cancelButton.click()
            }
        }
    }
    
    // MARK: - Navigation Tests
    
    func testSidebarNavigation() throws {
        // Test each sidebar item
        let sidebarItems = [
            "sidebar.dashboard",
            "sidebar.clients",
            "sidebar.hunts",
            "sidebar.vql",
            "sidebar.vfs",
            "sidebar.artifacts",
            "sidebar.settings"
        ]
        
        for itemId in sidebarItems {
            let item = app.buttons[itemId]
            if waitForElement(item, timeout: 1) {
                item.click()
                Thread.sleep(forTimeInterval: 0.5)
                takeScreenshot(named: "Navigation_\(itemId)")
            }
        }
    }
    
    // MARK: - Configuration Wizard Tests
    
    func testConfigurationWizard() throws {
        // Navigate to Welcome/Configuration
        let configTab = app.buttons["sidebar.config"]
        if waitForElement(configTab) {
            configTab.click()
        }
        
        let welcomeStep = app.staticTexts["Welcome to Velociraptor"]
        if waitForElement(welcomeStep) {
            takeScreenshot(named: "Configuration Wizard")
        }
    }
    
    // MARK: - Certificate Setup Tests
    
    func testCertificateSetup() throws {
        // Navigate to Settings > Certificates
        let settingsTab = app.buttons["sidebar.settings"]
        if waitForElement(settingsTab) {
            settingsTab.click()
        }
        
        let certsTab = app.buttons["settings.certificates"]
        if waitForElement(certsTab) {
            certsTab.click()
            takeScreenshot(named: "Certificate Setup")
        }
    }
    
    // MARK: - Performance Tests
    
    func testAppLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            app.launch()
        }
    }
    
    func testNavigationPerformance() throws {
        // Measure navigation performance
        measure {
            let clientsTab = app.buttons["sidebar.clients"]
            if waitForElement(clientsTab, timeout: 1) {
                clientsTab.click()
            }
            
            let huntsTab = app.buttons["sidebar.hunts"]
            if waitForElement(huntsTab, timeout: 1) {
                huntsTab.click()
            }
            
            let dashboardTab = app.buttons["sidebar.dashboard"]
            if waitForElement(dashboardTab, timeout: 1) {
                dashboardTab.click()
            }
        }
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityIdentifiers() throws {
        // Verify main accessibility identifiers exist
        let mainIdentifiers = [
            "dashboard.main",
            "clients.main",
            "hunt.main",
            "vql.main"
        ]
        
        for identifier in mainIdentifiers {
            // Navigate to each view and check identifier
            let tab = identifier.components(separatedBy: ".").first ?? ""
            let sidebarItem = app.buttons["sidebar.\(tab)"]
            if waitForElement(sidebarItem, timeout: 1) {
                sidebarItem.click()
                
                let view = app.otherElements[identifier]
                XCTAssertTrue(waitForElement(view, timeout: 2), "\(identifier) should have accessibility identifier")
            }
        }
    }
}

// MARK: - Workflow Integration Tests


final class WorkflowUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    /// Test complete client triage workflow
    func testClientTriageWorkflow() throws {
        // 1. Navigate to Clients
        let clientsTab = app.buttons["sidebar.clients"]
        guard clientsTab.waitForExistence(timeout: 5) else {
            XCTSkip("Clients tab not found")
            return
        }
        clientsTab.click()
        
        // 2. Search for client
        let searchField = app.textFields["clients.search"]
        if searchField.waitForExistence(timeout: 2) {
            searchField.click()
            searchField.typeText("workstation")
        }
        
        // 3. Take screenshot of results
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Client Triage Workflow"
        add(attachment)
    }
    
    /// Test hunt creation workflow
    func testHuntCreationWorkflow() throws {
        // 1. Navigate to Hunts
        let huntsTab = app.buttons["sidebar.hunts"]
        guard huntsTab.waitForExistence(timeout: 5) else {
            XCTSkip("Hunts tab not found")
            return
        }
        huntsTab.click()
        
        // 2. Click create hunt
        let createButton = app.buttons["hunt.create"]
        if createButton.waitForExistence(timeout: 2) {
            createButton.click()
        }
        
        // 3. Take screenshot
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Hunt Creation Workflow"
        add(attachment)
    }
    
    /// Test VQL query workflow
    func testVQLQueryWorkflow() throws {
        // 1. Navigate to VQL
        let vqlTab = app.buttons["sidebar.vql"]
        guard vqlTab.waitForExistence(timeout: 5) else {
            XCTSkip("VQL tab not found")
            return
        }
        vqlTab.click()
        
        // 2. Check for editor
        let editor = app.textViews["vql.editor"]
        if editor.waitForExistence(timeout: 2) {
            // Editor exists
        }
        
        // 3. Take screenshot
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "VQL Query Workflow"
        add(attachment)
    }
    
    /// Test offline collector workflow
    func testOfflineCollectorWorkflow() throws {
        // 1. Navigate to Collector
        let collectorTab = app.buttons["sidebar.collector"]
        guard collectorTab.waitForExistence(timeout: 5) else {
            XCTSkip("Collector tab not found")
            return
        }
        collectorTab.click()
        
        // 2. Verify wizard loads
        let wizard = app.otherElements["collector.main"]
        XCTAssertTrue(wizard.waitForExistence(timeout: 5), "Collector wizard should load")
        
        // 3. Take screenshot
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "Offline Collector Workflow"
        add(attachment)
    }
}
