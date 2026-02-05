//
//  ConfigurationWizardUITests.swift
//  VelociraptorMacOSUITests
//
//  Comprehensive UI tests for the Configuration Wizard
//  Tests all wizard steps using accessibility identifiers
//

import XCTest

/// Configuration Wizard UI Tests using proper accessibility identifiers

final class ConfigurationWizardUITests: XCTestCase {
    
    var app: XCUIApplication!
    var evidencePath: URL!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Create evidence directory
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        evidencePath = FileManager.default.temporaryDirectory
            .appendingPathComponent("test-evidence")
            .appendingPathComponent(timestamp)
        try? FileManager.default.createDirectory(at: evidencePath, withIntermediateDirectories: true)
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        // Capture screenshot on failure
        if testRun?.hasSucceeded == false {
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "failure-\(name)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
        app.terminate()
    }
    
    // MARK: - Certificate Settings Tests
    
    func testCertificateSettingsStep() throws {
        navigateToStep(2) // Certificate is step 3 (0-indexed: 2)
        
        // Verify we're on certificate step
        let stepView = app.otherElements[TestIDs.WizardStep.certificateSettings]
        XCTAssertTrue(stepView.waitForExistence(timeout: 5), "Certificate settings step should be visible")
        
        takeScreenshot(name: "certificate-settings-initial")
    }
    
    func testSelectSelfSignedCertificate() throws {
        navigateToStep(2)
        
        let selfSignedCard = app.buttons[TestIDs.CertificateSettings.selfSignedCard]
        if selfSignedCard.waitForExistence(timeout: 5) {
            selfSignedCard.click()
            takeScreenshot(name: "certificate-self-signed-selected")
        }
        
        // Verify expiration picker is visible
        let expirationPicker = app.popUpButtons[TestIDs.CertificateSettings.expirationPicker]
        XCTAssertTrue(expirationPicker.waitForExistence(timeout: 5), "Expiration picker should appear")
    }
    
    func testSelectCustomCertificate() throws {
        navigateToStep(2)
        
        // Click custom certificate option
        let customCard = app.buttons[TestIDs.CertificateSettings.customCard]
        if customCard.waitForExistence(timeout: 5) {
            customCard.click()
            takeScreenshot(name: "certificate-custom-selected")
        }
        
        // Verify certificate path field appears
        let certPathField = app.textFields[TestIDs.CertificateSettings.certPathField]
        XCTAssertTrue(certPathField.waitForExistence(timeout: 5), "Certificate path field should appear")
        
        let keyPathField = app.textFields[TestIDs.CertificateSettings.keyPathField]
        XCTAssertTrue(keyPathField.waitForExistence(timeout: 5), "Key path field should appear")
    }
    
    func testSelectLetsEncrypt() throws {
        navigateToStep(2)
        
        let letsEncryptCard = app.buttons[TestIDs.CertificateSettings.letsEncryptCard]
        if letsEncryptCard.waitForExistence(timeout: 5) {
            letsEncryptCard.click()
            takeScreenshot(name: "certificate-letsencrypt-selected")
        }
        
        // Verify domain field appears
        let domainField = app.textFields[TestIDs.CertificateSettings.domainField]
        XCTAssertTrue(domainField.waitForExistence(timeout: 5), "Domain field should appear")
    }
    
    // MARK: - Security Settings Tests
    
    func testSecuritySettingsStep() throws {
        navigateToStep(3) // Security is step 4
        
        let stepView = app.otherElements[TestIDs.WizardStep.securitySettings]
        XCTAssertTrue(stepView.waitForExistence(timeout: 5), "Security settings step should be visible")
        
        takeScreenshot(name: "security-settings-initial")
    }
    
    func testSecurityToggles() throws {
        navigateToStep(3)
        
        // Test TLS toggle
        let tlsToggle = app.switches[TestIDs.SecuritySettings.enforceTLSToggle]
        if tlsToggle.waitForExistence(timeout: 5) {
            let initialState = tlsToggle.value as? String
            tlsToggle.click()
            let newState = tlsToggle.value as? String
            XCTAssertNotEqual(initialState, newState, "TLS toggle should change state")
            takeScreenshot(name: "security-tls-toggled")
        }
        
        // Test Keychain toggle
        let keychainToggle = app.switches[TestIDs.SecuritySettings.useKeychainToggle]
        if keychainToggle.waitForExistence(timeout: 2) {
            keychainToggle.click()
            takeScreenshot(name: "security-keychain-toggled")
        }
    }
    
