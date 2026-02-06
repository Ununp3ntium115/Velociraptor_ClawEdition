// PortLockdownManagerTests.swift
// Velociraptor Claw Edition - Port Lockdown Manager Unit Tests
//
// Tests for the PortLockdownManager actor that handles port blocking
// during Emergency Mode lockdown

import XCTest
@testable import Velociraptor

// MARK: - Port Lockdown Manager Tests

/// Unit test suite for PortLockdownManager
final class PortLockdownManagerTests: XCTestCase {
    
    var manager: PortLockdownManager!
    
    // MARK: - Setup & Teardown
    
    override func setUp() async throws {
        try await super.setUp()
        manager = PortLockdownManager()
    }
    
    override func tearDown() async throws {
        // Ensure unlocked after each test
        _ = await manager.unlock()
        manager = nil
        try await super.tearDown()
    }
}

// MARK: - Initial State Tests

extension PortLockdownManagerTests {
    
    /// Test: Manager starts in unlocked state
    func testInitialStateUnlocked() async throws {
        let status = await manager.getCurrentStatus()
        XCTAssertFalse(status.isActive, "Manager should start unlocked")
    }
    
    /// Test: No blocked ports initially
    func testInitialStateNoBlockedPorts() async throws {
        let status = await manager.getCurrentStatus()
        XCTAssertEqual(status.blockedPortCount, 0, "Should have no blocked ports initially")
    }
    
    /// Test: No allowed ports initially
    func testInitialStateNoAllowedPorts() async throws {
        let status = await manager.getCurrentStatus()
        XCTAssertTrue(status.allowedPorts.isEmpty, "Should have no allowed ports initially")
    }
    
    /// Test: Start time is nil initially
    func testInitialStateNoStartTime() async throws {
        let status = await manager.getCurrentStatus()
        XCTAssertNil(status.startTime, "Start time should be nil initially")
    }
    
    /// Test: Status returns inactive struct
    func testInitialStatusInactive() async throws {
        let status = await manager.getCurrentStatus()
        XCTAssertEqual(status, LockdownStatus.inactive, "Should match inactive status")
    }
}

// MARK: - Lockdown Operation Tests

extension PortLockdownManagerTests {
    
    /// Test: Lockdown with allowed ports returns success or simulated
    func testLockdownReturnsResult() async throws {
        let allowedPorts: Set<UInt16> = [8889, 443, 22]
        let result = await manager.lockdown(allowingPorts: allowedPorts)
        
        switch result {
        case .success, .simulated:
            XCTAssertTrue(result.isComplete, "Lockdown should complete")
        case .failure(let error):
            XCTFail("Lockdown should not fail: \(error)")
        }
    }
    
    /// Test: Allowed ports are preserved after lockdown
    func testAllowedPortsPreserved() async throws {
        let allowedPorts: Set<UInt16> = [8889, 443, 22, 8000, 8001]
        _ = await manager.lockdown(allowingPorts: allowedPorts)
        
        let status = await manager.getCurrentStatus()
        XCTAssertEqual(status.allowedPorts, allowedPorts, "Allowed ports should be preserved")
    }
    
    /// Test: Blocked ports list is populated after lockdown
    func testBlockedPortsPopulated() async throws {
        let allowedPorts: Set<UInt16> = [8889, 443]
        let result = await manager.lockdown(allowingPorts: allowedPorts)
        
        switch result {
        case .success(let blockedPorts), .simulated(let blockedPorts):
            XCTAssertFalse(blockedPorts.isEmpty, "Should have blocked ports")
            // Verify allowed ports are NOT in blocked list
            for port in allowedPorts {
                XCTAssertFalse(blockedPorts.contains(port), "Allowed port \(port) should not be blocked")
            }
        case .failure:
            break // Acceptable if helper not available
        }
    }
    
    /// Test: isLocked becomes true after lockdown
    func testIsLockedAfterLockdown() async throws {
        let allowedPorts: Set<UInt16> = [8889]
        _ = await manager.lockdown(allowingPorts: allowedPorts)
        
        let status = await manager.getCurrentStatus()
        XCTAssertTrue(status.isActive, "Should be locked after lockdown")
    }
    
    /// Test: Start time is set after lockdown
    func testStartTimeSetAfterLockdown() async throws {
        let beforeLockdown = Date()
        _ = await manager.lockdown(allowingPorts: [8889])
        
        let status = await manager.getCurrentStatus()
        XCTAssertNotNil(status.startTime, "Start time should be set")
        if let startTime = status.startTime {
            XCTAssertGreaterThanOrEqual(startTime, beforeLockdown, "Start time should be after test started")
        }
    }
}

