# macOS Master Iteration Plan

**Document Version**: 1.0  
**Creation Date**: January 23, 2026  
**Methodology**: Circular Iteration with Line-by-Line Implementation  
**Target SDK**: macOS 13.0+ (Ventura), Swift 5.9+, SwiftUI

---

## Iteration Methodology

This plan follows a **circular iteration pattern**:

```
┌─────────────────────────────────────────────────────────────┐
│                    ITERATION CYCLE                          │
│                                                             │
│    ┌──────────┐    ┌──────────┐    ┌──────────┐            │
│    │  PLAN    │───>│  BUILD   │───>│  TEST    │            │
│    └──────────┘    └──────────┘    └──────────┘            │
│         ▲                               │                   │
│         │          ┌──────────┐         │                   │
│         └──────────│  REVIEW  │<────────┘                   │
│                    └──────────┘                             │
│                                                             │
│    Each iteration produces working, tested code             │
│    Line-by-line implementation ensures completeness         │
└─────────────────────────────────────────────────────────────┘
```

---

## Phase 1: Foundation (Iterations 1-5)

### Iteration 1: Project Structure Setup

**Objective**: Create macOS Xcode project with proper structure

**Files to Create**:

```swift
// File: apps/macos-legacy/VelociraptorMacOS/VelociraptorMacOSApp.swift
// Line 1-35: Main application entry point

import SwiftUI

@main
struct VelociraptorMacOSApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var deploymentManager = DeploymentManager()
    @StateObject private var keychainManager = KeychainManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(deploymentManager)
                .environmentObject(keychainManager)
                .frame(minWidth: 900, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            AppCommands()
        }
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}
```

```swift
// File: apps/macos-legacy/VelociraptorMacOS/Models/AppState.swift
// Line 1-50: Application state management

import SwiftUI
import Combine

@MainActor
class AppState: ObservableObject {
    @Published var currentStep: WizardStep = .welcome
    @Published var deploymentType: DeploymentType = .standalone
    @Published var isDeploying: Bool = false
    @Published var deploymentProgress: Double = 0.0
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    enum WizardStep: Int, CaseIterable {
        case welcome = 0
        case deploymentType = 1
        case certificateSettings = 2
        case securitySettings = 3
        case storageConfiguration = 4
        case networkConfiguration = 5
        case authentication = 6
        case review = 7
        case complete = 8
        
        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .deploymentType: return "Deployment Type"
            case .certificateSettings: return "Certificate Settings"
            case .securitySettings: return "Security Settings"
            case .storageConfiguration: return "Storage Configuration"
            case .networkConfiguration: return "Network Configuration"
            case .authentication: return "Authentication"
            case .review: return "Review & Generate"
            case .complete: return "Complete"
            }
        }
    }
    
    enum DeploymentType: String, CaseIterable {
        case server = "Server"
        case standalone = "Standalone"
        case client = "Client"
    }
}
```

**Test Case**:
```swift
// File: VelociraptorMacOSTests/AppStateTests.swift
import XCTest
@testable import VelociraptorMacOS

final class AppStateTests: XCTestCase {
    func testInitialState() async {
        let appState = await AppState()
        await MainActor.run {
            XCTAssertEqual(appState.currentStep, .welcome)
            XCTAssertEqual(appState.deploymentType, .standalone)
            XCTAssertFalse(appState.isDeploying)
        }
    }
}
```

**Completion Criteria**:
- [ ] Xcode project builds without errors
- [ ] Unit tests pass
- [ ] App launches and shows empty window

---

### Iteration 2: Configuration Data Model

**Objective**: Create comprehensive configuration model