    func testEnvironmentPicker() throws {
        navigateToStep(3)
        
        let environmentPicker = app.segmentedControls[TestIDs.SecuritySettings.environmentPicker]
        if environmentPicker.waitForExistence(timeout: 5) {
            // Click Development option
            let developmentButton = environmentPicker.buttons["Development"]
            if developmentButton.exists {
                developmentButton.click()
                takeScreenshot(name: "security-environment-development")
            }
        }
    }
    
    // MARK: - Network Configuration Tests
    
    func testNetworkConfigurationStep() throws {
        navigateToStep(5) // Network is step 6
        
        let stepView = app.otherElements[TestIDs.WizardStep.networkConfiguration]
        XCTAssertTrue(stepView.waitForExistence(timeout: 5), "Network configuration step should be visible")
        
        takeScreenshot(name: "network-config-initial")
    }
    
    func testNetworkPortFields() throws {
        navigateToStep(5)
        
        // Verify frontend port field
        let frontendPort = app.textFields[TestIDs.NetworkConfiguration.frontendPortField]
        if frontendPort.waitForExistence(timeout: 5) {
            frontendPort.click()
            frontendPort.typeKey("a", modifierFlags: .command)
            frontendPort.typeText("8000")
            takeScreenshot(name: "network-frontend-port")
        }
        
        // Verify GUI port field
        let guiPort = app.textFields[TestIDs.NetworkConfiguration.guiPortField]
        if guiPort.waitForExistence(timeout: 2) {
            guiPort.click()
            guiPort.typeKey("a", modifierFlags: .command)
            guiPort.typeText("8889")
        }
    }
    
    func testNetworkPresetButtons() throws {
        navigateToStep(5)
        
        // Click Standard preset
        let standardButton = app.buttons[TestIDs.NetworkConfiguration.presetStandardButton]
        if standardButton.waitForExistence(timeout: 5) {
            standardButton.click()
            takeScreenshot(name: "network-preset-standard")
        }
        
        // Click Development preset
        let devButton = app.buttons[TestIDs.NetworkConfiguration.presetDevelopmentButton]
        if devButton.waitForExistence(timeout: 2) {
            devButton.click()
            takeScreenshot(name: "network-preset-development")
        }
    }
    
    // MARK: - Storage Configuration Tests
    
    func testStorageConfigurationStep() throws {
        navigateToStep(4) // Storage is step 5
        
        let stepView = app.otherElements[TestIDs.WizardStep.storageConfiguration]
        XCTAssertTrue(stepView.waitForExistence(timeout: 5), "Storage configuration step should be visible")
        
        takeScreenshot(name: "storage-config-initial")
    }
    
    func testStoragePathFields() throws {
        navigateToStep(4)
        
        // Verify datastore path field
        let datastorePath = app.textFields[TestIDs.StorageConfiguration.datastorePathField]
        if datastorePath.waitForExistence(timeout: 5) {
            datastorePath.click()
            takeScreenshot(name: "storage-datastore-field")
        }
        
        // Verify browse button
        let browseButton = app.buttons[TestIDs.StorageConfiguration.browseDatastoreButton]
        XCTAssertTrue(browseButton.waitForExistence(timeout: 2), "Browse button should exist")
    }
    
    // MARK: - Authentication Step Tests
    
    func testAuthenticationStep() throws {
        navigateToStep(6) // Authentication is step 7
        
        let stepView = app.otherElements[TestIDs.WizardStep.authentication]
        XCTAssertTrue(stepView.waitForExistence(timeout: 5), "Authentication step should be visible")
        
        takeScreenshot(name: "authentication-initial")
    }
    
    func testUsernameField() throws {
        navigateToStep(6)
        
        let usernameField = app.textFields[TestIDs.Authentication.usernameField]
        if usernameField.waitForExistence(timeout: 5) {
            usernameField.click()
            usernameField.typeKey("a", modifierFlags: .command)
            usernameField.typeText("testadmin")
            takeScreenshot(name: "authentication-username-entered")
        }
    }
    
    func testPasswordFields() throws {
        navigateToStep(6)
        
        // Enter password
        let passwordField = app.secureTextFields[TestIDs.Authentication.passwordField]
        if passwordField.waitForExistence(timeout: 5) {
            passwordField.click()
            passwordField.typeText("TestPassword123!")
        }
        
        // Verify password strength indicator
        let strengthIndicator = app.otherElements[TestIDs.Authentication.passwordStrengthIndicator]
        XCTAssertTrue(strengthIndicator.waitForExistence(timeout: 2), "Password strength indicator should appear")
        
        takeScreenshot(name: "authentication-password-entered")
    }
    
