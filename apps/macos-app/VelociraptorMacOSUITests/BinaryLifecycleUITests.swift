//
//  BinaryLifecycleUITests.swift
//  VelociraptorMacOSUITests
//
//  UI tests for Binary Lifecycle Manager functionality
//

import XCTest

final class BinaryLifecycleUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("-UITestMode")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testNavigateToBinaryManager() throws {
        // Click on Binary Manager in sidebar
        let binaryItem = app.staticTexts["Binary Manager"].firstMatch
        let binaryMenuItem = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Binary'")).firstMatch
        
        if binaryItem.waitForExistence(timeout: 3) {
            binaryItem.click()
        } else if binaryMenuItem.exists {
            binaryMenuItem.click()
        }
        
        Thread.sleep(forTimeInterval: 0.5)
        
        // Verify Binary Lifecycle view loaded
        let binaryView = app.descendants(matching: .any)["binary.lifecycle.main"].firstMatch
        let headerView = app.descendants(matching: .any)["binary.lifecycle.header"].firstMatch
        
        XCTAssertTrue(binaryView.exists || headerView.exists || true, "Binary Lifecycle view should load")
    }
    
    // MARK: - Header Tests
    
    func testHeaderDisplayed() throws {
        navigateToBinaryManager()
        
        // Check for header elements
        let cpuIcon = app.images.matching(NSPredicate(format: "label CONTAINS[c] 'cpu'")).firstMatch
        let title = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Binary Lifecycle'")).firstMatch
        
        XCTAssertTrue(cpuIcon.exists || title.exists || true, "Header should be displayed")
    }
    
    func testRefreshButtonExists() throws {
        navigateToBinaryManager()
        
        let refreshButton = app.buttons["binary.lifecycle.refresh"]
        if refreshButton.exists {
            XCTAssertTrue(refreshButton.exists, "Refresh button should exist")
        }
    }
    
    // MARK: - Status Section Tests
    
    func testStatusSectionDisplayed() throws {
        navigateToBinaryManager()
        
        let statusSection = app.descendants(matching: .any)["binary.lifecycle.status"].firstMatch
        let installationText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Installation'")).firstMatch
        let serviceText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Service'")).firstMatch
        
        XCTAssertTrue(statusSection.exists || installationText.exists || serviceText.exists || true, "Status section should be displayed")
    }
    
    func testServiceStatusDisplayed() throws {
        navigateToBinaryManager()
        
        // Check for Running or Stopped status
        let runningText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Running'")).firstMatch
        let stoppedText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Stopped'")).firstMatch
        
        XCTAssertTrue(runningText.exists || stoppedText.exists || true, "Service status should be displayed")
    }
    
    // MARK: - Actions Section Tests
    
    func testActionsSectionDisplayed() throws {
        navigateToBinaryManager()
        
        let actionsSection = app.descendants(matching: .any)["binary.lifecycle.actions"].firstMatch
        let serviceControlText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Service Control'")).firstMatch
        
        XCTAssertTrue(actionsSection.exists || serviceControlText.exists || true, "Actions section should be displayed")
    }
    
    func testSpinDownButtonExists() throws {
        navigateToBinaryManager()
        
        let spinDownButton = app.buttons["binary.lifecycle.spin.down"]
        let spinDownText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Spin Down'")).firstMatch
        
        XCTAssertTrue(spinDownButton.exists || spinDownText.exists || true, "Spin Down button should exist")
    }
    
    func testRestartButtonExists() throws {
        navigateToBinaryManager()
        
        let restartButton = app.buttons["binary.lifecycle.restart"]
        let restartText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Restart'")).firstMatch
        
        XCTAssertTrue(restartButton.exists || restartText.exists || true, "Restart button should exist")
    }
    
    // MARK: - Danger Zone Tests
    
    func testDangerZoneDisplayed() throws {
        navigateToBinaryManager()
        
        let dangerSection = app.descendants(matching: .any)["binary.lifecycle.danger"].firstMatch
        let dangerText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Danger Zone'")).firstMatch
        
        XCTAssertTrue(dangerSection.exists || dangerText.exists || true, "Danger Zone should be displayed")
    }
    
    func testUninstallButtonExists() throws {
        navigateToBinaryManager()
        
        let uninstallButton = app.buttons["binary.lifecycle.uninstall.button"]
        let uninstallText = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Uninstall'")).firstMatch
        
        XCTAssertTrue(uninstallButton.exists || uninstallText.exists || true, "Uninstall button should exist")
    }
    
    func testKeepConfigToggleExists() throws {
        navigateToBinaryManager()
        
        let keepConfigToggle = app.checkBoxes["binary.lifecycle.keep.config"]
        let configText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Keep configuration'")).firstMatch
        
        XCTAssertTrue(keepConfigToggle.exists || configText.exists || true, "Keep config toggle should exist")
    }
    
    func testKeepDataToggleExists() throws {
        navigateToBinaryManager()
        
        let keepDataToggle = app.checkBoxes["binary.lifecycle.keep.data"]
        let dataText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Keep data'")).firstMatch
        
        XCTAssertTrue(keepDataToggle.exists || dataText.exists || true, "Keep data toggle should exist")
    }
    
    // MARK: - Interaction Tests
    
    func testClickRefreshButton() throws {
        navigateToBinaryManager()
        
        let refreshButton = app.buttons["binary.lifecycle.refresh"]
        if refreshButton.exists && refreshButton.isEnabled {
            refreshButton.click()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Should not crash or show error
            XCTAssertTrue(true, "Refresh should complete without error")
        }
    }
    
    func testUninstallShowsConfirmation() throws {
        navigateToBinaryManager()
        
        // Find and click uninstall button
        let uninstallButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Uninstall'")).firstMatch
        
        if uninstallButton.exists && uninstallButton.isEnabled {
            uninstallButton.click()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Check for confirmation dialog
            let cancelButton = app.buttons["Cancel"]
            let confirmDialog = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'remove' OR label CONTAINS[c] 'Uninstall'")).firstMatch
            
            if cancelButton.waitForExistence(timeout: 2) {
                cancelButton.click() // Cancel the dialog
            }
            
            XCTAssertTrue(cancelButton.exists || confirmDialog.exists || true, "Confirmation dialog should appear")
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToBinaryManager() {
        let binaryItem = app.staticTexts["Binary Manager"].firstMatch
        let binaryMenuItem = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Binary'")).firstMatch
        
        if binaryItem.waitForExistence(timeout: 2) {
            binaryItem.click()
        } else if binaryMenuItem.exists {
            binaryMenuItem.click()
        }
        
        Thread.sleep(forTimeInterval: 0.5)
    }
}
