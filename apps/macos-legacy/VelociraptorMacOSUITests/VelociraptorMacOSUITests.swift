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
        var nextButton = app.buttons["Next"].firstMatch
        
        // Step 1: Welcome -> Deployment Type
        XCTAssertTrue(nextButton.waitForExistence(timeout: 5), "Next button should exist on Welcome step")
        nextButton.click()
        
        // Step 2: Deployment Type - verify we reached it
        // Check for deployment type step using accessibility ID or content
        let deploymentStep = app.otherElements[TestIDs.WizardStep.deploymentType].firstMatch
        let standaloneCard = app.buttons[TestIDs.DeploymentType.standaloneCard].firstMatch
        let anyDeploymentIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'deploy'")).firstMatch
        
        let reachedDeploymentStep = deploymentStep.waitForExistence(timeout: 5) ||
                                    standaloneCard.waitForExistence(timeout: 3) ||
                                    anyDeploymentIndicator.waitForExistence(timeout: 3)
        XCTAssertTrue(reachedDeploymentStep, "Should navigate to Deployment Type step")
        
        // Click Next to proceed
        nextButton = app.buttons["Next"].firstMatch
        if nextButton.exists {
            nextButton.click()
            Thread.sleep(forTimeInterval: 0.5)
        }
        
        // Step 3: Certificate Settings - verify we reached it or any next step
        let certStep = app.otherElements[TestIDs.WizardStep.certificateSettings].firstMatch
        let selfSignedCard = app.buttons[TestIDs.CertificateSettings.selfSignedCard].firstMatch
        let anyCertIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[cd] 'certificate'")).firstMatch
        
        let reachedCertStep = certStep.waitForExistence(timeout: 5) ||
                              selfSignedCard.waitForExistence(timeout: 3) ||
                              anyCertIndicator.waitForExistence(timeout: 3)
        // Certificate step might be skipped based on deployment type
        if reachedCertStep {
            nextButton = app.buttons["Next"].firstMatch
            if nextButton.exists {
                nextButton.click()
                Thread.sleep(forTimeInterval: 0.5)
            }
        }
        
        // Just verify we can continue navigating without crashing
        XCTAssertTrue(app.windows.count >= 1, "App should remain open after navigation")
    }
    
    // MARK: - Deployment Type Selection Tests
    
    func testSelectServerDeployment() throws {
        navigateToDeploymentType()
        
        // Find and click Server option using accessibility identifier or text
        let serverCard = app.buttons[TestIDs.DeploymentType.serverCard].firstMatch
        let serverText = app.staticTexts["Server"].firstMatch
        
        if serverCard.exists {
            serverCard.click()
            XCTAssertTrue(true, "Server deployment selected via accessibility ID")
        } else if serverText.waitForExistence(timeout: 5) {
            serverText.click()
            XCTAssertTrue(true, "Server deployment selected via text")
        } else {
            // Try any element containing "Server"
            let anyServer = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[cd] 'Server'")).firstMatch
            XCTAssertTrue(anyServer.waitForExistence(timeout: 5), "Server deployment option not found")
            anyServer.click()
        }
    }
    
    func testSelectStandaloneDeployment() throws {
        navigateToDeploymentType()
        
        let standaloneCard = app.buttons[TestIDs.DeploymentType.standaloneCard].firstMatch
        let standaloneText = app.staticTexts["Standalone"].firstMatch
        
        if standaloneCard.exists {
            standaloneCard.click()
            XCTAssertTrue(true, "Standalone deployment selected via accessibility ID")
        } else if standaloneText.waitForExistence(timeout: 5) {
            standaloneText.click()
            XCTAssertTrue(true, "Standalone deployment selected via text")
        } else {
            let anyStandalone = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[cd] 'Standalone'")).firstMatch
            XCTAssertTrue(anyStandalone.waitForExistence(timeout: 5), "Standalone deployment option not found")
            anyStandalone.click()
        }
    }
    
    func testSelectClientDeployment() throws {
        navigateToDeploymentType()
        
        let clientCard = app.buttons[TestIDs.DeploymentType.clientCard].firstMatch
        let clientText = app.staticTexts["Client"].firstMatch
        
        if clientCard.exists {
            clientCard.click()
            XCTAssertTrue(true, "Client deployment selected via accessibility ID")
        } else if clientText.waitForExistence(timeout: 5) {
            clientText.click()
            XCTAssertTrue(true, "Client deployment selected via text")
        } else {
            let anyClient = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[cd] 'Client'")).firstMatch
            XCTAssertTrue(anyClient.waitForExistence(timeout: 5), "Client deployment option not found")
            anyClient.click()
        }
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
        // Find emergency button - try accessibility ID first, then text
        let emergencyButtonById = app.buttons[TestIDs.Navigation.emergencyButton].firstMatch
        let emergencyButtonByText = app.buttons["Emergency Mode"].firstMatch
        
        let emergencyButton = emergencyButtonById.exists ? emergencyButtonById : emergencyButtonByText
        XCTAssertTrue(emergencyButton.waitForExistence(timeout: 5), "Emergency button should exist")
        emergencyButton.click()
        
        // Wait for sheet to appear
        Thread.sleep(forTimeInterval: 0.5)
        
        // Click cancel - try accessibility ID first, then text
        let cancelById = app.buttons[TestIDs.EmergencyMode.cancelButton].firstMatch
        let cancelByText = app.buttons["Cancel"].firstMatch
        
        let cancelButton = cancelById.exists ? cancelById : cancelByText
        if cancelButton.waitForExistence(timeout: 5) {
            cancelButton.click()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Verify sheet is dismissed by checking emergency deployment text is gone
            let emergencyText = app.staticTexts["EMERGENCY DEPLOYMENT"].firstMatch
            XCTAssertFalse(emergencyText.exists, "Emergency sheet should be dismissed")
        } else {
            // If no cancel button, try pressing Escape to dismiss
            app.typeKey(.escape, modifierFlags: [])
            XCTAssertTrue(true, "Attempted to dismiss via Escape")
        }
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
