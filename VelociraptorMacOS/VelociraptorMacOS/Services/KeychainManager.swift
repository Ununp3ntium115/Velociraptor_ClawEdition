//
//  KeychainManager.swift
//  VelociraptorMacOS
//
//  Secure credential storage using macOS Keychain Services
//

import Foundation
import Security

/// Manages secure storage of credentials using macOS Keychain
/// Handles passwords, API keys, and certificates
@MainActor
class KeychainManager: ObservableObject {
    // MARK: - Constants
    
    /// Keychain service identifier
    private let serviceName = "com.velocidex.velociraptor"
    
    /// Access group for sharing between apps (optional)
    private let accessGroup: String? = nil
    
    // MARK: - Published Properties
    
    /// Whether Keychain access is available
    @Published var isAvailable: Bool = true
    
    /// Last Keychain operation result
    @Published var lastOperationResult: String?
    
    // MARK: - Initialization
    
    init() {
        checkAvailability()
    }
    
    private func checkAvailability() {
        // Test Keychain availability by attempting a query
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        // errSecItemNotFound is fine - Keychain is available but no items yet
        isAvailable = status == errSecSuccess || status == errSecItemNotFound
        
        Logger.shared.info("Keychain availability: \(isAvailable)", component: "Keychain")
    }
    
    // MARK: - Error Types
    
    /// Keychain operation errors
    enum KeychainError: LocalizedError {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case invalidData
        case accessDenied
        case noPassword
        case encodingFailed
        
