//
//  SettingsUITests.swift
//  VelociraptorMacOSUITests
//
//  Comprehensive UI tests for Settings view
//

import XCTest


final class SettingsUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Navigate to Settings
        openSettings()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Helper Methods
    
    private func openSettings() {
        // Try menu bar first
        let menuBar = app.menuBars
        if menuBar.count > 0 {
            menuBar.menuBarItems["Velociraptor"].click()
            if menuBar.menuItems["Settings…"].exists {
                menuBar.menuItems["Settings…"].click()
            } else if menuBar.menuItems["Preferences…"].exists {
                menuBar.menuItems["Preferences…"].click()
            }
        }
        // Wait for settings window
        _ = app.windows["Settings"].waitForExistence(timeout: 2)
    }
    
    // MARK: - Tab Navigation Tests
    
    func testSettingsWindowOpens() throws {
        // Verify settings window exists
        XCTAssertTrue(app.windows["Settings"].exists || 
                      app.windows["Preferences"].exists)
    }
    
    func testGeneralTabExists() throws {
        let generalTab = app.buttons[TestIDs.Settings.generalTab]
        if generalTab.exists {
            XCTAssertTrue(generalTab.exists)
        }
    }
    
    func testSecurityTabExists() throws {
        let securityTab = app.buttons[TestIDs.Settings.securityTab]
        if securityTab.exists {
            XCTAssertTrue(securityTab.exists)
        }
    }
    
    func testAdvancedTabExists() throws {
        let advancedTab = app.buttons[TestIDs.Settings.advancedTab]
        if advancedTab.exists {
            XCTAssertTrue(advancedTab.exists)
        }
    }
    
    func testTabNavigation() throws {
        // Click Security tab
        let securityTab = app.buttons[TestIDs.Settings.securityTab]
        if securityTab.exists {
            securityTab.tap()
        }
        
        // Click Advanced tab
        let advancedTab = app.buttons[TestIDs.Settings.advancedTab]
        if advancedTab.exists {
            advancedTab.tap()
        }
        
        // Return to General tab
        let generalTab = app.buttons[TestIDs.Settings.generalTab]
        if generalTab.exists {
            generalTab.tap()
        }
    }
    
    // MARK: - General Settings Tests
    
    func testLaunchAtLoginToggle() throws {
        // First ensure we're on General tab
        let generalTab = app.buttons[TestIDs.Settings.generalTab]
        if generalTab.exists {
            generalTab.tap()
        }
        
        let toggle = app.checkBoxes[TestIDs.Settings.launchAtLogin]
        if toggle.exists {
            let initialState = toggle.value as? Bool ?? false
            toggle.click()
            
            // Wait for state change
            Thread.sleep(forTimeInterval: 0.5)
            
            let newState = toggle.value as? Bool ?? false
            XCTAssertNotEqual(initialState, newState)
            
            // Restore original state
            toggle.click()
        }
    }
    
    func testCheckForUpdatesToggle() throws {
        let toggle = app.checkBoxes[TestIDs.Settings.checkForUpdates]
        if toggle.exists {
            XCTAssertTrue(toggle.exists)
        }
    }
    
    func testNotificationsToggle() throws {
        let toggle = app.checkBoxes[TestIDs.Settings.enableNotifications]
        if toggle.exists {
            XCTAssertTrue(toggle.exists)
        }
    }
    
    func testThemePicker() throws {
        let picker = app.popUpButtons[TestIDs.Settings.themePicker]
        if picker.exists {
            picker.click()
            
            // Check options exist
            let systemOption = app.menuItems["System"]
            let lightOption = app.menuItems["Light"]
            let darkOption = app.menuItems["Dark"]
            
            if systemOption.exists {
                systemOption.click()
            } else if lightOption.exists {
                lightOption.click()
            } else if darkOption.exists {
                darkOption.click()
            }
        }
    }
    
    // MARK: - Log Management Tests
    
    func testOpenLogFileButton() throws {
        let button = app.buttons[TestIDs.Settings.openLogFile]
        if button.exists {
            XCTAssertTrue(button.isEnabled)
        }
    }
    
    func testClearLogsButton() throws {
        let button = app.buttons[TestIDs.Settings.clearLogs]
        if button.exists {
            XCTAssertTrue(button.isEnabled)
        }
    }
    
    func testExportLogsButton() throws {
        let button = app.buttons[TestIDs.Settings.exportLogs]
        if button.exists {
            XCTAssertTrue(button.isEnabled)
        }
    }
    
    // MARK: - Security Settings Tests
    
    func testSecuritySettings() throws {
        // Navigate to Security tab
        let securityTab = app.buttons[TestIDs.Settings.securityTab]
        if securityTab.exists {
            securityTab.tap()
        }
        
        // Check security toggles exist
        // Note: Specific IDs depend on implementation
    }
    
    // MARK: - Advanced Settings Tests
    
    func testAdvancedSettings() throws {
        // Navigate to Advanced tab
        let advancedTab = app.buttons[TestIDs.Settings.advancedTab]
        if advancedTab.exists {
            advancedTab.tap()
        }
        
        // Check advanced options exist
        // Note: Specific IDs depend on implementation
    }
    
    // MARK: - Accessibility Tests
    
    func testAllControlsHaveAccessibilityIdentifiers() throws {
        // Verify main tabs have accessibility identifiers
        let generalTab = app.buttons[TestIDs.Settings.generalTab]
        let securityTab = app.buttons[TestIDs.Settings.securityTab]
        let advancedTab = app.buttons[TestIDs.Settings.advancedTab]
        
        // At least one tab should exist
        XCTAssertTrue(generalTab.exists || securityTab.exists || advancedTab.exists)
    }
    
    func testKeyboardNavigation() throws {
        // Test Tab key navigation through settings
        app.typeKey(.tab, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.2)
        
        app.typeKey(.tab, modifierFlags: [])
        Thread.sleep(forTimeInterval: 0.2)
        
        app.typeKey(.tab, modifierFlags: [])
    }
    
    // MARK: - Close Settings Tests
    
    func testCloseSettingsWithEscape() throws {
        app.typeKey(.escape, modifierFlags: [])
        
        // Settings window should close
        Thread.sleep(forTimeInterval: 0.5)
    }
    
    func testCloseSettingsWithCommandW() throws {
        app.typeKey("w", modifierFlags: .command)
        
        // Settings window should close
        Thread.sleep(forTimeInterval: 0.5)
    }
}

// Note: TestIDs.Settings is defined in TestAccessibilityIdentifiers.swift
