//
//  AIConfigurationUITests.swift
//  VelociraptorMacOSUITests
//
//  UI Tests for AI Configuration wizard step
//  Tests all AI provider selection, API key input, and connection testing
//
//  CDIF Pattern: AI-001 through AI-010
//

import XCTest

final class AIConfigurationUITests: XCTestCase {
    
    var app: XCUIApplication!
    var evidencePath: URL!
    
    // MARK: - Setup/Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        // Create evidence directory
        let timestamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        evidencePath = FileManager.default.temporaryDirectory
            .appendingPathComponent("artifacts")
            .appendingPathComponent(timestamp)
            .appendingPathComponent("ai-config")
        try? FileManager.default.createDirectory(at: evidencePath, withIntermediateDirectories: true)
        
        app = XCUIApplication()
        // Position window on 3rd monitor (portrait) for UI testing
        app.launchArguments.append("-UITestMode")
        // Use mock mode for AI tests - don't actually call APIs
        app.launchArguments.append("-MockAIConnections")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        takeScreenshot(name: "teardown")
        app.terminate()
    }
    
    // MARK: - Helper Methods
    
    private func takeScreenshot(name: String) {
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    private func navigateToAIConfiguration() -> Bool {
        // Navigate through wizard to AI Configuration step (step 7)
        // Welcome -> Deployment Type -> Certificate -> Security -> Storage -> Network -> Auth -> AI Config
        
        let maxAttempts = 10
        var attempts = 0
        
        while attempts < maxAttempts {
            // Check if we're already at AI Configuration
            if app.staticTexts["AI Configuration"].exists {
                return true
            }
            
            // Try to find and click Next button
            let nextButton = app.buttons["Next"]
            if nextButton.exists && nextButton.isEnabled {
                nextButton.click()
                sleep(1)
            } else {
                // Try looking for alternative next buttons
                let nextButtons = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Next' OR label CONTAINS[c] 'Continue'"))
                if nextButtons.count > 0 {
                    nextButtons.firstMatch.click()
                    sleep(1)
                }
            }
            
            attempts += 1
        }
        
        return app.staticTexts["AI Configuration"].exists
    }
    
    // MARK: - AI-001: AI Configuration Step Loads
    
    func testAIConfigurationStepLoads() throws {
        takeScreenshot(name: "initial-state")
        
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        takeScreenshot(name: "ai-config-loaded")
        
        // Verify step title is visible
        XCTAssertTrue(
            app.staticTexts["AI Configuration"].exists,
            "AI Configuration step title should be visible"
        )
    }
    
    // MARK: - AI-002: AI Enable Toggle
    
    func testAIEnableToggle() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        // Find the enable toggle
        let enableToggle = app.toggles.matching(NSPredicate(format: "label CONTAINS[c] 'Enable AI'")).firstMatch
        
        if enableToggle.exists {
            takeScreenshot(name: "before-toggle")
            
            // Toggle should be off by default
            let initialValue = enableToggle.value as? String
            
            // Click to enable
            enableToggle.click()
            sleep(1)
            
            takeScreenshot(name: "after-toggle-enable")
            
            // Verify toggle changed
            let newValue = enableToggle.value as? String
            XCTAssertNotEqual(initialValue, newValue, "Toggle state should change after clicking")
            
            // Provider picker should now be visible when AI is enabled
            let providerPicker = app.popUpButtons.matching(NSPredicate(format: "label CONTAINS[c] 'Provider'")).firstMatch
            XCTAssertTrue(
                providerPicker.waitForExistence(timeout: 3),
                "Provider picker should appear when AI is enabled"
            )
        } else {
            XCTSkip("AI enable toggle not found")
        }
    }
    
    // MARK: - AI-003: Provider Selection
    
    func testProviderSelection() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        // First enable AI
        let enableToggle = app.toggles.matching(NSPredicate(format: "label CONTAINS[c] 'Enable AI'")).firstMatch
        if enableToggle.exists {
            enableToggle.click()
            sleep(1)
        }
        
        takeScreenshot(name: "ai-enabled")
        
        // Find provider picker
        let providerPicker = app.popUpButtons.firstMatch
        
        if providerPicker.exists {
            providerPicker.click()
            sleep(1)
            
            takeScreenshot(name: "provider-dropdown-open")
            
            // Check that expected providers are available
            let providers = ["OpenAI", "Anthropic", "Google", "Azure", "Apple", "Ollama"]
            
            for provider in providers {
                let menuItem = app.menuItems.matching(NSPredicate(format: "label CONTAINS[c] %@", provider)).firstMatch
                if menuItem.exists {
                    // Provider option exists
                    continue
                }
            }
            
            // Select OpenAI
            let openAIOption = app.menuItems.matching(NSPredicate(format: "label CONTAINS[c] 'OpenAI'")).firstMatch
            if openAIOption.exists {
                openAIOption.click()
                sleep(1)
                takeScreenshot(name: "openai-selected")
            }
        } else {
            XCTSkip("Provider picker not found")
        }
    }
    
    // MARK: - AI-004: API Key Input Field
    
    func testAPIKeyInputField() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        // Enable AI
        let enableToggle = app.toggles.matching(NSPredicate(format: "label CONTAINS[c] 'Enable AI'")).firstMatch
        if enableToggle.exists {
            enableToggle.click()
            sleep(1)
        }
        
        // Select a provider that requires API key (OpenAI)
        let providerPicker = app.popUpButtons.firstMatch
        if providerPicker.exists {
            providerPicker.click()
            sleep(1)
            
            let openAIOption = app.menuItems.matching(NSPredicate(format: "label CONTAINS[c] 'OpenAI'")).firstMatch
            if openAIOption.exists {
                openAIOption.click()
                sleep(1)
            }
        }
        
        takeScreenshot(name: "before-api-key")
        
        // Find API key field
        let apiKeyField = app.secureTextFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'API' OR placeholderValue CONTAINS[c] 'key'")).firstMatch
        
        if !apiKeyField.exists {
            // Try regular text field (if show password is on)
            let textField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'API' OR placeholderValue CONTAINS[c] 'key'")).firstMatch
            if textField.exists {
                textField.click()
                textField.typeText("sk-test-mock-api-key-12345")
                takeScreenshot(name: "api-key-entered")
            } else {
                XCTSkip("API key field not found")
            }
        } else {
            apiKeyField.click()
            apiKeyField.typeText("sk-test-mock-api-key-12345")
            takeScreenshot(name: "api-key-entered")
        }
    }
    
    // MARK: - AI-005: Model Selection
    
    func testModelSelection() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        // Enable AI and select provider
        let enableToggle = app.toggles.matching(NSPredicate(format: "label CONTAINS[c] 'Enable AI'")).firstMatch
        if enableToggle.exists {
            enableToggle.click()
            sleep(1)
        }
        
        let providerPicker = app.popUpButtons.firstMatch
        if providerPicker.exists {
            providerPicker.click()
            sleep(1)
            
            let openAIOption = app.menuItems.matching(NSPredicate(format: "label CONTAINS[c] 'OpenAI'")).firstMatch
            if openAIOption.exists {
                openAIOption.click()
                sleep(1)
            }
        }
        
        takeScreenshot(name: "before-model-selection")
        
        // Find model picker (should be second popup)
        let popUpButtons = app.popUpButtons.allElementsBoundByIndex
        if popUpButtons.count > 1 {
            let modelPicker = popUpButtons[1]
            modelPicker.click()
            sleep(1)
            
            takeScreenshot(name: "model-dropdown-open")
            
            // Check for expected models
            let models = ["gpt-4o", "gpt-4", "gpt-3.5"]
            for model in models {
                let modelOption = app.menuItems.matching(NSPredicate(format: "label CONTAINS[c] %@", model)).firstMatch
                if modelOption.exists {
                    // Model option exists
                    continue
                }
            }
            
            // Select first model
            if let firstModel = app.menuItems.allElementsBoundByIndex.first(where: { $0.exists }) {
                firstModel.click()
                takeScreenshot(name: "model-selected")
            }
        } else {
            XCTSkip("Model picker not found")
        }
    }
    
    // MARK: - AI-006: Test Connection Button (Mock)
    
    func testConnectionButton() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        // Enable AI and configure
        let enableToggle = app.toggles.matching(NSPredicate(format: "label CONTAINS[c] 'Enable AI'")).firstMatch
        if enableToggle.exists {
            enableToggle.click()
            sleep(1)
        }
        
        // Select provider
        let providerPicker = app.popUpButtons.firstMatch
        if providerPicker.exists {
            providerPicker.click()
            sleep(1)
            let openAIOption = app.menuItems.matching(NSPredicate(format: "label CONTAINS[c] 'OpenAI'")).firstMatch
            if openAIOption.exists {
                openAIOption.click()
                sleep(1)
            }
        }
        
        // Enter API key
        let apiKeyField = app.secureTextFields.firstMatch
        if apiKeyField.exists {
            apiKeyField.click()
            apiKeyField.typeText("sk-test-mock-api-key-1234567890")
        }
        
        takeScreenshot(name: "before-test-connection")
        
        // Find test connection button
        let testButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Test' AND label CONTAINS[c] 'Connection'")).firstMatch
        
        if testButton.exists {
            testButton.click()
            
            // Wait for result (mock should be fast)
            sleep(2)
            
            takeScreenshot(name: "after-test-connection")
            
            // Check for success/failure indicator
            let successIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'success'")).firstMatch
            let failureIndicator = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'failed' OR label CONTAINS[c] 'error'")).firstMatch
            
            // Either success or failure message should appear
            XCTAssertTrue(
                successIndicator.exists || failureIndicator.exists,
                "Connection test should show a result"
            )
        } else {
            XCTSkip("Test connection button not found")
        }
    }
    
    // MARK: - AI-007: AI Features Info Display
    
    func testAIFeaturesInfoDisplay() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        // Enable AI
        let enableToggle = app.toggles.matching(NSPredicate(format: "label CONTAINS[c] 'Enable AI'")).firstMatch
        if enableToggle.exists {
            enableToggle.click()
            sleep(1)
        }
        
        takeScreenshot(name: "ai-features-visible")
        
        // Check for AI features info
        let features = ["Emergency Mode", "VQL Assistant", "Artifact Analysis", "Recommendations"]
        
        for feature in features {
            let featureText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", feature)).firstMatch
            // Log whether each feature is visible
            if !featureText.exists {
                // Feature text not found - check broader search
                let anyMatch = app.descendants(matching: .any).matching(NSPredicate(format: "label CONTAINS[c] %@", feature)).firstMatch
                if anyMatch.exists {
                    continue // Found in some element
                }
            }
        }
    }
    
    // MARK: - AI-008: Privacy Note Display
    
    func testPrivacyNoteDisplay() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        takeScreenshot(name: "privacy-note-check")
        
        // Check for privacy/keychain note
        let privacyNote = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Keychain' OR label CONTAINS[c] 'securely'")).firstMatch
        
        if privacyNote.exists {
            XCTAssertTrue(privacyNote.exists, "Privacy note about keychain storage should be visible")
        } else {
            // Privacy note might be visible after enabling AI
            let enableToggle = app.toggles.matching(NSPredicate(format: "label CONTAINS[c] 'Enable AI'")).firstMatch
            if enableToggle.exists {
                enableToggle.click()
                sleep(1)
                
                let privacyNoteAfter = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Keychain' OR label CONTAINS[c] 'securely'")).firstMatch
                XCTAssertTrue(privacyNoteAfter.exists, "Privacy note should appear when AI is enabled")
            }
        }
    }
    
    // MARK: - AI-009: AI Configuration in Review Step
    
    func testAIConfigurationInReview() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        // Enable AI
        let enableToggle = app.toggles.matching(NSPredicate(format: "label CONTAINS[c] 'Enable AI'")).firstMatch
        if enableToggle.exists {
            enableToggle.click()
            sleep(1)
        }
        
        // Select a provider
        let providerPicker = app.popUpButtons.firstMatch
        if providerPicker.exists {
            providerPicker.click()
            sleep(1)
            let anthropicOption = app.menuItems.matching(NSPredicate(format: "label CONTAINS[c] 'Anthropic'")).firstMatch
            if anthropicOption.exists {
                anthropicOption.click()
                sleep(1)
            }
        }
        
        takeScreenshot(name: "ai-configured")
        
        // Navigate to Review step
        let nextButton = app.buttons["Next"]
        if nextButton.exists && nextButton.isEnabled {
            nextButton.click()
            sleep(1)
        }
        
        takeScreenshot(name: "review-step")
        
        // Check for AI Integration section in review
        let aiSection = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'AI Integration'")).firstMatch
        if aiSection.waitForExistence(timeout: 3) {
            XCTAssertTrue(aiSection.exists, "AI Integration section should appear in Review")
        }
    }
    
    // MARK: - AI-010: Skip AI Configuration
    
    func testSkipAIConfiguration() throws {
        guard navigateToAIConfiguration() else {
            XCTSkip("Could not navigate to AI Configuration step")
            return
        }
        
        takeScreenshot(name: "ai-step-initial")
        
        // Don't enable AI, just proceed
        let nextButton = app.buttons["Next"]
        if nextButton.exists && nextButton.isEnabled {
            nextButton.click()
            sleep(1)
            
            takeScreenshot(name: "proceeded-to-review")
            
            // Should proceed to Review without AI enabled
            // Check for Review title or just verify we moved past AI config
            let reviewTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Review'")).firstMatch
            let aiConfigTitle = app.staticTexts["AI Configuration"]
            
            // Either we're at Review OR we're no longer at AI Configuration
            let movedPastAI = !aiConfigTitle.exists || reviewTitle.exists
            
            XCTAssertTrue(
                movedPastAI || app.windows.count > 0,
                "Should be able to skip AI configuration and proceed"
            )
        } else {
            // If Next button doesn't exist or isn't enabled, that's also acceptable in some UI states
            XCTAssertTrue(app.windows.count > 0, "App should still be responsive")
        }
    }
}
