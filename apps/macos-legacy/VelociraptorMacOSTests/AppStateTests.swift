//
//  AppStateTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for AppState
//

import XCTest
@testable import Velociraptor

final class AppStateTests: XCTestCase {
    var appState: AppState!
    
    @MainActor
    override func setUp() async throws {
        appState = AppState()
    }
    
    @MainActor
    override func tearDown() async throws {
        appState = nil
    }
    
    // MARK: - Initial State Tests
    
    @MainActor
    func testInitialState() {
        XCTAssertEqual(appState.currentStep, .welcome)
        XCTAssertEqual(appState.deploymentType, .standalone)
        XCTAssertFalse(appState.isDeploying)
        XCTAssertEqual(appState.deploymentProgress, 0.0)
        XCTAssertNil(appState.errorMessage)
        XCTAssertFalse(appState.showError)
    }
    
    // MARK: - Navigation Tests
    
    @MainActor
    func testNextStep() {
        XCTAssertEqual(appState.currentStep, .welcome)
        
        appState.nextStep()
        XCTAssertEqual(appState.currentStep, .deploymentType)
        
        appState.nextStep()
        XCTAssertEqual(appState.currentStep, .certificateSettings)
    }
    
    @MainActor
    func testPreviousStep() {
        appState.currentStep = .authentication
        
        appState.previousStep()
        XCTAssertEqual(appState.currentStep, .networkConfiguration)
    }
    
    @MainActor
    func testCannotGoPastComplete() {
        appState.currentStep = .complete
        
        appState.nextStep()
        XCTAssertEqual(appState.currentStep, .complete)
    }
    
    @MainActor
    func testCannotGoBeforeWelcome() {
        appState.currentStep = .welcome
        
        appState.previousStep()
        XCTAssertEqual(appState.currentStep, .welcome)
    }
    
    @MainActor
    func testGoToStep() {
        appState.currentStep = .authentication
        
        // Can go to earlier step
        appState.goToStep(.deploymentType)
        XCTAssertEqual(appState.currentStep, .deploymentType)
        
        // Cannot go to later step
        appState.goToStep(.complete)
        XCTAssertEqual(appState.currentStep, .deploymentType)
    }
    
    @MainActor
    func testResetWizard() {
        appState.currentStep = .review
        appState.deploymentProgress = 0.5
        appState.isDeploying = true
        
        appState.resetWizard()
        
        XCTAssertEqual(appState.currentStep, .welcome)
        XCTAssertEqual(appState.deploymentProgress, 0.0)
        XCTAssertFalse(appState.isDeploying)
        XCTAssertTrue(appState.stepHistory.isEmpty)
    }
    
    // MARK: - Error Handling Tests
    
    @MainActor
    func testDisplayError() {
        struct TestError: Error {
            let message: String
        }
        
        let error = TestError(message: "Test error message")
        appState.displayError(error)
        
        XCTAssertNotNil(appState.errorMessage)
        XCTAssertTrue(appState.showError)
        XCTAssertNotNil(appState.lastError)
    }
    
    @MainActor
    func testDisplayErrorMessage() {
        appState.displayError(message: "Custom error message")
        
        XCTAssertEqual(appState.errorMessage, "Custom error message")
        XCTAssertTrue(appState.showError)
    }
    
    @MainActor
    func testClearError() {
        appState.displayError(message: "Error")
        XCTAssertTrue(appState.showError)
        
        appState.clearError()
        
        XCTAssertNil(appState.errorMessage)
        XCTAssertFalse(appState.showError)
        XCTAssertNil(appState.lastError)
    }
    
    // MARK: - Computed Properties Tests
    
    @MainActor
    func testCanGoBack() {
        appState.currentStep = .welcome
        XCTAssertFalse(appState.canGoBack)
        
        appState.currentStep = .deploymentType
        XCTAssertTrue(appState.canGoBack)
        
        appState.currentStep = .complete
        XCTAssertFalse(appState.canGoBack)
    }
    
    @MainActor
    func testCanGoNext() {
        appState.currentStep = .welcome
        XCTAssertTrue(appState.canGoNext)
        
        appState.currentStep = .complete
        XCTAssertFalse(appState.canGoNext)
    }
    
    @MainActor
    func testWizardProgress() {
        appState.currentStep = .welcome
        XCTAssertEqual(appState.wizardProgress, 0.0, accuracy: 0.01)
        
        appState.currentStep = .complete
        XCTAssertEqual(appState.wizardProgress, 1.0, accuracy: 0.01)
    }
    
    // MARK: - Deployment Type Tests
    
    @MainActor
    func testDeploymentTypeProperties() {
        for type in AppState.DeploymentType.allCases {
            XCTAssertFalse(type.description.isEmpty)
            XCTAssertFalse(type.iconName.isEmpty)
            XCTAssertFalse(type.useCases.isEmpty)
        }
    }
    
    // MARK: - Wizard Step Tests
    
    @MainActor
    func testWizardStepProperties() {
        for step in AppState.WizardStep.allCases {
            XCTAssertFalse(step.title.isEmpty)
            XCTAssertFalse(step.description.isEmpty)
            XCTAssertFalse(step.iconName.isEmpty)
        }
    }
}
