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
                .frame(minWidth: 900, minHeight: 700)
                .onAppear {
                    NSWindow.allowsAutomaticWindowTabbing = false
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified(showsTitle: true))
        .commands {
            // Custom menu commands
            CommandGroup(replacing: .appInfo) {
                Button("About Velociraptor") {
                    appState.showAbout = true
                }
            }
            
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
            
            CommandGroup(replacing: .help) {
                Button("Velociraptor Help") {
                    if let url = URL(string: "https://docs.velociraptor.app/") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .keyboardShortcut("?", modifiers: .command)
                
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
    /// Performs startup initialization when the application finishes launching.
    /// 
    /// Sets the app's appearance to Dark Aqua and records a startup log entry.
    /// - Parameter notification: The notification sent by NSApplication indicating launch completion.
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Configure application appearance
        NSApp.appearance = NSAppearance(named: .darkAqua)
        
        // Log startup
        SyncLogger.shared.info("Velociraptor macOS started", component: "App")
    }
    
    /// Perform final cleanup when the application is about to terminate.
    /// - Parameter notification: The termination notification sent by the application.
    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup on termination
        SyncLogger.shared.info("Velociraptor macOS shutting down", component: "App")
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