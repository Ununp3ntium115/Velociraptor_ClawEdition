//
//  ConfigurationViewModel.swift
//  VelociraptorMacOS
//
//  View model for configuration management
//

import SwiftUI
import Combine

/// View model for managing configuration data and persistence
@MainActor
class ConfigurationViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Current configuration data
    @Published var data: ConfigurationData = ConfigurationData()
    
    /// Validation errors from last validation
    @Published var validationErrors: [ConfigurationData.ValidationError] = []
    
    /// Whether configuration has been modified
    @Published var isModified: Bool = false
    
    /// Path to last saved/loaded configuration
    @Published var configurationPath: URL?
    
    /// Whether save operation is in progress
    @Published var isSaving: Bool = false
    
    /// Whether load operation is in progress
    @Published var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    init() {
        setupObservers()
    }
    
    private func setupObservers() {
        // Track modifications
        $data
            .dropFirst()
            .sink { [weak self] _ in
                self?.isModified = true
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Validation
    
    /// Validate current configuration
    func validate() -> Bool {
        validationErrors = data.validate()
        return validationErrors.isEmpty
    }
    
    /// Check if a specific step is valid
    func validateStep(_ step: AppState.WizardStep) -> Bool {
        switch step {
        case .deploymentType:
            return !data.deploymentType.isEmpty
            
        case .certificateSettings:
            switch data.encryptionType {
            case .selfSigned:
                return true
            case .custom:
                return !data.customCertPath.isEmpty && !data.customKeyPath.isEmpty
            case .letsEncrypt:
                return !data.letsEncryptDomain.isEmpty
            }
            
        case .securitySettings:
            return true // All optional
            
        case .storageConfiguration:
            return !data.datastoreDirectory.isEmpty && !data.logsDirectory.isEmpty
            
        case .networkConfiguration:
            let portValid = (1...65535).contains(data.bindPort) && 
                           (1...65535).contains(data.guiBindPort) &&
                           (1...65535).contains(data.apiBindPort)
            let portsUnique = Set([data.bindPort, data.guiBindPort, data.apiBindPort]).count == 3
            return portValid && portsUnique
            
        case .authentication:
            return data.adminUsername.count >= 3 && 
                   data.adminPassword.count >= 8 &&
                   data.adminPassword == data.confirmPassword
            
        default:
            return true
        }
    }
    
    /// Get validation errors for a specific step
    func errorsForStep(_ step: AppState.WizardStep) -> [ConfigurationData.ValidationError] {
        let allErrors = data.validate()
        
        switch step {
        case .authentication:
            return allErrors.filter { error in
                switch error {
                case .emptyUsername, .usernameTooShort, .invalidUsernameCharacters,
                     .emptyPassword, .weakPassword, .passwordComplexity, .passwordMismatch:
                    return true
                default:
                    return false
                }
            }
            
        case .networkConfiguration:
            return allErrors.filter { error in
                switch error {
                case .invalidPort, .portConflict, .invalidIPAddress:
                    return true
                default:
                    return false
                }
            }
            
        case .storageConfiguration:
            return allErrors.filter { error in
                switch error {
                case .invalidPath:
                    return true
                default:
                    return false
                }
            }
            
        case .certificateSettings:
            return allErrors.filter { error in
                switch error {
                case .missingCertificate, .missingPrivateKey, .missingDomain, .invalidDomain:
                    return true
                default:
                    return false
                }
            }
            
        default:
            return []
        }
    }
    
    // MARK: - Reset
    
    /// Reset configuration to defaults
    func resetConfiguration() {
        data = ConfigurationData()
        validationErrors = []
        isModified = false
        configurationPath = nil
        Logger.shared.info("Configuration reset to defaults", component: "Config")
    }
    
    // MARK: - File Operations
    
    /// Save configuration to file
    func saveConfiguration(to url: URL) async throws {
        isSaving = true
        defer { isSaving = false }
        
        Logger.shared.info("Saving configuration to: \(url.path)", component: "Config")
        
        // Generate YAML content
        let yamlContent = data.toYAML()
        
        // Write to file
        try yamlContent.write(to: url, atomically: true, encoding: .utf8)
        
        configurationPath = url
        isModified = false
        
        Logger.shared.success("Configuration saved successfully", component: "Config")
    }
    
    /// Save configuration JSON (for persistence)
    func saveConfigurationJSON(to url: URL) async throws {
        isSaving = true
        defer { isSaving = false }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: url)
        
        Logger.shared.info("Configuration JSON saved", component: "Config")
    }
    
    /// Load configuration from JSON file
    func loadConfiguration(from url: URL) async throws {
        isLoading = true
        defer { isLoading = false }
        
        Logger.shared.info("Loading configuration from: \(url.path)", component: "Config")
        
        let jsonData = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        
        data = try decoder.decode(ConfigurationData.self, from: jsonData)
        configurationPath = url
        isModified = false
        
        Logger.shared.success("Configuration loaded successfully", component: "Config")
    }
    
    /// Export configuration as YAML
    func exportYAML() -> String {
        return data.toYAML()
    }
    
    // MARK: - Directory Operations
    
    /// Create required directories
    func createDirectories() async throws {
        let directories = [
            data.datastoreDirectory,
            data.logsDirectory,
            data.cacheDirectory
        ]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory) {
                try fileManager.createDirectory(
                    atPath: directory,
                    withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o750]
                )
                Logger.shared.info("Created directory: \(directory)", component: "Config")
            }
        }
    }
    
    /// Verify all directories exist and are writable
    func verifyDirectories() -> Bool {
        let directories = [
            data.datastoreDirectory,
            data.logsDirectory,
            data.cacheDirectory
        ]
        
        return directories.allSatisfy { directory in
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: directory, isDirectory: &isDir) {
                return isDir.boolValue && fileManager.isWritableFile(atPath: directory)
            }
            return false
        }
    }
    
    // MARK: - Quick Configuration
    
    /// Apply quick configuration preset
    func applyPreset(_ preset: ConfigurationPreset) {
        switch preset {
        case .development:
            data.environment = .development
            data.logLevel = .debug
            data.enableDebugLogging = true
            data.validateCertificates = false
            
        case .production:
            data.environment = .production
            data.logLevel = .info
            data.enableDebugLogging = false
            data.validateCertificates = true
            data.enforceTLS12 = true
            
        case .testing:
            data.environment = .testing
            data.logLevel = .debug
            data.enableDebugLogging = true
            
        case .emergency:
            data.deploymentType = "Standalone"
            data.encryptionType = .selfSigned
            data.environment = .production
            data.datastoreDirectory = emergencyDatastorePath
            data.logsDirectory = emergencyLogsPath
            data.adminUsername = "admin"
        }
        
        Logger.shared.info("Applied preset: \(preset.rawValue)", component: "Config")
    }
    
    /// Emergency datastore path
    private var emergencyDatastorePath: String {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("EmergencyVelociraptor")
            .path
    }
    
    /// Emergency logs path
    private var emergencyLogsPath: String {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("EmergencyVelociraptor/logs")
            .path
    }
    
    // MARK: - Configuration Presets
    
    enum ConfigurationPreset: String, CaseIterable {
        case development = "Development"
        case production = "Production"
        case testing = "Testing"
        case emergency = "Emergency"
        
        var description: String {
            switch self {
            case .development: return "Development settings with verbose logging"
            case .production: return "Production-ready with security hardening"
            case .testing: return "Testing configuration for QA"
            case .emergency: return "Rapid emergency deployment"
            }
        }
    }
}
