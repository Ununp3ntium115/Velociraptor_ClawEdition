//
//  Logger.swift
//  VelociraptorMacOS
//
//  Unified logging utility with os_log integration
//  Refactored to use Swift 6 actor pattern for thread-safe concurrency
//

import Foundation
import os.log

// MARK: - Log Level Enum (remains outside actor for accessibility)

/// Log severity levels with corresponding emoji and os_log types
enum LogLevel: Int, Comparable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3
    case critical = 4
    
    static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
    
    var emoji: String {
        switch self {
        case .debug: return "🔍"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        case .critical: return "🚨"
        }
    }
    
    var name: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        case .critical: return "CRITICAL"
        }
    }
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .critical: return .fault
        }
    }
}

// MARK: - Logger Actor

/// Unified logging utility for Velociraptor macOS
/// Uses Swift actor for thread-safe concurrent access
actor Logger {
    // MARK: - Shared Instance
    
    /// Shared logger instance
    static let shared = Logger()
    
    // MARK: - Properties
    
    private let subsystem = "com.velocidex.velociraptor"
    private var loggers: [String: os.Logger] = [:]
    
    /// File handle for writing to log file
    private var fileHandle: FileHandle?
    
    /// Path to log file
    private var logFilePath: URL?
    
    /// Minimum log level to output
    var minimumLogLevel: LogLevel = .info
    
    /// Whether to write logs to file
    var writeToFile: Bool = true
    
    /// Whether to include timestamps
    var includeTimestamp: Bool = true
    
    // MARK: - Initialization
    
    init() {
        setupFileLogging()
    }
    
    deinit {
        try? fileHandle?.close()
    }
    
    // MARK: - Setup
    
    /// Prepares file-based logging by ensuring the Velociraptor log directory exists
    private func setupFileLogging() {
        let logDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Velociraptor")
        
        do {
            try FileManager.default.createDirectory(
                at: logDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            
            logFilePath = logDirectory.appendingPathComponent("velociraptor-\(dateString).log")
            
            if let path = logFilePath, !FileManager.default.fileExists(atPath: path.path) {
                FileManager.default.createFile(atPath: path.path, contents: nil)
            }
            
            if let path = logFilePath {
                fileHandle = try FileHandle(forWritingTo: path)
                fileHandle?.seekToEndOfFile()
            }
            
        } catch {
            print("Failed to setup file logging: \(error)")
        }
    }
    
    // MARK: - Logger Cache
    
    /// Retrieve or create a per-component os.Logger, caching it for reuse
    private func logger(for component: String) -> os.Logger {
        if let existing = loggers[component] {
            return existing
        }
        let newLogger = os.Logger(subsystem: subsystem, category: component)
        loggers[component] = newLogger
        return newLogger
    }
    
    // MARK: - Logging Methods
    
    /// Logs a message at the debug level
    func debug(_ message: String, component: String = "App") {
        log(message, level: .debug, component: component)
    }
    
    /// Logs an informational message
    func info(_ message: String, component: String = "App") {
        log(message, level: .info, component: component)
    }
    
    /// Logs a success message at the info level
    func success(_ message: String, component: String = "App") {
        log("✅ \(message)", level: .info, component: component)
    }
    
    /// Logs a message at the warning level
    func warning(_ message: String, component: String = "App") {
        log(message, level: .warning, component: component)
    }
    
    /// Logs the given text as an error-level entry
    func error(_ message: String, component: String = "App") {
        log(message, level: .error, component: component)
    }
    
    /// Logs the provided error's localized description
    func error(_ error: Error, component: String = "App") {
        log(error.localizedDescription, level: .error, component: component)
    }
    
    /// Logs a message with the critical severity level
    func critical(_ message: String, component: String = "App") {
        log(message, level: .critical, component: component)
    }
    
    // MARK: - Core Logging
    
    /// Core logging function that handles all log entries
    private func log(_ message: String, level: LogLevel, component: String) {
        guard level >= minimumLogLevel else { return }
        
        // Format timestamp
        let timestamp: String
        if includeTimestamp {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
            timestamp = formatter.string(from: Date())
        } else {
            timestamp = ""
        }
        
        // Format log entry
        let logEntry = includeTimestamp
            ? "[\(timestamp)] [\(level.name)] [\(component)] \(message)"
            : "[\(level.name)] [\(component)] \(message)"
        
        // Log to os_log
        let osLogger = logger(for: component)
        osLogger.log(level: level.osLogType, "\(logEntry)")
        
        // Log to file (actor ensures thread safety)
        if writeToFile, let fileHandle = fileHandle {
            if let data = "\(logEntry)\n".data(using: .utf8) {
                fileHandle.write(data)
            }
        }
        
        // Also print to console in debug builds
        #if DEBUG
        print("\(level.emoji) \(logEntry)")
        #endif
    }
    
    // MARK: - Log File Management
    
    /// Retrieve the URL of the currently active log file
    func getCurrentLogFilePath() -> URL? {
        return logFilePath
    }
    
    /// Returns the log files created by Velociraptor, ordered from newest to oldest
    func getAllLogFiles() -> [URL] {
        let logDirectory = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Velociraptor")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(
                at: logDirectory,
                includingPropertiesForKeys: [.creationDateKey],
                options: [.skipsHiddenFiles]
            )
            return files.filter { $0.pathExtension == "log" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                    return date1 > date2
                }
        } catch {
            return []
        }
    }
    
    /// Load the contents of the active log file as a UTF-8 string
    func readCurrentLog() -> String? {
        guard let path = logFilePath else { return nil }
        return try? String(contentsOf: path, encoding: .utf8)
    }
    
    /// Removes log files older than the specified number of days
    func clearOldLogs(olderThanDays days: Int = 30) async {
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        
        for logFile in getAllLogFiles() {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: logFile.path)
                if let creationDate = attributes[.creationDate] as? Date,
                   creationDate < cutoffDate {
                    try FileManager.default.removeItem(at: logFile)
                    info("Removed old log file: \(logFile.lastPathComponent)", component: "Logger")
                }
            } catch {
                warning("Failed to process log file: \(error)", component: "Logger")
            }
        }
    }
    
    /// Forces any buffered log data to be synchronized to storage
    func flush() {
        try? fileHandle?.synchronize()
    }
}

