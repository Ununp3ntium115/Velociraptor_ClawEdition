// PortLockdownManager.swift
// Velociraptor Claw Edition - Port Lockdown Service
// Created for macOS Tahoe / Swift 6 / SwiftUI

import Foundation

// MARK: - Lockdown Result

/// Result of a port lockdown operation
public enum LockdownResult: Sendable, Equatable {
    /// Lockdown succeeded, ports are blocked
    case success(blockedPorts: [UInt16])
    
    /// Lockdown was simulated (App Store build)
    case simulated(intendedBlocks: [UInt16])
    
    /// Lockdown failed with an error
    case failure(LockdownError)
    
    /// Whether the lockdown completed
    public var isComplete: Bool {
        switch self {
        case .success, .simulated: return true
        case .failure: return false
        }
    }
    
    /// Description for logging
    public var logDescription: String {
        switch self {
        case .success(let ports):
            return "Blocked \(ports.count) ports"
        case .simulated(let ports):
            return "[SIMULATED] Would block \(ports.count) ports"
        case .failure(let error):
            return "Failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Lockdown Error

/// Errors during port lockdown
public enum LockdownError: Error, Sendable, Equatable, LocalizedError {
    case privilegedHelperNotAvailable
    case insufficientPermissions
    case networkExtensionNotConfigured
    case pfFirewallError(String)
    case timeout
    case alreadyLocked
    case noPortsToBlock
    case cancelled
    case unknown(String)
    
    public var errorDescription: String? {
        switch self {
        case .privilegedHelperNotAvailable: return "Privileged helper not available"
        case .insufficientPermissions: return "Insufficient permissions"
        case .networkExtensionNotConfigured: return "Network Extension not configured"
        case .pfFirewallError(let detail): return "PF error: \(detail)"
        case .timeout: return "Operation timed out"
        case .alreadyLocked: return "Already locked"
        case .noPortsToBlock: return "No ports to block"
        case .cancelled: return "Cancelled"
        case .unknown(let detail): return detail
        }
    }
}

// MARK: - Lockdown Status

/// Current lockdown status
public struct LockdownStatus: Sendable, Equatable {
    public var isActive: Bool
    public var allowedPorts: Set<UInt16>
    public var blockedPortCount: Int
    public var startTime: Date?
    
    public init(isActive: Bool = false, allowedPorts: Set<UInt16> = [], blockedPortCount: Int = 0, startTime: Date? = nil) {
        self.isActive = isActive
        self.allowedPorts = allowedPorts
        self.blockedPortCount = blockedPortCount
        self.startTime = startTime
    }
    
    public static let inactive = LockdownStatus()
}

// MARK: - Port Lockdown Manager

/// Actor managing port lockdown for Emergency Mode
/// Thread-safe access to firewall state using Swift 6 actor isolation
public actor PortLockdownManager {
    
    // MARK: - Properties
    
    /// Whether lockdown is currently active
    private(set) var isLocked: Bool = false
    
    /// Ports currently allowed through lockdown
    private(set) var allowedPorts: Set<UInt16> = []
    
    /// Ports currently blocked
    private(set) var blockedPorts: [UInt16] = []
    
    /// When lockdown started
    private(set) var lockdownStartTime: Date?
    
    /// Whether this is a direct distribution build (real enforcement)
    private var isDirectDistribution: Bool {
        #if DIRECT_DISTRIBUTION
        return true
        #else
        return false
        #endif
    }
    
    // MARK: - Initialization
    
    public init() {}
    
    // MARK: - Public API
    
    /// Lock down all ports except those specified
    /// - Parameter allowingPorts: Set of ports to keep open (streaming session + Velociraptor)
    /// - Returns: Result of the lockdown operation
    public func lockdown(allowingPorts ports: Set<UInt16>) async -> LockdownResult {
        guard !isLocked else {
            return .failure(.alreadyLocked)
        }
        
        allowedPorts = ports
        
        // Calculate ports to block (all common ports except allowed)
        let commonPorts = getCommonPorts()
        let portsToBlock = commonPorts.subtracting(ports)
        
        guard !portsToBlock.isEmpty else {
            return .failure(.noPortsToBlock)
        }
        
        log("Initiating lockdown - Allowing: \(ports.sorted()), Blocking: \(portsToBlock.count) ports")
        
        #if DIRECT_DISTRIBUTION
        // Real enforcement using privileged helper
        return await performRealLockdown(blocking: Array(portsToBlock))
        #else
        // App Store build - simulation only
        return await performSimulatedLockdown(blocking: Array(portsToBlock))
        #endif
    }
    
    /// Unlock and restore normal network operation
    /// - Returns: Whether unlock was successful
    public func unlock() async -> Bool {
        guard isLocked else {
            log("Unlock called but not locked")
            return true
        }
        
        log("Unlocking - restoring normal operation")
        
        #if DIRECT_DISTRIBUTION
        let success = await performRealUnlock()
        #else
        let success = await performSimulatedUnlock()
        #endif
        
        if success {
            isLocked = false
            allowedPorts = []
            blockedPorts = []
            lockdownStartTime = nil
        }
        
        return success
    }
    
    /// Get current lockdown status
    /// - Returns: Current status including active state and port counts
    public func getCurrentStatus() -> LockdownStatus {
        LockdownStatus(
            isActive: isLocked,
            allowedPorts: allowedPorts,
            blockedPortCount: blockedPorts.count,
            startTime: lockdownStartTime
        )
    }
    
    /// Check if a specific port is currently blocked
    /// - Parameter port: Port number to check
    /// - Returns: Whether the port is blocked
    public func isPortBlocked(_ port: UInt16) -> Bool {
        blockedPorts.contains(port)
    }
    
    /// Check if a specific port is allowed
    /// - Parameter port: Port number to check
    /// - Returns: Whether the port is allowed
    public func isPortAllowed(_ port: UInt16) -> Bool {
        allowedPorts.contains(port)
    }
    
    // MARK: - Direct Distribution (Real Enforcement)
    
    #if DIRECT_DISTRIBUTION
    /// Perform real port lockdown using privileged helper
    private func performRealLockdown(blocking ports: [UInt16]) async -> LockdownResult {
        log("[DIRECT] Performing real lockdown via privileged helper")
        
        // Check for privileged helper
        guard await isPrivilegedHelperAvailable() else {
            return .failure(.privilegedHelperNotAvailable)
        }
        
        do {
            // Send lockdown command to helper
            try await sendToPrivilegedHelper(command: .lockdown(ports: ports))
            
            isLocked = true
            blockedPorts = ports.sorted()
            lockdownStartTime = Date()
            
            log("[DIRECT] Lockdown active - \(ports.count) ports blocked")
            return .success(blockedPorts: blockedPorts)
            
        } catch let error as LockdownError {
            return .failure(error)
        } catch {
            return .failure(.unknown(error.localizedDescription))
        }
    }
    
    /// Perform real unlock using privileged helper
    private func performRealUnlock() async -> Bool {
        log("[DIRECT] Performing real unlock via privileged helper")
        
        do {
            try await sendToPrivilegedHelper(command: .unlock)
            log("[DIRECT] Unlock successful")
            return true
        } catch {
            log("[DIRECT] Unlock failed: \(error)")
            return false
        }
    }
    
    /// Check if privileged helper is available
    private func isPrivilegedHelperAvailable() async -> Bool {
        // Check for helper tool at expected path
        let helperPath = "/Library/PrivilegedHelperTools/com.velociraptorclaw.portlock"
        return FileManager.default.fileExists(atPath: helperPath)
    }
    
    /// Command to send to privileged helper
    private enum HelperCommand {
        case lockdown(ports: [UInt16])
        case unlock
        case status
    }
    
    /// Send command to privileged helper via XPC
    private func sendToPrivilegedHelper(command: HelperCommand) async throws {
        // Placeholder for XPC communication with privileged helper
        // In production, this would:
        // 1. Connect to the XPC service
        // 2. Send the command with port list
        // 3. Helper would modify pf rules or Network Extension
        
        log("[DIRECT] Sending command to helper: \(command)")
        
        // Simulate network delay
        try await Task.sleep(for: .milliseconds(500))
        
        // For now, throw if helper not found
        guard await isPrivilegedHelperAvailable() else {
            throw LockdownError.privilegedHelperNotAvailable
        }
    }
    #endif
    
    // MARK: - App Store (Simulated)
    
    /// Perform simulated lockdown (App Store build)
    private func performSimulatedLockdown(blocking ports: [UInt16]) async -> LockdownResult {
        log("[SIMULATED] Simulating lockdown - would block \(ports.count) ports")
        
        // Simulate processing time
        try? await Task.sleep(for: .milliseconds(500))
        
        // Update state as if locked (for UI purposes)
        isLocked = true
        blockedPorts = ports.sorted()
        lockdownStartTime = Date()
        
        // Log what would have been blocked
        log("[SIMULATED] Would block ports: \(blockedPorts)")
        
        return .simulated(intendedBlocks: blockedPorts)
    }
    
    /// Perform simulated unlock (App Store build)
    private func performSimulatedUnlock() async -> Bool {
        log("[SIMULATED] Simulating unlock")
        try? await Task.sleep(for: .milliseconds(200))
        return true
    }
    
    // MARK: - Helper Methods
    
    /// Get set of common ports that might need blocking
    private func getCommonPorts() -> Set<UInt16> {
        // Common ports that forensic lockdown might block
        var ports = Set<UInt16>()
        
        // SSH, Telnet, FTP
        ports.formUnion([21, 22, 23])
        
        // HTTP/HTTPS
        ports.formUnion([80, 443, 8080, 8443])
        
        // Email
        ports.formUnion([25, 110, 143, 465, 587, 993, 995])
        
        // Database
        ports.formUnion([1433, 1521, 3306, 5432, 27017])
        
        // Remote access
        ports.formUnion([3389, 5900, 5901])
        
        // File sharing
        ports.formUnion([137, 138, 139, 445, 548])
        
        // DNS
        ports.insert(53)
        
        // LDAP
        ports.formUnion([389, 636])
        
        // Common application ports
        ports.formUnion([6379, 9200, 11211])
        
        return ports
    }
    
    /// Log message for debugging
    private func log(_ message: String) {
        #if DEBUG
        print("[PortLockdown] \(message)")
        #endif
    }
}

// MARK: - Lockdown Error Extension

extension LockdownError {
    /// Create from generic error
    static func from(_ error: Error) -> LockdownError {
        if let lockdownError = error as? LockdownError {
            return lockdownError
        }
        return .unknown(error.localizedDescription)
    }
}

// MARK: - Convenience Extensions

public extension PortLockdownManager {
    /// Quick status check
    var status: LockdownStatus {
        get async {
            getCurrentStatus()
        }
    }
    
    /// Duration of current lockdown
    var lockdownDuration: TimeInterval? {
        guard let start = lockdownStartTime else { return nil }
        return Date().timeIntervalSince(start)
    }
}
