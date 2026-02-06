// MenuBarManager.swift
// Velociraptor Claw Edition - Menu Bar Status Item Manager
//
// Provides a persistent menu bar status item for monitoring
// Velociraptor status and quick actions

import SwiftUI
import AppKit

// MARK: - Menu Bar Status

/// Status states for the menu bar icon
enum MenuBarStatus: String, CaseIterable {
    case ready = "Ready"
    case connecting = "Connecting..."
    case connected = "Connected"
    case disconnected = "Disconnected"
    case collecting = "Collecting..."
    case processing = "Processing..."
    case emergency = "Emergency Mode"
    case error = "Error"
    
    /// SF Symbol name for status icon
    var iconName: String {
        switch self {
        case .ready: return "checkmark.circle.fill"
        case .connecting: return "arrow.triangle.2.circlepath"
        case .connected: return "link.circle.fill"
        case .disconnected: return "xmark.circle.fill"
        case .collecting: return "arrow.down.doc.fill"
        case .processing: return "gearshape.2.fill"
        case .emergency: return "exclamationmark.triangle.fill"
        case .error: return "exclamationmark.octagon.fill"
        }
    }
    
    /// Color for status indicator
    var color: NSColor {
        switch self {
        case .ready, .connected: return .systemGreen
        case .connecting, .processing: return .systemBlue
        case .disconnected: return .systemGray
        case .collecting: return .systemOrange
        case .emergency, .error: return .systemRed
        }
    }
    
    /// Whether status indicates activity
    var isActive: Bool {
        switch self {
        case .connecting, .collecting, .processing, .emergency:
            return true
        default:
            return false
        }
    }
}

// MARK: - Menu Bar Manager

/// Manages the system menu bar status item for Velociraptor Claw Edition
@MainActor
final class MenuBarManager: ObservableObject {
    
    // MARK: - Published Properties
    
    @Published var status: MenuBarStatus = .ready {
        didSet { updateIcon() }
    }
    
    @Published var statusMessage: String = "Ready"
    @Published var isEmergencyModeArmed: Bool = false
    @Published var connectedClients: Int = 0
    @Published var activeCollections: Int = 0
    
    // MARK: - Private Properties
    
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    
    // MARK: - Initialization
    
    init() {
        setupStatusItem()
    }
    
    deinit {
        Task { @MainActor in
            statusItem = nil
        }
    }
    
    // MARK: - Setup
    
    private func setupStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            updateIcon()
            button.action = #selector(statusItemClicked)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        setupMenu()
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Status header
        let statusHeader = NSMenuItem(title: "Velociraptor Claw Edition", action: nil, keyEquivalent: "")
        statusHeader.isEnabled = false
        menu.addItem(statusHeader)
        
