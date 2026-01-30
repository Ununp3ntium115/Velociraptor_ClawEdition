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
    
    /// Serialize the provided configuration into a YAML-formatted string.
    /// - Parameter config: The configuration to serialize.
    /// - Returns: A YAML representation of `config`.
    static func exportToYAML(_ config: ConfigurationData) throws -> String {
        return config.toYAML()
    }
    
    /// Encode a ConfigurationData instance as pretty-printed JSON with sorted keys.
    /// - Returns: JSON `Data` representing the configuration.
    /// - Throws: `ExportError.encodingFailed` if the configuration cannot be encoded to JSON.
    static func exportToJSON(_ config: ConfigurationData) throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            return try encoder.encode(config)
        } catch {
            throw ExportError.encodingFailed
        }
    }
    
    /// Encode a ConfigurationData instance into an XML property list.
    /// - Parameter config: The configuration to encode.
    /// - Returns: `Data` containing the configuration encoded as an XML property list.
    /// - Throws: `ExportError.encodingFailed` if encoding the configuration to a property list fails.
    static func exportToPlist(_ config: ConfigurationData) throws -> Data {
        let encoder = PropertyListEncoder()
        encoder.outputFormat = .xml
        
        do {
            return try encoder.encode(config)
        } catch {
            throw ExportError.encodingFailed
        }
    }
    
    /// Write the provided configuration to the given file URL using the specified export format.
    /// - Parameters:
    ///   - config: The configuration to export.
    ///   - url: Destination file URL where the exported data will be written.
    ///   - format: The export format to use (YAML, JSON, or plist).
    /// - Throws: `ExportError.encodingFailed` or `ExportError.writeFailed(_)` for encoding or write failures, or other underlying file system errors propagated from the write operations.
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
    
    /// Generate a timestamped default filename for a configuration export.
    /// - Parameter format: The export format whose file extension will be appended.
    /// - Returns: A filename of the form `velociraptor-config-YYYYMMDD-HHMMSS.{ext}` where `{ext}` is the format's file extension.
    static func defaultFilename(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd-HHmmss"
        let dateString = dateFormatter.string(from: Date())
        
        return "velociraptor-config-\(dateString).\(format.fileExtension)"
    }
    
    // MARK: - Import Methods
    
    /// Decode JSON-encoded configuration data into a ConfigurationData instance.
    /// - Parameters:
    ///   - data: JSON-encoded bytes representing a Velociraptor configuration.
    /// - Returns: A `ConfigurationData` decoded from the provided JSON data.
    /// - Throws: `ImportError.decodingFailed` with the decoder's error message if decoding fails.
    static func importFromJSON(_ data: Data) throws -> ConfigurationData {
        let decoder = JSONDecoder()
        
        do {
            return try decoder.decode(ConfigurationData.self, from: data)
        } catch {
            throw ImportError.decodingFailed(error.localizedDescription)
        }
    }
    
    /// Decodes a Property List into a ConfigurationData instance.
    /// - Parameter data: Property list data containing a serialized ConfigurationData.
    /// - Returns: A ConfigurationData populated from the provided plist.
    /// - Throws: `ImportError.decodingFailed` with the decoder's error message if decoding fails.
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
    /// Parses a minimal YAML document and produces a populated ConfigurationData instance.
    /// - Parameter content: The YAML document as a UTF-8 string; supports simple section headers and key:value pairs, with '#' comments and empty lines ignored.
    /// - Returns: A ConfigurationData populated from the parsed YAML content.
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
    
    /// Maps a parsed YAML section/key/value into the given ConfigurationData instance.
    /// 
    /// Recognizes specific sections and keys and updates the corresponding fields on `config`.
    /// Supported mappings:
    /// - Section "frontend":
    ///   - "bind_address" -> `bindAddress`
    ///   - "bind_port" -> `bindPort` (defaults to 8000 if value is not an integer)
    /// - Section "gui":
    ///   - "bind_address" -> `guiBindAddress`
    ///   - "bind_port" -> `guiBindPort` (defaults to 8889 if value is not an integer)
    /// - Section "api":
    ///   - "bind_address" -> `apiBindAddress`
    ///   - "bind_port" -> `apiBindPort` (defaults to 8001 if value is not an integer)
    /// - Section "datastore":
    ///   - "location" -> `datastoreDirectory`
    /// - Section "logging":
    ///   - "output_directory" -> `logsDirectory`
    /// - Top-level keys:
    ///   - "name" -> `organizationName`
    ///
    /// Unknown sections or keys are ignored.
    /// - Parameters:
    ///   - config: The configuration object to update.
    ///   - section: The YAML section name (case-insensitive).
    ///   - key: The YAML key name within the section (case-insensitive).
    ///   - value: The string value to apply.
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
    
    /// Import a Velociraptor configuration from the file at the given URL.
    /// - Parameters:
    ///   - url: A file URL pointing to a configuration file (JSON, plist, or YAML).
    /// - Returns: The decoded `ConfigurationData` represented by the file.
    /// - Throws:
    ///   - `ImportError.fileNotFound` if the file does not exist at the URL.
    ///   - `ImportError.invalidData` if the file cannot be interpreted as UTF-8 when required for parsing.
    ///   - `ImportError.unsupportedFormat` if the format cannot be determined or is not supported.
    ///   - `ImportError.decodingFailed` if decoding of the file content fails.
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
    
    /// Creates a JSON backup of the provided configuration and stores it in the specified or default backup directory.
    /// - Parameters:
    ///   - config: The configuration to back up.
    ///   - directory: Optional directory to store the backup. If `nil`, the `defaultBackupDirectory` is used.
    /// - Returns: The file URL of the created backup.
    /// - Throws: An error if the backup directory cannot be created or the configuration cannot be written to disk.
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
    
    /// List backup file URLs in the default backup directory.
    /// Only files with the `.json` extension are included; results are sorted by creation date with the newest first. If the directory cannot be read or an error occurs, an empty array is returned.
    /// - Returns: An array of backup file URLs (JSON files) sorted by creation date, newest first; an empty array on error.
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
    
    /// Prunes stored backup files so only the most recent entries remain.
    /// 
    /// Deletes oldest backup files beyond the specified count. Deletion failures are ignored.
    — Parameters:
    ///   - count: The maximum number of newest backups to retain; older backups will be removed.
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