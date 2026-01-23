//
//  DeploymentManager.swift
//  VelociraptorMacOS
//
//  Manages Velociraptor binary download, configuration, and deployment
//

import Foundation
import Combine

/// Manages the complete Velociraptor deployment lifecycle
/// Handles downloading, configuring, and managing the Velociraptor service
@MainActor
class DeploymentManager: ObservableObject {
    // MARK: - Published Properties
    
    /// Whether deployment is in progress
    @Published var isDeploying: Bool = false
    
    /// Current deployment progress (0.0 to 1.0)
    @Published var progress: Double = 0.0
    
    /// Current status message
    @Published var statusMessage: String = ""
    
    /// Detailed status for each step
    @Published var stepStatus: [DeploymentStep: StepStatus] = [:]
    
    /// Last error that occurred
    @Published var lastError: Error?
    
    /// Whether Velociraptor is currently running
    @Published var isRunning: Bool = false
    
    /// Current Velociraptor version (if installed)
    @Published var installedVersion: String?
    
    // MARK: - Private Properties
    
    private let fileManager = FileManager.default
    private var downloadTask: URLSessionDownloadTask?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Types
    
    /// Deployment steps
    enum DeploymentStep: String, CaseIterable, Identifiable {
        case preparation = "Preparation"
        case download = "Download"
        case extraction = "Extraction"
        case directories = "Directories"
        case configuration = "Configuration"
        case service = "Service Installation"
        case startup = "Startup"
        case verification = "Verification"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .preparation: return "gear"
            case .download: return "arrow.down.circle"
            case .extraction: return "archivebox"
            case .directories: return "folder"
            case .configuration: return "doc.text"
            case .service: return "gearshape.2"
            case .startup: return "play.circle"
            case .verification: return "checkmark.seal"
            }
        }
    }
    
    /// Status for each deployment step
    enum StepStatus {
        case pending
        case inProgress
        case completed
        case failed(Error)
        case skipped
    }
    
    /// Deployment errors
    enum DeploymentError: LocalizedError {
        case binaryNotFound
        case downloadFailed(String)
        case extractionFailed(String)
        case configGenerationFailed(String)
        case serviceInstallFailed(String)
        case startupFailed(String)
        case verificationFailed(String)
        case cancelled
        case permissionDenied
        case networkUnavailable
        case insufficientDiskSpace
        
        var errorDescription: String? {
            switch self {
            case .binaryNotFound:
                return "macOS Velociraptor binary not found in the latest release"
            case .downloadFailed(let message):
                return "Download failed: \(message)"
            case .extractionFailed(let message):
                return "Extraction failed: \(message)"
            case .configGenerationFailed(let message):
                return "Configuration generation failed: \(message)"
            case .serviceInstallFailed(let message):
                return "Service installation failed: \(message)"
            case .startupFailed(let message):
                return "Startup failed: \(message)"
            case .verificationFailed(let message):
                return "Verification failed: \(message)"
            case .cancelled:
                return "Deployment was cancelled"
            case .permissionDenied:
                return "Permission denied - administrator access may be required"
            case .networkUnavailable:
                return "Network connection unavailable"
            case .insufficientDiskSpace:
                return "Insufficient disk space for deployment"
            }
        }
        
        var recoverySuggestion: String? {
            switch self {
            case .permissionDenied:
                return "Try running with administrator privileges"
            case .networkUnavailable:
                return "Check your network connection and try again"
            case .insufficientDiskSpace:
                return "Free up disk space and try again"
            default:
                return "Check the logs for more details"
            }
        }
    }
    
    // MARK: - Initialization
    
    init() {
        resetStepStatus()
        checkCurrentInstallation()
    }
    
    private func resetStepStatus() {
        for step in DeploymentStep.allCases {
            stepStatus[step] = .pending
        }
    }
    
    // MARK: - Installation Check
    
    private func checkCurrentInstallation() {
        let binaryPath = ConfigurationData.defaultBinaryPath
        if fileManager.fileExists(atPath: binaryPath) {
            isRunning = checkIfRunning()
            installedVersion = getInstalledVersion(binaryPath: binaryPath)
        }
    }
    
    private func getInstalledVersion(binaryPath: String) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: binaryPath)
        process.arguments = ["version"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
            return output
        } catch {
            return nil
        }
    }
    
    private func checkIfRunning() -> Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", "velociraptor"]
        
        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }
    
    // MARK: - Full Deployment
    
    /// Execute full deployment with given configuration
    func deploy(config: ConfigurationData) async throws {
        isDeploying = true
        progress = 0.0
        lastError = nil
        resetStepStatus()
        
        defer {
            isDeploying = false
        }
        
        do {
            // Step 1: Preparation
            try await executeStep(.preparation) {
                try await self.prepareDeployment(config: config)
            }
            progress = 0.1
            
            // Step 2: Download binary
            let binaryPath = try await executeStep(.download) {
                try await self.downloadVelociraptor(to: config.datastoreDirectory)
            }
            progress = 0.4
            
            // Step 3: Create directories
            try await executeStep(.directories) {
                try await self.createDirectories(config: config)
            }
            progress = 0.5
            
            // Step 4: Generate configuration
            let configPath = try await executeStep(.configuration) {
                try await self.generateConfiguration(config: config, binaryPath: binaryPath)
            }
            progress = 0.6
            
            // Step 5: Install service
            try await executeStep(.service) {
                try await self.installService(binaryPath: binaryPath, configPath: configPath, config: config)
            }
            progress = 0.8
            
            // Step 6: Start service
            try await executeStep(.startup) {
                try await self.startService()
            }
            progress = 0.9
            
            // Step 7: Verify deployment
            try await executeStep(.verification) {
                try await self.verifyDeployment(config: config)
            }
            progress = 1.0
            
            statusMessage = "Deployment completed successfully!"
            isRunning = true
            Logger.shared.success("Deployment completed successfully", component: "Deploy")
            
        } catch {
            lastError = error
            statusMessage = "Deployment failed: \(error.localizedDescription)"
            Logger.shared.error("Deployment failed: \(error)", component: "Deploy")
            throw error
        }
    }
    
    /// Execute a deployment step with status tracking
    private func executeStep<T>(_ step: DeploymentStep, action: () async throws -> T) async throws -> T {
        stepStatus[step] = .inProgress
        statusMessage = "Step: \(step.rawValue)..."
        Logger.shared.info("Starting step: \(step.rawValue)", component: "Deploy")
        
        do {
            let result = try await action()
            stepStatus[step] = .completed
            Logger.shared.success("Completed step: \(step.rawValue)", component: "Deploy")
            return result
        } catch {
            stepStatus[step] = .failed(error)
            throw error
        }
    }
    
    // MARK: - Deployment Steps
    
    private func prepareDeployment(config: ConfigurationData) async throws {
        statusMessage = "Checking prerequisites..."
        
        // Check network connectivity
        guard await checkNetworkConnectivity() else {
            throw DeploymentError.networkUnavailable
        }
        
        // Check disk space
        let requiredSpace: Int64 = 500_000_000 // 500 MB
        let availableSpace = getAvailableDiskSpace(for: config.datastoreDirectory)
        
        guard availableSpace > requiredSpace else {
            throw DeploymentError.insufficientDiskSpace
        }
        
        Logger.shared.info("Prerequisites check passed", component: "Deploy")
    }
    
    private func downloadVelociraptor(to destination: String) async throws -> URL {
        statusMessage = "Fetching latest release information..."
        
        // Get latest release from GitHub API
        let releaseURL = URL(string: "https://api.github.com/repos/Velocidex/velociraptor/releases/latest")!
        
        let (releaseData, _) = try await URLSession.shared.data(from: releaseURL)
        let release = try JSONDecoder().decode(GitHubRelease.self, from: releaseData)
        
        // Find macOS binary - try arm64 first on Apple Silicon
        let arch = getSystemArchitecture()
        let archSuffix = arch == "arm64" ? "darwin-arm64" : "darwin-amd64"
        
        guard let asset = release.assets.first(where: { $0.name.contains(archSuffix) }) else {
            // Fallback to amd64
            guard let fallbackAsset = release.assets.first(where: { $0.name.contains("darwin-amd64") }) else {
                throw DeploymentError.binaryNotFound
            }
            return try await downloadAsset(fallbackAsset, to: destination)
        }
        
        return try await downloadAsset(asset, to: destination)
    }
    
    private func downloadAsset(_ asset: GitHubRelease.Asset, to destination: String) async throws -> URL {
        statusMessage = "Downloading \(asset.name)..."
        Logger.shared.info("Downloading: \(asset.browserDownloadURL)", component: "Deploy")
        
        let downloadURL = URL(string: asset.browserDownloadURL)!
        let (localURL, _) = try await URLSession.shared.download(from: downloadURL)
        
        // Determine destination path
        let destinationDir = URL(fileURLWithPath: destination)
        let binaryPath = destinationDir.appendingPathComponent("velociraptor")
        
        // Create destination directory if needed
        try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
        
        // Remove existing binary if present
        if fileManager.fileExists(atPath: binaryPath.path) {
            try fileManager.removeItem(at: binaryPath)
        }
        
        // Move downloaded file
        try fileManager.moveItem(at: localURL, to: binaryPath)
        
        // Make executable
        try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryPath.path)
        
        installedVersion = getInstalledVersion(binaryPath: binaryPath.path)
        Logger.shared.success("Downloaded and installed binary", component: "Deploy")
        
        return binaryPath
    }
    
    private func createDirectories(config: ConfigurationData) async throws {
        statusMessage = "Creating directories..."
        
        let directories = [
            config.datastoreDirectory,
            config.logsDirectory,
            config.cacheDirectory,
            config.datastoreDirectory + "/config"
        ]
        
        for directory in directories {
            if !fileManager.fileExists(atPath: directory) {
                try fileManager.createDirectory(
                    atPath: directory,
                    withIntermediateDirectories: true,
                    attributes: [.posixPermissions: 0o750]
                )
                Logger.shared.info("Created directory: \(directory)", component: "Deploy")
            }
        }
    }
    
    private func generateConfiguration(config: ConfigurationData, binaryPath: URL) async throws -> URL {
        statusMessage = "Generating configuration..."
        
        let configPath = URL(fileURLWithPath: config.datastoreDirectory)
            .appendingPathComponent("config/server.config.yaml")
        
        let process = Process()
        process.executableURL = binaryPath
        process.arguments = ["config", "generate", "-i"]
        
        // For interactive mode, we'll use a different approach
        // Generate config using the binary
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        // Actually, let's create the config file from our template
        let yamlContent = config.toYAML()
        try yamlContent.write(to: configPath, atomically: true, encoding: .utf8)
        
        // Set proper permissions
        try fileManager.setAttributes([.posixPermissions: 0o640], ofItemAtPath: configPath.path)
        
        Logger.shared.success("Configuration generated: \(configPath.path)", component: "Deploy")
        
        return configPath
    }
    
    private func installService(binaryPath: URL, configPath: URL, config: ConfigurationData) async throws {
        statusMessage = "Installing launchd service..."
        
        let plistContent = generateLaunchdPlist(binaryPath: binaryPath, configPath: configPath, config: config)
        
        let plistPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.velocidex.velociraptor.plist")
        
        // Ensure LaunchAgents directory exists
        let launchAgentsDir = plistPath.deletingLastPathComponent()
        try fileManager.createDirectory(at: launchAgentsDir, withIntermediateDirectories: true)
        
        // Unload existing service if present
        if fileManager.fileExists(atPath: plistPath.path) {
            await unloadService()
            try fileManager.removeItem(at: plistPath)
        }
        
        // Write new plist
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
        
        Logger.shared.success("Launchd plist installed: \(plistPath.path)", component: "Deploy")
    }
    
    private func generateLaunchdPlist(binaryPath: URL, configPath: URL, config: ConfigurationData) -> String {
        return """
        <?xml version="1.0" encoding="UTF-8"?>
        <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
        <plist version="1.0">
        <dict>
            <key>Label</key>
            <string>com.velocidex.velociraptor</string>
            <key>ProgramArguments</key>
            <array>
                <string>\(binaryPath.path)</string>
                <string>frontend</string>
                <string>--config</string>
                <string>\(configPath.path)</string>
            </array>
            <key>RunAtLoad</key>
            <\(config.launchAtLogin ? "true" : "false")/>
            <key>KeepAlive</key>
            <dict>
                <key>SuccessfulExit</key>
                <false/>
            </dict>
            <key>StandardOutPath</key>
            <string>\(config.logsDirectory)/velociraptor.log</string>
            <key>StandardErrorPath</key>
            <string>\(config.logsDirectory)/velociraptor.error.log</string>
            <key>WorkingDirectory</key>
            <string>\(config.datastoreDirectory)</string>
            <key>EnvironmentVariables</key>
            <dict>
                <key>PATH</key>
                <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
            </dict>
        </dict>
        </plist>
        """
    }
    
    private func startService() async throws {
        statusMessage = "Starting Velociraptor service..."
        
        let plistPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.velocidex.velociraptor.plist")
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["load", plistPath.path]
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw DeploymentError.startupFailed("launchctl load failed with status \(process.terminationStatus)")
        }
        
        // Wait for service to start
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        Logger.shared.success("Service started", component: "Deploy")
    }
    
    private func verifyDeployment(config: ConfigurationData) async throws {
        statusMessage = "Verifying deployment..."
        
        // Check if process is running
        guard checkIfRunning() else {
            throw DeploymentError.verificationFailed("Velociraptor process is not running")
        }
        
        // Check if GUI port is listening
        let guiURL = URL(string: "https://\(config.guiBindAddress):\(config.guiBindPort)")!
        
        var request = URLRequest(url: guiURL)
        request.timeoutInterval = 10
        
        let session = URLSession(configuration: .ephemeral, delegate: InsecureURLSessionDelegate(), delegateQueue: nil)
        
        do {
            let (_, response) = try await session.data(for: request)
            if let httpResponse = response as? HTTPURLResponse {
                Logger.shared.info("GUI responded with status: \(httpResponse.statusCode)", component: "Deploy")
            }
        } catch {
            Logger.shared.warning("Could not connect to GUI (may still be starting): \(error)", component: "Deploy")
            // Don't throw - service might still be initializing
        }
        
        isRunning = true
        Logger.shared.success("Deployment verified", component: "Deploy")
    }
    
    // MARK: - Service Management
    
    /// Stop the Velociraptor service
    func stopService() async throws {
        statusMessage = "Stopping service..."
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", "-w", fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.velocidex.velociraptor.plist").path]
        
        try process.run()
        process.waitUntilExit()
        
        isRunning = false
        Logger.shared.info("Service stopped", component: "Deploy")
    }
    
    /// Unload service without affecting run state
    private func unloadService() async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.velocidex.velociraptor.plist").path]
        
        try? process.run()
        process.waitUntilExit()
    }
    
    /// Restart the Velociraptor service
    func restartService() async throws {
        try await stopService()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        try await startService()
    }
    
    // MARK: - Emergency Deployment
    
    /// Execute emergency rapid deployment
    func emergencyDeploy() async throws {
        var config = ConfigurationData()
        config.deploymentType = "Standalone"
        config.encryptionType = .selfSigned
        config.datastoreDirectory = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("EmergencyVelociraptor").path
        config.logsDirectory = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("EmergencyVelociraptor/logs").path
        config.adminUsername = "admin"
        config.adminPassword = "emergency_\(UUID().uuidString.prefix(8))"
        
        try await deploy(config: config)
    }
    
    // MARK: - Helpers
    
    private func checkNetworkConnectivity() async -> Bool {
        let url = URL(string: "https://api.github.com")!
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    private func getAvailableDiskSpace(for path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return Int64(values.volumeAvailableCapacity ?? 0)
        } catch {
            return 0
        }
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
    
    // MARK: - GitHub API Types
    
    struct GitHubRelease: Codable {
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
}

// MARK: - Insecure URL Session Delegate

/// Delegate that allows self-signed certificates (for local testing)
class InsecureURLSessionDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            return (.useCredential, URLCredential(trust: serverTrust))
        }
        return (.performDefaultHandling, nil)
    }
}
