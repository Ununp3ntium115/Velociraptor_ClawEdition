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
    
    /// Subscribes to changes of `data` (ignoring the initial value) and sets `isModified` to `true` when `data` changes.
    /// The subscription is stored in `cancellables`.
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
    
    /// Validate current configuration data and record any validation errors.
    /// 
    /// Populates `validationErrors` with the results from `data.validate()`.
    /// - Returns: `true` if no validation errors were found, `false` otherwise.
    func validate() -> Bool {
        validationErrors = data.validate()
        return validationErrors.isEmpty
    }
    
    /// Validates the configuration fields required for the specified wizard step.
    /// - Parameter step: The wizard step whose required fields should be validated.
    /// - Returns: `true` if the configuration satisfies the requirements for the given step, `false` otherwise.
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
    
    /// Validation errors relevant to a specific wizard step.
    /// - Parameter step: The wizard step whose related validation errors should be returned.
    /// - Returns: An array of `ConfigurationData.ValidationError` containing errors applicable to the provided step; an empty array if there are no matching errors.
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
    
    /// Restores the view model's configuration state to default values.
    /// Clears validation errors, marks the configuration as not modified, and removes the stored configuration path.
    func resetConfiguration() {
        data = ConfigurationData()
        validationErrors = []
        isModified = false
        configurationPath = nil
        Logger.shared.info("Configuration reset to defaults", component: "Config")
    }
    
    // MARK: - File Operations
    
    /// Save current configuration as YAML to the specified file URL.
    /// 
    /// While saving, `isSaving` is set to `true` for the duration of the operation. On success the view model's `configurationPath` is updated to `url` and `isModified` is set to `false`.
    /// - Parameter url: Destination file URL where the YAML representation of the current configuration will be written.
    /// - Throws: An error if writing the YAML data to disk fails.
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
    
    /// Save the current configuration as pretty-printed, sorted JSON to the specified file URL.
    /// - Parameters:
    ///   - url: Destination file URL where the JSON will be written.
    /// - Throws: An error if encoding the configuration or writing the data to disk fails.
    func saveConfigurationJSON(to url: URL) async throws {
        isSaving = true
        defer { isSaving = false }
        
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        let jsonData = try encoder.encode(data)
        try jsonData.write(to: url)
        
        Logger.shared.info("Configuration JSON saved", component: "Config")
    }
    
    /// Load configuration from a JSON file at the provided URL and replace the view model's current configuration.
    /// - Parameter url: File URL pointing to a JSON-encoded `ConfigurationData` file.
    /// - Throws: An error if the file cannot be read or the data cannot be decoded into `ConfigurationData`.
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
    
    /// Generate a YAML representation of the current configuration data.
    /// - Returns: A YAML-formatted `String` representing the current `ConfigurationData`.
    func exportYAML() -> String {
        return data.toYAML()
    }
    
    // MARK: - Directory Operations
    
    /// Ensures the datastore, logs, and cache directories referenced by `data` exist, creating any that are missing with POSIX permissions 0o750.
    /// - Throws: An error from `FileManager` if creating a required directory fails.
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
    
    /// Checks that the datastore, logs, and cache directories exist, are directories, and are writable.
    /// - Returns: `true` if all configured datastore, logs, and cache paths exist, are directories, and are writable; `false` otherwise.
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
    
    /// Applies a predefined configuration preset to the view model.
    /// - Parameter preset: The preset to apply; updates environment, logging, certificate, storage, and admin settings according to the selected preset (development, production, testing, or emergency).
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