//
//  VelociraptorBinaryBridge.swift
//  VelociraptorMacOS
//
//  Direct communication bridge with Velociraptor binary
//  Provides streaming API and gRPC-like functionality
//
//  CDIF Pattern: Actor-isolated binary process manager with streaming
//  Swift 6 Concurrency: Strict mode compliant
//

import Foundation
import Combine

// MARK: - Binary Bridge Configuration

/// Configuration for the Velociraptor binary bridge
struct BinaryBridgeConfiguration: Sendable {
    /// Path to the Velociraptor binary
    let binaryPath: String
    
    /// Path to the server configuration YAML
    let configPath: String
    
    /// gRPC port for API communication (default 8000)
    let grpcPort: Int
    
    /// GUI port (default 8889)
    let guiPort: Int
    
    /// Whether to enable verbose logging
    let verbose: Bool
    
    init(
        binaryPath: String = ConfigurationData.defaultBinaryPath,
        configPath: String = "",
        grpcPort: Int = 8000,
        guiPort: Int = 8889,
        verbose: Bool = false
    ) {
        self.binaryPath = binaryPath
        self.configPath = configPath
        self.grpcPort = grpcPort
        self.guiPort = guiPort
        self.verbose = verbose
    }
}

// MARK: - Binary Bridge State

/// State of the binary bridge connection
enum BinaryBridgeState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case streaming
    case error(String)
    
    var isConnected: Bool {
        switch self {
        case .connected, .streaming: return true
        default: return false
        }
    }
}

// MARK: - Streaming Result

/// Result from a streaming VQL query
struct StreamingResult: Identifiable, Sendable {
    let id: UUID
    let timestamp: Date
    let columns: [String]
    let row: [VQLValue]
    let isComplete: Bool
    let totalRows: Int?
    let error: String?
    
    init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        columns: [String] = [],
        row: [VQLValue] = [],
        isComplete: Bool = false,
        totalRows: Int? = nil,
        error: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        self.columns = columns
        self.row = row
        self.isComplete = isComplete
        self.totalRows = totalRows
        self.error = error
    }
}

// MARK: - Certificate Info

/// Certificate information extracted from config
struct CertificateInfo: Sendable {
    let clientCertPEM: String
    let clientKeyPEM: String
    let caCertPEM: String
    let serverCN: String
    let expirationDate: Date?
    
    var isValid: Bool {
        guard let expiration = expirationDate else { return true }
        return expiration > Date()
    }
}

// MARK: - Binary Bridge Errors

enum BinaryBridgeError: LocalizedError {
    case binaryNotFound(String)
    case configNotFound(String)
    case connectionFailed(String)
    case streamingFailed(String)
    case certificateExtractionFailed(String)
    case processTerminated(Int32)
    case timeout
    case invalidResponse
    case configurationError(String)
    
    var errorDescription: String? {
        switch self {
        case .binaryNotFound(let path):
            return "Velociraptor binary not found at: \(path)"
        case .configNotFound(let path):
            return "Configuration file not found at: \(path)"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .streamingFailed(let reason):
            return "Streaming failed: \(reason)"
        case .certificateExtractionFailed(let reason):
            return "Certificate extraction failed: \(reason)"
        case .processTerminated(let code):
            return "Process terminated with code: \(code)"
        case .timeout:
            return "Operation timed out"
        case .invalidResponse:
            return "Invalid response from binary"
        case .configurationError(let reason):
            return "Configuration error: \(reason)"
        }
    }
}

// MARK: - Velociraptor Binary Bridge

/// Main bridge for direct communication with Velociraptor binary
/// Provides streaming VQL execution and certificate management
@MainActor
final class VelociraptorBinaryBridge: ObservableObject {
    // MARK: - Singleton
    
    static let shared = VelociraptorBinaryBridge()
    
    // MARK: - Published Properties
    
    @Published private(set) var state: BinaryBridgeState = .disconnected
    @Published private(set) var isProcessRunning: Bool = false
    @Published private(set) var lastError: Error?
    @Published private(set) var extractedCertificates: CertificateInfo?
    
    // MARK: - Private Properties
    
    private var configuration: BinaryBridgeConfiguration?
    private var process: Process?
    private var stdinPipe: Pipe?
    private var stdoutPipe: Pipe?
    private var stderrPipe: Pipe?
    private var cancellables = Set<AnyCancellable>()
    private let fileManager = FileManager.default
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Configuration
    
