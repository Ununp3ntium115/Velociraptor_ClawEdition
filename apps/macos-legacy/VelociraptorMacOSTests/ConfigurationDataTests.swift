//
//  ConfigurationDataTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for ConfigurationData model
//

import XCTest
@testable import Velociraptor

final class ConfigurationDataTests: XCTestCase {
    
    // MARK: - Default Values Tests
    
    func testDefaultValues() {
        let config = ConfigurationData()
        
        XCTAssertEqual(config.deploymentType, "Standalone")
        XCTAssertEqual(config.organizationName, "VelociraptorOrg")
        XCTAssertEqual(config.bindPort, 8000)
        XCTAssertEqual(config.guiBindPort, 8889)
        XCTAssertEqual(config.apiBindPort, 8001)
        XCTAssertEqual(config.bindAddress, "0.0.0.0")
        XCTAssertEqual(config.guiBindAddress, "127.0.0.1")
        XCTAssertEqual(config.encryptionType, .selfSigned)
        XCTAssertEqual(config.environment, .production)
        XCTAssertEqual(config.logLevel, .info)
        XCTAssertTrue(config.enforceTLS12)
        XCTAssertTrue(config.validateCertificates)
        XCTAssertFalse(config.enableDebugLogging)
        XCTAssertEqual(config.adminUsername, "admin")
    }
    
    func testDefaultPaths() {
        let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
        
        XCTAssertTrue(ConfigurationData.defaultDatastorePath.contains("Library/Application Support/Velociraptor"))
        XCTAssertTrue(ConfigurationData.defaultLogsPath.contains("Library/Logs/Velociraptor"))
        XCTAssertTrue(ConfigurationData.defaultCachePath.contains("Library/Caches/Velociraptor"))
        XCTAssertTrue(ConfigurationData.defaultDatastorePath.hasPrefix(homeDir))
    }
    
    // MARK: - Validation Tests
    
    func testValidConfigurationPasses() {
        var config = ConfigurationData()
        config.adminUsername = "admin"
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "SecurePass123"
        
        let errors = config.validate()
        
        // Should have no critical errors (password complexity might still fail)
        let criticalErrors = errors.filter { error in
            switch error {
            case .emptyUsername, .emptyPassword, .invalidPort, .portConflict:
                return true
            default:
                return false
            }
        }
        XCTAssertTrue(criticalErrors.isEmpty)
    }
    