```swift
// File: apps/macos-legacy/VelociraptorMacOS/Models/ConfigurationData.swift
// Line 1-120: Configuration data model

import Foundation

struct ConfigurationData: Codable, Equatable {
    // Deployment Settings
    var deploymentType: String = "Standalone"
    var organizationName: String = "VelociraptorOrg"
    
    // Storage Settings
    var datastoreDirectory: String = defaultDatastorePath
    var logsDirectory: String = defaultLogsPath
    var cacheDirectory: String = defaultCachePath
    
    // Network Settings
    var bindAddress: String = "0.0.0.0"
    var bindPort: Int = 8000
    var guiBindAddress: String = "127.0.0.1"
    var guiBindPort: Int = 8889
    
    // Certificate Settings
    var encryptionType: EncryptionType = .selfSigned
    var customCertPath: String = ""
    var customKeyPath: String = ""
    var letsEncryptDomain: String = ""
    var certificateExpiration: String = "1 Year"
    
    // Security Settings
    var environment: Environment = .production
    var logLevel: LogLevel = .info
    var enforceTLS12: Bool = true
    var validateCertificates: Bool = true
    var enableDebugLogging: Bool = false
    
    // Authentication
    var adminUsername: String = "admin"
    var adminPassword: String = ""
    var restrictVQL: Bool = false
    
    // macOS-Specific
    var launchAtLogin: Bool = false
    var useKeychain: Bool = true
    var enableNotifications: Bool = true
    
    // Enums
    enum EncryptionType: String, Codable, CaseIterable {
        case selfSigned = "SelfSigned"
        case custom = "Custom"
        case letsEncrypt = "LetsEncrypt"
        
        var description: String {
            switch self {
            case .selfSigned: return "Self-Signed Certificate (Recommended)"
            case .custom: return "Custom Certificate Files"
            case .letsEncrypt: return "Let's Encrypt (AutoCert)"
            }
        }
    }
    
    enum Environment: String, Codable, CaseIterable {
        case production = "Production"
        case development = "Development"
        case testing = "Testing"
        case staging = "Staging"
    }
    
    enum LogLevel: String, Codable, CaseIterable {
        case error = "ERROR"
        case warn = "WARN"
        case info = "INFO"
        case debug = "DEBUG"
    }
    
    // macOS default paths
    static var defaultDatastorePath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Velociraptor")
            .path
    }
    
    static var defaultLogsPath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Velociraptor")
            .path
    }
    
    static var defaultCachePath: String {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/Velociraptor")
            .path
    }
    
    // Validation
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []
        
        if adminUsername.isEmpty {
            errors.append(.emptyUsername)
        }
        if adminPassword.count < 8 {
            errors.append(.weakPassword)
        }
        if bindPort < 1 || bindPort > 65535 {
            errors.append(.invalidPort("Bind Port"))
        }
        if guiBindPort < 1 || guiBindPort > 65535 {
            errors.append(.invalidPort("GUI Port"))
        }
        
        return errors
    }
    
    enum ValidationError: LocalizedError {
        case emptyUsername
        case weakPassword
        case invalidPort(String)
        case invalidPath(String)
        
        var errorDescription: String? {
            switch self {
            case .emptyUsername: return "Admin username cannot be empty"
            case .weakPassword: return "Password must be at least 8 characters"
            case .invalidPort(let name): return "\(name) must be between 1 and 65535"
            case .invalidPath(let name): return "\(name) path is invalid"
            }
        }
    }
}
```

**Test Case**:
```swift
// File: VelociraptorMacOSTests/ConfigurationDataTests.swift
import XCTest
@testable import VelociraptorMacOS

final class ConfigurationDataTests: XCTestCase {
    func testDefaultValues() {
        let config = ConfigurationData()
        XCTAssertEqual(config.bindPort, 8000)
        XCTAssertEqual(config.guiBindPort, 8889)
        XCTAssertTrue(config.enforceTLS12)
    }
    
    func testValidation() {
        var config = ConfigurationData()
        config.adminPassword = "short"
        let errors = config.validate()
        XCTAssertTrue(errors.contains(.weakPassword))
    }
}
```

---

### Iteration 3: Main Content View

**Objective**: Create main navigation structure

