//
//  UpdateService.swift
//  VelociraptorMacOS
//
//  Handles automatic updates using Sparkle framework.
//  https://sparkle-project.org/
//
//  BUILD NOTE: Sparkle is conditionally imported. If not available,
//  stub implementations are used.
//

import Foundation
import SwiftUI

#if canImport(Sparkle)
import Sparkle
private let sparkleAvailable = true
#else
private let sparkleAvailable = false
#endif

// MARK: - Update Service

/// Service for managing application updates using Sparkle
@MainActor
public final class UpdateService: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared instance
    public static let shared = UpdateService()
    
    // MARK: - Published Properties
    
    /// Whether update checking is in progress
    @Published public private(set) var isChecking: Bool = false
    
    /// Whether an update is available
    @Published public private(set) var updateAvailable: Bool = false
    
    /// Current app version
    @Published public private(set) var currentVersion: String = ""
    
    /// Latest available version (if update available)
    @Published public private(set) var latestVersion: String?
    
    /// Last error message
    @Published public private(set) var lastError: String?
    
    /// Whether Sparkle is available
    public var isSparkleAvailable: Bool {
        sparkleAvailable
    }
    
    // MARK: - Private Properties
    
    #if canImport(Sparkle)
    private var updaterController: SPUStandardUpdaterController?
    #endif
    
    // MARK: - Configuration
    
    /// Appcast URL for update feed
    public static let appcastURL = URL(string: "https://raw.githubusercontent.com/Velocidex/velociraptor-gui/main/appcast.xml")
    
    // MARK: - Initialization
    
    private init() {
        // Get current version from bundle
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            currentVersion = version
        } else {
            currentVersion = "5.0.5" // Fallback
        }
        
        #if canImport(Sparkle)
        setupSparkle()
        #endif
        
        SyncLogger.shared.info("UpdateService initialized. Version: \(currentVersion), Sparkle: \(sparkleAvailable)", component: "Update")
    }
    
    // MARK: - Setup
    
    #if canImport(Sparkle)
    private func setupSparkle() {
        // Create updater controller with standard user interface
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
        
        SyncLogger.shared.info("Sparkle updater initialized", component: "Update")
    }
    #endif
    
    // MARK: - Public Methods
    
    /// Check for updates manually
    public func checkForUpdates() {
        guard !isChecking else { return }
        
        isChecking = true
        lastError = nil
        
        SyncLogger.shared.info("Checking for updates...", component: "Update")
        
        #if canImport(Sparkle)
        updaterController?.checkForUpdates(nil)
        
        // Reset checking state after a delay (Sparkle handles UI)
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            isChecking = false
        }
        #else
        // Stub implementation - simulate check
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            isChecking = false
            lastError = "Sparkle not available. Build with Sparkle framework to enable updates."
            SyncLogger.shared.warning("Update check skipped - Sparkle not available", component: "Update")
        }
        #endif
    }
    
    /// Enable/disable automatic update checks
    /// - Parameter enabled: Whether to automatically check for updates
    public func setAutomaticChecks(enabled: Bool) {
        #if canImport(Sparkle)
        updaterController?.updater.automaticallyChecksForUpdates = enabled
        SyncLogger.shared.info("Automatic updates: \(enabled)", component: "Update")
        #else
        SyncLogger.shared.warning("Cannot set automatic checks - Sparkle not available", component: "Update")
        #endif
    }
    
    /// Get whether automatic checks are enabled
    public var automaticChecksEnabled: Bool {
        #if canImport(Sparkle)
        return updaterController?.updater.automaticallyChecksForUpdates ?? false
        #else
        return false
        #endif
    }
    
    /// Get last update check date
    public var lastCheckDate: Date? {
        #if canImport(Sparkle)
        return updaterController?.updater.lastUpdateCheckDate
        #else
        return nil
        #endif
    }
}

// MARK: - SwiftUI View for Update Button

/// A button that checks for updates using Sparkle
public struct CheckForUpdatesButton: View {
    @ObservedObject private var updateService = UpdateService.shared
    
    public init() {}
    
    public var body: some View {
        Button(action: {
            updateService.checkForUpdates()
        }) {
            if updateService.isChecking {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text("Checking...")
                }
            } else {
                Label("Check for Updates", systemImage: "arrow.triangle.2.circlepath")
            }
        }
        .disabled(updateService.isChecking)
        .accessibilityIdentifier("settings.button.checkForUpdates")
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        CheckForUpdatesButton()
        
        Text("Version: \(UpdateService.shared.currentVersion)")
            .font(.caption)
            .foregroundColor(.secondary)
        
        if !UpdateService.shared.isSparkleAvailable {
            Text("Sparkle not available")
                .font(.caption)
                .foregroundColor(.orange)
        }
    }
    .padding()
}
