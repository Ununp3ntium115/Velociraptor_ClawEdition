//
//  Logger.swift
//  VelociraptorMacOS
//
//  Unified logging utility with os_log integration
//

import Foundation
import os.log

/// Unified logging utility for Velociraptor macOS
/// Integrates with Apple's unified logging system (os_log)
final class Logger {
    // MARK: - Singleton
    
    static let shared = Logger()
    
    // MARK: - Properties
    
    private let subsystem = "com.velocidex.velociraptor"
    private var loggers: [String: os.Logger] = [:]
    private let queue = DispatchQueue(label: "com.velocidex.velociraptor.logger")
    
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
    
    // MARK: - Log Level
    
    enum LogLevel: Int, Comparable {
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
    
    // MARK: - Initialization
    
    private init() {
        setupFileLogging()
    }
    
    deinit {
        try? fileHandle?.close()
    }
    
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
            
            if !FileManager.default.fileExists(atPath: logFilePath!.path) {
                FileManager.default.createFile(atPath: logFilePath!.path, contents: nil)
            }
            
            fileHandle = try FileHandle(forWritingTo: logFilePath!)
            fileHandle?.seekToEndOfFile()
            
        } catch {
            print("Failed to setup file logging: \(error)")
        }
    }
    
    // MARK: - Logger Access
    
    private func logger(for component: String) -> os.Logger {
        queue.sync {
            if let existing = loggers[component] {
                return existing
            }
            let newLogger = os.Logger(subsystem: subsystem, category: component)
            loggers[component] = newLogger
            return newLogger
        }
    }
    
    // MARK: - Logging Methods
    
    /// Log debug message
    func debug(_ message: String, component: String = "App") {
        log(message, level: .debug, component: component)
    }
    
    /// Log info message
    func info(_ message: String, component: String = "App") {
        log(message, level: .info, component: component)
    }
    
    /// Log success message (info level with success indicator)
    func success(_ message: String, component: String = "App") {
        log("✅ \(message)", level: .info, component: component)
    }
    
    /// Log warning message
    func warning(_ message: String, component: String = "App") {
        log(message, level: .warning, component: component)
    }
    
    /// Log error message
    func error(_ message: String, component: String = "App") {
        log(message, level: .error, component: component)
    }
    
    /// Log error with Error object
    func error(_ error: Error, component: String = "App") {
        log(error.localizedDescription, level: .error, component: component)
    }
    
    /// Log critical message
    func critical(_ message: String, component: String = "App") {
        log(message, level: .critical, component: component)
    }
    
    // MARK: - Core Logging
    
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
        
        // Log to file
        if writeToFile, let fileHandle = fileHandle {
            queue.async {
                if let data = "\(logEntry)\n".data(using: .utf8) {
                    fileHandle.write(data)
                }
            }
        }
        
        // Also print to console in debug builds
        #if DEBUG
        print("\(level.emoji) \(logEntry)")
        #endif
    }
    
    // MARK: - Log File Management
    
    /// Get path to current log file
    func getCurrentLogFilePath() -> URL? {
        return logFilePath
    }
    
    /// Get all log files
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
    
    /// Read contents of current log file
    func readCurrentLog() -> String? {
        guard let path = logFilePath else { return nil }
        return try? String(contentsOf: path, encoding: .utf8)
    }
    
    /// Clear old log files (older than specified days)
    func clearOldLogs(olderThanDays days: Int = 30) {
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
    
    /// Flush file buffer
    func flush() {
        queue.sync {
            try? fileHandle?.synchronize()
        }
    }
}