```swift
// File: apps/macos-legacy/VelociraptorMacOS/Views/ContentView.swift
// Line 1-100: Main content view with navigation

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var config = ConfigurationViewModel()
    
    var body: some View {
        NavigationSplitView {
            SidebarView(currentStep: $appState.currentStep)
                .frame(minWidth: 200)
        } detail: {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                    .frame(height: 80)
                
                Divider()
                
                // Content
                ScrollView {
                    StepContentView(step: appState.currentStep, config: config)
                        .padding()
                }
                
                Divider()
                
                // Navigation Buttons
                NavigationButtonsView(
                    currentStep: $appState.currentStep,
                    config: config
                )
                .frame(height: 60)
                .padding(.horizontal)
            }
        }
        .navigationTitle("Velociraptor Configuration Wizard")
        .toolbar {
            ToolbarContent()
        }
    }
}

struct SidebarView: View {
    @Binding var currentStep: AppState.WizardStep
    
    var body: some View {
        List(AppState.WizardStep.allCases, id: \.self) { step in
            HStack {
                Image(systemName: step.rawValue <= currentStep.rawValue ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(step.rawValue <= currentStep.rawValue ? .green : .secondary)
                Text(step.title)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                if step.rawValue <= currentStep.rawValue {
                    currentStep = step
                }
            }
        }
        .listStyle(.sidebar)
    }
}

struct HeaderView: View {
    var body: some View {
        HStack {
            Image(systemName: "shield.fill")
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading) {
                Text("VELOCIRAPTOR")
                    .font(.title.bold())
                Text("DFIR Framework Configuration Wizard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text("v5.0.5 | Free For All First Responders")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.accentColor.opacity(0.1))
    }
}

struct NavigationButtonsView: View {
    @Binding var currentStep: AppState.WizardStep
    @ObservedObject var config: ConfigurationViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        HStack {
            Spacer()
            
            Button("Back") {
                if let previous = AppState.WizardStep(rawValue: currentStep.rawValue - 1) {
                    currentStep = previous
                }
            }
            .disabled(currentStep == .welcome)
            
            Button(currentStep == .complete ? "Finish" : "Next") {
                if currentStep == .complete {
                    dismiss()
                } else if let next = AppState.WizardStep(rawValue: currentStep.rawValue + 1) {
                    currentStep = next
                }
            }
            .buttonStyle(.borderedProminent)
            
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(DeploymentManager())
        .environmentObject(KeychainManager())
}
```

---

### Iteration 4: Keychain Manager

**Objective**: Implement secure credential storage

```swift
// File: apps/macos-legacy/VelociraptorMacOS/Services/KeychainManager.swift
// Line 1-150: Keychain integration for macOS

import Foundation
import Security

@MainActor
class KeychainManager: ObservableObject {
    private let serviceName = "com.velocidex.velociraptor"
    
    enum KeychainError: LocalizedError {
        case duplicateItem
        case itemNotFound
        case unexpectedStatus(OSStatus)
        case invalidData
        
        var errorDescription: String? {
            switch self {
            case .duplicateItem: return "Item already exists in Keychain"
            case .itemNotFound: return "Item not found in Keychain"
            case .unexpectedStatus(let status): return "Keychain error: \(status)"
            case .invalidData: return "Invalid data format"
            }
        }
    }
    
    // MARK: - Password Storage
    
    func savePassword(_ password: String, for account: String) throws {
        let passwordData = password.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: passwordData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account
            ]
            
            let attributes: [String: Any] = [
                kSecValueData as String: passwordData
            ]
            
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
            guard updateStatus == errSecSuccess else {
                throw KeychainError.unexpectedStatus(updateStatus)
            }
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedStatus(status)
        }
    }
    
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
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }
        
        guard let data = result as? Data,
              let password = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        
        return password
    }
    
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
    }
    
    // MARK: - API Key Storage
    
    func saveAPIKey(_ key: String, identifier: String) throws {
        try savePassword(key, for: "api_key_\(identifier)")
    }
    
    func getAPIKey(identifier: String) throws -> String {
        try getPassword(for: "api_key_\(identifier)")
    }
    
    // MARK: - Certificate Storage
    
    func saveCertificate(_ certData: Data, label: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: label,
            kSecValueData as String: certData
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess || status == errSecDuplicateItem else {
            throw KeychainError.unexpectedStatus(status)
        }
    }
}
```

**Test Case**:
```swift
// File: VelociraptorMacOSTests/KeychainManagerTests.swift
import XCTest
@testable import VelociraptorMacOS

final class KeychainManagerTests: XCTestCase {
    var keychainManager: KeychainManager!
    
    override func setUp() async throws {
        keychainManager = await KeychainManager()
    }
    
    override func tearDown() async throws {
        try? await keychainManager.deletePassword(for: "test_account")
    }
    
    func testSaveAndRetrievePassword() async throws {
        try await keychainManager.savePassword("TestPassword123", for: "test_account")
        let retrieved = try await keychainManager.getPassword(for: "test_account")
        XCTAssertEqual(retrieved, "TestPassword123")
    }
}
```

---

### Iteration 5: Deployment Manager

**Objective**: Implement core deployment logic

