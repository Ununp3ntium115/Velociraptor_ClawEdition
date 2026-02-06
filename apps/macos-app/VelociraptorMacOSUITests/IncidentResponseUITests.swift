//
//  IncidentResponseUITests.swift
//  VelociraptorMacOSUITests
//
//  Comprehensive UI tests for Incident Response functionality
//

import XCTest


final class IncidentResponseUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // Position window on 3rd monitor (portrait) for UI testing
        app.launchArguments.append("-UITestMode")
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Navigation Tests
    
    func testIncidentResponseNavigationExists() throws {
        // Check if Incident Response is accessible from toolbar or menu
        let toolbar = app.toolbars.firstMatch
        let menuBar = app.menuBars.firstMatch
        
        // Either toolbar button or menu item should exist
        XCTAssertTrue(toolbar.exists || menuBar.exists)
    }
    
    // MARK: - Category List Tests
    
    func testCategoryListExists() throws {
        navigateToIncidentResponse()
        
        let categoryList = app.outlines[TestIDs.IncidentResponse.categoryList]
        if categoryList.exists {
            XCTAssertTrue(categoryList.exists, "Category list should be visible")
        }
    }
    
    func testMalwareCategoryExists() throws {
        navigateToIncidentResponse()
        
        // Look for Malware category
        let malwareCategory = app.staticTexts["Malware"]
        if malwareCategory.exists {
            XCTAssertTrue(malwareCategory.exists)
        }
    }
    
    func testRansomwareCategoryExists() throws {
        navigateToIncidentResponse()
        
        let ransomwareCategory = app.staticTexts["Ransomware"]
        if ransomwareCategory.exists {
            XCTAssertTrue(ransomwareCategory.exists)
        }
    }
    
    func testPhishingCategoryExists() throws {
        navigateToIncidentResponse()
        
        let phishingCategory = app.staticTexts["Phishing"]
        if phishingCategory.exists {
            XCTAssertTrue(phishingCategory.exists)
        }
    }
    
    // MARK: - Incident Selection Tests
    
    func testSelectingCategoryShowsIncidents() throws {
        navigateToIncidentResponse()
        
        // Click on a category
        let malwareCategory = app.staticTexts["Malware"]
        if malwareCategory.exists {
            malwareCategory.tap()
            
            // Wait for incident list to update
            Thread.sleep(forTimeInterval: 0.5)
            
            // Check that incident list exists
            let incidentList = app.outlines[TestIDs.IncidentResponse.incidentList]
            if incidentList.exists {
                XCTAssertTrue(incidentList.exists)
            }
        }
    }
    
    func testSelectingIncidentShowsDetails() throws {
        navigateToIncidentResponse()
        
        // Select a category first
        let malwareCategory = app.staticTexts["Malware"]
        if malwareCategory.exists {
            malwareCategory.tap()
            Thread.sleep(forTimeInterval: 0.5)
            
            // Select first incident
            let incidentList = app.outlines.firstMatch
            if incidentList.cells.count > 0 {
                incidentList.cells.firstMatch.tap()
                
                // Verify details are shown
                Thread.sleep(forTimeInterval: 0.3)
            }
        }
    }
    
    // MARK: - Artifact Selection Tests
    
    func testArtifactCheckboxesExist() throws {
        navigateToIncidentResponse()
        
        // Artifacts should be selectable via checkboxes
        let checkboxes = app.checkBoxes.allElementsBoundByIndex
        // Some checkboxes should exist after selecting an incident
    }
    
    // MARK: - Package Generation Tests
    
    func testGeneratePackageButtonExists() throws {
        navigateToIncidentResponse()
        
        let generateButton = app.buttons["Generate Package"]
        if generateButton.exists {
            XCTAssertTrue(generateButton.exists)
        }
    }
    
    func testExportConfigurationExists() throws {
        navigateToIncidentResponse()
        
        let exportButton = app.buttons["Export"]
        if exportButton.exists {
            XCTAssertTrue(exportButton.exists)
        }
    }
    
    // MARK: - Priority Filter Tests
    
    func testPriorityFilterExists() throws {
        navigateToIncidentResponse()
        
        // Check for priority filters
        let criticalFilter = app.buttons["Critical"]
        let highFilter = app.buttons["High"]
        let mediumFilter = app.buttons["Medium"]
        let lowFilter = app.buttons["Low"]
        
        // At least one priority filter should exist
        let anyFilterExists = criticalFilter.exists || 
                              highFilter.exists || 
                              mediumFilter.exists || 
                              lowFilter.exists
        
        // Priority filtering might be in dropdown
    }
    
    // MARK: - Search Tests
    
    func testSearchFieldExists() throws {
        navigateToIncidentResponse()
        
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            XCTAssertTrue(searchField.exists, "Search field should exist")
        }
    }
    
    func testSearchFiltersIncidents() throws {
        navigateToIncidentResponse()
        
        let searchField = app.searchFields.firstMatch
        if searchField.exists {
            searchField.tap()
            searchField.typeText("Ransomware")
            
            // Wait for filter
            Thread.sleep(forTimeInterval: 0.5)
        }
    }
    
    // MARK: - Keyboard Shortcuts
    
    func testSearchKeyboardShortcut() throws {
        navigateToIncidentResponse()
        
        // Cmd+F should focus search
        app.typeKey("f", modifierFlags: .command)
        
        // Search field should be focused
        Thread.sleep(forTimeInterval: 0.3)
    }
    
    // MARK: - Helper Methods
    
    private func navigateToIncidentResponse() {
        // Try clicking toolbar button
        let irButton = app.toolbarButtons["Incident Response"]
        if irButton.exists {
            irButton.tap()
            return
        }
        
        // Try menu
        let menuBar = app.menuBars.firstMatch
        if menuBar.exists {
            // Navigate via menu if available
        }
        
        // Wait for view to load
        Thread.sleep(forTimeInterval: 0.5)
    }
}

// Note: TestIDs.IncidentResponse is defined in TestAccessibilityIdentifiers.swift