    func testGeneratePasswordButton() throws {
        navigateToStep(6)
        
        let generateButton = app.buttons[TestIDs.Authentication.generatePasswordButton]
        if generateButton.waitForExistence(timeout: 5) {
            generateButton.click()
            takeScreenshot(name: "authentication-password-generated")
        }
    }
    
    // MARK: - Review Step Tests
    
    func testReviewStep() throws {
        navigateToStep(7) // Review is step 8
        
        let stepView = app.otherElements[TestIDs.WizardStep.review]
        XCTAssertTrue(stepView.waitForExistence(timeout: 5), "Review step should be visible")
        
        takeScreenshot(name: "review-step-initial")
    }
    
    func testReviewActionButtons() throws {
        navigateToStep(7)
        
        // Verify Preview YAML button
        let previewButton = app.buttons[TestIDs.Review.previewYAMLButton]
        XCTAssertTrue(previewButton.waitForExistence(timeout: 5), "Preview YAML button should exist")
        
        // Verify Export button
        let exportButton = app.buttons[TestIDs.Review.exportConfigButton]
        XCTAssertTrue(exportButton.waitForExistence(timeout: 2), "Export button should exist")
        
        // Verify Deploy button
        let deployButton = app.buttons[TestIDs.Review.deployButton]
        XCTAssertTrue(deployButton.waitForExistence(timeout: 2), "Deploy button should exist")
        
        takeScreenshot(name: "review-buttons")
    }
    
    func testPreviewYAMLDialog() throws {
        navigateToStep(7)
        
        let previewButton = app.buttons[TestIDs.Review.previewYAMLButton]
        if previewButton.waitForExistence(timeout: 5) {
            previewButton.click()
            
            // Verify YAML preview dialog appears
            let dialog = app.sheets.firstMatch
            XCTAssertTrue(dialog.waitForExistence(timeout: 5), "YAML preview dialog should appear")
            
            takeScreenshot(name: "review-yaml-preview")
            
            // Close dialog
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.click()
            }
        }
    }
    
    // MARK: - Full Workflow Test
    
    func testCompleteWizardWorkflow() throws {
        // Step 1: Welcome
        XCTAssertTrue(app.staticTexts["Welcome to the Velociraptor Configuration Wizard"].waitForExistence(timeout: 5))
        takeScreenshot(name: "workflow-01-welcome")
        clickNext()
        
        // Step 2: Deployment Type - select Standalone
        let standaloneCard = app.buttons[TestIDs.DeploymentType.standaloneCard]
        if standaloneCard.waitForExistence(timeout: 5) {
            standaloneCard.click()
        }
        takeScreenshot(name: "workflow-02-deployment-type")
        clickNext()
        
        // Step 3: Certificate Settings - use self-signed
        takeScreenshot(name: "workflow-03-certificate")
        clickNext()
        
        // Step 4: Security Settings
        takeScreenshot(name: "workflow-04-security")
        clickNext()
        
        // Step 5: Storage Configuration
        takeScreenshot(name: "workflow-05-storage")
        clickNext()
        
        // Step 6: Network Configuration
        takeScreenshot(name: "workflow-06-network")
        clickNext()
        
        // Step 7: Authentication - enter credentials
        let usernameField = app.textFields[TestIDs.Authentication.usernameField]
        if usernameField.waitForExistence(timeout: 5) {
            usernameField.click()
            usernameField.typeKey("a", modifierFlags: .command)
            usernameField.typeText("admin")
        }
        
        // Generate password
        let generateButton = app.buttons[TestIDs.Authentication.generatePasswordButton]
        if generateButton.waitForExistence(timeout: 2) {
            generateButton.click()
        }
        
        takeScreenshot(name: "workflow-07-authentication")
        clickNext()
        
        // Step 8: Review
        takeScreenshot(name: "workflow-08-review")
        
        // Verify we can see the review page
        let deployButton = app.buttons[TestIDs.Review.deployButton]
        XCTAssertTrue(deployButton.waitForExistence(timeout: 5), "Should reach review step with deploy button")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToStep(_ stepIndex: Int) {
        for _ in 0..<stepIndex {
            let nextButton = app.buttons[TestIDs.Navigation.nextButton]
            if nextButton.waitForExistence(timeout: 3) && nextButton.isEnabled {
                nextButton.click()
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }
    
    private func clickNext() {
        let nextButton = app.buttons[TestIDs.Navigation.nextButton]
        if nextButton.waitForExistence(timeout: 3) && nextButton.isEnabled {
            nextButton.click()
            Thread.sleep(forTimeInterval: 0.3)
        }
    }
    
    private func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
        
        // Also save to evidence path
        let filePath = evidencePath.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: filePath)
    }
}
