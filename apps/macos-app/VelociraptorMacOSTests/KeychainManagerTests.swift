//
//  KeychainManagerTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for KeychainManager
//

import XCTest
@testable import Velociraptor

final class KeychainManagerTests: XCTestCase {
    var keychainManager: KeychainManager!
    let testAccount = "test_account_\(UUID().uuidString)"
    
    @MainActor
    override func setUp() async throws {
        keychainManager = KeychainManager()
    }
    
    @MainActor
    override func tearDown() async throws {
        // Clean up test items
        try? keychainManager.deletePassword(for: testAccount)
        try? keychainManager.deleteAPIKey(identifier: testAccount)
        keychainManager = nil
    }
    
    // MARK: - Availability Tests
    
    @MainActor
    func testKeychainAvailability() {
        // Keychain should be available on macOS
        XCTAssertTrue(keychainManager.isAvailable)
    }
    
    // MARK: - Password Operations Tests
    
    @MainActor
    func testSaveAndRetrievePassword() throws {
        let password = "TestPassword123!"
        
        try keychainManager.savePassword(password, for: testAccount)
        let retrieved = try keychainManager.getPassword(for: testAccount)
        
        XCTAssertEqual(password, retrieved)
    }
    
    @MainActor
    func testUpdatePassword() throws {
        let initialPassword = "InitialPassword123"
        let updatedPassword = "UpdatedPassword456"
        
        try keychainManager.savePassword(initialPassword, for: testAccount)
        try keychainManager.savePassword(updatedPassword, for: testAccount)
        
        let retrieved = try keychainManager.getPassword(for: testAccount)
        XCTAssertEqual(updatedPassword, retrieved)
    }
    
    @MainActor
    func testDeletePassword() throws {
        let password = "ToBeDeleted"
        
        try keychainManager.savePassword(password, for: testAccount)
        XCTAssertTrue(keychainManager.hasPassword(for: testAccount))
        
        try keychainManager.deletePassword(for: testAccount)
        XCTAssertFalse(keychainManager.hasPassword(for: testAccount))
    }
    
    @MainActor
    func testGetNonexistentPassword() {
        let nonexistent = "nonexistent_\(UUID().uuidString)"
        
        XCTAssertThrowsError(try keychainManager.getPassword(for: nonexistent)) { error in
            XCTAssertTrue(error is KeychainManager.KeychainError)
            if let keychainError = error as? KeychainManager.KeychainError {
                XCTAssertEqual(keychainError, .itemNotFound)
            }
        }
    }
    
    @MainActor
    func testEmptyPasswordThrows() {
        XCTAssertThrowsError(try keychainManager.savePassword("", for: testAccount)) { error in
            XCTAssertTrue(error is KeychainManager.KeychainError)
            if let keychainError = error as? KeychainManager.KeychainError {
                XCTAssertEqual(keychainError, .noPassword)
            }
        }
    }
    
    @MainActor
    func testHasPassword() throws {
        XCTAssertFalse(keychainManager.hasPassword(for: testAccount))
        
        try keychainManager.savePassword("test", for: testAccount)
        
        XCTAssertTrue(keychainManager.hasPassword(for: testAccount))
    }
    
    // MARK: - API Key Tests
    
    @MainActor
    func testSaveAndRetrieveAPIKey() throws {
        let apiKey = "api_key_\(UUID().uuidString)"
        
        try keychainManager.saveAPIKey(apiKey, identifier: testAccount)
        let retrieved = try keychainManager.getAPIKey(identifier: testAccount)
        
        XCTAssertEqual(apiKey, retrieved)
    }
    
    @MainActor
    func testDeleteAPIKey() throws {
        let apiKey = "to_be_deleted_key"
        
        try keychainManager.saveAPIKey(apiKey, identifier: testAccount)
        try keychainManager.deleteAPIKey(identifier: testAccount)
        
        XCTAssertThrowsError(try keychainManager.getAPIKey(identifier: testAccount))
    }
    
    // MARK: - Admin Password Tests
    
    @MainActor
    func testAdminPasswordOperations() throws {
        // Note: This test modifies actual Keychain - be careful with state
        let testPassword = "AdminTestPassword\(UUID().uuidString)"
        
        try keychainManager.saveAdminPassword(testPassword)
        XCTAssertTrue(keychainManager.hasAdminPassword)
        
        let retrieved = try keychainManager.getAdminPassword()
        XCTAssertEqual(testPassword, retrieved)
        
        // Clean up
        try keychainManager.deletePassword(for: KeychainManager.StandardAccount.adminPassword.rawValue)
    }
    
    // MARK: - List Accounts Tests
    
    @MainActor
    func testListAccounts() throws {
        // Save a test password
        try keychainManager.savePassword("test", for: testAccount)
        
        let accounts = keychainManager.listAccounts()
        
        XCTAssertTrue(accounts.contains(testAccount))
    }
    
    // MARK: - Error Message Tests
    
    func testErrorDescriptions() {
        let errors: [KeychainManager.KeychainError] = [
            .duplicateItem,
            .itemNotFound,
            .unexpectedStatus(0),
            .invalidData,
            .accessDenied,
            .noPassword,
            .encodingFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    // MARK: - Standard Account Tests
    
    func testStandardAccountRawValues() {
        XCTAssertEqual(KeychainManager.StandardAccount.adminPassword.rawValue, "velociraptor_admin")
        XCTAssertEqual(KeychainManager.StandardAccount.serverAPIKey.rawValue, "velociraptor_api_key")
        XCTAssertEqual(KeychainManager.StandardAccount.clientNonce.rawValue, "velociraptor_client_nonce")
    }
}

// MARK: - KeychainError Equatable

extension KeychainManager.KeychainError: Equatable {
    public static func == (lhs: KeychainManager.KeychainError, rhs: KeychainManager.KeychainError) -> Bool {
        switch (lhs, rhs) {
        case (.duplicateItem, .duplicateItem),
             (.itemNotFound, .itemNotFound),
             (.invalidData, .invalidData),
             (.accessDenied, .accessDenied),
             (.noPassword, .noPassword),
             (.encodingFailed, .encodingFailed):
            return true
        case (.unexpectedStatus(let l), .unexpectedStatus(let r)):
            return l == r
        default:
            return false
        }
    }
}