```swift
// File: apps/macos-legacy/VelociraptorMacOS/Services/DeploymentManager.swift
// Line 1-200: Deployment management for macOS

import Foundation
import Combine

@MainActor
class DeploymentManager: ObservableObject {
    @Published var isDeploying: Bool = false
    @Published var progress: Double = 0.0
    @Published var statusMessage: String = ""
    @Published var lastError: Error?
    
    private let fileManager = FileManager.default
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Directory Setup
    
    func setupDirectories(config: ConfigurationData) async throws {
        statusMessage = "Creating directories..."
        progress = 0.1
        
        let directories = [
            config.datastoreDirectory,
            config.logsDirectory,
            config.cacheDirectory
        ]
        
        for (index, directory) in directories.enumerated() {
            try fileManager.createDirectory(
                atPath: directory,
                withIntermediateDirectories: true,
                attributes: [.posixPermissions: 0o750]
            )
            progress = 0.1 + (Double(index + 1) / Double(directories.count)) * 0.1
        }
    }
    
    // MARK: - Binary Download
    
    func downloadVelociraptor(to destination: String) async throws -> URL {
        statusMessage = "Fetching latest release..."
        progress = 0.2
        
        // Get latest release info
        let releaseURL = URL(string: "https://api.github.com/repos/Velocidex/velociraptor/releases/latest")!
        let (releaseData, _) = try await URLSession.shared.data(from: releaseURL)
        
        let release = try JSONDecoder().decode(GitHubRelease.self, from: releaseData)
        
        // Find macOS binary
        guard let macOSAsset = release.assets.first(where: { $0.name.contains("darwin-amd64") }) else {
            throw DeploymentError.binaryNotFound
        }
        
        statusMessage = "Downloading Velociraptor..."
        progress = 0.3
        
        let downloadURL = URL(string: macOSAsset.browserDownloadURL)!
        let (localURL, _) = try await URLSession.shared.download(from: downloadURL)
        
        // Move to destination
        let destinationURL = URL(fileURLWithPath: destination)
            .appendingPathComponent("velociraptor")
        
        if fileManager.fileExists(atPath: destinationURL.path) {
            try fileManager.removeItem(at: destinationURL)
        }
        
        try fileManager.moveItem(at: localURL, to: destinationURL)
        
        // Make executable
        try fileManager.setAttributes(
            [.posixPermissions: 0o755],
            ofItemAtPath: destinationURL.path
        )
        
        progress = 0.5
        return destinationURL
    }
    
    // MARK: - Configuration Generation
    
    func generateConfiguration(config: ConfigurationData, binaryPath: URL) async throws -> URL {
        statusMessage = "Generating configuration..."
        progress = 0.6
        
        let configPath = URL(fileURLWithPath: config.datastoreDirectory)
            .appendingPathComponent("velociraptor.config.yaml")
        
        let process = Process()
        process.executableURL = binaryPath
        process.arguments = ["config", "generate", "--config", configPath.path]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe
        
        try process.run()
        process.waitUntilExit()
        
        guard process.terminationStatus == 0 else {
            throw DeploymentError.configGenerationFailed
        }
        
        progress = 0.7
        return configPath
    }
    
    // MARK: - Service Installation
    
    func installLaunchdService(binaryPath: URL, configPath: URL, config: ConfigurationData) async throws {
        statusMessage = "Installing launchd service..."
        progress = 0.8
        
        let plistContent = """
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
            <true/>
            <key>StandardOutPath</key>
            <string>\(config.logsDirectory)/velociraptor.log</string>
            <key>StandardErrorPath</key>
            <string>\(config.logsDirectory)/velociraptor.error.log</string>
        </dict>
        </plist>
        """
        
        let plistPath = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.velocidex.velociraptor.plist")
        
        try plistContent.write(to: plistPath, atomically: true, encoding: .utf8)
        
        progress = 0.9
    }
    
    // MARK: - Full Deployment
    
    func deploy(config: ConfigurationData) async throws {
        isDeploying = true
        progress = 0.0
        
        do {
            try await setupDirectories(config: config)
            let binaryPath = try await downloadVelociraptor(to: config.datastoreDirectory)
            let configPath = try await generateConfiguration(config: config, binaryPath: binaryPath)
            try await installLaunchdService(binaryPath: binaryPath, configPath: configPath, config: config)
            
            statusMessage = "Deployment complete!"
            progress = 1.0
        } catch {
            lastError = error
            throw error
        }
        
        isDeploying = false
    }
    
    // MARK: - Supporting Types
    
    struct GitHubRelease: Codable {
        let tagName: String
        let assets: [Asset]
        
        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case assets
        }
        
        struct Asset: Codable {
            let name: String
            let browserDownloadURL: String
            
            enum CodingKeys: String, CodingKey {
                case name
                case browserDownloadURL = "browser_download_url"
            }
        }
    }
    
    enum DeploymentError: LocalizedError {
        case binaryNotFound
        case configGenerationFailed
        case serviceInstallFailed
        
        var errorDescription: String? {
            switch self {
            case .binaryNotFound: return "macOS binary not found in release"
            case .configGenerationFailed: return "Failed to generate configuration"
            case .serviceInstallFailed: return "Failed to install launchd service"
            }
        }
    }
}
```