// MARK: - Convenience Extension for Non-Async Contexts

extension Logger {
    /// Non-isolated wrapper for quick logging from any context
    nonisolated func logSync(_ message: String, level: LogLevel = .info, component: String = "App") {
        Task {
            await self.log(message, level: level, component: component)
        }
    }
}

// MARK: - Backward Compatibility Wrapper

/// Synchronous logger wrapper for backward compatibility
/// Wraps actor calls in Tasks for non-async contexts
final class SyncLogger: @unchecked Sendable {
    static let shared = SyncLogger()
    
    private let actor = Logger.shared
    
    private init() {}
    
    /// Minimum log level - updates actor asynchronously
    var minimumLogLevel: LogLevel {
        get { LogLevel.info } // Default, actual value is in actor
        set { Task { await actor.setMinimumLogLevel(newValue) } }
    }
    
    /// Whether to write logs to file
    var writeToFile: Bool {
        get { true }
        set { Task { await actor.setWriteToFile(newValue) } }
    }
    
    /// Whether to include timestamps
    var includeTimestamp: Bool {
        get { true }
        set { Task { await actor.setIncludeTimestamp(newValue) } }
    }
    
    func debug(_ message: String, component: String = "App") {
        Task { await actor.debug(message, component: component) }
    }
    
    func info(_ message: String, component: String = "App") {
        Task { await actor.info(message, component: component) }
    }
    
    func success(_ message: String, component: String = "App") {
        Task { await actor.success(message, component: component) }
    }
    
    func warning(_ message: String, component: String = "App") {
        Task { await actor.warning(message, component: component) }
    }
    
    func error(_ message: String, component: String = "App") {
        Task { await actor.error(message, component: component) }
    }
    
    func error(_ error: Error, component: String = "App") {
        Task { await actor.error(error, component: component) }
    }
    
    func critical(_ message: String, component: String = "App") {
        Task { await actor.critical(message, component: component) }
    }
    
    func getCurrentLogFilePath() async -> URL? {
        await actor.getCurrentLogFilePath()
    }
    
    func getAllLogFiles() async -> [URL] {
        await actor.getAllLogFiles()
    }
    
    func readCurrentLog() async -> String? {
        await actor.readCurrentLog()
    }
    
    func clearOldLogs(olderThanDays days: Int = 30) {
        Task { await actor.clearOldLogs(olderThanDays: days) }
    }
    
    func flush() {
        Task { await actor.flush() }
    }
}

// MARK: - Actor Property Setters

extension Logger {
    func setMinimumLogLevel(_ level: LogLevel) {
        minimumLogLevel = level
    }
    
    func setWriteToFile(_ enabled: Bool) {
        writeToFile = enabled
    }
    
    func setIncludeTimestamp(_ enabled: Bool) {
        includeTimestamp = enabled
    }
}
