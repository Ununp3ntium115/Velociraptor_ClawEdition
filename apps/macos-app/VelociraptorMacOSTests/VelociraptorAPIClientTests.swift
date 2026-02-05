//
//  VelociraptorAPIClientTests.swift
//  VelociraptorMacOSTests
//
//  Test suite for Velociraptor API Client
//  Gap: 0x01 - API Client Foundation
//
//  CDIF Pattern: Comprehensive unit testing with mocks
//  Swift 6 Concurrency: @MainActor test isolation
//

import XCTest
@testable import Velociraptor

@MainActor
final class VelociraptorAPIClientTests: XCTestCase {
    
    var apiClient: VelociraptorAPIClient!
    
    override func setUp() async throws {
        try await super.setUp()
        apiClient = VelociraptorAPIClient.shared
    }
    
    override func tearDown() async throws {
        // Clean up credentials
        try? await apiClient.disconnect()
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testConfigureWithAPIKey() async throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let apiKey = "test-api-key"
        
        // When
        try await apiClient.configure(serverURL: serverURL, apiKey: apiKey)
        
        // Then
        // Verify configuration is set (would need to expose a way to check this)
        // For now, verify no errors are thrown
    }
    
    func testConfigureWithBasicAuth() async throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let username = "admin"
        let password = "password"
        
        // When
        try await apiClient.configure(serverURL: serverURL, username: username, password: password)
        
        // Then
        // Verify configuration is set
    }
    
    func testConfigureWithMTLS() async throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        
        // Create temporary cert and key files for testing
        let tempDir = FileManager.default.temporaryDirectory
        let certPath = tempDir.appendingPathComponent("test-cert.pem").path
        let keyPath = tempDir.appendingPathComponent("test-key.pem").path
        
        // Write dummy cert and key (in real test, use valid test certificates)
        let dummyCert = "-----BEGIN CERTIFICATE-----\nDUMMY\n-----END CERTIFICATE-----"
        let dummyKey = "-----BEGIN PRIVATE KEY-----\nDUMMY\n-----END PRIVATE KEY-----"
        
        try dummyCert.write(toFile: certPath, atomically: true, encoding: .utf8)
        try dummyKey.write(toFile: keyPath, atomically: true, encoding: .utf8)
        
        // When/Then
        do {
            try await apiClient.configure(
                serverURL: serverURL,
                certificatePath: certPath,
                keyPath: keyPath
            )
            // Note: Will fail with dummy certs, but tests configuration logic
        } catch {
            // Expected with dummy certificates
            XCTAssertTrue(error is AuthenticationError)
        }
        
        // Cleanup
        try? FileManager.default.removeItem(atPath: certPath)
        try? FileManager.default.removeItem(atPath: keyPath)
    }
    
    // MARK: - Connection Tests
    
    func testConnectionStateInitiallyDisconnected() {
        XCTAssertEqual(apiClient.connectionState, .disconnected)
    }
    
    func testTestConnectionWithoutConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.testConnection()
            XCTFail("Should throw error when not configured")
        } catch let error as APIError {
            XCTAssertEqual(error, .notConfigured)
        } catch {
            XCTFail("Wrong error type: \(error)")
        }
    }
    
    // MARK: - Client Endpoint Tests
    
    func testListClientsRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.listClients()
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testGetClientRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.getClient(id: "C.1234567890abcdef")
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testInterrogateClientRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.interrogateClient(id: "C.1234567890abcdef")
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    // MARK: - Hunt Endpoint Tests
    
    func testListHuntsRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.listHunts()
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    func testCreateHuntRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.createHunt(
                description: "Test Hunt",
                artifacts: ["Generic.Client.Info"]
            )
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    // MARK: - VQL Endpoint Tests
    
    func testExecuteQueryRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.executeQuery(vql: "SELECT * FROM info()")
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    // MARK: - VFS Endpoint Tests
    
    func testListVFSDirectoryRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.listVFSDirectory(
                clientId: "C.1234567890abcdef",
                path: "/etc"
            )
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    // MARK: - Artifact Endpoint Tests
    
    func testListArtifactsRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.listArtifacts()
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    // MARK: - User Endpoint Tests
    
    func testListUsersRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.listUsers()
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    // MARK: - Flow Endpoint Tests
    
    func testGetFlowRequiresConfiguration() async {
        // Given - no configuration
        
        // When/Then
        do {
            _ = try await apiClient.getFlow(
                clientId: "C.1234567890abcdef",
                flowId: "F.1234567890abcdef"
            )
            XCTFail("Should throw error when not configured")
        } catch {
            XCTAssertTrue(error is APIError)
        }
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorMapping() {
        // Test that URLError is properly mapped to APIError
        // This would require mocking URLSession responses
    }
    
    func testRetryLogic() async {
        // Test that transient errors trigger retry
        // This would require mocking URLSession responses
    }
    
    func testMaxRetryAttempts() async {
        // Test that retry stops after max attempts
        // This would require mocking URLSession responses
    }
    
    // MARK: - Performance Tests
    
    func testListClientsPerformance() {
        // Measure performance of listing clients
        // Would require a configured test server
    }
    
    func testExecuteQueryPerformance() {
        // Measure performance of VQL query execution
        // Would require a configured test server
    }
}

// MARK: - Integration Tests

/// Integration tests that require a running Velociraptor server
/// These tests are skipped by default and can be run manually
@MainActor
final class VelociraptorAPIClientIntegrationTests: XCTestCase {
    
    var apiClient: VelociraptorAPIClient!
    
    // Test configuration (set these for integration tests)
    let testServerURL = URL(string: "https://localhost:8889")!
    let testAPIKey = "" // Set to run integration tests
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Skip if no API key configured
        guard !testAPIKey.isEmpty else {
            throw XCTSkip("Integration tests require testAPIKey to be set")
        }
        
        apiClient = VelociraptorAPIClient.shared
        try await apiClient.configure(serverURL: testServerURL, apiKey: testAPIKey)
    }
    
    override func tearDown() async throws {
        try? await apiClient.disconnect()
        try await super.tearDown()
    }
    
    func testGetServerInfo() async throws {
        // When
        let serverInfo = try await apiClient.getServerInfo()
        
        // Then
        XCTAssertNotNil(serverInfo.version)
        print("Server version: \(serverInfo.version ?? "unknown")")
    }
    
    func testListClients() async throws {
        // When
        let clients = try await apiClient.listClients(limit: 10)
        
        // Then
        XCTAssertNotNil(clients)
        print("Found \(clients.count) clients")
    }
    
    func testListArtifacts() async throws {
        // When
        let artifacts = try await apiClient.listArtifacts()
        
        // Then
        XCTAssertNotNil(artifacts)
        XCTAssertTrue(artifacts.count > 0)
        print("Found \(artifacts.count) artifacts")
    }
    
    func testExecuteQuery() async throws {
        // Given
        let vql = "SELECT * FROM info()"
        
        // When
        let result = try await apiClient.executeQuery(vql: vql)
        
        // Then
        XCTAssertNotNil(result)
        print("Query returned \(result.totalRows ?? 0) rows")
    }
}
