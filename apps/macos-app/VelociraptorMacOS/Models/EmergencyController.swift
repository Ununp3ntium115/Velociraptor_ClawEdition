//
//  EmergencyController.swift
//  VelociraptorMacOS
//
//  Emergency Mode State Machine and Controller
//  Manages the forensic lockdown sequence with Liquid Glass UI
//
//  Based on EMERGENCY_BUTTON_CONCEPT.md
//

import SwiftUI
import Combine

// MARK: - Emergency Phase

/// State machine phases for Emergency Mode
enum EmergencyPhase: Equatable {
    case idle
    case armed(firstTapAt: Date)
    case confirming(countdownSeconds: Int)
    case backupPrompt
    case lockingDown
    case running
    case cancelled
    
    var displayTitle: String {
        switch self {
        case .idle: return "Emergency Mode"
        case .armed: return "Tap Again to Confirm"
        case .confirming(let seconds): return "Initiating in \(seconds)..."
        case .backupPrompt: return "Backup Recommended"
        case .lockingDown: return "Locking Down..."
        case .running: return "Forensic Mode Active"
        case .cancelled: return "Cancelled"
        }
    }
    
    var isHot: Bool {
        switch self {
        case .armed, .confirming, .lockingDown: return true
        default: return false
        }
    }
}

// MARK: - Emergency Config

/// Configuration for Emergency Mode behavior
struct EmergencyConfig {
    var armWindowSeconds: TimeInterval = 2.0
    var confirmCountdownSeconds: Int = 5
    var lockdownTimeoutSeconds: TimeInterval = 30.0
    var preserveNetworkPorts: [Int] = [8889, 443, 22] // Keep DFIR ports open
    var enablePortLockdown: Bool = true
    var enableBackupPrompt: Bool = true
    var mockMode: Bool = false // For UI testing
}

// MARK: - Emergency Controller

/// Main controller for Emergency Mode state machine
@MainActor
final class EmergencyController: ObservableObject {
    // MARK: - Published State
    
    @Published private(set) var phase: EmergencyPhase = .idle
    @Published private(set) var isAnimating: Bool = false
    @Published private(set) var pulseAnimation: Bool = false
    @Published private(set) var collectionProgress: Double = 0.0
    @Published private(set) var statusMessage: String = ""
    @Published private(set) var activePorts: [Int] = []
    @Published private(set) var blockedPortCount: Int = 0
    
    // MARK: - Configuration
    
    var config: EmergencyConfig
    
    // MARK: - Private Properties
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(config: EmergencyConfig = EmergencyConfig()) {
        self.config = config
        startPulseAnimation()
    }
    
    // Note: Timers are automatically invalidated when the controller is deallocated
    // due to weak references in timer closures
    
    // MARK: - Public Actions
    
    /// Handle tap on emergency button
    func handleTap() {
        switch phase {
        case .idle:
            arm()
        case .armed:
            startConfirmation()
        case .confirming:
            // Already confirming, ignore
            break
        case .backupPrompt:
            // Handled by backup prompt buttons
            break
        case .lockingDown, .running:
            // Cannot interrupt lockdown
            break
        case .cancelled:
            reset()
        }
    }
    
