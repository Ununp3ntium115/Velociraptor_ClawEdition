//
//  ConfigurationExporter.swift
//  VelociraptorMacOS
//
//  Configuration import/export utilities
//

import Foundation
import UniformTypeIdentifiers

/// Handles import and export of Velociraptor configurations
class ConfigurationExporter {
    // MARK: - Types
    
    /// Export format options
    enum ExportFormat: String, CaseIterable, Identifiable {
        case yaml = "yaml"
        case json = "json"
        case plist = "plist"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .yaml: return "YAML Configuration"
            case .json: return "JSON Configuration"
            case .plist: return "Property List"
            }
        }
        
        var fileExtension: String {
            switch self {
            case .yaml: return "yaml"
            case .json: return "json"
            case .plist: return "plist"
            }
        }
        
        var contentType: UTType {
            switch self {
            case .yaml: return .yaml
            case .json: return .json
            case .plist: return .propertyList
            }
        }
    }
    
    /// Export errors
    enum ExportError: LocalizedError {
        case encodingFailed
        case writeFailed(String)
        case unsupportedFormat
        case invalidConfiguration
        
        var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "Failed to encode configuration"
            case .writeFailed(let path):
                return "Failed to write to: \(path)"
            case .unsupportedFormat:
                return "Unsupported export format"
            case .invalidConfiguration:
                return "Configuration is invalid and cannot be exported"
            }
        }
    }
    
    /// Import errors
    enum ImportError: LocalizedError {
        case fileNotFound
        case decodingFailed(String)
        case unsupportedFormat
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .fileNotFound:
                return "Configuration file not found"
            case .decodingFailed(let reason):
                return "Failed to decode configuration: \(reason)"
            case .unsupportedFormat:
                return "Unsupported import format"
            case .invalidData:
                return "Configuration data is invalid"
            }
        }
    }
    
    // MARK: - Export Methods
    
    /// Export configuration to YAML format
    static func exportToYAML(_ config: ConfigurationData) throws -> String {
        return config.toYAML()
    }
    
    /// Export configuration to JSON format
    static func exportToJSON(_ config: ConfigurationData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            return try encoder.encode(config)
        } catch {
            throw ExportError.encodingFailed
        }
    }
    
    /// Export configuration to PropertyList format
    static func exportToPlist(_ config: ConfigurationData) throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            return try encoder.encode(config)
        } catch {
            throw ExportError.encodingFailed
        }
    }
    
    /// Export configuration to file
    static func export(_ config: ConfigurationData, to url: URL, format: ExportFormat) throws {
        switch format {
        case .yaml:
            let yaml = try exportToYAML(config)
            try yaml.write(to: url, atomically: true, encoding: .utf8)
            
        case .json:
            let json = try exportToJSON(config)
            try json.write(to: url)
            
        case .plist:
            let plist = try exportToPlist(config)
            try plist.write(to: url)
        }
        
        Logger.shared.success("Exported configuration to: \(url.path)", component: "Export")
    }
    
    /// Generate default filename for export
    static func defaultFilename(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        return "velociraptor-config-\(dateString).\(format.fileExtension)"
    }
    
    // MARK: - Import Methods
    
    /// Import configuration from JSON
    static func importFromJSON(_ data: Data) throws -> ConfigurationData {
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(ConfigurationData.self, from: data)
        } catch {
            throw ImportError.decodingFailed(error.localizedDescription)
        }
    }
    
    /// Import configuration from PropertyList
    static func importFromPlist(_ data: Data) throws -> ConfigurationData {
        let decoder = PropertyListDecoder()
        
        do {
            return try decoder.decode(ConfigurationData.self, from: data)
        } catch {
            throw ImportError.decodingFailed(error.localizedDescription)
        }
    }
    
    /// Import configuration from YAML
    /// Note: Full YAML parsing would require a library like Yams
    /// This is a simplified implementation that handles basic cases
    static func importFromYAML(_ content: String) throws -> ConfigurationData {
        var config = ConfigurationData()
        
        let lines = content.components(separatedBy: .newlines)
        var currentSection = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip comments and empty lines
            if trimmed.isEmpty || trimmed.hasPrefix("#") {
                continue
            }
            
            // Check for section headers
            if !trimmed.hasPrefix("-") && trimmed.hasSuffix(":") && !trimmed.contains(" ") {
                currentSection = String(trimmed.dropLast())
                continue
            }
            
            // Parse key-value pairs
            if let colonIndex = trimmed.firstIndex(of: ":") {
                let key = String(trimmed[..<colonIndex]).trimmingCharacters(in: .whitespaces)
                var value = String(trimmed[trimmed.index(after: colonIndex)...])
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                
                // Handle quoted values
                if value.hasPrefix("\"") && value.hasSuffix("\"") {
                    value = String(value.dropFirst().dropLast())
                }
                
                // Apply values based on section and key
                applyYAMLValue(to: &config, section: currentSection, key: key, value: value)
            }
        }
        
        return config
    }
    
    private static func applyYAMLValue(to config: inout ConfigurationData, section: String, key: String, value: String) {
        switch section.lowercased() {
        case "frontend":
            switch key.lowercased() {
            case "bind_address":
                config.bindAddress = value
            case "bind_port":
                config.bindPort = Int(value) ?? 8000
            default:
                break
            }
            
        case "gui":
            switch key.lowercased() {
            case "bind_address":
                config.guiBindAddress = value
            case "bind_port":
                config.guiBindPort = Int(value) ?? 8889
            default:
                break
            }
            
        case "api":
            switch key.lowercased() {
            case "bind_address":
                config.apiBindAddress = value
            case "bind_port":
                config.apiBindPort = Int(value) ?? 8001
            default:
                break
            }
            
        case "datastore":
            switch key.lowercased() {
            case "location":
                config.datastoreDirectory = value
            default:
                break
            }
            
        case "logging":
            switch key.lowercased() {
            case "output_directory":
                config.logsDirectory = value
            default:
                break
            }
            
        default:
            // Handle top-level keys
            switch key.lowercased() {
            case "name":
                config.organizationName = value
            default:
                break
            }
        }
    }
    
    /// Import configuration from file
    static func importFrom(_ url: URL) throws -> ConfigurationData {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw ImportError.fileNotFound
        }
        
        let data = try Data(contentsOf: url)
        
        // Determine format from extension
        let ext = url.pathExtension.lowercased()
        
        switch ext {
        case "json":
            return try importFromJSON(data)
            
        case "plist":
            return try importFromPlist(data)
            
        case "yaml", "yml":
            guard let content = String(data: data, encoding: .utf8) else {
                throw ImportError.invalidData
            }
            return try importFromYAML(content)
            
        default:
            // Try to auto-detect format
            if let content = String(data: data, encoding: .utf8) {
                // Check if it looks like JSON
                if content.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{") {
                    return try importFromJSON(data)
                }
                // Try YAML
                return try importFromYAML(content)
            }
            
            throw ImportError.unsupportedFormat
        }
    }
    
    // MARK: - Backup Methods
    
    /// Create a timestamped backup of current configuration
    static func createBackup(of config: ConfigurationData, in directory: URL? = nil) throws -> URL {
        let backupDir = directory ?? defaultBackupDirectory
        
        try FileManager.default.createDirectory(at: backupDir, withIntermediateDirectories: true)
        
        let filename = defaultFilename(format: .json)
        let backupURL = backupDir.appendingPathComponent(filename)
        
        try export(config, to: backupURL, format: .json)
        
        Logger.shared.info("Created backup: \(backupURL.path)", component: "Export")
        
        return backupURL
    }
    
    /// Default backup directory
    static var defaultBackupDirectory: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Velociraptor/Backups")
    }
    
    /// List available backups
    static func listBackups() -> [URL] {
        do {
            let backupDir = defaultBackupDirectory
            let files = try FileManager.default.contentsOfDirectory(
                at: backupDir,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            
            return files
                .filter { $0.pathExtension == "json" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            return []
        }
    }
    
    /// Delete old backups, keeping only the most recent N
    static func pruneBackups(keeping count: Int = 10) {
        let backups = listBackups()
        
        guard backups.count > count else { return }
        
        for backup in backups.dropFirst(count) {
            try? FileManager.default.removeItem(at: backup)
            Logger.shared.debug("Deleted old backup: \(backup.lastPathComponent)", component: "Export")
        }
    }
}

// MARK: - UTType Extension

extension UTType {
    static var yaml: UTType {
        UTType(filenameExtension: "yaml") ?? .plainText
    }
}