    /// Configure the binary bridge
    func configure(_ config: BinaryBridgeConfiguration) async throws {
        // Validate binary exists
        guard fileManager.fileExists(atPath: config.binaryPath) else {
            throw BinaryBridgeError.binaryNotFound(config.binaryPath)
        }
        
        // Validate config exists if specified
        if !config.configPath.isEmpty {
            guard fileManager.fileExists(atPath: config.configPath) else {
                throw BinaryBridgeError.configNotFound(config.configPath)
            }
        }
        
        self.configuration = config
        Logger.shared.info("Binary bridge configured: \(config.binaryPath)", component: "Bridge")
    }
    
    // MARK: - Binary Execution
    
    /// Execute a VQL query and stream results
    func executeQueryStreaming(vql: String) -> AsyncThrowingStream<StreamingResult, Error> {
        return AsyncThrowingStream { continuation in
            Task {
                do {
                    guard let config = configuration else {
                        throw BinaryBridgeError.connectionFailed("Bridge not configured")
                    }
                    
                    state = .streaming
                    
                    // Build the query command
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: config.binaryPath)
                    process.arguments = [
                        "query",
                        "--config", config.configPath,
                        "--format", "jsonl",
                        vql
                    ]
                    
                    let stdoutPipe = Pipe()
                    let stderrPipe = Pipe()
                    process.standardOutput = stdoutPipe
                    process.standardError = stderrPipe
                    
                    // Handle stdout line by line
                    let outputHandle = stdoutPipe.fileHandleForReading
                    
                    // Start process
                    try process.run()
                    self.isProcessRunning = true
                    
                    // Read output in background
                    await withTaskGroup(of: Void.self) { group in
                        group.addTask {
                            var buffer = Data()
                            var columns: [String] = []
                            var rowCount = 0
                            
                            while true {
                                let data = outputHandle.availableData
                                if data.isEmpty { break }
                                
                                buffer.append(data)
                                
                                // Process complete lines
                                while let newlineRange = buffer.firstIndex(of: UInt8(ascii: "\n")) {
                                    let lineData = buffer[..<newlineRange]
                                    buffer = buffer[(buffer.index(after: newlineRange))...]
                                    
                                    guard let line = String(data: lineData, encoding: .utf8),
                                          !line.isEmpty else { continue }
                                    
                                    // Parse JSON line
                                    if let jsonData = line.data(using: .utf8),
                                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                                        
                                        // Extract columns from first row
                                        if columns.isEmpty {
                                            columns = Array(json.keys).sorted()
                                        }
                                        
                                        // Build row values
                                        let row = columns.map { key -> VQLValue in
                                            if let value = json[key] {
                                                return VQLValue.from(value)
                                            }
                                            return .null
                                        }
                                        
                                        rowCount += 1
                                        
                                        let result = StreamingResult(
                                            columns: columns,
                                            row: row,
                                            isComplete: false,
                                            totalRows: rowCount
                                        )
                                        
                                        continuation.yield(result)
                                    }
                                }
                            }
                            
                            // Send completion
                            let completion = StreamingResult(
                                columns: columns,
                                row: [],
                                isComplete: true,
                                totalRows: rowCount
                            )
                            continuation.yield(completion)
                        }
                    }
                    
                    process.waitUntilExit()
                    self.isProcessRunning = false
                    
                    if process.terminationStatus != 0 {
                        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                        let errorMessage = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
                        throw BinaryBridgeError.processTerminated(process.terminationStatus)
                    }
                    
                    state = .connected
                    continuation.finish()
                    
                } catch {
                    state = .error(error.localizedDescription)
                    lastError = error
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    /// Execute a query and return all results at once
    func executeQuery(vql: String) async throws -> VQLResult {
        guard let config = configuration else {
            throw BinaryBridgeError.connectionFailed("Bridge not configured")
        }
        
        state = .connecting
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: config.binaryPath)
        process.arguments = [
            "query",
            "--config", config.configPath,
            "--format", "json",
            vql
        ]
        
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe
        
        try process.run()
        isProcessRunning = true
        process.waitUntilExit()
        isProcessRunning = false
        
        guard process.terminationStatus == 0 else {
            let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
            let errorMessage = String(data: stderrData, encoding: .utf8) ?? "Unknown error"
            state = .error(errorMessage)
            throw BinaryBridgeError.processTerminated(process.terminationStatus)
        }
        
        let outputData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
        
        guard let json = try? JSONSerialization.jsonObject(with: outputData) as? [[String: Any]],
              !json.isEmpty else {
            state = .connected
            return VQLResult(columns: [], rows: [])
        }
        
        // Extract columns from first row
        let columns = Array(json[0].keys).sorted()
        
        // Build rows
        let rows: [[VQLValue]] = json.map { row in
            columns.map { key in
                if let value = row[key] {
                    return VQLValue.from(value)
                }
                return .null
            }
        }
        
        state = .connected
        Logger.shared.success("Query executed: \(rows.count) rows", component: "Bridge")
        
        return VQLResult(columns: columns, rows: rows)
    }
    
    // MARK: - Certificate Management
    
    /// Extract certificates from server configuration YAML
    func extractCertificates(from configPath: String) async throws -> CertificateInfo {
        guard fileManager.fileExists(atPath: configPath) else {
            throw BinaryBridgeError.configNotFound(configPath)
        }
        
        guard let configData = fileManager.contents(atPath: configPath),
              let configString = String(data: configData, encoding: .utf8) else {
            throw BinaryBridgeError.certificateExtractionFailed("Cannot read config file")
        }
        
        // Parse YAML to extract certificate sections
        // Note: This is a simplified extraction - production would use proper YAML parsing
        let clientCert = extractYAMLValue(from: configString, key: "client_cert")
        let clientKey = extractYAMLValue(from: configString, key: "client_private_key")
        let caCert = extractYAMLValue(from: configString, key: "ca_certificate")
        let serverCN = extractYAMLValue(from: configString, key: "Common_Name") ?? "VelociraptorServer"
        
        guard let cert = clientCert, let key = clientKey, let ca = caCert else {
            throw BinaryBridgeError.certificateExtractionFailed("Missing certificate fields in config")
        }
        
        let certInfo = CertificateInfo(
            clientCertPEM: cert,
            clientKeyPEM: key,
            caCertPEM: ca,
            serverCN: serverCN,
            expirationDate: parseCertificateExpiration(cert)
        )
        
        extractedCertificates = certInfo
        Logger.shared.success("Extracted certificates from config", component: "Bridge")
        
        return certInfo
    }
    
    /// Pre-pull certificates and configure mTLS for API client
    func configureMTLSFromConfig(configPath: String) async throws {
        let certInfo = try await extractCertificates(from: configPath)
        
        // Write certificates to temporary files for URLSession
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("velociraptor-certs")
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)
        
        let certPath = tempDir.appendingPathComponent("client.crt")
        let keyPath = tempDir.appendingPathComponent("client.key")
        let caPath = tempDir.appendingPathComponent("ca.crt")
        
        try certInfo.clientCertPEM.write(to: certPath, atomically: true, encoding: .utf8)
        try certInfo.clientKeyPEM.write(to: keyPath, atomically: true, encoding: .utf8)
        try certInfo.caCertPEM.write(to: caPath, atomically: true, encoding: .utf8)
        
        // Configure the API client with mTLS
        guard let config = configuration else {
            throw BinaryBridgeError.connectionFailed("Bridge not configured")
        }
        
        let serverURLString = "https://127.0.0.1:\(config.guiPort)"
        
        guard let serverURL = URL(string: serverURLString) else {
            throw BinaryBridgeError.configurationError("Invalid server URL")
        }
        
        // Store mTLS certificate paths for use by URLSession configuration
        UserDefaults.standard.set(certPath.path, forKey: "mTLS.clientCertPath")
        UserDefaults.standard.set(keyPath.path, forKey: "mTLS.clientKeyPath")
        UserDefaults.standard.set(caPath.path, forKey: "mTLS.caCertPath")
        
        // Configure API client (mTLS auth via stored certificates)
        try await VelociraptorAPIClient.shared.configure(
            serverURL: serverURL,
            apiKey: "mtls-authenticated"
        )
        
        Logger.shared.success("Configured mTLS from pre-pulled certificates", component: "Bridge")
    }
    