// MARK: - Unlock Operation Tests

extension PortLockdownManagerTests {
    
    /// Test: Unlock clears blocked ports
    func testUnlockClearsBlockedPorts() async throws {
        _ = await manager.lockdown(allowingPorts: [8889])
        _ = await manager.unlock()
        
        let status = await manager.getCurrentStatus()
        XCTAssertEqual(status.blockedPortCount, 0, "Should have no blocked ports after unlock")
    }
    
    /// Test: isLocked becomes false after unlock
    func testIsLockedFalseAfterUnlock() async throws {
        _ = await manager.lockdown(allowingPorts: [8889])
        _ = await manager.unlock()
        
        let status = await manager.getCurrentStatus()
        XCTAssertFalse(status.isActive, "Should not be locked after unlock")
    }
    
    /// Test: Allowed ports are cleared after unlock
    func testAllowedPortsClearedAfterUnlock() async throws {
        _ = await manager.lockdown(allowingPorts: [8889, 443])
        _ = await manager.unlock()
        
        let status = await manager.getCurrentStatus()
        XCTAssertTrue(status.allowedPorts.isEmpty, "Allowed ports should be cleared")
    }
    
    /// Test: Start time is cleared after unlock
    func testStartTimeClearedAfterUnlock() async throws {
        _ = await manager.lockdown(allowingPorts: [8889])
        _ = await manager.unlock()
        
        let status = await manager.getCurrentStatus()
        XCTAssertNil(status.startTime, "Start time should be nil after unlock")
    }
    
    /// Test: Unlock returns true on success
    func testUnlockReturnsTrue() async throws {
        _ = await manager.lockdown(allowingPorts: [8889])
        let success = await manager.unlock()
        XCTAssertTrue(success, "Unlock should return true")
    }
    
    /// Test: Unlock on unlocked state returns true
    func testUnlockWhenNotLockedReturnsTrue() async throws {
        let success = await manager.unlock()
        XCTAssertTrue(success, "Unlock should return true even when not locked")
    }
}

// MARK: - Error Handling Tests

extension PortLockdownManagerTests {
    
    /// Test: Cannot lock when already locked
    func testCannotLockWhenAlreadyLocked() async throws {
        _ = await manager.lockdown(allowingPorts: [8889])
        let result = await manager.lockdown(allowingPorts: [443])
        
        if case .failure(let error) = result {
            XCTAssertEqual(error, .alreadyLocked, "Should return alreadyLocked error")
        } else {
            XCTFail("Should fail with alreadyLocked when already locked")
        }
    }
    
    /// Test: Proper error types are returned
    func testErrorTypesAreProper() async throws {
        // Test alreadyLocked error
        _ = await manager.lockdown(allowingPorts: [8889])
        let result = await manager.lockdown(allowingPorts: [443])
        
        switch result {
        case .failure(let error):
            // Verify error has proper description
            XCTAssertNotNil(error.errorDescription, "Error should have description")
        default:
            break
        }
    }
}

// MARK: - Port Query Tests

extension PortLockdownManagerTests {
    
    /// Test: isPortBlocked returns correct values
    func testIsPortBlockedReturnsCorrectly() async throws {
        let allowedPorts: Set<UInt16> = [8889, 443]
        let result = await manager.lockdown(allowingPorts: allowedPorts)
        
        switch result {
        case .success(let blockedPorts), .simulated(let blockedPorts):
            // Check a blocked port
            if let blockedPort = blockedPorts.first {
                let isBlocked = await manager.isPortBlocked(blockedPort)
                XCTAssertTrue(isBlocked, "Port \(blockedPort) should be blocked")
            }
            
            // Check an allowed port
            let isAllowedBlocked = await manager.isPortBlocked(8889)
            XCTAssertFalse(isAllowedBlocked, "Allowed port should not be blocked")
        case .failure:
            break
        }
    }
    
    /// Test: isPortAllowed returns correct values
    func testIsPortAllowedReturnsCorrectly() async throws {
        let allowedPorts: Set<UInt16> = [8889, 443, 22]
        _ = await manager.lockdown(allowingPorts: allowedPorts)
        
        // Check allowed ports
        let is8889Allowed = await manager.isPortAllowed(8889)
        XCTAssertTrue(is8889Allowed, "Port 8889 should be allowed")
        
        let is443Allowed = await manager.isPortAllowed(443)
        XCTAssertTrue(is443Allowed, "Port 443 should be allowed")
        
        // Check non-allowed port
        let is80Allowed = await manager.isPortAllowed(80)
        XCTAssertFalse(is80Allowed, "Port 80 should not be in allowed list")
    }
}

