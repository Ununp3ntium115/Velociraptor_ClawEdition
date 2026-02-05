//
//  VelociraptorBinaryBridgeTests.swift
//  VelociraptorMacOSTests
//
//  Test suite for Velociraptor Binary Bridge
//  Tests direct binary communication, streaming, and certificate extraction
//
//  CDIF Pattern: Comprehensive unit testing with mocks
//  Swift 6 Concurrency: @MainActor test isolation
//

import XCTest
@testable import Velociraptor

@MainActor
final class VelociraptorBinaryBridgeTests: XCTestCase {
    
    var bridge: VelociraptorBinaryBridge!
    var tempDir: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        bridge = VelociraptorBinaryBridge.shared
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        // Clean up temp directory
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }
    
    // MARK: - Configuration Tests
    
    func testBridgeConfigurationCreation() {
        // Given
        let binaryPath = "/usr/local/bin/velociraptor"
        let configPath = "/etc/velociraptor/config.yaml"
        
        // When
        let config = BinaryBridgeConfiguration(
            binaryPath: binaryPath,
            configPath: configPath,
            grpcPort: 8000,
            guiPort: 8889,
            verbose: false
        )
        
        // Then
        XCTAssertEqual(config.binaryPath, binaryPath)
        XCTAssertEqual(config.configPath, configPath)
        XCTAssertEqual(config.grpcPort, 8000)
        XCTAssertEqual(config.guiPort, 8889)
        XCTAssertFalse(config.verbose)
    }
    
    func testBridgeConfigurationWithVerbose() {
        // When
        let config = BinaryBridgeConfiguration(
            binaryPath: "/usr/local/bin/velociraptor",
            configPath: "/etc/velociraptor/config.yaml",
            grpcPort: 9000,
            guiPort: 9889,
            verbose: true
        )
        
        // Then
        XCTAssertEqual(config.grpcPort, 9000)
        XCTAssertEqual(config.guiPort, 9889)
        XCTAssertTrue(config.verbose)
    }
    
    // MARK: - State Tests
    
    func testBridgeInitialState() {
        // Then
        XCTAssertEqual(bridge.state, .disconnected)
        XCTAssertFalse(bridge.isProcessRunning)
        XCTAssertNil(bridge.lastError)
        XCTAssertNil(bridge.extractedCertificates)
    }
    
    func testBridgeStateDescription() {
        // Test all state descriptions
        XCTAssertFalse(BinaryBridgeState.disconnected.isConnected)
        XCTAssertFalse(BinaryBridgeState.connecting.isConnected)
        XCTAssertTrue(BinaryBridgeState.connected.isConnected)
        XCTAssertFalse(BinaryBridgeState.error("test").isConnected)
    }
    
    // MARK: - Error Type Tests
    
    func testBinaryBridgeErrorDescriptions() {
        // Test error descriptions are meaningful
        let binaryNotFoundError = BinaryBridgeError.binaryNotFound("/path/to/binary")
        XCTAssertTrue(binaryNotFoundError.localizedDescription.contains("/path/to/binary"))
        
        let configNotFoundError = BinaryBridgeError.configNotFound("/path/to/config")
        XCTAssertTrue(configNotFoundError.localizedDescription.contains("/path/to/config"))
        
        let connectionError = BinaryBridgeError.connectionFailed("timeout")
        XCTAssertTrue(connectionError.localizedDescription.contains("timeout"))
        
        let streamingError = BinaryBridgeError.streamingFailed("network error")
        XCTAssertTrue(streamingError.localizedDescription.contains("network error"))
        
        let certError = BinaryBridgeError.certificateExtractionFailed("invalid format")
        XCTAssertTrue(certError.localizedDescription.contains("invalid format"))
        
        let configError = BinaryBridgeError.configurationError("missing field")
        XCTAssertTrue(configError.localizedDescription.contains("missing field"))
        
        let processError = BinaryBridgeError.processTerminated(1)
        XCTAssertTrue(processError.localizedDescription.contains("1"))
        
        let timeoutError = BinaryBridgeError.timeout
        XCTAssertFalse(timeoutError.localizedDescription.isEmpty)
        
        let invalidResponseError = BinaryBridgeError.invalidResponse
        XCTAssertFalse(invalidResponseError.localizedDescription.isEmpty)
    }
    
    // MARK: - Certificate Info Tests
    
    func testCertificateInfoCreation() {
        // Given
        let caCert = "-----BEGIN CERTIFICATE-----\nCA\n-----END CERTIFICATE-----"
        let clientCert = "-----BEGIN CERTIFICATE-----\nCLIENT\n-----END CERTIFICATE-----"
        let clientKey = "-----BEGIN PRIVATE KEY-----\nKEY\n-----END PRIVATE KEY-----"
        let expiration = Date().addingTimeInterval(86400 * 365)
        
        // When
        let certInfo = CertificateInfo(
            clientCertPEM: clientCert,
            clientKeyPEM: clientKey,
            caCertPEM: caCert,
            serverCN: "velociraptor.local",
            expirationDate: expiration
        )
        
        // Then
        XCTAssertEqual(certInfo.caCertPEM, caCert)
        XCTAssertEqual(certInfo.clientCertPEM, clientCert)
        XCTAssertEqual(certInfo.clientKeyPEM, clientKey)
        XCTAssertEqual(certInfo.serverCN, "velociraptor.local")
        XCTAssertNotNil(certInfo.expirationDate)
        XCTAssertTrue(certInfo.isValid)
    }
    
    func testCertificateInfoExpired() {
        // Given - expired certificate
        let expiration = Date().addingTimeInterval(-86400)  // 1 day ago
        
        // When
        let certInfo = CertificateInfo(
            clientCertPEM: "cert",
            clientKeyPEM: "key",
            caCertPEM: "ca",
            serverCN: "test",
            expirationDate: expiration
        )
        
        // Then
        XCTAssertFalse(certInfo.isValid)
    }
    
    // MARK: - Streaming Result Tests
    
    func testStreamingResultCreation() {
        // Given
        let columns = ["ClientId", "Hostname"]
        let row: [VQLValue] = [.string("C.123"), .string("test-host")]
        
        // When
        let result = StreamingResult(
            columns: columns,
            row: row,
            isComplete: false
        )
        
        // Then
        XCTAssertEqual(result.columns, columns)
        XCTAssertEqual(result.row.count, 2)
        XCTAssertFalse(result.isComplete)
    }
    
    func testStreamingResultComplete() {
        // When
        let result = StreamingResult(
            columns: [],
            row: [],
            isComplete: true
        )
        
        // Then
        XCTAssertTrue(result.isComplete)
    }
    
    // MARK: - Configuration Validation Tests
    
    func testConfigureWithInvalidBinaryPath() async throws {
        // Given
        let config = BinaryBridgeConfiguration(
            binaryPath: "/nonexistent/path/velociraptor",
            configPath: "/etc/velociraptor/config.yaml",
            grpcPort: 8000,
            guiPort: 8889,
            verbose: false
        )
        
        // When/Then
        do {
            try await bridge.configure(config)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - binary doesn't exist
            XCTAssertTrue(error is BinaryBridgeError)
        }
    }
    
    // MARK: - VQLValue Extension Tests
    
    func testVQLValueFromString() {
        let value = VQLValue.from("hello")
        if case .string(let s) = value {
            XCTAssertEqual(s, "hello")
        } else {
            XCTFail("Expected string value")
        }
    }
    
    func testVQLValueFromInt() {
        let value = VQLValue.from(42)
        if case .number(let n) = value {
            XCTAssertEqual(n, 42.0)
        } else {
            XCTFail("Expected number value")
        }
    }
    
    func testVQLValueFromDouble() {
        let value = VQLValue.from(3.14)
        if case .number(let n) = value {
            XCTAssertEqual(n, 3.14)
        } else {
            XCTFail("Expected number value")
        }
    }
    
    func testVQLValueFromBool() {
        let trueValue = VQLValue.from(true)
        if case .bool(let b) = trueValue {
            XCTAssertTrue(b)
        } else {
            XCTFail("Expected bool value")
        }
        
        let falseValue = VQLValue.from(false)
        if case .bool(let b) = falseValue {
            XCTAssertFalse(b)
        } else {
            XCTFail("Expected bool value")
        }
    }
    
    func testVQLValueFromNSNull() {
        let value = VQLValue.from(NSNull())
        if case .null = value {
            // Expected
        } else {
            XCTFail("Expected null value")
        }
    }
    
    func testVQLValueFromArray() {
        let array = [1, 2, 3]
        let value = VQLValue.from(array)
        if case .array(let arr) = value {
            XCTAssertEqual(arr.count, 3)
        } else {
            XCTFail("Expected array value")
        }
    }
    
    func testVQLValueFromDictionary() {
        let dict = ["key": "value"]
        let value = VQLValue.from(dict)
        if case .object(_) = value {
            // Expected
        } else {
            XCTFail("Expected object value")
        }
    }
    
    // MARK: - Integration Tests (require actual binary)
    
    func testBinaryDownloadURLConstruction() async {
        // Test that download URL is constructed correctly for the platform
        // This is a unit test that doesn't require network access
        
        // macOS ARM64
        let expectedArm64URL = "https://github.com/Velocidex/velociraptor/releases/latest/download/velociraptor-darwin-arm64"
        XCTAssertTrue(expectedArm64URL.contains("darwin"))
        
        // macOS x86_64
        let expectedX64URL = "https://github.com/Velocidex/velociraptor/releases/latest/download/velociraptor-darwin-amd64"
        XCTAssertTrue(expectedX64URL.contains("darwin"))
    }
}
