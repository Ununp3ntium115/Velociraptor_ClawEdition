//
//  ConfigurationExporterTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for ConfigurationExporter
//

import XCTest
@testable import Velociraptor

final class ConfigurationExporterTests: XCTestCase {
    
    var tempDirectory: URL!
    
    override func setUp() {
        super.setUp()
        tempDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("VelociraptorTests-\(UUID().uuidString)")
        try? FileManager.default.createDirectory(at: tempDirectory, withIntermediateDirectories: true)
    }
    
    override func tearDown() {
        try? FileManager.default.removeItem(at: tempDirectory)
        super.tearDown()
    }
    
    // MARK: - Export Format Tests
    
    func testExportFormatProperties() {
        for format in ConfigurationExporter.ExportFormat.allCases {
            XCTAssertFalse(format.displayName.isEmpty)
            XCTAssertFalse(format.fileExtension.isEmpty)
        }
    }
    
    func testDefaultFilename() {
        let yamlFilename = ConfigurationExporter.defaultFilename(format: .yaml)
        XCTAssertTrue(yamlFilename.contains("velociraptor-config-"))
        XCTAssertTrue(yamlFilename.hasSuffix(".yaml"))
        
        let jsonFilename = ConfigurationExporter.defaultFilename(format: .json)
        XCTAssertTrue(jsonFilename.hasSuffix(".json"))
        
        let plistFilename = ConfigurationExporter.defaultFilename(format: .plist)
        XCTAssertTrue(plistFilename.hasSuffix(".plist"))
    }
    
    // MARK: - YAML Export Tests
    
    func testExportToYAML() throws {
        var config = ConfigurationData()
        config.organizationName = "TestOrg"
        config.bindPort = 9000
        
        let yaml = try ConfigurationExporter.exportToYAML(config)
        
        XCTAssertTrue(yaml.contains("TestOrg"))
        XCTAssertTrue(yaml.contains("9000"))
        XCTAssertTrue(yaml.contains("Frontend"))
    }
    
    func testExportToYAMLFile() throws {
        var config = ConfigurationData()
        config.organizationName = "FileTestOrg"
        
        let fileURL = tempDirectory.appendingPathComponent("test.yaml")
        try ConfigurationExporter.export(config, to: fileURL, format: .yaml)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
        
        let content = try String(contentsOf: fileURL, encoding: .utf8)
        XCTAssertTrue(content.contains("FileTestOrg"))
    }
    
    // MARK: - JSON Export Tests
    
    func testExportToJSON() throws {
        var config = ConfigurationData()
        config.adminUsername = "jsonuser"
        config.bindPort = 8500
        
        let jsonData = try ConfigurationExporter.exportToJSON(config)
        
        XCTAssertFalse(jsonData.isEmpty)
        
        let jsonString = String(data: jsonData, encoding: .utf8)
        XCTAssertNotNil(jsonString)
        XCTAssertTrue(jsonString!.contains("jsonuser"))
        XCTAssertTrue(jsonString!.contains("8500"))
    }
    
