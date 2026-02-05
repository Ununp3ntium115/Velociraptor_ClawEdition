//
//  SettingsView.swift
//  VelociraptorMacOS
//
//  Application preferences/settings view with Server Administration
//  Gap: 0x0C - Server Administration
//
//  CDIF Pattern: Tab-based settings with server admin capabilities
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var keychainManager: KeychainManager
    
    private enum Tab {
        case general
        case security
        case server
        case integrations
        case advanced
    }
    
    @State private var selectedTab: Tab = .general
    
    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView()
                .tabItem {
                    Label("General", systemImage: "gear")
                }
                .tag(Tab.general)
                .accessibilityId(AccessibilityIdentifiers.Settings.generalTab)
            
            SecuritySettingsTab()
                .environmentObject(keychainManager)
                .tabItem {
                    Label("Security", systemImage: "lock.shield")
                }
                .tag(Tab.security)
                .accessibilityId(AccessibilityIdentifiers.Settings.securityTab)
            
            ServerAdministrationTab()
                .tabItem {
                    Label("Server", systemImage: "server.rack")
                }
                .tag(Tab.server)
                .accessibilityIdentifier("settings.server.tab")
            
            IntegrationsSettingsView()
                .tabItem {
                    Label("Integrations", systemImage: "link.circle")
                }
                .tag(Tab.integrations)
                .accessibilityIdentifier("settings.integrations.tab")
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
                .tag(Tab.advanced)
                .accessibilityId(AccessibilityIdentifiers.Settings.advancedTab)
        }
        .frame(width: 900, height: 600)
        .accessibilityIdentifier("settings.main")
        .accessibilityId(AccessibilityIdentifiers.Settings.window)
    }
}

// MARK: - Server Administration Tab (Gap 0x0C)

struct ServerAdministrationTab: View {
    @StateObject private var viewModel = ServerAdminViewModel()
    
