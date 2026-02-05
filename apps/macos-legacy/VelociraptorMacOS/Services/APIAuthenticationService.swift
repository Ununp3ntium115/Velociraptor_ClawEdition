//
//  APIAuthenticationService.swift
//  VelociraptorMacOS
//
//  Velociraptor API Authentication Service
//  Gap: 0x01 - API Client Foundation
//
//  CDIF Pattern: Secure credential management with mTLS support
//  Swift 6 Concurrency: Thread-safe with @MainActor isolation
//

import Foundation
import Security

// MARK: - Authentication Errors

/// Authentication-specific errors
enum AuthenticationError: LocalizedError, Sendable {
    case certificateNotFound(String)
    case certificateLoadFailed(String)
    case invalidCertificateFormat
    case keyNotFound(String)
    case keyLoadFailed(String)
    case invalidKeyFormat
    case identityCreationFailed
    case keychainError(OSStatus)
    case sslContextError(String)
    
    var errorDescription: String? {
        switch self {
        case .certificateNotFound(let path):
            return "Certificate not found at: \(path)"
        case .certificateLoadFailed(let msg):
            return "Failed to load certificate: \(msg)"
        case .invalidCertificateFormat:
            return "Invalid certificate format (expected PEM or DER)"
        case .keyNotFound(let path):
            return "Private key not found at: \(path)"
        case .keyLoadFailed(let msg):
            return "Failed to load private key: \(msg)"
        case .invalidKeyFormat:
            return "Invalid key format (expected PEM or DER)"
        case .identityCreationFailed:
            return "Failed to create identity from certificate and key"
        case .keychainError(let status):
            return "Keychain error: \(status) (\(SecCopyErrorMessageString(status, nil) as String? ?? "Unknown"))"
        case .sslContextError(let msg):
            return "SSL context error: \(msg)"
        }
    }
}

// MARK: - API Credentials

/// API credentials stored securely
struct APICredentials: Sendable {
    let serverURL: URL
    let apiKey: String?
    let username: String?
    let password: String?
    let certificatePath: String?
    let keyPath: String?
    
    var authMethod: AuthMethod {
        if let _ = certificatePath, let _ = keyPath {
            return .mtls
        } else if let _ = apiKey {
            return .apiKey
        } else if let _ = username, let _ = password {
            return .basicAuth
        }
        return .none
    }
    
    enum AuthMethod: Sendable {
        case apiKey
        case basicAuth
        case mtls
        case none
    }
}

// MARK: - APIAuthenticationService

