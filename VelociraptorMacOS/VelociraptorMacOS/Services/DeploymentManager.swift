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
    
    /// Resets all deployment steps to the `pending` state by updating the internal stepStatus dictionary.
    private func resetStepStatus() {
        for step in DeploymentStep.allCases {
            stepStatus[step] = .pending
        }
    }
    
    /// Checks for an existing Velociraptor binary at the default path and updates local state.
    /// 
    /// If the binary exists, updates `isRunning` to reflect whether the process is currently running
    /// and sets `installedVersion` to the binary's reported version. No changes are made if the binary is absent.
    
    private func checkCurrentInstallation() {
        let binaryPath = ConfigurationData.defaultBinaryPath
        if fileManager.fileExists(atPath: binaryPath) {
            isRunning = checkIfRunning()
            installedVersion = getInstalledVersion(binaryPath: binaryPath)
        }
    }
    
    /// Reads the version string reported by the Velociraptor executable at the given path by invoking it with the `version` command.
    /// - Parameter binaryPath: Filesystem path to the Velociraptor executable.
    /// - Returns: The trimmed stdout produced by the executable (expected to be the version string), or `nil` if the process could not be executed or output could not be read.
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
    
    /// Determines whether a process named "velociraptor" is currently running on the system.
    /// - Returns: `true` if a process named "velociraptor" is running, `false` otherwise.
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
    
    /// Orchestrates the full deployment workflow for Velociraptor using the provided configuration.
    /// 
    /// This method runs the deployment as a sequence of ordered steps (preparation, download,
    /// directory setup, configuration generation, service installation, startup, and verification),
    /// updating progress and per-step statuses as it proceeds. On success it marks the agent as running;
    /// on failure it records the error and updates statusMessage and lastError.
    /// - Parameters:
    ///   - config: ConfigurationData containing deployment settings (datastore paths, GUI/network options, credentials, and other options) to use for this deployment.
    /// - Throws: An error if any deployment step fails (propagates errors from preparation, download, configuration,
    ///   service installation, startup, or verification).
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
            
            // Step 2: Download or copy binary (supports offline mode)
            let binaryPath = try await executeStep(.download) {
                try await self.downloadVelociraptor(to: config.datastoreDirectory, config: config)
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
            SyncLogger.shared.success("Deployment completed successfully", component: "Deploy")
            
        } catch {
            lastError = error
            statusMessage = "Deployment failed: \(error.localizedDescription)"
            SyncLogger.shared.error("Deployment failed: \(error)", component: "Deploy")
            throw error
        }
    }
    
    /// Executes a deployment step by updating its status and running the provided action.
    /// - Parameters:
    ///   - step: The deployment step being executed; used to update `stepStatus` and `statusMessage`.
    ///   - action: An asynchronous throwing closure that performs the work for the step.
    /// - Returns: The value produced by `action`.
    /// - Throws: Any error thrown by `action`; the step's status will be set to `.failed(error)` before the error is propagated.
    private func executeStep<T>(_ step: DeploymentStep, action: () async throws -> T) async throws -> T {
        stepStatus[step] = .inProgress
        statusMessage = "Step: \(step.rawValue)..."
        SyncLogger.shared.info("Starting step: \(step.rawValue)", component: "Deploy")
        
        do {
            let result = try await action()
            stepStatus[step] = .completed
            SyncLogger.shared.success("Completed step: \(step.rawValue)", component: "Deploy")
            return result
        } catch {
            stepStatus[step] = .failed(error)
            throw error
        }
    }
    
    /// Validates prerequisites required to start a deployment.
    /// - Parameters:
    ///   - config: Configuration data whose `datastoreDirectory` is used to check available disk space.
    /// - Throws:
    ///   - `DeploymentError.networkUnavailable` if the network check fails.
    ///   - `DeploymentError.insufficientDiskSpace` if there is less than 500 MB of free space at the datastore directory.
    
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
        
        SyncLogger.shared.info("Prerequisites check passed", component: "Deploy")
    }
    
    /// Downloads or copies the Velociraptor binary based on configuration.
    /// 
    /// Supports three modes:
    /// 1. Offline mode with local binary path - copies the specified binary
    /// 2. Offline mode with bundled binary - uses app bundle resources
    /// 3. Online mode - downloads from GitHub releases
    ///
    /// - Parameters:
    ///   - destination: Filesystem directory path where the `velociraptor` binary will be placed.
    ///   - config: Configuration data containing offline mode settings.
    /// - Returns: The file URL of the installed `velociraptor` binary.
    /// - Throws: `DeploymentError.binaryNotFound` if no suitable binary is available.
    private func downloadVelociraptor(to destination: String, config: ConfigurationData? = nil) async throws -> URL {
        // Check for offline mode
        if let config = config, config.offlineMode {
            return try await handleOfflineMode(destination: destination, config: config)
        }
        
        // Online mode: download from GitHub
        return try await downloadFromGitHub(to: destination)
    }
    
    /// Handles offline mode binary deployment
    private func handleOfflineMode(destination: String, config: ConfigurationData) async throws -> URL {
        statusMessage = "Using offline mode..."
        SyncLogger.shared.info("Offline mode enabled", component: "Deploy")
        
        let destinationDir = URL(fileURLWithPath: destination)
        let binaryPath = destinationDir.appendingPathComponent("velociraptor")
        
        // Try local binary path first
        if !config.localBinaryPath.isEmpty {
            let localURL = URL(fileURLWithPath: config.localBinaryPath)
            if fileManager.fileExists(atPath: localURL.path) {
                statusMessage = "Copying local binary..."
                SyncLogger.shared.info("Using local binary: \(config.localBinaryPath)", component: "Deploy")
                
                try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
                
                if fileManager.fileExists(atPath: binaryPath.path) {
                    try fileManager.removeItem(at: binaryPath)
                }
                
                try fileManager.copyItem(at: localURL, to: binaryPath)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryPath.path)
                
                SyncLogger.shared.success("Copied local binary", component: "Deploy")
                return binaryPath
            }
        }
        
        // Try bundled binary
        if config.useBundledBinary {
            if let bundledURL = findBundledBinary() {
                statusMessage = "Using bundled binary..."
                SyncLogger.shared.info("Using bundled binary", component: "Deploy")
                
                try fileManager.createDirectory(at: destinationDir, withIntermediateDirectories: true)
                
                if fileManager.fileExists(atPath: binaryPath.path) {
                    try fileManager.removeItem(at: binaryPath)
                }
                
                try fileManager.copyItem(at: bundledURL, to: binaryPath)
                try fileManager.setAttributes([.posixPermissions: 0o755], ofItemAtPath: binaryPath.path)
                
                SyncLogger.shared.success("Copied bundled binary", component: "Deploy")
                return binaryPath
            }
        }
        
        throw DeploymentError.binaryNotFound
    }
    
    /// Finds bundled Velociraptor binary in app resources
    private func findBundledBinary() -> URL? {
        let arch = getSystemArchitecture()
        let binaryName = arch == "arm64" ? "velociraptor-darwin-arm64" : "velociraptor-darwin-amd64"
        
        // Check for bundled binary in various locations
        let searchPaths = [
            Bundle.main.resourceURL?.appendingPathComponent(binaryName),
            Bundle.main.resourceURL?.appendingPathComponent("velociraptor"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/\(binaryName)"),
            Bundle.main.bundleURL.appendingPathComponent("Contents/Resources/velociraptor")
        ]
        
        for path in searchPaths {
            if let path = path, fileManager.fileExists(atPath: path.path) {
                return path
            }
        }
        
        return nil
    }
    
    /// Downloads the latest Velociraptor macOS release from GitHub
    private func downloadFromGitHub(to destination: String) async throws -> URL {
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
    
    /// Download the given GitHub release asset and install it as the Velociraptor binary in the specified directory.
    /// - Parameters:
    ///   - asset: The GitHub release asset describing the downloadable binary (name and browserDownloadURL are used).
    ///   - destination: Filesystem directory path where the `velociraptor` binary will be placed; the directory will be created if missing.
    /// - Returns: The file URL of the installed `velociraptor` binary.
    private func downloadAsset(_ asset: GitHubRelease.Asset, to destination: String) async throws -> URL {
        statusMessage = "Downloading \(asset.name)..."
        SyncLogger.shared.info("Downloading: \(asset.browserDownloadURL)", component: "Deploy")
        
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
        SyncLogger.shared.success("Downloaded and installed binary", component: "Deploy")
        
        return binaryPath
    }
    
    /// Ensures required deployment directories exist and applies appropriate permissions.
    /// 
    /// Creates the datastore, logs, cache, and datastore/config directories if they do not exist, setting POSIX permissions to 0o750.
    /// - Parameter config: Configuration data providing paths for datastoreDirectory, logsDirectory, and cacheDirectory.
    /// - Throws: An error from FileManager if creating any directory fails.
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
                SyncLogger.shared.info("Created directory: \(directory)", component: "Deploy")
            }
        }
    }
    
    /// Generates a Velociraptor server YAML configuration from the provided configuration data and writes it to the datastore directory.
    /// - Parameters:
    ///   - config: Configuration values used to build the YAML configuration file.
    ///   - binaryPath: URL of the Velociraptor executable (used as the binary reference for configuration generation).
    /// - Returns: The file URL of the written configuration file (datastoreDirectory/config/server.config.yaml).
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
        
        SyncLogger.shared.success("Configuration generated: \(configPath.path)", component: "Deploy")
        
        return configPath
    }
    
    /// Installs or replaces the user LaunchAgent plist for Velociraptor in ~/Library/LaunchAgents.
    /// - Parameters:
    ///   - binaryPath: Filesystem URL of the Velociraptor binary to reference in the plist.
    ///   - configPath: Filesystem URL of the configuration file to reference in the plist.
    ///   - config: Deployment configuration used to configure the generated plist (e.g., launch-at-login setting and paths).
    /// - Throws: File system errors if the LaunchAgents directory cannot be created, an existing plist cannot be removed, or the new plist cannot be written. Existing service plist (if present) is unloaded before replacement.
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
        
        SyncLogger.shared.success("Launchd plist installed: \(plistPath.path)", component: "Deploy")
    }
    
    /// Creates a LaunchAgent plist XML to run the Velociraptor frontend using the provided binary and configuration.
    /// - Parameters:
    ///   - binaryPath: Filesystem URL of the Velociraptor binary to execute.
    ///   - configPath: Filesystem URL of the YAML configuration file to pass to the binary.
    ///   - config: Deployment configuration used to populate RunAtLoad, log paths, working directory, and other plist fields.
    /// - Returns: A String containing the plist XML for a user LaunchAgent (Label `com.velocidex.velociraptor`) that launches the frontend with the specified binary and configuration.
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
    
    /// Load the user LaunchAgent plist for Velociraptor into launchd and wait briefly for the service to start.
    /// 
    /// Initiates `launchctl load` for ~/Library/LaunchAgents/com.velocidex.velociraptor.plist and pauses for 2 seconds to allow the service to initialize.
    /// - Throws: `DeploymentError.startupFailed` if `launchctl` exits with a non-zero status.
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
        
        SyncLogger.shared.success("Service started", component: "Deploy")
    }
    
    /// Verifies the deployed Velociraptor service and performs a brief GUI health check.
    /// 
    /// Attempts to confirm the Velociraptor process is running and sends an HTTPS request to the configured GUI address and port. If the process check succeeds, `isRunning` is set to `true`. Failures to connect to the GUI are logged but do not cause the verification to fail (the service may still be initializing).
    /// - Parameter config: Configuration data containing the GUI bind address and port used for the verification request.
    /// - Throws: `DeploymentError.verificationFailed` if the Velociraptor process is not running.
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
                SyncLogger.shared.info("GUI responded with status: \(httpResponse.statusCode)", component: "Deploy")
            }
        } catch {
            SyncLogger.shared.warning("Could not connect to GUI (may still be starting): \(error)", component: "Deploy")
            // Don't throw - service might still be initializing
        }
        
        isRunning = true
        SyncLogger.shared.success("Deployment verified", component: "Deploy")
    }
    
    // MARK: - Service Management
    
    /// Stops the Velociraptor LaunchAgent and updates the manager's running state.
    /// 
    /// The method invokes `/bin/launchctl unload -w` on `~/Library/LaunchAgents/com.velocidex.velociraptor.plist`, sets `statusMessage` to indicate shutdown progress, and sets `isRunning` to `false` when the unload completes.
    /// - Throws: An error if starting or running the `launchctl` process fails.
    func stopService() async throws {
        statusMessage = "Stopping service..."
        
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", "-w", fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.velocidex.velociraptor.plist").path]
        
        try process.run()
        process.waitUntilExit()
        
        isRunning = false
        SyncLogger.shared.info("Service stopped", component: "Deploy")
    }
    
    /// Attempts to unload the user LaunchAgent plist for Velociraptor using `launchctl`.
    /// 
    /// Runs `launchctl unload` on ~/Library/LaunchAgents/com.velocidex.velociraptor.plist and waits for the command to finish. Any errors from launching or running the process are ignored and not propagated; this method does not modify the manager's `isRunning` state.
    private func unloadService() async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = ["unload", fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.velocidex.velociraptor.plist").path]
        
        try? process.run()
        process.waitUntilExit()
    }
    
    /// Restarts the Velociraptor launch agent by stopping the service, waiting one second, then starting it again.
    /// - Throws: An error if stopping or starting the service fails.
    func restartService() async throws {
        try await stopService()
        try await Task.sleep(nanoseconds: 1_000_000_000)
        try await startService()
    }
    
    // MARK: - Emergency Deployment
    
    /// Creates a minimal standalone configuration with a generated admin password and performs an emergency deployment.
    /// 
    /// The configuration uses a user-home subdirectory "EmergencyVelociraptor" for datastore and logs, sets the deployment type to "Standalone",
    /// and the encryption type to `.selfSigned`. An admin user "admin" is created with a short random password.
    /// - Throws: Any error thrown by `deploy(config:)` when the emergency deployment fails.
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
    
    /// Checks whether the machine can reach the GitHub API.
    /// 
    /// - Returns: `true` if the GitHub API responds with HTTP 200, `false` otherwise.
    
    private func checkNetworkConnectivity() async -> Bool {
        let url = URL(string: "https://api.github.com")!
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            return (response as? HTTPURLResponse)?.statusCode == 200
        } catch {
            return false
        }
    }
    
    /// Get available disk space for the volume containing the given filesystem path.
    /// - Parameter path: A filesystem path located on the volume to query.
    /// - Returns: The number of free bytes available on that volume as `Int64`; returns `0` if the value cannot be determined.
    private func getAvailableDiskSpace(for path: String) -> Int64 {
        let url = URL(fileURLWithPath: path)
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityKey])
            return Int64(values.volumeAvailableCapacity ?? 0)
        } catch {
            return 0
        }
    }
    
    /// Obtains the system's machine architecture identifier.
    /// - Returns: The architecture identifier string from the system (for example "arm64" or "x86_64").
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
    /// Allows a server-trust challenge to proceed by supplying a `URLCredential` created from the server trust when available.
    /// - Parameters:
    ///   - session: The `URLSession` that received the authentication challenge.
    ///   - challenge: The authentication challenge to evaluate; if its protection space contains a `serverTrust`, a corresponding credential will be returned.
    /// - Returns: A tuple containing the `AuthChallengeDisposition` and an optional `URLCredential`. Returns `(.useCredential, URLCredential(trust: serverTrust))` when a `serverTrust` is present; otherwise returns `(.performDefaultHandling, nil)`.
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
           let serverTrust = challenge.protectionSpace.serverTrust {
            return (.useCredential, URLCredential(trust: serverTrust))
        }
        return (.performDefaultHandling, nil)
    }
}