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
    
    /// Probes the system Keychain and updates `isAvailable` accordingly.
    /// - Discussion: Performs a lightweight query for a generic password item for the configured service. Treats `errSecItemNotFound` as a valid reachable Keychain (no items present). Updates the `isAvailable` published property and logs the resulting availability.
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
    /// Save a password into the Keychain for the specified account.
    /// - Parameters:
    ///   - password: The password string to store. Must not be empty.
    ///   - account: The account identifier under which to store the password.
    ///   - label: An optional human-readable label for the Keychain item.
    /// - Throws: `KeychainError.noPassword` if `password` is empty; `KeychainError.encodingFailed` if the password cannot be encoded as UTF-8; `KeychainError.accessDenied` if the Keychain rejects access; `KeychainError.unexpectedStatus(_:)` for other Keychain errors.
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
    
    /// Update the existing Keychain password stored for the specified account.
    /// - Parameters:
    ///   - password: The new password to store for the account.
    ///   - account: The Keychain account identifier whose password will be replaced.
    /// - Throws:
    ///   - `KeychainError.encodingFailed` if the password cannot be encoded as UTF‑8.
    ///   - `KeychainError.unexpectedStatus(_:)` if the Keychain update returns an unexpected OSStatus.
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
    /// Retrieve the password stored in the keychain for the specified account.
    /// - Parameters:
    ///   - account: The account identifier whose password to retrieve.
    /// - Returns: The password string for the specified account.
    /// - Throws:
    ///   - `KeychainError.itemNotFound` if no item exists for the account.
    ///   - `KeychainError.accessDenied` if keychain access is denied or authentication fails.
    ///   - `KeychainError.invalidData` if the stored data cannot be decoded as UTF-8 text.
    ///   - `KeychainError.unexpectedStatus(_:)` for any other Keychain `OSStatus` error.
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
    /// Remove the password stored for the specified account from the Keychain.
    /// - Parameters:
    ///   - account: The account identifier used as the Keychain item's account attribute.
    /// - Throws: `KeychainError.unexpectedStatus` if the Keychain deletion fails with an unexpected OSStatus. The function treats "item not found" as success (no-op).
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
    
    /// Checks whether a password entry exists for the given account in the Keychain.
    /// - Parameters:
    ///   - account: The account identifier to look up in the Keychain service.
    /// - Returns: `true` if a password entry exists for the account, `false` otherwise.
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
    
    /// Stores an API key in the Keychain using a namespaced account name.
    /// - Parameters:
    ///   - key: The API key value to store.
    ///   - identifier: A unique identifier appended to `api_key_` to form the Keychain account name.
    /// - Throws: `KeychainError` if the Keychain operation fails (for example: access denied, duplicate item, invalid data, or encoding failure).
    func saveAPIKey(_ key: String, identifier: String) throws {
        try savePassword(key, for: "api_key_\(identifier)", label: "Velociraptor API Key: \(identifier)")
    }
    
    /// Retrieves the API key associated with the given identifier.
    /// - Parameter identifier: The unique identifier for the API key (used to locate the stored key).
    /// - Returns: The API key string for the specified identifier.
    /// - Throws: `KeychainError` if the key cannot be found, is inaccessible, or another keychain error occurs.
    func getAPIKey(identifier: String) throws -> String {
        try getPassword(for: "api_key_\(identifier)")
    }
    
    /// Deletes the API key associated with the provided identifier from the Keychain.
    /// - Parameter identifier: The unique identifier for the API key (used to form the account name `api_key_<identifier>`).
    /// - Throws: `KeychainError` if the deletion fails (for example, when the item is not found, access is denied, or an unexpected Keychain status occurs).
    func deleteAPIKey(identifier: String) throws {
        try deletePassword(for: "api_key_\(identifier)")
    }
    
    // MARK: - Certificate Operations
    
    /// Save certificate to Keychain
    /// - Parameters:
    ///   - certData: Certificate data (DER or PEM encoded)
    /// Stores a DER-encoded X.509 certificate in the Keychain using the provided label.
    /// If an item with the same label already exists it will be replaced.
    /// - Parameters:
    ///   - certData: DER-encoded certificate data.
    ///   - label: Keychain item label to identify the certificate.
    /// - Throws: `KeychainError.invalidData` if `certData` cannot be parsed as a certificate; `KeychainError.unexpectedStatus(_:)` for other Keychain failures.
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
    
    /// Retrieve a certificate from the Keychain using its label.
    /// - Parameters:
    ///   - label: The Keychain item label used to locate the certificate.
    /// - Returns: The `SecCertificate` matching the specified label.
    /// - Throws:
    ///   - `KeychainError.itemNotFound` if no certificate with the given label exists.
    ///   - `KeychainError.unexpectedStatus(_:)` for any SecItemCopyMatching status other than success or not found.
    ///   - `KeychainError.invalidData` if the retrieved item cannot be interpreted as a `SecCertificate`.
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
    
    /// Deletes a certificate item from the Keychain that matches the provided label.
    /// - Parameters:
    ///   - label: The Keychain item's `kSecAttrLabel` value identifying the certificate to delete.
    /// - Throws: `KeychainError.unexpectedStatus` containing the `OSStatus` when the deletion fails for any reason other than success or item not found.
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
    
    /// Removes all Velociraptor-related items from the user's Keychain.
    /// 
    /// Deletes generic password items stored under the Velociraptor service and certificates labeled "Velociraptor". Updates `lastOperationResult` and emits a warning log when completed.
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
    
    /// Lists stored account names for the Velociraptor Keychain service.
    /// - Returns: An array of account names; empty array if no accounts are found or if the query fails.
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
    
    /// Saves the Velociraptor admin password to the Keychain.
    /// - Parameter password: The admin password to store.
    /// - Throws: `KeychainError` if the save operation fails (for example: `accessDenied`, `encodingFailed`, `duplicateItem`, `unexpectedStatus`, or `itemNotFound`).
    func saveAdminPassword(_ password: String) throws {
        try savePassword(password, for: StandardAccount.adminPassword.rawValue, label: "Velociraptor Admin Password")
    }
    
    /// Retrieves the Velociraptor admin password from the Keychain.
    /// - Returns: The admin password as a UTF-8 string.
    /// - Throws: `KeychainError` if the password is not found, access is denied, or another Keychain error occurs.
    func getAdminPassword() throws -> String {
        try getPassword(for: StandardAccount.adminPassword.rawValue)
    }
    
    /// Check if admin password is stored
    var hasAdminPassword: Bool {
        hasPassword(for: StandardAccount.adminPassword.rawValue)
    }
}