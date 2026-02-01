//
//  LogsView.swift
//  VelociraptorMacOS
//
//  Log viewer for Velociraptor logs
//

import SwiftUI

struct LogsView: View {
    @StateObject private var viewModel = LogsViewModel()
    @State private var searchText = ""
    @State private var selectedLogFile: URL?
    @State private var showExportSheet = false
    
    var body: some View {
        HSplitView {
            // Left panel - Log files list
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("Log Files")
                        .font(.headline)
                    
                    Spacer()
                    
                    Button {
                        viewModel.refreshLogFiles()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                
                Divider()
                
                List(selection: $selectedLogFile) {
                    ForEach(viewModel.logFiles, id: \.self) { file in
                        LogFileRow(file: file, isSelected: selectedLogFile == file)
                            .tag(file)
                    }
                }
                .listStyle(.sidebar)
                .onChange(of: selectedLogFile) { newValue in
                    if let file = newValue {
                        viewModel.loadLogFile(file)
                    }
                }
                
                Divider()
                
                // Summary
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(viewModel.logFiles.count) log files")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Total: \(viewModel.totalLogSize)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .frame(minWidth: 200, maxWidth: 300)
            
            // Right panel - Log content
            VStack(spacing: 0) {
                // Toolbar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search logs...", text: $searchText)
                        .textFieldStyle(.plain)
                    
                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Divider()
                        .frame(height: 20)
                    
                    Picker("Level", selection: $viewModel.filterLevel) {
                        Text("All").tag(LogsViewModel.LogLevel?.none)
                        ForEach(LogsViewModel.LogLevel.allCases) { level in
                            Text(level.rawValue).tag(LogsViewModel.LogLevel?.some(level))
                        }
                    }
                    .frame(width: 100)
                    
                    Button {
                        showExportSheet = true
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .help("Export logs")
                    
                    Button {
                        viewModel.clearLogs()
                    } label: {
                        Image(systemName: "trash")
                    }
                    .help("Clear old logs")
                }
                .padding()
                
                Divider()
                
                // Log content
                if viewModel.isLoading {
                    VStack {
                        ProgressView()
                        Text("Loading logs...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.filteredEntries.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text(selectedLogFile == nil ? "Select a log file" : "No log entries")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 2) {
                                ForEach(filteredAndSearched, id: \.self) { entry in
                                    LogEntryRow(entry: entry)
                                        .id(entry)
                                }
                            }
                            .padding()
                        }
                        .onAppear {
                            if let last = filteredAndSearched.last {
                                proxy.scrollTo(last, anchor: .bottom)
                            }
                        }
                    }
                }
                
                Divider()
                
                // Status bar
                HStack {
                    Text("\(viewModel.filteredEntries.count) entries")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if let file = selectedLogFile {
                        Text(file.lastPathComponent)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if viewModel.isAutoScrollEnabled {
                        Image(systemName: "arrow.down.circle.fill")
                            .foregroundColor(.accentColor)
                    }
                    
                    Toggle("Auto-scroll", isOn: $viewModel.isAutoScrollEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .onAppear {
            viewModel.refreshLogFiles()
            if selectedLogFile == nil, let first = viewModel.logFiles.first {
                selectedLogFile = first
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportLogsSheet(viewModel: viewModel)
        }
    }
    
    private var filteredAndSearched: [String] {
        if searchText.isEmpty {
            return viewModel.filteredEntries
        }
        return viewModel.filteredEntries.filter { $0.localizedCaseInsensitiveContains(searchText) }
    }
}

// MARK: - Log File Row

struct LogFileRow: View {
    let file: URL
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "doc.text")
                .foregroundColor(isSelected ? .accentColor : .secondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(file.lastPathComponent)
                    .font(.subheadline)
                    .lineLimit(1)
                
                Text(fileDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(fileSize)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var fileDate: String {
        guard let date = try? file.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate else {
            return ""
        }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private var fileSize: String {
        guard let size = try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize else {
            return ""
        }
        return ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)
    }
}

// MARK: - Log Entry Row

struct LogEntryRow: View {
    let entry: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            // Level indicator
            Circle()
                .fill(levelColor)
                .frame(width: 8, height: 8)
                .padding(.top, 4)
            
            // Timestamp
            if let timestamp = extractTimestamp() {
                Text(timestamp)
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
                    .frame(width: 140, alignment: .leading)
            }
            
            // Message
            Text(extractMessage())
                .font(.caption.monospaced())
                .textSelection(.enabled)
        }
        .padding(.vertical, 2)
    }
    
    private var levelColor: Color {
        if entry.contains("[ERROR]") || entry.contains("❌") {
            return .red
        } else if entry.contains("[WARN]") || entry.contains("⚠️") {
            return .orange
        } else if entry.contains("[DEBUG]") || entry.contains("🔍") {
            return .purple
        } else if entry.contains("✅") {
            return .green
        } else {
            return .blue
        }
    }
    
    /// Extracts the timestamp substring from the current log `entry`.
    /// - Returns: The timestamp in the format `[YYYY-MM-DD HH:MM:SS.mmm]` if present, `nil` otherwise.
    private func extractTimestamp() -> String? {
        // Match [YYYY-MM-DD HH:MM:SS.mmm] pattern
        let pattern = #"\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3})\]"#
        if let range = entry.range(of: pattern, options: .regularExpression) {
            return String(entry[range])
        }
        return nil
    }
    
    /// Extracts the log message by removing a leading timestamp if present.
    /// 
    /// If the entry begins with a timestamp in the form `[YYYY-MM-DD HH:MM:SS.mmm]`, that timestamp and any following whitespace are removed; otherwise the original entry is returned.
    /// - Returns: The log message with any leading timestamp removed.
    private func extractMessage() -> String {
        // Remove timestamp if present
        let pattern = #"^\[\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3}\]\s*"#
        return entry.replacingOccurrences(of: pattern, with: "", options: .regularExpression)
    }
}

// MARK: - Export Logs Sheet

struct ExportLogsSheet: View {
    @ObservedObject var viewModel: LogsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var exportOption = ExportOption.current
    @State private var includeAllLevels = true
    
    enum ExportOption {
        case current
        case all
        case dateRange
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Logs")
                .font(.headline)
            
            Picker("Export:", selection: $exportOption) {
                Text("Current Log").tag(ExportOption.current)
                Text("All Logs").tag(ExportOption.all)
            }
            .pickerStyle(.segmented)
            
            Toggle("Include all log levels", isOn: $includeAllLevels)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Button("Export") {
                    exportLogs()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 300)
    }
    
    /// Presents a save dialog and saves the currently displayed (filtered) logs to the chosen file.
    /// - Details:
    ///   - The save panel defaults to a plain-text file named "velociraptor-logs-<ISO8601 date>.txt".
    ///   - If the user confirms, the view model's `filteredEntries` are joined with newline characters and written as UTF-8 plain text to the selected URL.
    ///   - Write failures are ignored (no error is thrown or propagated).
    ///   - The export sheet is dismissed after the save panel completes.
    private func exportLogs() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "velociraptor-logs-\(Date().ISO8601Format()).txt"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let content = viewModel.filteredEntries.joined(separator: "\n")
                try? content.write(to: url, atomically: true, encoding: .utf8)
                dismiss()
            }
        }
    }
}

// MARK: - Logs View Model

@MainActor
class LogsViewModel: ObservableObject {
    @Published var logFiles: [URL] = []
    @Published var logEntries: [String] = []
    @Published var isLoading = false
    @Published var isAutoScrollEnabled = true
    @Published var filterLevel: LogLevel?
    
    enum LogLevel: String, CaseIterable, Identifiable {
        case error = "ERROR"
        case warn = "WARN"
        case info = "INFO"
        case debug = "DEBUG"
        
        var id: String { rawValue }
    }
    
    var filteredEntries: [String] {
        guard let level = filterLevel else {
            return logEntries
        }
        return logEntries.filter { $0.contains("[\(level.rawValue)]") }
    }
    
    var totalLogSize: String {
        let totalBytes = logFiles.reduce(0) { total, file in
            let size = (try? file.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
            return total + size
        }
        return ByteCountFormatter.string(fromByteCount: Int64(totalBytes), countStyle: .file)
    }
    
    /// Refreshes the view model's list of available log files by reading the user's ~/Library/Logs/Velociraptor directory.
    /// 
    /// Updates `logFiles` with files that have a `.log` extension, sorted by modification date with the newest first.
    /// On any error while reading the directory, `logFiles` is set to an empty array.
    func refreshLogFiles() {
        let logDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Velociraptor")
        
        do {
            logFiles = try FileManager.default.contentsOfDirectory(
                at: logDir,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
                options: [.skipsHiddenFiles]
            )
            .filter { $0.pathExtension == "log" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? Date.distantPast
                return date1 > date2
            }
        } catch {
            logFiles = []
        }
    }
    
    /// Loads the given log file and updates the view model's entries.
    /// 
    /// While the file is being read the `isLoading` flag is set to true; on completion it is set to false. On success the file's UTF-8 contents are split into lines and any empty lines are removed before assigning to `logEntries`. On failure `logEntries` is set to a single error message describing the failure.
    /// - Parameter file: The file URL of the log file to load.
    func loadLogFile(_ file: URL) {
        isLoading = true
        
        Task {
            do {
                let content = try String(contentsOf: file, encoding: .utf8)
                logEntries = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
            } catch {
                logEntries = ["Error loading log file: \(error.localizedDescription)"]
            }
            isLoading = false
        }
    }
    
    /// Deletes log files older than 30 days and refreshes the list of available log files.
    func clearLogs() {
        Logger.shared.clearOldLogs(olderThanDays: 30)
        refreshLogFiles()
    }
}

#Preview {
    LogsView()
        .frame(width: 900, height: 600)
}