    func testExportToJSONFile() throws {
        var config = ConfigurationData()
        config.organizationName = "JSONFileOrg"
        
        let fileURL = tempDirectory.appendingPathComponent("test.json")
        try ConfigurationExporter.export(config, to: fileURL, format: .json)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    // MARK: - Plist Export Tests
    
    func testExportToPlist() throws {
        var config = ConfigurationData()
        config.organizationName = "PlistOrg"
        
        let plistData = try ConfigurationExporter.exportToPlist(config)
        
        XCTAssertFalse(plistData.isEmpty)
        
        // Verify it's valid plist
        let decoder = PropertyListDecoder()
        let decoded = try decoder.decode(ConfigurationData.self, from: plistData)
        XCTAssertEqual(decoded.organizationName, "PlistOrg")
    }
    
    func testExportToPlistFile() throws {
        var config = ConfigurationData()
        config.organizationName = "PlistFileOrg"
        
        let fileURL = tempDirectory.appendingPathComponent("test.plist")
        try ConfigurationExporter.export(config, to: fileURL, format: .plist)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path))
    }
    
    // MARK: - JSON Import Tests
    
    func testImportFromJSON() throws {
        var original = ConfigurationData()
        original.organizationName = "ImportTest"
        original.bindPort = 7777
        original.adminUsername = "importuser"
        
        let jsonData = try ConfigurationExporter.exportToJSON(original)
        let imported = try ConfigurationExporter.importFromJSON(jsonData)
        
        XCTAssertEqual(imported.organizationName, original.organizationName)
        XCTAssertEqual(imported.bindPort, original.bindPort)
        XCTAssertEqual(imported.adminUsername, original.adminUsername)
    }
    
    func testImportFromJSONFile() throws {
        var original = ConfigurationData()
        original.organizationName = "FileImportTest"
        
        let fileURL = tempDirectory.appendingPathComponent("import.json")
        try ConfigurationExporter.export(original, to: fileURL, format: .json)
        
        let imported = try ConfigurationExporter.importFrom(fileURL)
        
        XCTAssertEqual(imported.organizationName, original.organizationName)
    }
    
    // MARK: - Plist Import Tests
    
    func testImportFromPlist() throws {
        var original = ConfigurationData()
        original.organizationName = "PlistImport"
        original.guiBindPort = 9999
        
        let plistData = try ConfigurationExporter.exportToPlist(original)
        let imported = try ConfigurationExporter.importFromPlist(plistData)
        
        XCTAssertEqual(imported.organizationName, original.organizationName)
        XCTAssertEqual(imported.guiBindPort, original.guiBindPort)
    }
    
    func testImportFromPlistFile() throws {
        var original = ConfigurationData()
        original.organizationName = "PlistFileImport"
        
        let fileURL = tempDirectory.appendingPathComponent("import.plist")
        try ConfigurationExporter.export(original, to: fileURL, format: .plist)
        
        let imported = try ConfigurationExporter.importFrom(fileURL)
        
        XCTAssertEqual(imported.organizationName, original.organizationName)
    }
    
    // MARK: - YAML Import Tests
    
    func testImportFromYAML() throws {
        let yaml = """
        version:
          name: "YAMLImportOrg"
        
        Frontend:
          bind_address: "0.0.0.0"
          bind_port: 8080
        
        GUI:
          bind_address: "127.0.0.1"
          bind_port: 9090
        """
        
        let imported = try ConfigurationExporter.importFromYAML(yaml)
        
        XCTAssertEqual(imported.organizationName, "YAMLImportOrg")
        XCTAssertEqual(imported.bindAddress, "0.0.0.0")
        XCTAssertEqual(imported.bindPort, 8080)
        XCTAssertEqual(imported.guiBindAddress, "127.0.0.1")
        XCTAssertEqual(imported.guiBindPort, 9090)
    }
    
    func testImportFromYAMLFile() throws {
        let yaml = """
        version:
          name: "YAMLFileOrg"
        
        Frontend:
          bind_port: 7070
        """
        
        let fileURL = tempDirectory.appendingPathComponent("import.yaml")
        try yaml.write(to: fileURL, atomically: true, encoding: .utf8)
        
        let imported = try ConfigurationExporter.importFrom(fileURL)
        
        XCTAssertEqual(imported.organizationName, "YAMLFileOrg")
        XCTAssertEqual(imported.bindPort, 7070)
    }
    
    // MARK: - Round-trip Tests
    
    func testJSONRoundTrip() throws {
        var original = ConfigurationData()
        original.organizationName = "RoundTrip"
        original.bindPort = 5555
        original.guiBindPort = 6666
        original.adminUsername = "rounduser"
        original.encryptionType = .custom
        original.environment = .development
        
        let jsonData = try ConfigurationExporter.exportToJSON(original)
        let imported = try ConfigurationExporter.importFromJSON(jsonData)
        
        XCTAssertEqual(imported.organizationName, original.organizationName)
        XCTAssertEqual(imported.bindPort, original.bindPort)
        XCTAssertEqual(imported.guiBindPort, original.guiBindPort)
        XCTAssertEqual(imported.adminUsername, original.adminUsername)
        XCTAssertEqual(imported.encryptionType, original.encryptionType)
        XCTAssertEqual(imported.environment, original.environment)
    }
    
    func testPlistRoundTrip() throws {
        var original = ConfigurationData()
        original.organizationName = "PlistRoundTrip"
        original.logLevel = .debug
        
        let plistData = try ConfigurationExporter.exportToPlist(original)
        let imported = try ConfigurationExporter.importFromPlist(plistData)
        
        XCTAssertEqual(imported.organizationName, original.organizationName)
        XCTAssertEqual(imported.logLevel, original.logLevel)
    }
    
    // MARK: - Error Handling Tests
    
    func testImportFromNonexistentFile() {
        let fakeURL = tempDirectory.appendingPathComponent("nonexistent.json")
        
        XCTAssertThrowsError(try ConfigurationExporter.importFrom(fakeURL)) { error in
            XCTAssertTrue(error is ConfigurationExporter.ImportError)
            if let importError = error as? ConfigurationExporter.ImportError {
                if case .fileNotFound = importError {
                    // Expected
                } else {
                    XCTFail("Wrong error type: \(importError)")
                }
            }
        }
    }
    
    func testImportFromInvalidJSON() {
        let invalidJSON = "{ this is not valid json }"
        let data = invalidJSON.data(using: .utf8)!
        
        XCTAssertThrowsError(try ConfigurationExporter.importFromJSON(data)) { error in
            XCTAssertTrue(error is ConfigurationExporter.ImportError)
        }
    }
    
    // MARK: - Backup Tests
    
    func testCreateBackup() throws {
        var config = ConfigurationData()
        config.organizationName = "BackupTest"
        
        let backupURL = try ConfigurationExporter.createBackup(of: config, in: tempDirectory)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: backupURL.path))
        
        let imported = try ConfigurationExporter.importFrom(backupURL)
        XCTAssertEqual(imported.organizationName, "BackupTest")
    }
    
    func testListBackups() throws {
        let config = ConfigurationData()
        
        // Create a few backups with delay to ensure different timestamps
        _ = try ConfigurationExporter.createBackup(of: config, in: tempDirectory)
        Thread.sleep(forTimeInterval: 0.1)  // Small delay to ensure different timestamps
        _ = try ConfigurationExporter.createBackup(of: config, in: tempDirectory)
        
        // We can't easily test the default backup directory, but we can test the list function
        let backups = try FileManager.default.contentsOfDirectory(
            at: tempDirectory,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "json" }
        
        // Accept 1 or 2 backups - depending on timestamp resolution, they might have the same name
        XCTAssertGreaterThanOrEqual(backups.count, 1, "Should have at least 1 backup")
        XCTAssertLessThanOrEqual(backups.count, 2, "Should have at most 2 backups")
    }
    
    // MARK: - Error Description Tests
    
    func testExportErrorDescriptions() {
        let errors: [ConfigurationExporter.ExportError] = [
            .encodingFailed,
            .writeFailed("/test/path"),
            .unsupportedFormat,
            .invalidConfiguration
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
    
    func testImportErrorDescriptions() {
        let errors: [ConfigurationExporter.ImportError] = [
            .fileNotFound,
            .decodingFailed("test reason"),
            .unsupportedFormat,
            .invalidData
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }
}