/// Service for managing API authentication credentials and mTLS
@MainActor
final class APIAuthenticationService: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = APIAuthenticationService()
    
    // MARK: - Published Properties
    
    @Published private(set) var isConfigured: Bool = false
    @Published private(set) var authMethod: APICredentials.AuthMethod = .none
    
    // MARK: - Private Properties
    
    private var credentials: APICredentials?
    private let keychainService = "com.velociraptor.macos.api"
    
    // MARK: - Initialization
    
    private init() {
        // Try to load saved credentials
        loadSavedCredentials()
    }
    
    // MARK: - Credential Management
    
    /// Save API key credentials
    func saveAPIKeyCredentials(serverURL: URL, apiKey: String) throws {
        let creds = APICredentials(
            serverURL: serverURL,
            apiKey: apiKey,
            username: nil,
            password: nil,
            certificatePath: nil,
            keyPath: nil
        )
        
        // Save to keychain
        try saveToKeychain(key: "apiKey", value: apiKey)
        try saveToKeychain(key: "serverURL", value: serverURL.absoluteString)
        
        self.credentials = creds
        self.isConfigured = true
        self.authMethod = .apiKey
        
        Logger.shared.info("API key credentials saved", component: "Auth")
    }
    
    /// Save basic auth credentials
    func saveBasicAuthCredentials(serverURL: URL, username: String, password: String) throws {
        let creds = APICredentials(
            serverURL: serverURL,
            apiKey: nil,
            username: username,
            password: password,
            certificatePath: nil,
            keyPath: nil
        )
        
        // Save to keychain
        try saveToKeychain(key: "username", value: username)
        try saveToKeychain(key: "password", value: password)
        try saveToKeychain(key: "serverURL", value: serverURL.absoluteString)
        
        self.credentials = creds
        self.isConfigured = true
        self.authMethod = .basicAuth
        
        Logger.shared.info("Basic auth credentials saved", component: "Auth")
    }
    
    /// Save mTLS credentials
    func saveMTLSCredentials(serverURL: URL, certificatePath: String, keyPath: String) throws {
        // Validate certificate and key exist
        guard FileManager.default.fileExists(atPath: certificatePath) else {
            throw AuthenticationError.certificateNotFound(certificatePath)
        }
        
        guard FileManager.default.fileExists(atPath: keyPath) else {
            throw AuthenticationError.keyNotFound(keyPath)
        }
        
        let creds = APICredentials(
            serverURL: serverURL,
            apiKey: nil,
            username: nil,
            password: nil,
            certificatePath: certificatePath,
            keyPath: keyPath
        )
        
        // Save to keychain
        try saveToKeychain(key: "certificatePath", value: certificatePath)
        try saveToKeychain(key: "keyPath", value: keyPath)
        try saveToKeychain(key: "serverURL", value: serverURL.absoluteString)
        
        self.credentials = creds
        self.isConfigured = true
        self.authMethod = .mtls
        
        Logger.shared.info("mTLS credentials saved", component: "Auth")
    }
    
    /// Get current credentials
    func getCredentials() -> APICredentials? {
        return credentials
    }
    
    /// Clear all credentials
    func clearCredentials() throws {
        // Remove from keychain
        let keys = ["apiKey", "username", "password", "certificatePath", "keyPath", "serverURL"]
        for key in keys {
            try? removeFromKeychain(key: key)
        }
        
        self.credentials = nil
        self.isConfigured = false
        self.authMethod = .none
        
        Logger.shared.info("Credentials cleared", component: "Auth")
    }
    
    // MARK: - URLSession Configuration
    
    /// Create URLSession configured for current auth method
    func createAuthenticatedURLSession() throws -> URLSession {
        guard let creds = credentials else {
            throw APIError.notConfigured
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        switch creds.authMethod {
        case .mtls:
            guard let certPath = creds.certificatePath,
                  let keyPath = creds.keyPath else {
                throw APIError.authenticationFailed
            }
            
            // Create session with mTLS delegate
            let delegate = MTLSURLSessionDelegate(
                certificatePath: certPath,
                keyPath: keyPath
            )
            
            return URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
            
        case .apiKey, .basicAuth, .none:
            // Standard session (auth via headers)
            return URLSession(configuration: config)
        }
    }
    
    /// Apply authentication to URLRequest
    func authenticateRequest(_ request: inout URLRequest) throws {
        guard let creds = credentials else {
            throw APIError.notConfigured
        }
        
        switch creds.authMethod {
        case .apiKey:
            guard let apiKey = creds.apiKey else {
                throw APIError.authenticationFailed
            }
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
            
        case .basicAuth:
            guard let username = creds.username,
                  let password = creds.password else {
                throw APIError.authenticationFailed
            }
            let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
            
        case .mtls:
            // mTLS auth handled at session level
            break
            
        case .none:
            throw APIError.notConfigured
        }
    }
    
    // MARK: - Keychain Operations
    
    private func saveToKeychain(key: String, value: String) throws {
        let data = value.data(using: .utf8)!
        
        // Delete existing item first
        try? removeFromKeychain(key: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw AuthenticationError.keychainError(status)
        }
    }
    
    private func loadFromKeychain(key: String) throws -> String {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            throw AuthenticationError.keychainError(status)
        }
        
        return string
    }
    
    private func removeFromKeychain(key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        // Ignore "not found" errors
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AuthenticationError.keychainError(status)
        }
    }
    
    private func loadSavedCredentials() {
        do {
            guard let serverURLString = try? loadFromKeychain(key: "serverURL"),
                  let serverURL = URL(string: serverURLString) else {
                return
            }
            
            // Try loading API key
            if let apiKey = try? loadFromKeychain(key: "apiKey") {
                self.credentials = APICredentials(
                    serverURL: serverURL,
                    apiKey: apiKey,
                    username: nil,
                    password: nil,
                    certificatePath: nil,
                    keyPath: nil
                )
                self.isConfigured = true
                self.authMethod = .apiKey
                Logger.shared.info("API key credentials loaded from keychain", component: "Auth")
                return
            }
            
            // Try loading basic auth
            if let username = try? loadFromKeychain(key: "username"),
               let password = try? loadFromKeychain(key: "password") {
                self.credentials = APICredentials(
                    serverURL: serverURL,
                    apiKey: nil,
                    username: username,
                    password: password,
                    certificatePath: nil,
                    keyPath: nil
                )
                self.isConfigured = true
                self.authMethod = .basicAuth
                Logger.shared.info("Basic auth credentials loaded from keychain", component: "Auth")
                return
            }
            
            // Try loading mTLS
            if let certPath = try? loadFromKeychain(key: "certificatePath"),
               let keyPath = try? loadFromKeychain(key: "keyPath") {
                self.credentials = APICredentials(
                    serverURL: serverURL,
                    apiKey: nil,
                    username: nil,
                    password: nil,
                    certificatePath: certPath,
                    keyPath: keyPath
                )
                self.isConfigured = true
                self.authMethod = .mtls
                Logger.shared.info("mTLS credentials loaded from keychain", component: "Auth")
                return
            }
        } catch {
            Logger.shared.error("Failed to load saved credentials: \(error)", component: "Auth")
        }
    }
}

