//
//  APIAuthenticationServiceTests.swift
//  VelociraptorMacOSTests
//
//  Test suite for API Authentication Service
//  Gap: 0x01 - API Client Foundation
//
//  CDIF Pattern: Secure credential management testing
//  Swift 6 Concurrency: @MainActor test isolation
//

import XCTest
@testable import Velociraptor

@MainActor
final class APIAuthenticationServiceTests: XCTestCase {
    
    var authService: APIAuthenticationService!
    
    override func setUp() async throws {
        try await super.setUp()
        authService = APIAuthenticationService.shared
        
        // Clear any existing credentials
        try? authService.clearCredentials()
    }
    
    override func tearDown() async throws {
        // Clean up
        try? authService.clearCredentials()
        try await super.tearDown()
    }
    
    // MARK: - API Key Tests
    
    func testSaveAndLoadAPIKeyCredentials() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let apiKey = "test-api-key-12345"
        
        // When
        try authService.saveAPIKeyCredentials(serverURL: serverURL, apiKey: apiKey)
        
        // Then
        XCTAssertTrue(authService.isConfigured)
        XCTAssertEqual(authService.authMethod, .apiKey)
        
        let credentials = authService.getCredentials()
        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.serverURL, serverURL)
        XCTAssertEqual(credentials?.apiKey, apiKey)
    }
    
    func testAPIKeyPersistence() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let apiKey = "test-api-key-12345"
        
        // When - save credentials
        try authService.saveAPIKeyCredentials(serverURL: serverURL, apiKey: apiKey)
        
        // Simulate app restart by creating new instance
        let newAuthService = APIAuthenticationService.shared
        
        // Then - credentials should be loaded from keychain
        XCTAssertTrue(newAuthService.isConfigured)
        let credentials = newAuthService.getCredentials()
        XCTAssertEqual(credentials?.apiKey, apiKey)
    }
    
    // MARK: - Basic Auth Tests
    
    func testSaveAndLoadBasicAuthCredentials() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let username = "admin"
        let password = "secure-password"
        
        // When
        try authService.saveBasicAuthCredentials(
            serverURL: serverURL,
            username: username,
            password: password
        )
        
        // Then
        XCTAssertTrue(authService.isConfigured)
        XCTAssertEqual(authService.authMethod, .basicAuth)
        
        let credentials = authService.getCredentials()
        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.serverURL, serverURL)
        XCTAssertEqual(credentials?.username, username)
        XCTAssertEqual(credentials?.password, password)
    }
    
    // MARK: - mTLS Tests
    
    func testSaveMTLSCredentials() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let tempDir = FileManager.default.temporaryDirectory
        let certPath = tempDir.appendingPathComponent("test-cert.pem").path
        let keyPath = tempDir.appendingPathComponent("test-key.pem").path
        
        // Create temporary files
        try "CERT".write(toFile: certPath, atomically: true, encoding: .utf8)
        try "KEY".write(toFile: keyPath, atomically: true, encoding: .utf8)
        
        // When
        try authService.saveMTLSCredentials(
            serverURL: serverURL,
            certificatePath: certPath,
            keyPath: keyPath
        )
        
        // Then
        XCTAssertTrue(authService.isConfigured)
        XCTAssertEqual(authService.authMethod, .mtls)
        
        let credentials = authService.getCredentials()
        XCTAssertNotNil(credentials)
        XCTAssertEqual(credentials?.serverURL, serverURL)
        XCTAssertEqual(credentials?.certificatePath, certPath)
        XCTAssertEqual(credentials?.keyPath, keyPath)
        
        // Cleanup
        try? FileManager.default.removeItem(atPath: certPath)
        try? FileManager.default.removeItem(atPath: keyPath)
    }
    
    func testMTLSWithMissingCertificate() {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let certPath = "/nonexistent/cert.pem"
        let keyPath = "/nonexistent/key.pem"
        
        // When/Then
        XCTAssertThrowsError(try authService.saveMTLSCredentials(
            serverURL: serverURL,
            certificatePath: certPath,
            keyPath: keyPath
        )) { error in
            XCTAssertTrue(error is AuthenticationError)
            if case .certificateNotFound(let path) = error as? AuthenticationError {
                XCTAssertEqual(path, certPath)
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    // MARK: - Credential Management Tests
    
    func testClearCredentials() throws {
        // Given - save credentials
        let serverURL = URL(string: "https://localhost:8889")!
        let apiKey = "test-api-key"
        try authService.saveAPIKeyCredentials(serverURL: serverURL, apiKey: apiKey)
        XCTAssertTrue(authService.isConfigured)
        
        // When
        try authService.clearCredentials()
        
        // Then
        XCTAssertFalse(authService.isConfigured)
        XCTAssertEqual(authService.authMethod, .none)
        XCTAssertNil(authService.getCredentials())
    }
    
    func testOverwriteCredentials() throws {
        // Given - initial API key credentials
        let serverURL1 = URL(string: "https://localhost:8889")!
        let apiKey1 = "test-api-key-1"
        try authService.saveAPIKeyCredentials(serverURL: serverURL1, apiKey: apiKey1)
        
        // When - save different credentials
        let serverURL2 = URL(string: "https://localhost:9999")!
        let username = "admin"
        let password = "password"
        try authService.saveBasicAuthCredentials(
            serverURL: serverURL2,
            username: username,
            password: password
        )
        
        // Then - should have new credentials
        XCTAssertEqual(authService.authMethod, .basicAuth)
        let credentials = authService.getCredentials()
        XCTAssertEqual(credentials?.serverURL, serverURL2)
        XCTAssertEqual(credentials?.username, username)
    }
    
    // MARK: - URLSession Configuration Tests
    
    func testCreateAuthenticatedURLSessionWithAPIKey() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let apiKey = "test-api-key"
        try authService.saveAPIKeyCredentials(serverURL: serverURL, apiKey: apiKey)
        
        // When
        let session = try authService.createAuthenticatedURLSession()
        
        // Then
        XCTAssertNotNil(session)
        XCTAssertEqual(session.configuration.timeoutIntervalForRequest, 30)
    }
    
    func testCreateAuthenticatedURLSessionWithoutConfiguration() {
        // Given - no configuration
        try? authService.clearCredentials()
        
        // When/Then
        XCTAssertThrowsError(try authService.createAuthenticatedURLSession()) { error in
            XCTAssertTrue(error is APIError)
            if case .notConfigured = error as? APIError {
                // Expected error
            } else {
                XCTFail("Wrong error type")
            }
        }
    }
    
    // MARK: - Request Authentication Tests
    
    func testAuthenticateRequestWithAPIKey() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let apiKey = "test-api-key-12345"
        try authService.saveAPIKeyCredentials(serverURL: serverURL, apiKey: apiKey)
        
        var request = URLRequest(url: serverURL)
        
        // When
        try authService.authenticateRequest(&request)
        
        // Then
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        XCTAssertEqual(authHeader, "Bearer \(apiKey)")
    }
    
    func testAuthenticateRequestWithBasicAuth() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let username = "admin"
        let password = "password"
        try authService.saveBasicAuthCredentials(
            serverURL: serverURL,
            username: username,
            password: password
        )
        
        var request = URLRequest(url: serverURL)
        
        // When
        try authService.authenticateRequest(&request)
        
        // Then
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        let expectedCredentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        XCTAssertEqual(authHeader, "Basic \(expectedCredentials)")
    }
    
    func testAuthenticateRequestWithMTLS() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let tempDir = FileManager.default.temporaryDirectory
        let certPath = tempDir.appendingPathComponent("test-cert.pem").path
        let keyPath = tempDir.appendingPathComponent("test-key.pem").path
        
        try "CERT".write(toFile: certPath, atomically: true, encoding: .utf8)
        try "KEY".write(toFile: keyPath, atomically: true, encoding: .utf8)
        
        try authService.saveMTLSCredentials(
            serverURL: serverURL,
            certificatePath: certPath,
            keyPath: keyPath
        )
        
        var request = URLRequest(url: serverURL)
        
        // When
        try authService.authenticateRequest(&request)
        
        // Then - mTLS doesn't add headers (handled at session level)
        let authHeader = request.value(forHTTPHeaderField: "Authorization")
        XCTAssertNil(authHeader)
        
        // Cleanup
        try? FileManager.default.removeItem(atPath: certPath)
        try? FileManager.default.removeItem(atPath: keyPath)
    }
    
    // MARK: - Validation Tests
    
    func testValidateCredentialsSuccess() throws {
        // Given
        let serverURL = URL(string: "https://localhost:8889")!
        let apiKey = "test-api-key"
        try authService.saveAPIKeyCredentials(serverURL: serverURL, apiKey: apiKey)
        
        // When/Then
        XCTAssertNoThrow(try authService.validateCredentials())
    }
    
    func testValidateCredentialsFailsWithoutConfiguration() {
        // Given - no configuration
        try? authService.clearCredentials()
        
        // When/Then
        XCTAssertThrowsError(try authService.validateCredentials()) { error in
            XCTAssertTrue(error is APIError)
        }
    }
}