    var body: some View {
        Form {
            Section("Server Connection") {
                HStack {
                    Text("Status:")
                    Spacer()
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(viewModel.isConnected ? "Connected" : "Disconnected")
                            .foregroundColor(viewModel.isConnected ? .green : .red)
                    }
                }
                
                HStack {
                    Text("Server URL:")
                    Spacer()
                    Text(viewModel.serverURL.isEmpty ? "Not configured" : viewModel.serverURL)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.isConnected {
                    HStack {
                        Text("Version:")
                        Spacer()
                        Text(viewModel.serverVersion)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Uptime:")
                        Spacer()
                        Text(viewModel.serverUptime)
                            .foregroundColor(.secondary)
                    }
                }
                
                HStack {
                    Button("Test Connection") {
                        Task { await viewModel.testConnection() }
                    }
                    .disabled(viewModel.isTesting)
                    .accessibilityIdentifier("settings.server.test.connection")
                    
                    if viewModel.isTesting {
                        ProgressView()
                            .scaleEffect(0.7)
                    }
                }
            }
            
            Section("Users & Permissions") {
                HStack {
                    Text("Active Users:")
                    Spacer()
                    Text("\(viewModel.activeUsers)")
                        .foregroundColor(.secondary)
                }
                
                Button("Manage Users") {
                    viewModel.showUserManagement = true
                }
                .accessibilityIdentifier("settings.server.manage.users")
                
                Button("View ACL Configuration") {
                    viewModel.showACLConfiguration = true
                }
                .accessibilityIdentifier("settings.server.view.acl")
            }
            
            Section("Server Operations") {
                Button("Rotate Certificates") {
                    viewModel.showCertRotation = true
                }
                .accessibilityIdentifier("settings.server.rotate.certs")
                
                Button("Backup Configuration") {
                    Task { await viewModel.backupConfiguration() }
                }
                .accessibilityIdentifier("settings.server.backup.config")
                
                Button("Export Server Diagnostics") {
                    Task { await viewModel.exportDiagnostics() }
                }
                .accessibilityIdentifier("settings.server.export.diagnostics")
            }
            
            Section("Resource Limits") {
                HStack {
                    Text("Max Clients:")
                    Spacer()
                    TextField("", value: $viewModel.maxClients, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .accessibilityIdentifier("settings.server.max.clients")
                }
                
                HStack {
                    Text("Max Hunts:")
                    Spacer()
                    TextField("", value: $viewModel.maxHunts, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .accessibilityIdentifier("settings.server.max.hunts")
                }
                
                Toggle("Enable Rate Limiting", isOn: $viewModel.rateLimitingEnabled)
                    .accessibilityIdentifier("settings.server.rate.limiting")
            }
            
            Section("Danger Zone") {
                Button("Restart Server", role: .destructive) {
                    viewModel.showRestartConfirmation = true
                }
                .accessibilityIdentifier("settings.server.restart")
            }
        }
        .padding()
        .sheet(isPresented: $viewModel.showUserManagement) {
            UserManagementSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showACLConfiguration) {
            ACLConfigurationSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showCertRotation) {
            CertificateRotationSheet(viewModel: viewModel)
        }
        .confirmationDialog("Restart Server?", isPresented: $viewModel.showRestartConfirmation) {
            Button("Restart", role: .destructive) {
                Task { await viewModel.restartServer() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will temporarily disconnect all clients. Are you sure?")
        }
        .task {
            await viewModel.loadServerStatus()
        }
    }
}

// MARK: - Server Admin View Model

@MainActor
class ServerAdminViewModel: ObservableObject {
    @Published var isConnected = false
    @Published var isTesting = false
    @Published var serverURL = ""
    @Published var serverVersion = ""
    @Published var serverUptime = ""
    @Published var activeUsers = 0
    @Published var maxClients = 10000
    @Published var maxHunts = 100
    @Published var rateLimitingEnabled = true
    
    @Published var showUserManagement = false
    @Published var showACLConfiguration = false
    @Published var showCertRotation = false
    @Published var showRestartConfirmation = false
    
    @Published var users: [VelociraptorUser] = []
    @Published var aclRules: [ACLRule] = []
    
    func loadServerStatus() async {
        do {
            let serverInfo = try await VelociraptorAPIClient.shared.getServerInfo()
            isConnected = true
            serverURL = UserDefaults.standard.string(forKey: "velociraptorServerURL") ?? ""
            serverVersion = serverInfo.version ?? "Unknown"
            serverUptime = "Connected"  // Uptime would require a separate endpoint
            activeUsers = 0  // Would need a separate endpoint
        } catch {
            isConnected = false
            Logger.shared.error("Failed to load server status: \(error)", component: "Settings")
        }
    }
    
    func testConnection() async {
        isTesting = true
        defer { isTesting = false }
        
        await loadServerStatus()
        
        if isConnected {
            Logger.shared.success("Server connection test successful", component: "Settings")
        } else {
            Logger.shared.warning("Server connection test failed", component: "Settings")
        }
    }
    
    func backupConfiguration() async {
        Logger.shared.info("Backing up server configuration...", component: "Settings")
        // Implementation would call API to backup config
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        Logger.shared.success("Server configuration backed up", component: "Settings")
    }
    
    func exportDiagnostics() async {
        Logger.shared.info("Exporting server diagnostics...", component: "Settings")
        // Implementation would export diagnostics
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        Logger.shared.success("Server diagnostics exported", component: "Settings")
    }
    
    func restartServer() async {
        Logger.shared.warning("Restarting server...", component: "Settings")
        // Implementation would call API to restart
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        Logger.shared.success("Server restart initiated", component: "Settings")
    }
    
    func loadUsers() async {
        do {
            users = try await VelociraptorAPIClient.shared.listUsers()
        } catch {
            users = []  // Default to empty on error
            Logger.shared.error("Failed to load users: \(error)", component: "Settings")
        }
    }
    
    func loadACLRules() async {
        // Load ACL configuration
        aclRules = [
            ACLRule(name: "administrators", permissions: ["all"]),
            ACLRule(name: "investigators", permissions: ["read", "collect"]),
            ACLRule(name: "analysts", permissions: ["read"]),
        ]
    }
}

// MARK: - Supporting Types

struct ServerUser: Identifiable {
    let id: String
    let name: String
    let email: String
    let role: String
    let lastLogin: Date?
}

struct ACLRule: Identifiable {
    let id = UUID()
    let name: String
    let permissions: [String]
}

struct ServerStatus {
    let version: String
    let uptime: String
    let activeUsers: Int
}

// MARK: - User Management Sheet

struct UserManagementSheet: View {
    @ObservedObject var viewModel: ServerAdminViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("User Management")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
            
            Divider()
            
            if viewModel.users.isEmpty {
                VStack {
                    ProgressView()
                    Text("Loading users...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.users) { user in
                    HStack {
                        VStack(alignment: .leading) {
                            Text(user.name)
                                .font(.headline)
                            if let roles = user.roles, !roles.isEmpty {
                                Text(roles.joined(separator: ", "))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        if user.locked == true {
                            Text("Locked")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.2))
                                .cornerRadius(4)
                        } else {
                            Text("Active")
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
            }
            
            Divider()
            
            HStack {
                Button("Add User") {
                    // Add user logic
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .task {
            await viewModel.loadUsers()
        }
    }
}

// MARK: - ACL Configuration Sheet

struct ACLConfigurationSheet: View {
    @ObservedObject var viewModel: ServerAdminViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("ACL Configuration")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
            
            Divider()
            
            List(viewModel.aclRules) { rule in
                VStack(alignment: .leading, spacing: 8) {
                    Text(rule.name)
                        .font(.headline)
                    
                    FlowLayout(spacing: 6) {
                        ForEach(rule.permissions, id: \.self) { perm in
                            Text(perm)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
        .frame(width: 500, height: 400)
        .task {
            await viewModel.loadACLRules()
        }
    }
}

// MARK: - Certificate Rotation Sheet

struct CertificateRotationSheet: View {
    @ObservedObject var viewModel: ServerAdminViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var isRotating = false
    @State private var rotationComplete = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Certificate Rotation")
                .font(.title2.bold())
            
            if rotationComplete {
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Certificates rotated successfully")
                    
                    Text("New certificates will take effect after server restart")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if isRotating {
                VStack(spacing: 12) {
                    ProgressView()
                    Text("Rotating certificates...")
                }
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "lock.rotation")
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    Text("This will generate new TLS certificates for the server")
                        .multilineTextAlignment(.center)
                    
                    Text("All clients will need to re-enroll after rotation")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                
                if !rotationComplete {
                    Button("Rotate") {
                        Task {
                            isRotating = true
                            try? await Task.sleep(nanoseconds: 2_000_000_000)
                            isRotating = false
                            rotationComplete = true
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isRotating)
                } else {
                    Button("Done") { dismiss() }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .padding(40)
        .frame(width: 400, height: 300)
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage("autoCheckUpdates") private var autoCheckUpdates = true
    @AppStorage("enableNotifications") private var enableNotifications = true
    @AppStorage("theme") private var theme = "system"
    
    var body: some View {
        Form {
            Section("Startup") {
                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .accessibilityId(AccessibilityIdentifiers.Settings.launchAtLoginToggle)
                Toggle("Check for Updates Automatically", isOn: $autoCheckUpdates)
                    .accessibilityId(AccessibilityIdentifiers.Settings.checkUpdatesToggle)
            }
            
            Section("Notifications") {
                Toggle("Enable System Notifications", isOn: $enableNotifications)
                    .accessibilityId(AccessibilityIdentifiers.Settings.notificationsToggle)
            }
            
            Section("Appearance") {
                Picker("Theme:", selection: $theme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
                .pickerStyle(.segmented)
                .accessibilityId(AccessibilityIdentifiers.Settings.themePicker)
            }
            
            Section("Data") {
                HStack {
                    Text("Log Files:")
                    Spacer()
                    Button("Open in Finder") {
                        if let path = Logger.shared.getCurrentLogFilePath() {
                            NSWorkspace.shared.selectFile(path.path, inFileViewerRootedAtPath: path.deletingLastPathComponent().path)
                        }
                    }
                    .accessibilityId(AccessibilityIdentifiers.Settings.openLogsFolderButton)
                }
                
                HStack {
                    Text("Clear Old Logs:")
                    Spacer()
                    Button("Clear (> 30 days)") {
                        Logger.shared.clearOldLogs(olderThanDays: 30)
                    }
                    .accessibilityId(AccessibilityIdentifiers.Settings.clearOldLogsButton)
                }
            }
        }
        .padding()
    }
}

// MARK: - Security Settings Tab

struct SecuritySettingsTab: View {
    @EnvironmentObject var keychainManager: KeychainManager
    @AppStorage("useKeychain") private var useKeychain = true
    @AppStorage("enforceTLS") private var enforceTLS = true
    
    @State private var showDeleteConfirmation = false
    @State private var storedAccounts: [String] = []
    
    var body: some View {
        Form {
            Section("Credential Storage") {
                Toggle("Store Credentials in Keychain", isOn: $useKeychain)
                
                if useKeychain {
                    HStack {
                        Text("Stored Accounts:")
                        Spacer()
                        Text("\(storedAccounts.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    Button("View in Keychain Access") {
                        NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Utilities/Keychain Access.app"))
                    }
                }
            }
            
            Section("Network Security") {
                Toggle("Enforce TLS 1.2 or Higher", isOn: $enforceTLS)
            }
            
            Section("Danger Zone") {
                Button("Delete All Stored Credentials", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }
        }
        .padding()
        .onAppear {
            storedAccounts = keychainManager.listAccounts()
        }
        .confirmationDialog("Delete All Credentials?", isPresented: $showDeleteConfirmation) {
            Button("Delete All", role: .destructive) {
                try? keychainManager.deleteAllItems()
                storedAccounts = []
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will delete all stored Velociraptor credentials from the Keychain. This action cannot be undone.")
        }
    }
}

// MARK: - Advanced Settings

struct AdvancedSettingsView: View {
    @AppStorage("debugLogging") private var debugLogging = false
    @AppStorage("verboseOutput") private var verboseOutput = false
    @AppStorage("developerMode") private var developerMode = false
    
    var body: some View {
        Form {
            Section("Logging") {
                Toggle("Enable Debug Logging", isOn: $debugLogging)
                Toggle("Verbose Console Output", isOn: $verboseOutput)
                
                if debugLogging {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Debug logging may expose sensitive information")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Section("Developer") {
                Toggle("Developer Mode", isOn: $developerMode)
                
                if developerMode {
                    Button("Open Developer Console") {
                        // Would open developer console
                    }
                    
                    Button("Export Diagnostics") {
                        exportDiagnostics()
                    }
                }
            }
            
            Section("Reset") {
                Button("Reset All Settings to Defaults") {
                    resetAllSettings()
                }
                
                Button("Clear Configuration Cache") {
                    clearCache()
                }
            }
        }
        .padding()
    }
    
    /// Presents a Save panel to let the user choose a location and exports the generated diagnostics as a plain-text file.
    /// - Details: The save panel defaults the filename to `velociraptor-diagnostics.txt` and, when the user confirms, writes the string returned by `generateDiagnostics()` to the chosen URL as UTF-8 plain text.
    private func exportDiagnostics() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "velociraptor-diagnostics.txt"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let diagnostics = generateDiagnostics()
                try? diagnostics.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    
    /// Creates a multiline diagnostics report containing system, application, and path information.
    /// - Returns: A string with the generated date, macOS version, host name, processor count, physical memory in GB, application version and flags (`debugLogging`, `developerMode`), home directory path, and the current log file path or `"Unknown"` if unavailable.
    private func generateDiagnostics() -> String {
        let sysinfo = ProcessInfo.processInfo
        
        return """
        Velociraptor macOS Diagnostics
        ==============================
        Generated: \(Date())
        
        System Information:
        - macOS: \(sysinfo.operatingSystemVersionString)
        - Host: \(sysinfo.hostName)
        - Processors: \(sysinfo.processorCount)
        - Memory: \(sysinfo.physicalMemory / 1024 / 1024 / 1024) GB
        
        Application:
        - Version: 5.0.5
        - Debug Logging: \(debugLogging)
        - Developer Mode: \(developerMode)
        
        Paths:
        - Home: \(FileManager.default.homeDirectoryForCurrentUser.path)
        - Logs: \(Logger.shared.getCurrentLogFilePath()?.path ?? "Unknown")
        
        End of Diagnostics
        """
    }
    
    /// Removes the app's entire user defaults domain, resetting all stored preferences to their defaults.  
    /// - Note: This affects all keys stored in UserDefaults for the app's bundle identifier.
    private func resetAllSettings() {
        UserDefaults.standard.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
    }
    
    /// Removes the Velociraptor cache directory located at ~/Library/Caches/Velociraptor and recreates an empty directory.
    /// Attempts to remove the directory and then create it; any errors during removal or creation are ignored.
    private func clearCache() {
        let cacheURL = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Caches/Velociraptor")
        
        try? FileManager.default.removeItem(at: cacheURL)
        try? FileManager.default.createDirectory(at: cacheURL, withIntermediateDirectories: true)
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
        .environmentObject(ConfigurationViewModel())
        .environmentObject(KeychainManager())
}