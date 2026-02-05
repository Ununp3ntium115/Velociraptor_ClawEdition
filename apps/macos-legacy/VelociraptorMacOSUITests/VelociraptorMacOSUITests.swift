//
//  VelociraptorMacOSUITests.swift
//  VelociraptorMacOSUITests
//
//  UI tests for the Velociraptor macOS application
//

import XCTest


final class VelociraptorMacOSUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app.terminate()
    }
    
    // MARK: - Launch Tests
    
    func testAppLaunch() throws {
        // Verify app launches successfully
        XCTAssertTrue(app.windows.count >= 1)
    }
    
    func testMainWindowTitle() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
    }
    
    // MARK: - Welcome Step Tests
    
    func testWelcomeStepDisplays() throws {
        // Verify welcome content is displayed
        XCTAssertTrue(app.staticTexts["Welcome to the Velociraptor Configuration Wizard"].waitForExistence(timeout: 5))
    }
    
    func testWelcomeStepHasNextButton() throws {
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        XCTAssertTrue(nextButton.isEnabled)
    }
    
    func testEmergencyModeButton() throws {
        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 5))
    }
    
    // MARK: - Navigation Tests
    
    func testNextButtonNavigatesToDeploymentType() throws {
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        nextButton.click()
        
        // Verify we're on deployment type step
        XCTAssertTrue(app.staticTexts["Choose how you want to deploy Velociraptor:"].waitForExistence(timeout: 5))
    }
    
    func testBackButtonNavigatesBack() throws {
        // Go to deployment type step
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        nextButton.click()
        
        // Click back
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.click()
        
        // Verify we're back on welcome
        XCTAssertTrue(app.staticTexts["Welcome to the Velociraptor Configuration Wizard"].waitForExistence(timeout: 5))
    }
    
    func testCanNavigateThroughAllSteps() throws {
        var nextButton = app.buttons["Next"]
        
        // Step 1: Welcome -> Deployment Type
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        nextButton.click()
        
        // Step 2: Deployment Type (select Standalone)
        // The first deployment type card should be clickable
        XCTAssertTrue(app.staticTexts["Standalone"].waitForExistence(timeout: 5))
        nextButton = app.buttons["Next"]
        nextButton.click()
        
        // Step 3: Certificate Settings
        XCTAssertTrue(app.staticTexts["Self-Signed Certificate"].waitForExistence(timeout: 5))
        nextButton = app.buttons["Next"]
        nextButton.click()
        
        // Step 4: Security Settings
        XCTAssertTrue(app.staticTexts["Environment"].waitForExistence(timeout: 5))
        nextButton = app.buttons["Next"]
        nextButton.click()
        
        // Step 5: Storage Configuration
        XCTAssertTrue(app.staticTexts["Datastore Directory"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Deployment Type Selection Tests
    
    func testSelectServerDeployment() throws {
        navigateToDeploymentType()
        
        // Find and click Server option
        let serverText = app.staticTexts["Server"]
        XCTAssertTrue(serverText.waitForExistence(timeout: 5))
        serverText.click()
    }
    
    func testSelectStandaloneDeployment() throws {
        navigateToDeploymentType()
        
        let standaloneText = app.staticTexts["Standalone"]
        XCTAssertTrue(standaloneText.waitForExistence(timeout: 5))
        standaloneText.click()
    }
    
    func testSelectClientDeployment() throws {
        navigateToDeploymentType()
        
        let clientText = app.staticTexts["Client"]
        XCTAssertTrue(clientText.waitForExistence(timeout: 5))
        clientText.click()
    }
    
    // MARK: - Emergency Mode Tests
    
    func testEmergencyModeOpensSheet() throws {
        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 5))
        emergencyButton.click()
        
        // Verify emergency mode sheet appears
        XCTAssertTrue(app.staticTexts["EMERGENCY DEPLOYMENT"].waitForExistence(timeout: 5))
    }
    
    func testEmergencyModeCanBeCancelled() throws {
        let emergencyButton = app.buttons["Emergency Mode"]
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 5))
        emergencyButton.click()
        
        // Click cancel
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.click()
        
        // Verify sheet is dismissed
        XCTAssertFalse(app.staticTexts["EMERGENCY DEPLOYMENT"].exists)
    }
    
    // MARK: - Sidebar Navigation Tests
    
    func testSidebarShowsAllSteps() throws {
        // Verify sidebar contains all wizard steps
        let sidebar = app.outlines.firstMatch
        XCTAssertTrue(sidebar.exists)
        
        XCTAssertTrue(app.staticTexts["Welcome"].exists)
        XCTAssertTrue(app.staticTexts["Deployment Type"].exists)
        XCTAssertTrue(app.staticTexts["Certificate Settings"].exists)
    }
    
    // MARK: - Text Field Tests
    
    func testUsernameFieldInAuthentication() throws {
        navigateToAuthentication()
        
        let usernameField = app.textFields["admin"]
        XCTAssertTrue(usernameField.waitForExistence(timeout: 5))
    }
    
    func testPasswordFieldInAuthentication() throws {
        navigateToAuthentication()
        
        // Secure fields are used for passwords
        let passwordField = app.secureTextFields["Password"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
    }
    
    // MARK: - Menu Tests
    
    func testFileMenuExists() throws {
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.exists)
        
        menuBar.menuBarItems["File"].click()
        XCTAssertTrue(app.menuItems["New Configuration"].waitForExistence(timeout: 5))
    }
    
    func testHelpMenuExists() throws {
        let menuBar = app.menuBars.firstMatch
        XCTAssertTrue(menuBar.exists)
        
        menuBar.menuBarItems["Help"].click()
        XCTAssertTrue(app.menuItems["Velociraptor Help"].waitForExistence(timeout: 5))
    }
    
    // MARK: - Accessibility Tests
    
    func testMainWindowHasAccessibilityTitle() throws {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists)
        XCTAssertNotNil(window.title)
    }
    
    func testButtonsHaveAccessibilityLabels() throws {
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5))
        XCTAssertNotNil(nextButton.label)
    }
    
    // MARK: - Performance Tests
    
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, *) {
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToDeploymentType() {
        let nextButton = app.buttons["Next"]
        _ = nextButton.waitForExistence(timeout: 5)
        nextButton.click()
    }
    
    private func navigateToAuthentication() {
        // Navigate through all steps to get to authentication
        for _ in 0..<6 {
            let nextButton = app.buttons["Next"]
            if nextButton.waitForExistence(timeout: 2) && nextButton.isEnabled {
                nextButton.click()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
    }
}

// Note: IncidentResponseUITests and SettingsUITests are defined in their own files
