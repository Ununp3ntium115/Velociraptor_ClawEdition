//
//  ConfigurationData.swift
//  VelociraptorMacOS
//
//  Configuration data model for Velociraptor deployment
//

import Foundation

/// Complete configuration data for Velociraptor deployment
/// Handles all settings from the configuration wizard
struct ConfigurationData: Codable, Equatable {
    // MARK: - Deployment Settings
    
    /// Type of deployment (Server, Standalone, Client)
    var deploymentType: String = "Standalone"
    
    /// Organization name for certificate generation
    var organizationName: String = "VelociraptorOrg"
    
    // MARK: - Storage Settings
    
    /// Directory for datastore
    var datastoreDirectory: String = ConfigurationData.defaultDatastorePath
    
    /// Directory for logs
    var logsDirectory: String = ConfigurationData.defaultLogsPath
    
    /// Directory for cache
    var cacheDirectory: String = ConfigurationData.defaultCachePath
    
    /// Datastore size preset
    var datastoreSize: DatastoreSize = .medium
    
    // MARK: - Network Settings
    
    /// Frontend bind address
    var bindAddress: String = "0.0.0.0"
    
    /// Frontend bind port
    var bindPort: Int = 8000
    
    /// GUI bind address
    var guiBindAddress: String = "127.0.0.1"
    
    /// GUI bind port
    var guiBindPort: Int = 8889
    
    /// API bind address
    var apiBindAddress: String = "127.0.0.1"
    
    /// API bind port
    var apiBindPort: Int = 8001
    
    // MARK: - Certificate Settings
    
    /// Type of encryption/certificate to use
    var encryptionType: EncryptionType = .selfSigned
    
    /// Path to custom certificate file
    var customCertPath: String = ""
    
    /// Path to custom private key file
    var customKeyPath: String = ""
    
    /// Domain for Let's Encrypt
    var letsEncryptDomain: String = ""
    
    /// Let's Encrypt cache directory
    var letsEncryptCacheDir: String = ""
    
    /// Certificate expiration period
    var certificateExpiration: String = "1 Year"
    
    // MARK: - Security Settings
    
    /// Deployment environment
    var environment: Environment = .production
    
    /// Logging level
    var logLevel: LogLevel = .info
    
    /// Enforce TLS 1.2 or higher
    var enforceTLS12: Bool = true
    
    /// Validate SSL certificates
    var validateCertificates: Bool = true
    
    /// Enable debug logging
    var enableDebugLogging: Bool = false
    
    /// Restrict VQL capabilities
    var restrictVQL: Bool = false
    
    /// Use Windows Registry for config (Windows only)
    var useRegistry: Bool = false
    
    /// Registry path (Windows only)
    var registryPath: String = ""
    
    // MARK: - Authentication
    
    /// Admin username
    var adminUsername: String = "admin"
    
    /// Admin password (not persisted to config file)
    var adminPassword: String = ""
    
    /// Confirm password field
    var confirmPassword: String = ""
    
    // MARK: - macOS-Specific Settings
    
    /// Launch Velociraptor at login
    var launchAtLogin: Bool = false
    
    /// Store credentials in Keychain
    var useKeychain: Bool = true
    
    /// Enable system notifications
    var enableNotifications: Bool = true
    
    /// Auto-check for updates
    var autoCheckUpdates: Bool = true
    
    /// Send anonymous usage telemetry
    var enableTelemetry: Bool = false
    
    // MARK: - Enums
    
    /// Encryption/certificate type options
    enum EncryptionType: String, Codable, CaseIterable, Identifiable {
        case selfSigned = "SelfSigned"
        case custom = "Custom"
        case letsEncrypt = "LetsEncrypt"
        
        var id: String { rawValue }
        
        var displayName: String {
            switch self {
            case .selfSigned: return "Self-Signed Certificate"
            case .custom: return "Custom Certificate Files"
            case .letsEncrypt: return "Let's Encrypt (AutoCert)"
            }
        }
        