---

## Phase 2: UI Implementation (Iterations 6-15)

### Iteration 6-9: Wizard Step Views

Each step view follows this pattern:

```swift
// File: apps/macos-legacy/VelociraptorMacOS/Views/Steps/DeploymentTypeStepView.swift
import SwiftUI

struct DeploymentTypeView: View {
    @ObservedObject var config: ConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Select Deployment Type")
                .font(.title2.bold())
                .foregroundColor(.accentColor)
            
            ForEach(ConfigurationData.DeploymentType.allCases, id: \.self) { type in
                DeploymentTypeCard(
                    type: type,
                    isSelected: config.data.deploymentType == type.rawValue,
                    action: { config.data.deploymentType = type.rawValue }
                )
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Deployment Type Selection")
    }
}

struct DeploymentTypeCard: View {
    let type: ConfigurationData.DeploymentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                VStack(alignment: .leading) {
                    Text(type.rawValue)
                        .font(.headline)
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color.clear)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.3))
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(type.rawValue) deployment")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
```

---

### Iteration 10-12: Incident Response Views

```swift
// File: apps/macos-legacy/VelociraptorMacOS/Views/IncidentResponse/IncidentResponseView.swift
import SwiftUI

struct IncidentResponseView: View {
    @StateObject private var viewModel = IncidentResponseViewModel()
    
    var body: some View {
        HSplitView {
            // Left: Category & Incident Selection
            VStack(alignment: .leading) {
                CategoryPicker(selection: $viewModel.selectedCategory)
                IncidentList(
                    incidents: viewModel.filteredIncidents,
                    selection: $viewModel.selectedIncident
                )
            }
            .frame(minWidth: 300)
            
            // Right: Details & Configuration
            VStack {
                IncidentDetailsView(incident: viewModel.selectedIncident)
                Divider()
                CollectorConfigurationView(config: $viewModel.collectorConfig)
                Divider()
                ActionButtonsView(viewModel: viewModel)
            }
        }
        .navigationTitle("Incident Response Collector")
    }
}
```

---

## Phase 3: Testing (Iterations 16-20)

### Iteration 16: XCTest Unit Tests

```swift
// File: VelociraptorMacOSTests/DeploymentManagerTests.swift
import XCTest
@testable import VelociraptorMacOS

final class DeploymentManagerTests: XCTestCase {
    var deploymentManager: DeploymentManager!
    
    override func setUp() async throws {
        deploymentManager = await DeploymentManager()
    }
    
    func testDirectoryCreation() async throws {
        var config = ConfigurationData()
        config.datastoreDirectory = NSTemporaryDirectory() + "VelociraptorTest"
        
        try await deploymentManager.setupDirectories(config: config)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: config.datastoreDirectory))
        
        // Cleanup
        try? FileManager.default.removeItem(atPath: config.datastoreDirectory)
    }
}
```

### Iteration 17-18: XCUITest UI Tests

```swift
// File: VelociraptorMacOSUITests/ConfigurationWizardUITests.swift
import XCTest

final class ConfigurationWizardUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testWizardNavigation() throws {
        // TC001: Verify wizard loads
        XCTAssertTrue(app.windows["Velociraptor Configuration Wizard"].exists)
        
        // TC002: Navigate forward
        let nextButton = app.buttons["Next"]
        XCTAssertTrue(nextButton.exists)
        nextButton.click()
        
        // Verify step change
        XCTAssertTrue(app.staticTexts["Deployment Type"].exists)
        
        // TC003: Navigate backward
        let backButton = app.buttons["Back"]
        XCTAssertTrue(backButton.isEnabled)
        backButton.click()
        
        XCTAssertTrue(app.staticTexts["Welcome"].exists)
    }
    
    func testDeploymentTypeSelection() throws {
        // Navigate to deployment type step
        app.buttons["Next"].click()
        
        // TC004: Select Server deployment
        let serverOption = app.buttons["Server deployment"]
        serverOption.click()
        
        // Verify selection
        XCTAssertTrue(serverOption.isSelected)
    }
    
    func testEmergencyMode() throws {
        // TC009: Test emergency deployment
        let emergencyButton = app.buttons["Emergency deployment mode"]
        XCTAssertTrue(emergencyButton.exists)
        
        emergencyButton.click()
        
        // Verify confirmation dialog
        XCTAssertTrue(app.alerts["Emergency Deployment"].exists)
    }
}
```