        var errorDescription: String? {
            switch self {
            case .duplicateItem:
                return "Item already exists in Keychain"
            case .itemNotFound:
                return "Item not found in Keychain"
            case .unexpectedStatus(let status):
                return "Keychain error: \(status) - \(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown")"
            case .invalidData:
                return "Invalid data format"
            case .accessDenied:
                return "Access to Keychain denied"
            case .noPassword:
                return "No password provided"
            case .encodingFailed:
                return "Failed to encode data"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .accessDenied:
                return "Check Keychain Access permissions in System Preferences"
            case .itemNotFound:
                return "The requested item may not have been saved yet"
            default:
                return nil
            }
        }
    }
    
    // MARK: - Password Operations
    
    /// Save password to Keychain
    /// - Parameters:
    ///   - password: Password string to save
    ///   - account: Account identifier
    ///   - label: Human-readable label (optional)
    func savePassword(_ password: String, for account: String, label: String? = nil) throws {
        guard !password.isEmpty else {
            throw KeychainError.noPassword
        }
        
        guard let passwordData = password.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]
        
        if let label = label {
            query[kSecAttrLabel as String] = label
        }
        
        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            Logger.shared.success("Saved password for account: \(account)", component: "Keychain")
            lastOperationResult = "Password saved successfully"
            
        case errSecDuplicateItem:
            // Update existing item
            try updatePassword(password, for: account)
            
        case errSecAuthFailed:
            throw KeychainError.accessDenied
            
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Update existing password in Keychain
    private func updatePassword(_ password: String, for account: String) throws {
        guard let passwordData = password.data(using: .utf8) else {
            throw KeychainError.encodingFailed
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: passwordData
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        guard status == errSecSuccess else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        Logger.shared.success("Updated password for account: \(account)", component: "Keychain")
        lastOperationResult = "Password updated successfully"
    }
    
    /// Retrieve password from Keychain
    /// - Parameter account: Account identifier
    /// - Returns: Stored password string
    func getPassword(for account: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        switch status {
        case errSecSuccess:
            guard let data = result as? Data,
                  let password = String(data: data, encoding: .utf8) else {
                throw KeychainError.invalidData
            }
            return password
            
        case errSecItemNotFound:
            throw KeychainError.itemNotFound
            
        case errSecAuthFailed:
            throw KeychainError.accessDenied
            
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Delete password from Keychain
    /// - Parameter account: Account identifier
    func deletePassword(for account: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        Logger.shared.info("Deleted password for account: \(account)", component: "Keychain")
        lastOperationResult = "Password deleted"
    }
    
    /// Check if password exists for account
    func hasPassword(for account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        return status == errSecSuccess
    }
    
    // MARK: - API Key Operations
    
    /// Save API key
    func saveAPIKey(_ key: String, identifier: String) throws {
        try savePassword(key, for: "api_key_\(identifier)", label: "Velociraptor API Key: \(identifier)")
    }
    
    /// Retrieve API key
    func getAPIKey(identifier: String) throws -> String {
        try getPassword(for: "api_key_\(identifier)")
    }
    
    /// Delete API key
    func deleteAPIKey(identifier: String) throws {
        try deletePassword(for: "api_key_\(identifier)")
    }
    
    // MARK: - Certificate Operations
    
    /// Save certificate to Keychain
    /// - Parameters:
    ///   - certData: Certificate data (DER or PEM encoded)
    ///   - label: Human-readable label
    func saveCertificate(_ certData: Data, label: String) throws {
        // First try to create a SecCertificate from the data
        guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
            throw KeychainError.invalidData
        }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: certificate,
            kSecAttrLabel as String: label,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        switch status {
        case errSecSuccess:
            Logger.shared.success("Saved certificate: \(label)", component: "Keychain")
            
        case errSecDuplicateItem:
            // Delete existing and re-add
            let deleteQuery: [String: Any] = [
                kSecClass as String: kSecClassCertificate,
                kSecAttrLabel as String: label
            ]
            SecItemDelete(deleteQuery as CFDictionary)
            
            let retryStatus = SecItemAdd(query as CFDictionary, nil)
            guard retryStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(retryStatus)
            }
            Logger.shared.info("Updated certificate: \(label)", component: "Keychain")
            
        default:
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
    /// Retrieve certificate from Keychain
    func getCertificate(label: String) throws -> SecCertificate {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: label,
            kSecReturnRef as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let certificate = result as! SecCertificate? else {
            throw KeychainError.invalidData
        }
        
        return certificate
    }
    
    /// Delete certificate from Keychain
    func deleteCertificate(label: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: label
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unexpectedStatus(status)
        }
        
        Logger.shared.info("Deleted certificate: \(label)", component: "Keychain")
    }
    
    // MARK: - Bulk Operations
    
    /// Delete all Velociraptor items from Keychain
    func deleteAllItems() throws {
        // Delete passwords
        let passwordQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName
        ]
        SecItemDelete(passwordQuery as CFDictionary)
        
        // Delete certificates with our label prefix
        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: "Velociraptor"
        ]
        SecItemDelete(certQuery as CFDictionary)
        
        Logger.shared.warning("Deleted all Velociraptor Keychain items", component: "Keychain")
        lastOperationResult = "All items deleted"
    }
    
    /// List all stored account names
    func listAccounts() -> [String] {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecReturnAttributes as String: true,
            kSecMatchLimit as String: kSecMatchLimitAll
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return []
        }
        
        return items.compactMap { $0[kSecAttrAccount as String] as? String }
    }
    
    // MARK: - Velociraptor-Specific Convenience Methods
    
    /// Standard account names used by Velociraptor
    enum StandardAccount: String {
        case adminPassword = "velociraptor_admin"
        case serverAPIKey = "velociraptor_api_key"
        case clientNonce = "velociraptor_client_nonce"
    }
    
    /// Save admin password
    func saveAdminPassword(_ password: String) throws {
        try savePassword(password, for: StandardAccount.adminPassword.rawValue, label: "Velociraptor Admin Password")
    }
    
    /// Get admin password
    func getAdminPassword() throws -> String {
        try getPassword(for: StandardAccount.adminPassword.rawValue)
    }
    
    /// Check if admin password is stored
    var hasAdminPassword: Bool {
        hasPassword(for: StandardAccount.adminPassword.rawValue)
    }
}