        let statusDetail = NSMenuItem(title: "Status: \(status.rawValue)", action: nil, keyEquivalent: "")
        statusDetail.isEnabled = false
        menu.addItem(statusDetail)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quick actions
        let openApp = NSMenuItem(title: "Open Velociraptor Claw Edition", action: #selector(openMainWindow), keyEquivalent: "o")
        openApp.target = self
        menu.addItem(openApp)
        
        menu.addItem(NSMenuItem.separator())
        
        // DFIR Actions
        let collectItem = NSMenuItem(title: "Quick Collect Artifacts", action: #selector(quickCollect), keyEquivalent: "c")
        collectItem.target = self
        menu.addItem(collectItem)
        
        let vqlItem = NSMenuItem(title: "Run VQL Query", action: #selector(runVQL), keyEquivalent: "v")
        vqlItem.target = self
        menu.addItem(vqlItem)
        
        // Emergency Mode submenu
        let emergencySubmenu = NSMenu()
        let armEmergency = NSMenuItem(title: "Arm Emergency Mode", action: #selector(armEmergencyMode), keyEquivalent: "e")
        armEmergency.target = self
        emergencySubmenu.addItem(armEmergency)
        
        let emergencyStatus = NSMenuItem(title: "Emergency Status: Inactive", action: nil, keyEquivalent: "")
        emergencyStatus.isEnabled = false
        emergencySubmenu.addItem(emergencyStatus)
        
        let emergencyItem = NSMenuItem(title: "Emergency Mode", action: nil, keyEquivalent: "")
        emergencyItem.submenu = emergencySubmenu
        menu.addItem(emergencyItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Utility items
        let logsItem = NSMenuItem(title: "Show Logs", action: #selector(showLogs), keyEquivalent: "l")
        logsItem.target = self
        menu.addItem(logsItem)
        
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Velociraptor Claw Edition", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem?.menu = menu
    }
    
    // MARK: - Icon Updates
    
    private func updateIcon() {
        guard let button = statusItem?.button else { return }
        
        // Create icon with status color
        if let image = NSImage(systemSymbolName: status.iconName, accessibilityDescription: status.rawValue) {
            let config = NSImage.SymbolConfiguration(pointSize: 16, weight: .medium)
            let configuredImage = image.withSymbolConfiguration(config)
            
            // Apply tint color
            let tintedImage = configuredImage?.tinted(with: status.color)
            button.image = tintedImage ?? configuredImage
        } else {
            // Fallback to text
            button.title = "VC"
        }
        
        button.toolTip = "Velociraptor Claw Edition - \(status.rawValue)"
    }
    
    // MARK: - Actions
    
    @objc private func statusItemClicked() {
        // Show menu on click
    }
    
    @objc private func openMainWindow() {
        NSApp.activate(ignoringOtherApps: true)
        if let window = NSApp.windows.first(where: { $0.isVisible }) {
            window.makeKeyAndOrderFront(nil)
        } else {
            // Post notification to open main window
            NotificationCenter.default.post(name: .openMainWindow, object: nil)
        }
    }
    
    @objc private func quickCollect() {
        openMainWindow()
        NotificationCenter.default.post(name: .navigateToView, object: "incidentResponse")
    }
    
    @objc private func runVQL() {
        openMainWindow()
        NotificationCenter.default.post(name: .navigateToView, object: "terminal")
    }
    
    @objc private func armEmergencyMode() {
        openMainWindow()
        NotificationCenter.default.post(name: .armEmergencyMode, object: nil)
    }
    
    @objc private func showLogs() {
        openMainWindow()
        NotificationCenter.default.post(name: .navigateToView, object: "logs")
    }
    
    @objc private func openSettings() {
        openMainWindow()
        NotificationCenter.default.post(name: .openSettings, object: nil)
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    // MARK: - Public Methods
    
    /// Update status with optional message
    func updateStatus(_ newStatus: MenuBarStatus, message: String? = nil) {
        status = newStatus
        statusMessage = message ?? newStatus.rawValue
        refreshMenu()
    }
    
    /// Refresh the menu with current data
    func refreshMenu() {
        setupMenu()
    }
    
    /// Show notification in menu bar area
    func showNotification(_ message: String) {
        if let button = statusItem?.button {
            button.title = message
            
            // Reset after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.updateIcon()
            }
        }
    }
}

// MARK: - Notification Names
// Note: Notification names are defined in VelociraptorMacOSApp.swift

// MARK: - NSImage Extension

private extension NSImage {
    func tinted(with color: NSColor) -> NSImage {
        let image = self.copy() as! NSImage
        image.lockFocus()
        color.set()
        let imageRect = NSRect(origin: .zero, size: image.size)
        imageRect.fill(using: .sourceAtop)
        image.unlockFocus()
        return image
    }
}

// MARK: - Preview Helper

#if DEBUG
extension MenuBarManager {
    static var preview: MenuBarManager {
        let manager = MenuBarManager()
        manager.status = .ready
        manager.connectedClients = 5
        manager.activeCollections = 2
        return manager
    }
}
#endif
