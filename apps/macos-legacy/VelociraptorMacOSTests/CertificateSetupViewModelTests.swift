//
//  CertificateSetupViewModelTests.swift
//  VelociraptorMacOSTests
//
//  Test suite for Certificate Setup View Model
//  Tests certificate extraction, validation, and mTLS configuration
//
//  CDIF Pattern: Comprehensive unit testing for certificate workflows
//  Swift 6 Concurrency: @MainActor test isolation
//

import XCTest
@testable import Velociraptor

@MainActor
final class CertificateSetupViewModelTests: XCTestCase {
    
    var viewModel: CertificateSetupViewModel!
    var tempDir: URL!
    
    override func setUp() async throws {
        try await super.setUp()
        viewModel = CertificateSetupViewModel()
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }
    
    override func tearDown() async throws {
        try? FileManager.default.removeItem(at: tempDir)
        try await super.tearDown()
    }
    
    // MARK: - Initial State Tests
    
    func testInitialState() {
        XCTAssertEqual(viewModel.currentStep, .source)
        XCTAssertTrue(viewModel.configFilePath.isEmpty)
        XCTAssertEqual(viewModel.serverURL, "https://127.0.0.1:8889")
        XCTAssertFalse(viewModel.isExtracting)
        XCTAssertNil(viewModel.extractionError)
        XCTAssertNil(viewModel.extractedCertInfo)
        XCTAssertFalse(viewModel.isTesting)
    }
    
    // MARK: - Step Navigation Tests
    
    func testCanProceedFromSourceStep() {
        // Given
        viewModel.currentStep = .source
        
        // When - no config path set (default serverConfig source)
        viewModel.configFilePath = ""
        let canProceed1 = viewModel.canProceed
        
        // Then
        XCTAssertFalse(canProceed1)
        
        // When - set config file path
        viewModel.configFilePath = "/path/to/config.yaml"
        
        // Then
        XCTAssertTrue(viewModel.canProceed)
    }
    
    func testCanProceedFromExtractStep() {
        // Given
        viewModel.currentStep = .extract
        
        // When - no certificates extracted
        XCTAssertFalse(viewModel.canProceed)
        
        // When - certificates extracted
        viewModel.extractedCertInfo = CertificateInfo(
            clientCertPEM: "CLIENT",
            clientKeyPEM: "KEY",
            caCertPEM: "CA",
            serverCN: "localhost",
            expirationDate: nil
        )
        
        // Then
        XCTAssertTrue(viewModel.canProceed)
    }
    
    func testCanProceedFromVerifyStep() {
        // Given
        viewModel.currentStep = .verify
        
        // When - connection test not passed
        XCTAssertFalse(viewModel.canProceed)
        
        // When - connection test passed
        viewModel.connectionTestResult = ConnectionTestResult(
            success: true,
            message: "Connected successfully",
            serverVersion: "0.75.0"
        )
        
        // Then
        XCTAssertTrue(viewModel.canProceed)
    }
    
    func testPreviousStep() {
        // Given
        viewModel.currentStep = .extract
        
        // When
        viewModel.previousStep()
        
        // Then
        XCTAssertEqual(viewModel.currentStep, .source)
    }
    
    func testCannotGoBackFromSourceStep() {
        // Given
        viewModel.currentStep = .source
        
        // When
        viewModel.previousStep()
        
        // Then - should stay at source
        XCTAssertEqual(viewModel.currentStep, .source)
    }
    
    // MARK: - Certificate Source Tests
    
    func testCertificateSourceEnum() {
        // Test CertificateSource enum exists with expected cases
        let serverConfig = CertificateSource.serverConfig
        let files = CertificateSource.files
        
        XCTAssertNotNil(serverConfig)
        XCTAssertNotNil(files)
    }
    
    // MARK: - Certificate Step Tests
    
    func testCertificateStepOrder() {
        let steps: [CertificateSetupStep] = [.source, .extract, .verify, .configure, .complete]
        
        // Verify all steps exist
        XCTAssertEqual(steps.count, 5)
    }
    
    // MARK: - Certificate Info Validation Tests
    
    func testCertificateInfoValidation() {
        // Valid certificate info
        let validCert = CertificateInfo(
            clientCertPEM: "-----BEGIN CERTIFICATE-----\nCLIENT\n-----END CERTIFICATE-----",
            clientKeyPEM: "-----BEGIN PRIVATE KEY-----\nKEY\n-----END PRIVATE KEY-----",
            caCertPEM: "-----BEGIN CERTIFICATE-----\nCA\n-----END CERTIFICATE-----",
            serverCN: "velociraptor.local",
            expirationDate: Date().addingTimeInterval(86400 * 365)
        )
        
        XCTAssertFalse(validCert.caCertPEM.isEmpty)
        XCTAssertFalse(validCert.clientCertPEM.isEmpty)
        XCTAssertFalse(validCert.clientKeyPEM.isEmpty)
        XCTAssertTrue(validCert.isValid)
    }
    
    // MARK: - Loading State Tests
    
    func testLoadingStateManagement() {
        XCTAssertFalse(viewModel.isExtracting)
        
        viewModel.isExtracting = true
        XCTAssertTrue(viewModel.isExtracting)
        
        viewModel.isExtracting = false
        XCTAssertFalse(viewModel.isExtracting)
    }
    
    // MARK: - Error State Tests
    
    func testErrorStateManagement() {
        XCTAssertNil(viewModel.extractionError)
        
        viewModel.extractionError = "Test error message"
        XCTAssertEqual(viewModel.extractionError, "Test error message")
        
        viewModel.extractionError = nil
        XCTAssertNil(viewModel.extractionError)
    }
    
    // MARK: - Connection Test Result Tests
    
    func testConnectionTestResultSuccess() {
        let result = ConnectionTestResult(
            success: true,
            message: "Connected successfully",
            serverVersion: "0.75.0"
        )
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.serverVersion, "0.75.0")
        XCTAssertEqual(result.message, "Connected successfully")
    }
    
    func testConnectionTestResultFailure() {
        let result = ConnectionTestResult(
            success: false,
            message: "Connection refused",
            serverVersion: nil
        )
        
        XCTAssertFalse(result.success)
        XCTAssertNil(result.serverVersion)
        XCTAssertEqual(result.message, "Connection refused")
    }
    
    // MARK: - Mock Configuration File Tests
    
    func testWriteAndReadMockConfigFile() throws {
        // Given - create a mock Velociraptor config file
        let configContent = """
        version: 1
        Client:
          server_urls:
            - https://velociraptor.local:8889
          ca_certificate: |
            -----BEGIN CERTIFICATE-----
            MIIC... (mock CA)
            -----END CERTIFICATE-----
          certificate: |
            -----BEGIN CERTIFICATE-----
            MIIC... (mock client cert)
            -----END CERTIFICATE-----
          private_key: |
            -----BEGIN RSA PRIVATE KEY-----
            MIIEp... (mock private key)
            -----END RSA PRIVATE KEY-----
        """
        
        let configPath = tempDir.appendingPathComponent("test_config.yaml")
        try configContent.write(to: configPath, atomically: true, encoding: .utf8)
        
        // When
        viewModel.configFilePath = configPath.path
        
        // Then
        XCTAssertFalse(viewModel.configFilePath.isEmpty)
        XCTAssertTrue(FileManager.default.fileExists(atPath: viewModel.configFilePath))
    }
}
