//
//  SettingsView.swift
//  VelociraptorMacOS
//
//  Application preferences/settings view
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var keychainManager: KeychainManager
    
    private enum Tab {
        case general
        case security
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
            
            AdvancedSettingsView()
                .tabItem {
                    Label("Advanced", systemImage: "gearshape.2")
                }
                .tag(Tab.advanced)
                .accessibilityId(AccessibilityIdentifiers.Settings.advancedTab)
        }
        .frame(width: 500, height: 400)
        .accessibilityId(AccessibilityIdentifiers.Settings.window)
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