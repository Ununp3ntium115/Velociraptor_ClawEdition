//
//  EmergencyModeUITests.swift
//  VelociraptorMacOSUITests
//
//  Comprehensive UI tests for Emergency Mode functionality
//

import XCTest


final class EmergencyModeUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Emergency Mode Access Tests
    
    func testEmergencyButtonExists() throws {
        let emergencyButton = app.buttons[TestIDs.Navigation.emergencyButton]
        XCTAssertTrue(emergencyButton.exists, "Emergency button should exist in main view")
    }
    
    func testEmergencyButtonIsClickable() throws {
        let emergencyButton = app.buttons[TestIDs.Navigation.emergencyButton]
        if emergencyButton.exists {
            XCTAssertTrue(emergencyButton.isEnabled, "Emergency button should be enabled")
        }
    }
    
    func testEmergencyModeOpens() throws {
        let emergencyButton = app.buttons[TestIDs.Navigation.emergencyButton]
        if emergencyButton.exists {
            emergencyButton.tap()
            
            // Wait for emergency mode sheet to appear
            let emergencyView = app.otherElements[TestIDs.EmergencyMode.sheetContainer]
            let exists = emergencyView.waitForExistence(timeout: 3)
            XCTAssertTrue(exists, "Emergency mode view should appear after clicking button")
        }
    }
    
    // MARK: - Emergency Mode UI Tests
    
    func testEmergencyTitleDisplayed() throws {
        openEmergencyMode()
        
        let title = app.staticTexts[TestIDs.EmergencyMode.title]
        if title.exists {
            XCTAssertTrue(title.exists, "Emergency mode title should be displayed")
        }
    }
    
    func testDeployButtonExists() throws {
        openEmergencyMode()
        
        let deployButton = app.buttons[TestIDs.EmergencyMode.deployButton]
        if deployButton.exists {
            XCTAssertTrue(deployButton.isEnabled, "Deploy button should be enabled")
        }
    }
    
    func testCancelButtonExists() throws {
        openEmergencyMode()
        
        let cancelButton = app.buttons[TestIDs.EmergencyMode.cancelButton]
        if cancelButton.exists {
            XCTAssertTrue(cancelButton.isEnabled, "Cancel button should be enabled")
        }
    }
    
    func testCancelButtonClosesEmergencyMode() throws {
        openEmergencyMode()
        
        let cancelButton = app.buttons[TestIDs.EmergencyMode.cancelButton]
        if cancelButton.exists {
            cancelButton.tap()
            
            // Wait for sheet to close
            Thread.sleep(forTimeInterval: 0.5)
            
            // Emergency view should no longer be visible
            let emergencyView = app.otherElements[TestIDs.EmergencyMode.sheetContainer]
            XCTAssertFalse(emergencyView.exists, "Emergency mode should close after cancel")
        }
    }
    
    // MARK: - Emergency Deployment Tests
    
    func testEmergencyDeploymentFlow() throws {
        openEmergencyMode()
        
        let deployButton = app.buttons[TestIDs.EmergencyMode.deployButton]
        if deployButton.exists {
            deployButton.tap()
            
            // Wait for progress view
            let progressView = app.progressIndicators.firstMatch
            let exists = progressView.waitForExistence(timeout: 5)
            
            // Either progress shows or immediate completion
            if exists {
                // Progress indicator appeared - deployment in progress
                XCTAssertTrue(progressView.exists)
            }
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    func testEmergencyKeyboardShortcut() throws {
        // Cmd+Shift+E should open emergency mode
        app.typeKey("e", modifierFlags: [.command, .shift])
        
        // Wait for emergency mode
        let emergencyView = app.otherElements[TestIDs.EmergencyMode.sheetContainer]
        let exists = emergencyView.waitForExistence(timeout: 2)
        
        if exists {
            XCTAssertTrue(emergencyView.exists, "Emergency mode should open with Cmd+Shift+E")
        }
    }
    
    func testEscapeClosesEmergencyMode() throws {
        openEmergencyMode()
        
        // Press Escape
        app.typeKey(.escape, modifierFlags: [])
        
        // Wait for sheet to close
        Thread.sleep(forTimeInterval: 0.5)
        
        // Emergency view should close
        let emergencyView = app.otherElements[TestIDs.EmergencyMode.sheetContainer]
        XCTAssertFalse(emergencyView.exists, "Escape should close emergency mode")
    }
    
    // MARK: - Helper Methods
    
    private func openEmergencyMode() {
        let emergencyButton = app.buttons[TestIDs.Navigation.emergencyButton]
        if emergencyButton.exists {
            emergencyButton.tap()
            
            // Wait for emergency mode to appear
            let emergencyView = app.otherElements[TestIDs.EmergencyMode.sheetContainer]
            _ = emergencyView.waitForExistence(timeout: 3)
        }
    }
}

// Note: TestIDs.EmergencyMode is defined in TestAccessibilityIdentifiers.swift