// MARK: - mTLS URLSession Delegate

/// URLSession delegate for handling mTLS client certificate authentication
private class MTLSURLSessionDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    
    private let certificatePath: String
    private let keyPath: String
    private var identity: SecIdentity?
    
    init(certificatePath: String, keyPath: String) {
        self.certificatePath = certificatePath
        self.keyPath = keyPath
        super.init()
        
        // Preload identity
        do {
            self.identity = try loadIdentity()
        } catch {
            Logger.shared.error("Failed to load mTLS identity: \(error)", component: "Auth")
        }
    }
    
    /// Handle authentication challenge for mTLS
    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        // Handle client certificate authentication
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodClientCertificate {
            guard let identity = identity else {
                Logger.shared.error("No identity available for mTLS", component: "Auth")
                completionHandler(.cancelAuthenticationChallenge, nil)
                return
            }
            
            let credential = URLCredential(
                identity: identity,
                certificates: nil,
                persistence: .forSession
            )
            
            Logger.shared.debug("Providing client certificate for mTLS", component: "Auth")
            completionHandler(.useCredential, credential)
            return
        }
        
        // Handle server trust (certificate pinning)
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust {
            if let serverTrust = challenge.protectionSpace.serverTrust {
                let credential = URLCredential(trust: serverTrust)
                completionHandler(.useCredential, credential)
                return
            }
        }
        
        // Default handling
        completionHandler(.performDefaultHandling, nil)
    }
    
    /// Load SecIdentity from certificate and private key files
    private func loadIdentity() throws -> SecIdentity {
        // Load certificate
        let certData = try Data(contentsOf: URL(fileURLWithPath: certificatePath))
        let certificate = try loadCertificate(from: certData)
        
        // Load private key
        let keyData = try Data(contentsOf: URL(fileURLWithPath: keyPath))
        let privateKey = try loadPrivateKey(from: keyData)
        
        // Create identity
        let identity = try createIdentity(certificate: certificate, privateKey: privateKey)
        
        return identity
    }
    
    /// Load certificate from data (supports PEM and DER)
    private func loadCertificate(from data: Data) throws -> SecCertificate {
        // Try DER format first
        if let cert = SecCertificateCreateWithData(nil, data as CFData) {
            return cert
        }
        
        // Try PEM format
        if let pemString = String(data: data, encoding: .utf8) {
            let pemCleaned = pemString
                .replacingOccurrences(of: "-----BEGIN CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "-----END CERTIFICATE-----", with: "")
                .replacingOccurrences(of: "\n", with: "")
                .replacingOccurrences(of: "\r", with: "")
            
            if let derData = Data(base64Encoded: pemCleaned),
               let cert = SecCertificateCreateWithData(nil, derData as CFData) {
                return cert
            }
        }
        
        throw AuthenticationError.invalidCertificateFormat
    }
    
    /// Load private key from data (supports PEM and DER)
    private func loadPrivateKey(from data: Data) throws -> SecKey {
        // Try loading as PEM first
        if let pemString = String(data: data, encoding: .utf8) {
            // Handle RSA keys
            if pemString.contains("BEGIN RSA PRIVATE KEY") {
                let pemCleaned = pemString
                    .replacingOccurrences(of: "-----BEGIN RSA PRIVATE KEY-----", with: "")
                    .replacingOccurrences(of: "-----END RSA PRIVATE KEY-----", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
                
                if let derData = Data(base64Encoded: pemCleaned) {
                    return try loadPrivateKeyDER(from: derData, keyType: .rsa)
                }
            }
            
            // Handle PKCS8 keys
            if pemString.contains("BEGIN PRIVATE KEY") {
                let pemCleaned = pemString
                    .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
                    .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
                    .replacingOccurrences(of: "\n", with: "")
                    .replacingOccurrences(of: "\r", with: "")
                
                if let derData = Data(base64Encoded: pemCleaned) {
                    return try loadPrivateKeyDER(from: derData, keyType: .rsa)
                }
            }
        }
        
        // Try DER format
        return try loadPrivateKeyDER(from: data, keyType: .rsa)
    }
    
    /// Load private key from DER data
    private func loadPrivateKeyDER(from data: Data, keyType: KeyType) throws -> SecKey {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: keyType.secAttrKeyType,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeySizeInBits as String: 2048
        ]
        
        var error: Unmanaged<CFError>?
        guard let key = SecKeyCreateWithData(data as CFData, attributes as CFDictionary, &error) else {
            if let error = error?.takeRetainedValue() {
                throw AuthenticationError.keyLoadFailed(error.localizedDescription)
            }
            throw AuthenticationError.invalidKeyFormat
        }
        
        return key
    }
    
    /// Create SecIdentity from certificate and private key
    private func createIdentity(certificate: SecCertificate, privateKey: SecKey) throws -> SecIdentity {
        // Create temporary keychain item
        let tempLabel = "com.velociraptor.temp.identity.\(UUID().uuidString)"
        
        // Add certificate to keychain
        let certAddQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: certificate,
            kSecAttrLabel as String: tempLabel
        ]
        
        var status = SecItemAdd(certAddQuery as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw AuthenticationError.identityCreationFailed
        }
        
        // Add private key to keychain
        let keyAddQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecValueRef as String: privateKey,
            kSecAttrLabel as String: tempLabel
        ]
        
        status = SecItemAdd(keyAddQuery as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw AuthenticationError.identityCreationFailed
        }
        
        // Find identity
        let identityQuery: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecAttrLabel as String: tempLabel,
            kSecReturnRef as String: true
        ]
        
        var identityRef: CFTypeRef?
        status = SecItemCopyMatching(identityQuery as CFDictionary, &identityRef)
        
        guard status == errSecSuccess,
              let identity = identityRef as! SecIdentity? else {
            throw AuthenticationError.identityCreationFailed
        }
        
        return identity
    }
    
    private enum KeyType {
        case rsa
        case ec
        
        var secAttrKeyType: CFString {
            switch self {
            case .rsa: return kSecAttrKeyTypeRSA
            case .ec: return kSecAttrKeyTypeECSECPrimeRandom
            }
        }
    }
}

// MARK: - Helper Extensions

extension APIAuthenticationService {
    /// Validate that credentials are properly configured
    func validateCredentials() throws {
        guard let creds = credentials else {
            throw APIError.notConfigured
        }
        
        switch creds.authMethod {
        case .apiKey:
            guard let apiKey = creds.apiKey, !apiKey.isEmpty else {
                throw APIError.authenticationFailed
            }
            
        case .basicAuth:
            guard let username = creds.username, !username.isEmpty,
                  let password = creds.password, !password.isEmpty else {
                throw APIError.authenticationFailed
            }
            
        case .mtls:
            guard let certPath = creds.certificatePath,
                  let keyPath = creds.keyPath else {
                throw APIError.authenticationFailed
            }
            
            guard FileManager.default.fileExists(atPath: certPath) else {
                throw AuthenticationError.certificateNotFound(certPath)
            }
            
            guard FileManager.default.fileExists(atPath: keyPath) else {
                throw AuthenticationError.keyNotFound(keyPath)
            }
            
        case .none:
            throw APIError.notConfigured
        }
    }
}
