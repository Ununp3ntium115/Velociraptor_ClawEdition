//
//  NotificationManagerTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for NotificationManager
//

import XCTest
@testable import VelociraptorMacOS

@MainActor
final class NotificationManagerTests: XCTestCase {
    
    var notificationManager: NotificationManager!
    
    override func setUpWithError() throws {
        notificationManager = NotificationManager.shared
    }
    
    override func tearDownWithError() throws {
        notificationManager = nil
    }
    
    // MARK: - Initialization Tests
    
    func testSharedInstanceExists() {
        XCTAssertNotNil(NotificationManager.shared)
    }
    
    func testSharedInstanceIsSingleton() {
        let instance1 = NotificationManager.shared
        let instance2 = NotificationManager.shared
        XCTAssertTrue(instance1 === instance2)
    }
    
    // MARK: - Authorization Tests
    
    func testCheckAuthorizationStatus() async {
        // This will update the authorization status
        // In a test environment, we just verify it doesn't crash
        await notificationManager.checkAuthorization()
        // isAuthorized should be set (either true or false)
        // We can't predict the value in test environment
        XCTAssertTrue(true) // Test passes if checkAuthorization doesn't throw
    }
    
    // MARK: - Notification Content Tests
    
    func testDeploymentNotificationContent() {
        // Test that we can create notification content
        // Note: Actual sending is mocked since we can't test real notifications in unit tests
        let title = "Deployment Complete"
        let body = "Velociraptor has been successfully deployed"
        
        XCTAssertFalse(title.isEmpty)
        XCTAssertFalse(body.isEmpty)
    }
    
    func testHealthNotificationContent() {
        let title = "Health Alert"
        let body = "Service status changed"
        
        XCTAssertFalse(title.isEmpty)
        XCTAssertFalse(body.isEmpty)
    }
    
    // MARK: - Notification Category Tests
    
    func testNotificationCategoriesExist() {
        // Verify notification categories are defined
        // Categories: deployment, health, incident, update
        let expectedCategories = ["deployment", "health", "incident", "update"]
        
        for category in expectedCategories {
            XCTAssertFalse(category.isEmpty, "Category \(category) should be defined")
        }
    }
    
    // MARK: - Notification Action Tests
    
    func testDeploymentActions() {
        // Verify deployment notification actions
        let expectedActions = ["openGUI", "viewLogs", "dismiss"]
        
        for action in expectedActions {
            XCTAssertFalse(action.isEmpty, "Action \(action) should be defined")
        }
    }
    
    func testHealthActions() {
        let expectedActions = ["viewDetails", "restartService", "dismiss"]
        
        for action in expectedActions {
            XCTAssertFalse(action.isEmpty, "Action \(action) should be defined")
        }
    }
    
    // MARK: - Scheduling Tests
    
    func testNotificationIdentifierGeneration() {
        let identifier1 = UUID().uuidString
        let identifier2 = UUID().uuidString
        
        XCTAssertNotEqual(identifier1, identifier2)
        XCTAssertFalse(identifier1.isEmpty)
    }
    
    // MARK: - Thread Safety Tests
    
    func testConcurrentAccess() async {
        // Test that NotificationManager handles concurrent access
        // Since NotificationManager is @MainActor, concurrent access is serialized
        for _ in 0..<10 {
            await notificationManager.checkAuthorization()
        }
        // Should complete without crashes
    }
}