// MARK: - Lockdown Result Tests

extension PortLockdownManagerTests {
    
    /// Test: LockdownResult success case properties
    func testLockdownResultSuccessProperties() {
        let result = LockdownResult.success(blockedPorts: [22, 80, 443])
        
        XCTAssertTrue(result.isComplete, "Success should be complete")
        XCTAssertTrue(result.logDescription.contains("Blocked"), "Should mention blocked in log")
    }
    
    /// Test: LockdownResult simulated case properties
    func testLockdownResultSimulatedProperties() {
        let result = LockdownResult.simulated(intendedBlocks: [22, 80])
        
        XCTAssertTrue(result.isComplete, "Simulated should be complete")
        XCTAssertTrue(result.logDescription.contains("SIMULATED"), "Should mention simulated in log")
    }
    
    /// Test: LockdownResult failure case properties
    func testLockdownResultFailureProperties() {
        let result = LockdownResult.failure(.timeout)
        
        XCTAssertFalse(result.isComplete, "Failure should not be complete")
        XCTAssertTrue(result.logDescription.contains("Failed"), "Should mention failed in log")
    }
}

// MARK: - Lockdown Status Tests

extension PortLockdownManagerTests {
    
    /// Test: LockdownStatus inactive static property
    func testLockdownStatusInactive() {
        let status = LockdownStatus.inactive
        
        XCTAssertFalse(status.isActive, "Inactive status should not be active")
        XCTAssertTrue(status.allowedPorts.isEmpty, "Inactive should have no allowed ports")
        XCTAssertEqual(status.blockedPortCount, 0, "Inactive should have no blocked ports")
        XCTAssertNil(status.startTime, "Inactive should have no start time")
    }
    
    /// Test: LockdownStatus custom initialization
    func testLockdownStatusInit() {
        let now = Date()
        let status = LockdownStatus(
            isActive: true,
            allowedPorts: [8889, 443],
            blockedPortCount: 50,
            startTime: now
        )
        
        XCTAssertTrue(status.isActive)
        XCTAssertEqual(status.allowedPorts.count, 2)
        XCTAssertEqual(status.blockedPortCount, 50)
        XCTAssertEqual(status.startTime, now)
    }
}

// MARK: - Lockdown Error Tests

extension PortLockdownManagerTests {
    
    /// Test: All error types have descriptions
    func testAllErrorTypesHaveDescriptions() {
        let errors: [LockdownError] = [
            .privilegedHelperNotAvailable,
            .insufficientPermissions,
            .networkExtensionNotConfigured,
            .pfFirewallError("test"),
            .timeout,
            .alreadyLocked,
            .noPortsToBlock,
            .cancelled,
            .unknown("test")
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription, "Error \(error) should have description")
            XCTAssertFalse(error.errorDescription?.isEmpty ?? true, "Description should not be empty")
        }
    }
    
    /// Test: LockdownError from generic error
    func testLockdownErrorFromGenericError() {
        let genericError = NSError(domain: "test", code: 1, userInfo: nil)
        let lockdownError = LockdownError.from(genericError)
        
        if case .unknown = lockdownError {
            // Expected
        } else {
            XCTFail("Should convert to unknown error")
        }
    }
    
    /// Test: LockdownError from itself
    func testLockdownErrorFromSelf() {
        let original = LockdownError.timeout
        let converted = LockdownError.from(original)
        XCTAssertEqual(converted, original, "Should preserve original error")
    }
}

// MARK: - Concurrency Tests

extension PortLockdownManagerTests {
    
    /// Test: Actor isolation works correctly
    func testActorIsolation() async throws {
        // Run sequential operations to test actor isolation
        _ = await manager.lockdown(allowingPorts: [8889])
        let status = await manager.getCurrentStatus()
        
        // Should complete without issues
        XCTAssertNotNil(status, "Status should be returned")
        XCTAssertTrue(status.isActive, "Should be locked")
    }
    
    /// Test: Multiple sequential operations
    func testSequentialOperations() async throws {
        // Lock
        _ = await manager.lockdown(allowingPorts: [8889])
        var status = await manager.getCurrentStatus()
        XCTAssertTrue(status.isActive)
        
        // Unlock
        _ = await manager.unlock()
        status = await manager.getCurrentStatus()
        XCTAssertFalse(status.isActive)
        
        // Lock again
        _ = await manager.lockdown(allowingPorts: [443])
        status = await manager.getCurrentStatus()
        XCTAssertTrue(status.isActive)
    }
}
