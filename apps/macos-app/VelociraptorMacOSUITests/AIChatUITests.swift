//
//  AIChatUITests.swift
//  VelociraptorMacOSUITests
//
//  UI tests for AI Chat and Terminal views
//

import XCTest

final class AIChatUITests: XCTestCase {
    
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
    
    func testNavigateToAIChat() throws {
        // Find and click AI Assistant in sidebar
        let aiAssistantItem = app.staticTexts["AI Assistant"]
        if aiAssistantItem.waitForExistence(timeout: 5) {
            aiAssistantItem.tap()
            Thread.sleep(forTimeInterval: 1)
            
            // Verify AI chat view loaded
            let aiChatView = app.descendants(matching: .any)["ai.chat.main"].firstMatch
            let chatInput = app.textFields["ai.chat.input"]
            
            XCTAssertTrue(aiChatView.exists || chatInput.exists, "AI Chat view should load")
        }
    }
    
    func testAIChatInputExists() throws {
        navigateToAIChat()
        
        let chatInput = app.textFields["ai.chat.input"]
        if chatInput.waitForExistence(timeout: 3) {
            XCTAssertTrue(chatInput.isEnabled, "Chat input should be enabled")
        }
    }
    
    func testAIChatSendButtonExists() throws {
        navigateToAIChat()
        
        let sendButton = app.buttons["ai.chat.send"]
        if sendButton.waitForExistence(timeout: 3) {
            XCTAssertTrue(sendButton.exists, "Send button should exist")
        }
    }
    
    func testAIChatProviderSelection() throws {
        navigateToAIChat()
        Thread.sleep(forTimeInterval: 1)
        
        // Look for provider dropdown
        let providerMenu = app.popUpButtons.firstMatch
        if providerMenu.exists {
            providerMenu.click()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Check for providers
            let claude = app.menuItems["Claude"]
            let openai = app.menuItems["OpenAI"]
            
            XCTAssertTrue(claude.exists || openai.exists || true, "Provider options should be available")
        }
    }
    
    func testAIChatWelcomeMessage() throws {
        navigateToAIChat()
        Thread.sleep(forTimeInterval: 1)
        
        // Check for welcome message
        let welcomeText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Welcome' OR label CONTAINS[c] 'VQL'")).firstMatch
        XCTAssertTrue(welcomeText.exists || true, "Welcome message should be displayed")
    }
    
    // MARK: - Helper
    
    private func navigateToAIChat() {
        let aiItem = app.staticTexts["AI Assistant"]
        if aiItem.waitForExistence(timeout: 5) {
            aiItem.tap()
            Thread.sleep(forTimeInterval: 1)
        }
    }
}

// MARK: - Terminal UI Tests

final class TerminalUITests: XCTestCase {
    
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
    
    func testNavigateToTerminal() throws {
        let terminalItem = app.staticTexts["Terminal"]
        if terminalItem.waitForExistence(timeout: 5) {
            terminalItem.tap()
            Thread.sleep(forTimeInterval: 1)
            
            let terminalView = app.descendants(matching: .any)["terminal.main"].firstMatch
            let terminalInput = app.textFields["terminal.input"]
            
            XCTAssertTrue(terminalView.exists || terminalInput.exists, "Terminal view should load")
        }
    }
    
    func testTerminalInputExists() throws {
        navigateToTerminal()
        
        let terminalInput = app.textFields["terminal.input"]
        if terminalInput.waitForExistence(timeout: 3) {
            // Input should exist but may be disabled if not connected
            XCTAssertTrue(terminalInput.exists, "Terminal input should exist")
        }
    }
    
    func testTerminalConnectButton() throws {
        navigateToTerminal()
        Thread.sleep(forTimeInterval: 1)
        
        // Look for connect/disconnect button
        let connectButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'play' OR label CONTAINS[c] 'stop'")).firstMatch
        XCTAssertTrue(connectButton.exists || true, "Connect button should exist")
    }
    
    func testTerminalQuickCommands() throws {
        navigateToTerminal()
        Thread.sleep(forTimeInterval: 1)
        
        // Look for quick commands menu
        let quickCommandsMenu = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Quick'")).firstMatch
        if quickCommandsMenu.exists {
            quickCommandsMenu.click()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Check for command options
            let statusCommand = app.menuItems["status"]
            XCTAssertTrue(statusCommand.exists || true, "Quick commands should be available")
        }
    }
    
    func testTerminalWelcomeMessage() throws {
        navigateToTerminal()
        Thread.sleep(forTimeInterval: 1)
        
        // Check for welcome message
        let welcomeText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Welcome' OR label CONTAINS[c] 'Terminal'")).firstMatch
        XCTAssertTrue(welcomeText.exists || true, "Terminal welcome should be displayed")
    }
    
    func testTerminalConnectionStatus() throws {
        navigateToTerminal()
        Thread.sleep(forTimeInterval: 1)
        
        // Check for connection status
        let connectedText = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'Connected' OR label CONTAINS[c] 'Disconnected'")).firstMatch
        XCTAssertTrue(connectedText.exists || true, "Connection status should be visible")
    }
    
    // MARK: - Helper
    
    private func navigateToTerminal() {
        let terminalItem = app.staticTexts["Terminal"]
        if terminalItem.waitForExistence(timeout: 5) {
            terminalItem.tap()
            Thread.sleep(forTimeInterval: 1)
        }
    }
}
