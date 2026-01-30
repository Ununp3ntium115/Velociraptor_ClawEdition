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
        
        /// Determine whether one `LogLevel` is less than another by comparing their raw values.
        /// - Returns: `true` if `lhs` has a smaller raw value than `rhs`, `false` otherwise.
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
    
    /// Prepares file-based logging by ensuring the Velociraptor log directory exists and opening/appending to a daily log file.
    /// 
    /// Sets `logFilePath` to a per-day file under `~/Library/Logs/Velociraptor/` (named `velociraptor-YYYY-MM-DD.log`) and opens `fileHandle` for appending. If the file does not exist it is created. Any setup failures are printed to the console.
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
    
    /// Retrieve or create a per-component `os.Logger`, caching it for reuse.
    /// - Parameters:
    ///   - component: The category name to associate with the logger.
    /// - Returns: An `os.Logger` configured with the logger's subsystem and the specified component; subsequent calls with the same component return the cached instance.
    
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
    
    /// Logs a message at the debug level.
    /// - Parameters:
    ///   - message: The message to record.
    ///   - component: The component or category for the log entry; defaults to "App".
    func debug(_ message: String, component: String = "App") {
        log(message, level: .debug, component: component)
    }
    
    /// Logs an informational message for a specific component.
    /// - Parameters:
    ///   - message: The message to log.
    ///   - component: The component or category associated with this log entry. Defaults to "App".
    func info(_ message: String, component: String = "App") {
        log(message, level: .info, component: component)
    }
    
    /// Logs a success message at the info level, prefixed with a visible success indicator.
    /// - Parameters:
    ///   - message: The success message to record.
    ///   - component: The component/category used for the log entry; defaults to "App".
    func success(_ message: String, component: String = "App") {
        log("✅ \(message)", level: .info, component: component)
    }
    
    /// Logs a message at the warning level.
    /// - Parameters:
    ///   - message: The text to record in the log entry.
    ///   - component: The component or category for the log entry; defaults to `"App"`.
    func warning(_ message: String, component: String = "App") {
        log(message, level: .warning, component: component)
    }
    
    /// Logs the given text as an error-level entry.
    /// - Parameters:
    ///   - message: The message to record.
    ///   - component: The component or category associated with the message; defaults to `"App"`.
    func error(_ message: String, component: String = "App") {
        log(message, level: .error, component: component)
    }
    
    /// Logs the provided error's localized description at the error level.
    /// - Parameters:
    ///   - error: The error whose `localizedDescription` will be recorded.
    ///   - component: The logging category or component name to associate with the entry (default: `"App"`).
    func error(_ error: Error, component: String = "App") {
        log(error.localizedDescription, level: .error, component: component)
    }
    
    /// Logs a message with the critical severity level.
    /// - Parameters:
    ///   - message: The text to record in the log.
    ///   - component: The component or category for the log entry; defaults to `"App"`.
    func critical(_ message: String, component: String = "App") {
        log(message, level: .critical, component: component)
    }
    
    /// Dispatches a formatted log entry to the system logger, optionally appends it to the active log file, and prints to the console in debug builds.
    /// 
    /// The function respects the logger's `minimumLogLevel`, includes a timestamp when `includeTimestamp` is enabled, and maps the provided `level` to the appropriate system log type. When file logging is enabled and a file handle is available, the entry is written asynchronously to the file. In DEBUG builds the entry is printed with the level emoji.
    
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
    
    /// Retrieve the URL of the currently active log file.
    /// - Returns: The file URL of the active log file, or `nil` if file logging is disabled or no log file is available.
    func getCurrentLogFilePath() -> URL? {
        return logFilePath
    }
    
    /// Returns the log files created by Velociraptor, ordered from newest to oldest.
    /// - Returns: An array of file URLs for `.log` files in `~/Library/Logs/Velociraptor`, sorted by creation date with the newest first; returns an empty array if the directory cannot be read or an error occurs.
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
    
    /// Load the contents of the active log file as a UTF-8 string.
    /// - Returns: The log file contents, or `nil` if there is no active log file or the file cannot be read.
    func readCurrentLog() -> String? {
        guard let path = logFilePath else { return nil }
        return try? String(contentsOf: path, encoding: .utf8)
    }
    
    /// Removes log files older than the specified number of days from the Velociraptor log directory.
    /// 
    /// Iterates the module's log files and deletes any whose creation date is earlier than the cutoff computed from `days`. Errors encountered while processing individual files are ignored so the method continues attempting to clean remaining files.
    /// - Parameter days: Remove files created more than this many days ago. Default is 30.
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
    
    /// Forces any buffered log data for the active log file to be synchronized to storage.
    /// - Note: If no log file is open this is a no-op. The synchronization is performed on the logger's internal queue.
    func flush() {
        queue.sync {
            try? fileHandle?.synchronize()
        }
    }
}