    // MARK: - Binary Download
    
    /// Download Velociraptor binary to specified location
    func downloadBinary(to destination: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        state = .connecting
        
        // Get latest release info from GitHub
        let releaseURL = URL(string: "https://api.github.com/repos/Velocidex/velociraptor/releases/latest")!
        let (releaseData, _) = try await URLSession.shared.data(from: releaseURL)
        
        guard let release = try? JSONDecoder().decode(GitHubReleaseInfo.self, from: releaseData) else {
            throw BinaryBridgeError.invalidResponse
        }
        
        // Find appropriate binary for this system
        let arch = getSystemArchitecture()
        let assetName = arch == "arm64" ? "darwin-arm64" : "darwin-amd64"
        
        guard let asset = release.assets.first(where: { $0.name.contains(assetName) }) else {
            // Fallback to amd64
            guard let fallback = release.assets.first(where: { $0.name.contains("darwin-amd64") }) else {
                throw BinaryBridgeError.binaryNotFound("No macOS binary in release")
            }
            return try await downloadAsset(fallback, to: destination, progress: progress)
        }
        
        return try await downloadAsset(asset, to: destination, progress: progress)
    }
    
    private func downloadAsset(_ asset: GitHubReleaseInfo.Asset, to destination: URL, progress: @escaping (Double) -> Void) async throws -> URL {
        let downloadURL = URL(string: asset.browserDownloadURL)!
        
        // Create download delegate for progress tracking
        let delegate = DownloadProgressDelegate(progress: progress)
        let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        
        let (localURL, _) = try await session.download(from: downloadURL)
        
        // Move to destination
        let binaryPath = destination.appendingPathComponent("velociraptor")
        
        if fileManager.fileExists(atPath: binaryPath.path) {
            try fileManager.removeItem(at: binaryPath)
        }
        
        try fileManager.createDirectory(at: destination, withIntermediateDirectories: true)
        try fileManager.moveItem(at: localURL, to: binaryPath)
        
        // Make executable
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryPath.path)
        