        var description: String {
            switch self {
            case .selfSigned:
                return "Automatically generate a self-signed certificate. Best for testing and internal deployments."
            case .custom:
                return "Use your own certificate and private key files. Required for production with trusted certificates."
            case .letsEncrypt:
                return "Automatically obtain certificates from Let's Encrypt. Requires a public domain name."
            }
        }
        
        var iconName: String {
            switch self {
            case .selfSigned: return "signature"
            case .custom: return "doc.badge.gearshape"
            case .letsEncrypt: return "lock.rotation"
            }
        }
    }
    
    /// Deployment environment options
    enum Environment: String, Codable, CaseIterable, Identifiable {
        case production = "Production"
        case development = "Development"
        case testing = "Testing"
        case staging = "Staging"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .production: return "Production environment with security hardening"
            case .development: return "Development environment with verbose logging"
            case .testing: return "Testing environment for QA"
            case .staging: return "Staging environment for pre-production"
            }
        }
    }
    
    /// Log level options
    enum LogLevel: String, Codable, CaseIterable, Identifiable {
        case error = "ERROR"
        case warn = "WARN"
        case info = "INFO"
        case debug = "DEBUG"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .error: return "Only log errors"
            case .warn: return "Log warnings and errors"
            case .info: return "Log general information"
            case .debug: return "Verbose debug logging"
            }
        }
    }
    
    /// Datastore size presets
    enum DatastoreSize: String, Codable, CaseIterable, Identifiable {
        case small = "Small"
        case medium = "Medium"
        case large = "Large"
        case enterprise = "Enterprise"
        
        var id: String { rawValue }
        
        var description: String {
            switch self {
            case .small: return "Up to 100 clients"
            case .medium: return "100-1,000 clients"
            case .large: return "1,000-10,000 clients"
            case .enterprise: return "10,000+ clients"
            }
        }
        
        var recommendedDiskSpace: String {
            switch self {
            case .small: return "10 GB"
            case .medium: return "50 GB"
            case .large: return "200 GB"
            case .enterprise: return "1+ TB"
            }
        }
    }
    
    // MARK: - Default Paths (macOS)
    
    /// Default datastore path following Apple guidelines
    static var defaultDatastorePath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Velociraptor")
            .path
    }
    
    /// Default logs path following Apple guidelines
    static var defaultLogsPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Velociraptor")
            .path
    }
    
    /// Default cache path following Apple guidelines
    static var defaultCachePath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/Velociraptor")
            .path
    }
    
    /// Default binary path
    static var defaultBinaryPath: String {
        "/usr/local/bin/velociraptor"
    }
    
    // MARK: - Validation
    
    /// Validate the current configuration and collect any detected validation issues.
    /// 
    /// Performs checks for administrator credentials, port ranges and conflicts, IP addresses, required filesystem paths, certificate-related settings based on encryption type, and organization name.
    /// - Returns: An array of `ValidationError` describing each problem found; an empty array indicates no validation errors.
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // Username validation
        if adminUsername.isEmpty {
            errors.append(.emptyUsername)
        } else if adminUsername.count < 3 {
            errors.append(.usernameTooShort)
        } else if !adminUsername.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) {
            errors.append(.invalidUsernameCharacters)
        }
        
        // Password validation
        if adminPassword.isEmpty {
            errors.append(.emptyPassword)
        } else if adminPassword.count < 8 {
            errors.append(.weakPassword)
        } else {
            // Check password complexity
            let hasUppercase = adminPassword.contains(where: { $0.isUppercase })
            let hasLowercase = adminPassword.contains(where: { $0.isLowercase })
            let hasNumber = adminPassword.contains(where: { $0.isNumber })
            
            if !hasUppercase || !hasLowercase || !hasNumber {
                errors.append(.passwordComplexity)
            }
        }
        
        // Password confirmation
        if adminPassword != confirmPassword {
            errors.append(.passwordMismatch)
        }
        
        // Port validation
        if bindPort < 1 || bindPort > 65535 {
            errors.append(.invalidPort("Frontend Port"))
        }
        if guiBindPort < 1 || guiBindPort > 65535 {
            errors.append(.invalidPort("GUI Port"))
        }
        if apiBindPort < 1 || apiBindPort > 65535 {
            errors.append(.invalidPort("API Port"))
        }
        
        // Port conflicts
        let ports = [bindPort, guiBindPort, apiBindPort]
        if Set(ports).count != ports.count {
            errors.append(.portConflict)
        }
        
        // IP address validation
        if !isValidIPAddress(bindAddress) && bindAddress != "0.0.0.0" {
            errors.append(.invalidIPAddress("Frontend Bind Address"))
        }
        if !isValidIPAddress(guiBindAddress) && guiBindAddress != "0.0.0.0" {
            errors.append(.invalidIPAddress("GUI Bind Address"))
        }
        
        // Path validation
        if datastoreDirectory.isEmpty {
            errors.append(.invalidPath("Datastore Directory"))
        }
        if logsDirectory.isEmpty {
            errors.append(.invalidPath("Logs Directory"))
        }
        
        // Certificate validation
        switch encryptionType {
        case .custom:
            if customCertPath.isEmpty {
                errors.append(.missingCertificate)
            }
            if customKeyPath.isEmpty {
                errors.append(.missingPrivateKey)
            }
        case .letsEncrypt:
            if letsEncryptDomain.isEmpty {
                errors.append(.missingDomain)
            } else if !isValidDomain(letsEncryptDomain) {
                errors.append(.invalidDomain)
            }
        case .selfSigned:
            break
        }
        
        // Organization name
        if organizationName.isEmpty {
            errors.append(.emptyOrganization)
        }
        
        return errors
    }
    
    /// Check if configuration is valid
    var isValid: Bool {
        validate().isEmpty
    }
    
    /// Checks whether a string is a valid IPv4 address in dotted-decimal notation.
    /// - Parameter ip: The string to validate as an IPv4 address.
    /// - Returns: `true` if `ip` contains exactly four numeric octets and each octet is between 0 and 255, `false` otherwise.
    
    private func isValidIPAddress(_ ip: String) -> Bool {
        let parts = ip.split(separator: ".")
        guard parts.count == 4 else { return false }
        return parts.allSatisfy { part in
            guard let num = Int(part) else { return false }
            return num >= 0 && num <= 255
        }
    }
    
    /// Validates whether a string is a well-formed domain name with a top-level domain.
    /// - Parameter domain: The domain to validate; may include subdomains and must end with a TLD (e.g., `example.com`).
    /// - Returns: `true` if `domain` matches the expected domain-name pattern (labels start and end with alphanumeric characters, may contain hyphens, and end with a TLD of at least two letters), `false` otherwise.
    private func isValidDomain(_ domain: String) -> Bool {
        let domainRegex = #"^[a-zA-Z0-9][a-zA-Z0-9-]{0,61}[a-zA-Z0-9](?:\.[a-zA-Z]{2,})+$"#
        return domain.range(of: domainRegex, options: .regularExpression) != nil
    }
    
    // MARK: - Validation Errors
    
    /// Configuration validation errors
    enum ValidationError: LocalizedError, Equatable {
        case emptyUsername
        case usernameTooShort
        case invalidUsernameCharacters
        case emptyPassword
        case weakPassword
        case passwordComplexity
        case passwordMismatch
        case invalidPort(String)
        case portConflict
        case invalidIPAddress(String)
        case invalidPath(String)
        case missingCertificate
        case missingPrivateKey
        case missingDomain
        case invalidDomain
        case emptyOrganization
        
        var errorDescription: String? {
            switch self {
            case .emptyUsername: return "Admin username cannot be empty"
            case .usernameTooShort: return "Username must be at least 3 characters"
            case .invalidUsernameCharacters: return "Username can only contain letters, numbers, and underscores"
            case .emptyPassword: return "Password cannot be empty"
            case .weakPassword: return "Password must be at least 8 characters"
            case .passwordComplexity: return "Password must contain uppercase, lowercase, and numbers"
            case .passwordMismatch: return "Passwords do not match"
            case .invalidPort(let name): return "\(name) must be between 1 and 65535"
            case .portConflict: return "All ports must be different"
            case .invalidIPAddress(let name): return "\(name) is not a valid IP address"
            case .invalidPath(let name): return "\(name) path is invalid"
            case .missingCertificate: return "Certificate file path is required"
            case .missingPrivateKey: return "Private key file path is required"
            case .missingDomain: return "Domain name is required for Let's Encrypt"
            case .invalidDomain: return "Domain name format is invalid"
            case .emptyOrganization: return "Organization name cannot be empty"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .weakPassword:
                return "Use a password with at least 8 characters including letters and numbers"
            case .passwordComplexity:
                return "Include at least one uppercase letter, one lowercase letter, and one number"
            case .portConflict:
                return "Choose different port numbers for frontend, GUI, and API"
            default:
                return nil
            }
        }
    }
    
    // MARK: - Password Strength
    
    /// Estimates the strength of the admin password as a score from 0 to 100.
    /// - Returns: An `Int` score between 0 and 100 where higher values indicate a stronger password; the score increases with password length (up to 40 points) and with use of varied character types (uppercase, lowercase, digits, and symbols).
    func passwordStrength() -> Int {
        var score = 0
        let password = adminPassword
        
        // Length scoring
        score += min(password.count * 4, 40)
        
        // Character variety scoring
        if password.contains(where: { $0.isUppercase }) { score += 15 }
        if password.contains(where: { $0.isLowercase }) { score += 15 }
        if password.contains(where: { $0.isNumber }) { score += 15 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 15 }
        
        return min(score, 100)
    }
    
    /// Password strength level
    var passwordStrengthLevel: PasswordStrength {
        let score = passwordStrength()
        switch score {
        case 0..<30: return .weak
        case 30..<60: return .medium
        case 60..<80: return .strong
        default: return .veryStrong
        }
    }
    
    enum PasswordStrength: String {
        case weak = "Weak"
        case medium = "Medium"
        case strong = "Strong"
        case veryStrong = "Very Strong"
        
        var color: String {
            switch self {
            case .weak: return "red"
            case .medium: return "orange"
            case .strong: return "green"
            case .veryStrong: return "blue"
            }
        }
    }
}

