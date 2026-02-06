//
//  VelociraptorMacOSApp.swift
//  VelociraptorMacOS
//
//  Velociraptor DFIR Framework - macOS Native Application
//  Version: 5.0.5
//  Free For All First Responders
//
//  Created by Velociraptor Project Team
//  Copyright © 2026 Velocidex. All rights reserved.
//

import SwiftUI

/// Main application entry point for Velociraptor macOS
/// Implements the configuration wizard, incident response collector,
/// and deployment management for macOS systems.
@main
struct VelociraptorMacOSApp: App {
    // MARK: - State Objects
    
    /// Global application state
    @StateObject private var appState = AppState()
    
    /// Configuration view model
    @StateObject private var configViewModel = ConfigurationViewModel()
    
    /// Deployment manager for installation operations
    @StateObject private var deploymentManager = DeploymentManager()
    
    /// Keychain manager for secure credential storage
    @StateObject private var keychainManager = KeychainManager()
    
    /// Incident response view model
    @StateObject private var incidentResponseViewModel = IncidentResponseViewModel()
    
    /// Velociraptor API client (singleton wrapped for environment)
    @StateObject private var apiClient = VelociraptorAPIClient.shared
    
    /// WebSocket service for real-time updates
    @StateObject private var webSocketService = WebSocketService.shared
    
    // MARK: - App Delegate
    
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    // MARK: - Body
    