        state = .connected
        Logger.shared.success("Downloaded binary to: \(binaryPath.path)", component: "Bridge")
        
        return binaryPath
    }
    
    // MARK: - Helpers
    
    private func extractYAMLValue(from yaml: String, key: String) -> String? {
        let pattern = "\(key):\\s*[|>]?\\n?\\s*(.+?)(?=\\n\\w|$)"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            return nil
        }
        
        let range = NSRange(yaml.startIndex..., in: yaml)
        guard let match = regex.firstMatch(in: yaml, range: range),
              let valueRange = Range(match.range(at: 1), in: yaml) else {
            return nil
        }
        
        return String(yaml[valueRange]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func parseCertificateExpiration(_ pem: String) -> Date? {
        // In production, use Security framework to parse the certificate
        // For now, return nil (would need proper X509 parsing)
        return nil
    }
    
    private func getSystemArchitecture() -> String {
        var sysinfo = utsname()
        uname(&sysinfo)
        let machine = withUnsafePointer(to: &sysinfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        return machine
    }
}

// MARK: - GitHub Release Types

private struct GitHubReleaseInfo: Codable {
    let tagName: String
    let name: String
    let assets: [Asset]
    
    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case name
        case assets
    }
    
    struct Asset: Codable {
        let name: String
        let browserDownloadURL: String
        let size: Int
        
        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
            case size
        }
    }
}

// MARK: - Download Progress Delegate

private final class DownloadProgressDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    let progressHandler: (Double) -> Void
    
    init(progress: @escaping (Double) -> Void) {
        self.progressHandler = progress
    }
    
    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            self.progressHandler(progress)
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // Handled by async download call
    }
}

// MARK: - VQLValue Extension

extension VQLValue {
    /// Create VQLValue from Any type
    static func from(_ value: Any) -> VQLValue {
        if value is NSNull {
            return .null
        } else if let string = value as? String {
            return .string(string)
        } else if let number = value as? NSNumber {
            // Both integers and floats map to .number
            return .number(number.doubleValue)
        } else if let bool = value as? Bool {
            return .bool(bool)
        } else if let array = value as? [Any] {
            // Map array to Any array
            return .array(array)
        } else if let dict = value as? [String: Any] {
            // Map dictionary to Any object
            return .object(dict)
        } else {
            return .string(String(describing: value))
        }
    }
}