### Iteration 19: Accessibility Tests

```swift
// File: VelociraptorMacOSUITests/AccessibilityUITests.swift
import XCTest

final class AccessibilityUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    func testVoiceOverLabels() throws {
        // TC_A001: Main window accessibility
        let window = app.windows.firstMatch
        XCTAssertNotNil(window.value(forKey: "accessibilityLabel"))
        
        // TC_A002: Next button accessibility
        let nextButton = app.buttons["Next"]
        XCTAssertEqual(nextButton.label, "Next step")
        
        // TC_A003: Back button accessibility  
        let backButton = app.buttons["Back"]
        XCTAssertEqual(backButton.label, "Previous step")
    }
    
    func testKeyboardNavigation() throws {
        // Test Tab navigation
        app.typeKey(.tab, modifierFlags: [])
        // Verify focus moved
        
        // Test Shift+Tab navigation
        app.typeKey(.tab, modifierFlags: .shift)
        // Verify focus moved back
    }
}
```

---

## Phase 4: Integration & Polish (Iterations 21-25)

### Iteration 21: Code Signing Setup

```bash
# Commands for code signing setup
# Execute in project directory

# Create entitlements file
cat > apps/macos-legacy/VelociraptorMacOS/VelociraptorMacOS.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <false/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.keychain-access-groups</key>
    <array>
        <string>$(AppIdentifierPrefix)com.velocidex.velociraptor</string>
    </array>
</dict>
</plist>
EOF

# Build for distribution
xcodebuild -project VelociraptorMacOS.xcodeproj \
    -scheme VelociraptorMacOS \
    -configuration Release \
    -archivePath ./build/VelociraptorMacOS.xcarchive \
    archive

# Export for distribution
xcodebuild -exportArchive \
    -archivePath ./build/VelociraptorMacOS.xcarchive \
    -exportPath ./build/export \
    -exportOptionsPlist ExportOptions.plist

# Notarize
xcrun notarytool submit ./build/export/VelociraptorMacOS.app.zip \
    --apple-id "$APPLE_ID" \
    --password "$APP_SPECIFIC_PASSWORD" \
    --team-id "$TEAM_ID" \
    --wait

# Staple
xcrun stapler staple ./build/export/VelociraptorMacOS.app
```

### Iteration 22-25: Final Integration

- Homebrew formula update
- CI/CD pipeline setup
- Documentation completion
- Release packaging

---

## Execution Schedule

| Iteration | Focus | Duration | Dependencies |
|-----------|-------|----------|--------------|
| 1 | Project Structure | 1 day | None |
| 2 | Data Models | 1 day | Iteration 1 |
| 3 | Main Content View | 1 day | Iteration 2 |
| 4 | Keychain Manager | 1 day | Iteration 1 |
| 5 | Deployment Manager | 2 days | Iterations 2, 4 |
| 6-9 | Wizard Step Views | 4 days | Iteration 3 |
| 10-12 | Incident Response | 3 days | Iterations 5-9 |
| 13-15 | Emergency Mode & Polish | 2 days | Iterations 10-12 |
| 16 | Unit Tests | 1 day | All features |
| 17-18 | UI Tests | 2 days | All features |
| 19 | Accessibility Tests | 1 day | All features |
| 20 | Performance Tests | 1 day | All features |
| 21 | Code Signing | 1 day | Iterations 16-20 |
| 22 | Homebrew Update | 0.5 days | Iteration 21 |
| 23 | CI/CD Setup | 0.5 days | Iteration 22 |
| 24 | Documentation | 1 day | All iterations |
| 25 | Release Packaging | 1 day | All iterations |

**Total Estimated Duration**: 22 working days

---

## Success Criteria

### Per-Iteration Criteria

- [ ] All code compiles without warnings
- [ ] Unit tests pass (>80% coverage)
- [ ] UI tests pass for new features
- [ ] Accessibility audit passes
- [ ] Code review completed
- [ ] Documentation updated

### Final Release Criteria

- [ ] All 94 UI controls implemented
- [ ] All P0 gaps addressed
- [ ] Code signing and notarization complete
- [ ] Homebrew formula updated and tested
- [ ] All test suites pass
- [ ] Documentation complete
- [ ] Performance benchmarks met

---

**Document Maintainer**: Velociraptor Project Coordination Team  
**Iteration Tracking**: See GitHub Issues with `macos-iteration` label