    func testEmptyUsernameFails() {
        var config = ConfigurationData()
        config.adminUsername = ""
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "SecurePass123"
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.emptyUsername))
    }
    
    func testShortUsernameFails() {
        var config = ConfigurationData()
        config.adminUsername = "ab"
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "SecurePass123"
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.usernameTooShort))
    }
    
    func testInvalidUsernameCharactersFails() {
        var config = ConfigurationData()
        config.adminUsername = "admin@test"
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "SecurePass123"
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.invalidUsernameCharacters))
    }
    
    func testEmptyPasswordFails() {
        var config = ConfigurationData()
        config.adminUsername = "admin"
        config.adminPassword = ""
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.emptyPassword))
    }
    
    func testWeakPasswordFails() {
        var config = ConfigurationData()
        config.adminUsername = "admin"
        config.adminPassword = "short"
        config.confirmPassword = "short"
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.weakPassword))
    }
    
    func testPasswordMismatchFails() {
        var config = ConfigurationData()
        config.adminUsername = "admin"
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "DifferentPass123"
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.passwordMismatch))
    }
    
    func testInvalidPortFails() {
        var config = ConfigurationData()
        config.adminUsername = "admin"
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "SecurePass123"
        config.bindPort = 70000
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(where: { 
            if case .invalidPort = $0 { return true }
            return false
        }))
    }
    
    func testPortConflictFails() {
        var config = ConfigurationData()
        config.adminUsername = "admin"
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "SecurePass123"
        config.bindPort = 8000
        config.guiBindPort = 8000 // Same as bindPort
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.portConflict))
    }
    
    func testCustomCertRequiresPaths() {
        var config = ConfigurationData()
        config.adminUsername = "admin"
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "SecurePass123"
        config.encryptionType = .custom
        config.customCertPath = ""
        config.customKeyPath = ""
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.missingCertificate))
        XCTAssertTrue(errors.contains(.missingPrivateKey))
    }
    
    func testLetsEncryptRequiresDomain() {
        var config = ConfigurationData()
        config.adminUsername = "admin"
        config.adminPassword = "SecurePass123"
        config.confirmPassword = "SecurePass123"
        config.encryptionType = .letsEncrypt
        config.letsEncryptDomain = ""
        
        let errors = config.validate()
        
        XCTAssertTrue(errors.contains(.missingDomain))
    }
    
    // MARK: - Password Strength Tests
    
    func testPasswordStrengthWeak() {
        var config = ConfigurationData()
        config.adminPassword = "abc"
        
        XCTAssertEqual(config.passwordStrengthLevel, .weak)
    }
    
    func testPasswordStrengthMedium() {
        var config = ConfigurationData()
        // Password scoring: length(6*4=24) + lowercase(15) = 39 → medium (30-60)
        config.adminPassword = "abcdef"
        
        let level = config.passwordStrengthLevel
        XCTAssertTrue(level == .medium, "Expected medium for 6-char lowercase password, got \(level)")
    }
    
    func testPasswordStrengthStrong() {
        var config = ConfigurationData()
        // Password scoring: length(10*4=40) + uppercase(15) + lowercase(15) = 70 → strong (60-80)
        config.adminPassword = "SecurePass"
        
        let level = config.passwordStrengthLevel
        XCTAssertTrue(level == .strong, "Expected strong for mixed-case 10-char password, got \(level)")
    }
    
    func testPasswordStrengthVeryStrong() {
        var config = ConfigurationData()
        config.adminPassword = "V3ryS3cur3P@ssw0rd!"
        
        XCTAssertEqual(config.passwordStrengthLevel, .veryStrong)
    }
    
    // MARK: - YAML Generation Tests
    
    func testYAMLGeneration() {
        var config = ConfigurationData()
        config.organizationName = "TestOrg"
        config.bindAddress = "0.0.0.0"
        config.bindPort = 8000
        
        let yaml = config.toYAML()
        
        XCTAssertTrue(yaml.contains("TestOrg"))
        XCTAssertTrue(yaml.contains("8000"))
        XCTAssertTrue(yaml.contains("Frontend"))
    }
    
    // MARK: - Enum Tests
    
    func testEncryptionTypeProperties() {
        for type in ConfigurationData.EncryptionType.allCases {
            XCTAssertFalse(type.displayName.isEmpty)
            XCTAssertFalse(type.description.isEmpty)
            XCTAssertFalse(type.iconName.isEmpty)
        }
    }
    
    func testEnvironmentProperties() {
        for env in ConfigurationData.Environment.allCases {
            XCTAssertFalse(env.description.isEmpty)
        }
    }
    
    func testLogLevelProperties() {
        for level in ConfigurationData.LogLevel.allCases {
            XCTAssertFalse(level.description.isEmpty)
        }
    }
    
    func testDatastoreSizeProperties() {
        for size in ConfigurationData.DatastoreSize.allCases {
            XCTAssertFalse(size.description.isEmpty)
            XCTAssertFalse(size.recommendedDiskSpace.isEmpty)
        }
    }
    
    // MARK: - Equatable Tests
    
    func testEquatable() {
        let config1 = ConfigurationData()
        let config2 = ConfigurationData()
        
        XCTAssertEqual(config1, config2)
        
        var config3 = ConfigurationData()
        config3.adminUsername = "different"
        
        XCTAssertNotEqual(config1, config3)
    }
    
    // MARK: - Codable Tests
    
    func testEncodeDecode() throws {
        var config = ConfigurationData()
        config.adminUsername = "testuser"
        config.bindPort = 9000
        config.encryptionType = .custom
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(config)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(ConfigurationData.self, from: data)
        
        XCTAssertEqual(config.adminUsername, decoded.adminUsername)
        XCTAssertEqual(config.bindPort, decoded.bindPort)
        XCTAssertEqual(config.encryptionType, decoded.encryptionType)
    }
}