    var body: some Scene {
        // Main Configuration Wizard Window
        WindowGroup("Velociraptor Configuration Wizard") {
            ContentView()
                .environmentObject(appState)
                .environmentObject(configViewModel)
                .environmentObject(deploymentManager)
                .environmentObject(keychainManager)
                .environmentObject(incidentResponseViewModel)
                .environmentObject(apiClient)
                .environmentObject(webSocketService)
                .environmentObject(AppDelegate.sharedEmergencyController)
                .frame(minWidth: 900, minHeight: 700)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            // MARK: - App Info Commands
            CommandGroup(replacing: .appInfo) {
                Button("About Velociraptor") {
                    appState.showAbout = true
                }
            }
            
            // MARK: - File Commands
            CommandGroup(replacing: .newItem) {
                Button("New Configuration") {
                    configViewModel.resetConfiguration()
                    appState.currentStep = .welcome
                }
                .keyboardShortcut("n", modifiers: .command)
            }
            
            CommandGroup(after: .newItem) {
                Button("Open Configuration...") {
                    appState.showOpenPanel = true
                }
                .keyboardShortcut("o", modifiers: .command)
                
                Button("Save Configuration") {
                    appState.showSavePanel = true
                }
                .keyboardShortcut("s", modifiers: .command)
                
                Divider()
                
                Button("Emergency Deployment") {
                    appState.showEmergencyMode = true
                }
                .keyboardShortcut("e", modifiers: [.command, .shift])
            }
            
            // MARK: - Navigation Commands (Cmd+1 through Cmd+0)
            CommandGroup(after: .sidebar) {
                Divider()
                
                Text("Navigate To")
                    .font(.caption)
                
                Button("Configuration Wizard") {
                    appState.selectedSidebarItem = .wizard
                }
                .keyboardShortcut("1", modifiers: .command)
                
                Button("Control Panel") {
                    appState.selectedSidebarItem = .dashboard
                }
                .keyboardShortcut("2", modifiers: .command)
                
                Button("Incident Response") {
                    appState.selectedSidebarItem = .incidentResponse
                }
                .keyboardShortcut("3", modifiers: .command)
                
                Button("Health Monitor") {
                    appState.selectedSidebarItem = .health
                }
                .keyboardShortcut("4", modifiers: .command)
                
                Button("Integrations") {
                    appState.selectedSidebarItem = .integrations
                }
                .keyboardShortcut("5", modifiers: .command)
                
                Button("Offline Packages") {
                    appState.selectedSidebarItem = .offlinePackages
                }
                .keyboardShortcut("6", modifiers: .command)
                
                Button("AI Assistant") {
                    appState.selectedSidebarItem = .aiChat
                }
                .keyboardShortcut("7", modifiers: .command)
                
                Button("Terminal") {
                    appState.selectedSidebarItem = .terminal
                }
                .keyboardShortcut("8", modifiers: .command)
                
                Button("Binary Manager") {
                    appState.selectedSidebarItem = .binaryLifecycle
                }
                .keyboardShortcut("9", modifiers: .command)
                
                Button("Logs") {
                    appState.selectedSidebarItem = .logs
                }
                .keyboardShortcut("0", modifiers: .command)
            }
            
            // MARK: - Quick Actions (Cmd+Shift)
            CommandMenu("Actions") {
                Button("Quick Incident Response") {
                    appState.selectedSidebarItem = .incidentResponse
                    appState.showEmergencyMode = true
                }
                .keyboardShortcut("i", modifiers: [.command, .shift])
                
                Button("Open AI Assistant") {
                    appState.selectedSidebarItem = .aiChat
                }
                .keyboardShortcut("a", modifiers: [.command, .shift])
                
                Button("Open Terminal") {
                    appState.selectedSidebarItem = .terminal
                }
                .keyboardShortcut("t", modifiers: [.command, .shift])
                
                Button("View Logs") {
                    appState.selectedSidebarItem = .logs
                }
                .keyboardShortcut("l", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Refresh") {
                    NotificationCenter.default.post(name: .refreshCurrentView, object: nil)
                }
                .keyboardShortcut("r", modifiers: .command)
                
                Divider()
                
                Button("Check System Health") {
                    appState.selectedSidebarItem = .health
                }
                .keyboardShortcut("h", modifiers: [.command, .shift])
                
                Button("Manage Binaries") {
                    appState.selectedSidebarItem = .binaryLifecycle
                }
                .keyboardShortcut("b", modifiers: [.command, .shift])
            }
            
            // MARK: - Wizard Navigation
            CommandMenu("Wizard") {
                Button("Next Step") {
                    appState.nextStep()
                }
                .keyboardShortcut(.rightArrow, modifiers: [.command, .option])
                .disabled(!appState.canGoNext)
                
                Button("Previous Step") {
                    appState.previousStep()
                }
                .keyboardShortcut(.leftArrow, modifiers: [.command, .option])
                .disabled(!appState.canGoBack)
                
                Divider()
                
                Button("Reset Wizard") {
                    appState.resetWizard()
                }
                .keyboardShortcut("r", modifiers: [.command, .shift])
                
                Divider()
                
                Button("Go to Welcome") {
                    appState.goToStep(.welcome)
                }
                
                Button("Go to Review") {
                    appState.goToStep(.review)
                }
            }
            
            // MARK: - Window Commands
            CommandGroup(before: .windowSize) {
                Button("Close Dialog") {
                    appState.showError = false
                    appState.showAbout = false
                    appState.showOpenPanel = false
                    appState.showSavePanel = false
                    appState.showEmergencyMode = false
                    appState.showPreferences = false
                }
                .keyboardShortcut(.escape, modifiers: [])
            }
            
            // MARK: - Help Commands
            CommandGroup(replacing: .help) {
                Button("Velociraptor Help") {
                    if let url = URL(string: "https://docs.velociraptor.app/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("?", modifiers: .command)
                
                Button("Keyboard Shortcuts") {
                    if let url = URL(string: "https://docs.velociraptor.app/docs/gui/keyboard/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("/", modifiers: .command)
                
                Divider()
                
                Button("Troubleshooting Guide") {
                    if let url = URL(string: "https://docs.velociraptor.app/docs/deployment/troubleshooting/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
                Button("Report an Issue") {
                    if let url = URL(string: "https://github.com/Velocidex/velociraptor/issues") {
                        NSWorkspace.shared.open(url)
                    }
                }
            }
        }
        
        // Incident Response Window
        Window("Incident Response Collector", id: "incident-response") {
            IncidentResponseView()
                .environmentObject(appState)
                .environmentObject(incidentResponseViewModel)
                .environmentObject(deploymentManager)
                .frame(minWidth: 1000, minHeight: 700)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        
        // Artifact Manager Window
        Window("Artifact Manager", id: "artifact-manager") {
            ArtifactManagerView()
                .frame(minWidth: 1200, minHeight: 800)
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .defaultSize(width: 1400, height: 900)
        
        // Settings Window
        Settings {
            SettingsView()
                .environmentObject(appState)
                .environmentObject(configViewModel)
                .environmentObject(keychainManager)
        }
    }
}

// MARK: - App Delegate

/// Application delegate for handling macOS-specific lifecycle events
class AppDelegate: NSObject, NSApplicationDelegate {
    /// Shared EmergencyController for Touch Bar integration
    @MainActor
    static var sharedEmergencyController: EmergencyController = {
        // Use mock mode when not connected to a real Velociraptor server
        var config = EmergencyConfig()
        config.mockMode = true // Safe for development
        return EmergencyController(config: config)
    }()
    
    /// Performs startup initialization when the application finishes launching.
    /// 
    /// Sets the app's appearance to Dark Aqua and records a startup log entry.
    /// - Parameter notification: The notification sent by NSApplication indicating launch completion.
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure application appearance
        NSApp.appearance = NSAppearance(named: .darkAqua)
        
        // Log startup
        Logger.shared.info("Velociraptor macOS started", component: "App")
        
        // Configure Touch Bar with Emergency button
        Task { @MainActor in
            configureTouchBar()
            Logger.shared.info("Touch Bar configured with Emergency button", component: "App")
        }
        
        // Position window on specific monitor for UI testing
        if ProcessInfo.processInfo.arguments.contains("-UITestMode") ||
           ProcessInfo.processInfo.environment["UI_TEST_MODE"] == "1" {
            positionWindowOnTestMonitor()
        }
    }
    
    /// Provides the application-level Touch Bar
    @MainActor
    func applicationTouchBar() -> NSTouchBar? {
        return EmergencyTouchBarProvider.shared.makeTouchBar()
    }
    
    /// Positions the main window on the 3rd monitor (index 2) for UI testing
    /// This is typically a portrait monitor at 90 degrees
    private func positionWindowOnTestMonitor() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let mainWindow = NSApp.windows.first(where: { $0.isVisible }) else {
                Logger.shared.warning("No visible window to position for UI testing", component: "App")
                return
            }
            
            let screens = NSScreen.screens
            
            // Log available screens for debugging
            for (index, screen) in screens.enumerated() {
                let frame = screen.frame
                let isPortrait = frame.height > frame.width
                Logger.shared.info("Screen \(index): \(Int(frame.width))x\(Int(frame.height)) at (\(Int(frame.origin.x)), \(Int(frame.origin.y))) - \(isPortrait ? "Portrait" : "Landscape")", component: "App")
            }
            
            // Try to find the 3rd monitor (index 2) or a portrait monitor
            var targetScreen: NSScreen?
            
            // First priority: 3rd monitor if it exists
            if screens.count >= 3 {
                targetScreen = screens[2]
                Logger.shared.info("Using 3rd monitor for UI testing", component: "App")
            } else {
                // Fallback: find a portrait-oriented monitor
                targetScreen = screens.first(where: { $0.frame.height > $0.frame.width })
                if targetScreen != nil {
                    Logger.shared.info("Using portrait monitor for UI testing", component: "App")
                }
            }
            
            if let screen = targetScreen {
                // Center the window on the target screen
                let screenFrame = screen.visibleFrame
                let windowSize = mainWindow.frame.size
                let newOrigin = NSPoint(
                    x: screenFrame.origin.x + (screenFrame.width - windowSize.width) / 2,
                    y: screenFrame.origin.y + (screenFrame.height - windowSize.height) / 2
                )
                mainWindow.setFrameOrigin(newOrigin)
                mainWindow.makeKeyAndOrderFront(nil)
                Logger.shared.info("Window positioned at (\(Int(newOrigin.x)), \(Int(newOrigin.y))) on test monitor", component: "App")
            } else {
                Logger.shared.warning("Could not find 3rd or portrait monitor, using default position", component: "App")
            }
        }
    }
    
    // MARK: - Dock Menu
    
    /// Provides the Dock menu when right-clicking the app icon in the Dock
    func applicationDockMenu(_ sender: NSApplication) -> NSMenu? {
        let menu = NSMenu()
        
        // Quick Collect Artifacts
        let collectItem = NSMenuItem(title: "Quick Collect Artifacts", action: #selector(dockMenuQuickCollect), keyEquivalent: "")
        collectItem.target = self
        menu.addItem(collectItem)
        
        // Run VQL Query
        let vqlItem = NSMenuItem(title: "Run VQL Query", action: #selector(dockMenuRunVQL), keyEquivalent: "")
        vqlItem.target = self
        menu.addItem(vqlItem)
        
        // View Logs
        let logsItem = NSMenuItem(title: "View Logs", action: #selector(dockMenuViewLogs), keyEquivalent: "")
        logsItem.target = self
        menu.addItem(logsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Emergency Mode submenu
        let emergencySubmenu = NSMenu()
        let armEmergency = NSMenuItem(title: "Arm Emergency Mode", action: #selector(dockMenuArmEmergency), keyEquivalent: "")
        armEmergency.target = self
        emergencySubmenu.addItem(armEmergency)
        
        let emergencyItem = NSMenuItem(title: "Emergency Mode", action: nil, keyEquivalent: "")
        emergencyItem.submenu = emergencySubmenu
        menu.addItem(emergencyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Open Configuration Wizard
        let wizardItem = NSMenuItem(title: "Open Configuration Wizard", action: #selector(dockMenuOpenWizard), keyEquivalent: "")
        wizardItem.target = self
        menu.addItem(wizardItem)
        
        // AI Assistant
        let aiItem = NSMenuItem(title: "AI Assistant", action: #selector(dockMenuOpenAI), keyEquivalent: "")
        aiItem.target = self
        menu.addItem(aiItem)
        
        return menu
    }
    
    // MARK: - Dock Menu Actions
    
    @objc func dockMenuQuickCollect() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .navigateToView, object: "incidentResponse")
    }
    
    @objc func dockMenuRunVQL() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .navigateToView, object: "terminal")
    }
    
    @objc func dockMenuViewLogs() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .navigateToView, object: "logs")
    }
    
    @objc func dockMenuArmEmergency() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .armEmergencyMode, object: nil)
    }
    
    @objc func dockMenuOpenWizard() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .navigateToView, object: "wizard")
    }
    
    @objc func dockMenuOpenAI() {
        NSApp.activate(ignoringOtherApps: true)
        NotificationCenter.default.post(name: .navigateToView, object: "aiChat")
    }
    
    /// Perform final cleanup when the application is about to terminate.
    /// - Parameter notification: The termination notification sent by the application.
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup on termination
        Logger.shared.info("Velociraptor macOS shutting down", component: "App")
    }
    
    /// Allow the app to terminate when the last open window is closed.
    /// - Returns: `true` to terminate the app after the last window closes, `false` otherwise.
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
    
    /// Indicates that the application supports secure state restoration.
    /// - Returns: `true` to indicate the application supports secure restorable state.
    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}

// MARK: - Notification Names for Keyboard Shortcuts

extension Notification.Name {
    /// Posted when the user triggers Cmd+R to refresh the current view
    static let refreshCurrentView = Notification.Name("refreshCurrentView")
    
    /// Posted to navigate to a specific view
    static let navigateToView = Notification.Name("navigateToView")
    
    /// Posted to arm Emergency Mode
    static let armEmergencyMode = Notification.Name("armEmergencyMode")
    
    /// Posted to open the main window
    static let openMainWindow = Notification.Name("openMainWindow")
    
    /// Posted to open settings
    static let openSettings = Notification.Name("openSettings")
}