    /// Cancel the current phase
    func cancel() {
        withAnimation(.spring(response: 0.3)) {
            phase = .cancelled
        }
        
        // Reset after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.reset()
        }
    }
    
    /// Skip backup and proceed directly to lockdown
    func skipBackup() {
        startLockdown()
    }
    
    /// Perform backup then proceed to lockdown
    func performBackup() {
        statusMessage = "Creating backup..."
        
        Task {
            // Simulate backup (in production, call actual backup service)
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            statusMessage = "Backup complete"
            startLockdown()
        }
    }
    
    /// Reset to idle state
    func reset() {
        withAnimation(.spring(response: 0.3)) {
            phase = .idle
            collectionProgress = 0.0
            statusMessage = ""
        }
    }
    
    // MARK: - Private Methods
    
    private func arm() {
        withAnimation(.spring(response: 0.25, dampingFraction: 0.75)) {
            phase = .armed(firstTapAt: Date())
        }
        
        // Auto-reset after arm window expires
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(self?.config.armWindowSeconds ?? 2.0) * 1_000_000_000)
            if case .armed = self?.phase {
                self?.reset()
            }
        }
    }
    
    private func startConfirmation() {
        var countdown = config.confirmCountdownSeconds
        
        withAnimation(.spring(response: 0.3)) {
            phase = .confirming(countdownSeconds: countdown)
        }
        
        // Use Task-based countdown instead of Timer to avoid Sendable issues
        Task { @MainActor [weak self] in
            while countdown > 0 {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                countdown -= 1
                
                if countdown <= 0 {
                    self?.onConfirmationComplete()
                } else {
                    withAnimation(.linear(duration: 0.15)) {
                        self?.phase = .confirming(countdownSeconds: countdown)
                    }
                }
            }
        }
    }
    
    private func onConfirmationComplete() {
        if config.enableBackupPrompt {
            withAnimation(.spring(response: 0.3)) {
                phase = .backupPrompt
            }
        } else {
            startLockdown()
        }
    }
    
    private func startLockdown() {
        withAnimation(.easeInOut(duration: 0.35)) {
            phase = .lockingDown
        }
        
        statusMessage = "Initiating forensic lockdown..."
        
        Task {
            // Step 1: Identify active ports
            statusMessage = "Identifying active streaming ports..."
            activePorts = await identifyActivePorts()
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Step 2: Lock down ports (mocked in test mode)
            if config.enablePortLockdown {
                statusMessage = "Locking down non-essential ports..."
                blockedPortCount = await lockdownPorts()
                try? await Task.sleep(nanoseconds: 500_000_000)
            }
            
            // Step 3: Start forensic collection
            statusMessage = "Starting forensic collection..."
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Transition to running
            withAnimation(.spring(response: 0.3)) {
                phase = .running
            }
            
            // Simulate collection progress
            await simulateCollection()
        }
    }
    
    private func identifyActivePorts() async -> [Int] {
        // In production, use netstat or lsof to find active connections
        // For now, return configured preservation ports
        if config.mockMode {
            return config.preserveNetworkPorts
        }
        
        // Mock: Simulate port discovery
        return [8889, 443, 22, 53]
    }
    
    private func lockdownPorts() async -> Int {
        // In production, this would use PF (Packet Filter) or NetworkExtension
        // For safety, this is mocked
        if config.mockMode {
            return 142 // Mock: 142 ports blocked
        }
        
        // Mock port lockdown simulation
        return 142
    }
    
    private func simulateCollection() async {
        let steps = [
            "Collecting process information...",
            "Capturing memory artifacts...",
            "Analyzing network connections...",
            "Scanning for IOCs...",
            "Generating forensic report..."
        ]
        
        for (index, step) in steps.enumerated() {
            statusMessage = step
            
            // Animate progress
            for subStep in 0..<10 {
                collectionProgress = Double(index) / Double(steps.count) + Double(1) / Double(steps.count) * Double(subStep) / 10.0
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }
        
        collectionProgress = 1.0
        statusMessage = "Collection complete"
    }
    
    // MARK: - Animation Helpers
    
    private func startPulseAnimation() {
        Task { @MainActor [weak self] in
            while true {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard self?.phase == .idle else { continue }
                withAnimation(.easeInOut(duration: 0.75)) {
                    self?.pulseAnimation.toggle()
                }
            }
        }
    }
    
}

// MARK: - Port Lock Manager (Production Stub)

/// Manages port lockdown using macOS security frameworks
/// NOTE: Actual implementation requires root/admin privileges and entitlements
actor PortLockManager {
    
    enum LockdownMethod {
        case packetFilter  // PF - requires root
        case networkExtension  // NetworkExtension - App Store compatible
        case mock  // For testing
    }
    
    private var method: LockdownMethod = .mock
    private var preservedPorts: Set<Int> = []
    private var isLocked: Bool = false
    
    init(method: LockdownMethod = .mock) {
        self.method = method
    }
    
    /// Lock all ports except the specified ones
    func lockdown(preserving ports: [Int]) async throws -> Int {
        preservedPorts = Set(ports)
        
        switch method {
        case .packetFilter:
            return try await lockdownWithPF(preserving: ports)
        case .networkExtension:
            return try await lockdownWithNetworkExtension(preserving: ports)
        case .mock:
            return await mockLockdown(preserving: ports)
        }
    }
    
    /// Restore normal network access
    func unlock() async throws {
        isLocked = false
        // In production, flush PF rules or disable network filter
    }
    
    // MARK: - Private Implementation
    
    private func lockdownWithPF(preserving ports: [Int]) async throws -> Int {
        // Production implementation would:
        // 1. Generate PF rules to block all except preserved ports
        // 2. Load rules via `pfctl -f /etc/pf.conf`
        // 3. Enable PF via `pfctl -e`
        // Requires root privileges
        
        // Stub for now
        isLocked = true
        return 65535 - ports.count
    }
    
    private func lockdownWithNetworkExtension(preserving ports: [Int]) async throws -> Int {
        // Production implementation would:
        // 1. Use NEFilterProvider to filter traffic
        // 2. Allow only traffic on preserved ports
        // Requires com.apple.developer.networking.networkextension entitlement
        
        // Stub for now
        isLocked = true
        return 65535 - ports.count
    }
    
    private func mockLockdown(preserving ports: [Int]) async -> Int {
        // Simulate lockdown without actually blocking
        isLocked = true
        return 142 // Mock blocked port count
    }
}