// MARK: - YAML Generation

extension ConfigurationData {
    /// Renders the current configuration as a Velociraptor YAML configuration snippet.
    /// 
    /// The generated YAML includes a header with version and generation date, a `Client` section
    /// (server URL, CA certificate placeholder, nonce, and writeback path), and, when `deploymentType`
    /// is not `"Client"`, additional `Frontend`, `GUI`, `API`, `Datastore`, and `Logging` sections.
    /// - Returns: A YAML-formatted `String` representing this configuration.
    func toYAML() -> String {
        var yaml = """
        # Velociraptor Configuration
        # Generated by Velociraptor macOS v5.0.5
        # Date: \(ISO8601DateFormatter().string(from: Date()))
        
        version:
          name: "\(organizationName)"
          
        Client:
          server_urls:
            - https://\(bindAddress):\(bindPort)/
          ca_certificate: |
            # CA certificate will be generated
          nonce: ""
          writeback_darwin: /etc/velociraptor/velociraptor.writeback.yaml
          
        """
        
        if deploymentType != "Client" {
            yaml += """
            
            Frontend:
              bind_address: "\(bindAddress)"
              bind_port: \(bindPort)
              
            GUI:
              bind_address: "\(guiBindAddress)"
              bind_port: \(guiBindPort)
              
            API:
              bind_address: "\(apiBindAddress)"
              bind_port: \(apiBindPort)
              
            Datastore:
              implementation: FileBaseDataStore
              location: "\(datastoreDirectory)"
              
            Logging:
              output_directory: "\(logsDirectory)"
              separate_logs_per_component: true
              
            """
        }
        
        return yaml
    }
}