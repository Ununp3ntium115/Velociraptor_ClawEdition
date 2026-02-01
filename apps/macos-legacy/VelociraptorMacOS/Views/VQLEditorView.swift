//
//  VQLEditorView.swift
//  VelociraptorMacOS
//
//  VQL query editor and execution terminal
//  Gap: 0x04 - VQL Terminal
//
//  CDIF Pattern: SwiftUI split view with editor and results
//

import SwiftUI
import Combine
import AppKit

// MARK: - VQL Editor View

/// Main VQL editor and terminal view
struct VQLEditorView: View {
    @StateObject private var viewModel = VQLEditorViewModel()
    @State private var dividerPosition: CGFloat = 0.5
    
    var body: some View {
        VSplitView {
            // Top: Query Editor
            VQLQueryEditor(viewModel: viewModel)
                .frame(minHeight: 150)
            
            // Bottom: Results
            VQLResultsView(viewModel: viewModel)
                .frame(minHeight: 200)
        }
        .navigationTitle("VQL Terminal")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { viewModel.executeQuery() }) {
                    Label("Execute", systemImage: "play.fill")
                }
                .keyboardShortcut(.return, modifiers: [.command])
                .accessibilityIdentifier("vql.execute.button")
                .disabled(viewModel.queryText.isEmpty || viewModel.isExecuting)
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { viewModel.clearResults() }) {
                    Label("Clear", systemImage: "trash")
                }
                .accessibilityIdentifier("vql.clear.button")
                .disabled(viewModel.results.isEmpty)
            }
            
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("Export as JSON") { viewModel.exportResults(format: .json) }
                    Button("Export as CSV") { viewModel.exportResults(format: .csv) }
                } label: {
                    Label("Export", systemImage: "square.and.arrow.up")
                }
                .accessibilityIdentifier("vql.export.menu")
                .disabled(viewModel.results.isEmpty)
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { viewModel.showHistory.toggle() }) {
                    Label("History", systemImage: "clock")
                }
                .accessibilityIdentifier("vql.history.button")
            }
        }
        .sheet(isPresented: $viewModel.showHistory) {
            QueryHistorySheet(viewModel: viewModel)
        }
    }
}

// MARK: - VQL Query Editor

/// Top panel with query input
struct VQLQueryEditor: View {
    @ObservedObject var viewModel: VQLEditorViewModel
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            HStack {
                Text("Query")
                    .font(.headline)
                
                Spacer()
                
                // Example Queries Dropdown
                Menu("Examples") {
                    ForEach(VQLExamples.allCases) { example in
                        Button(example.title) {
                            viewModel.queryText = example.query
                        }
                    }
                }
                .menuStyle(.borderlessButton)
                .accessibilityIdentifier("vql.examples.menu")
                
                if viewModel.isExecuting {
                    ProgressView()
                        .scaleEffect(0.6)
                        .padding(.horizontal, 8)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Query Input
            VQLTextEditor(text: $viewModel.queryText, font: .monospacedSystemFont(ofSize: 13, weight: .regular))
                .focused($isFocused)
                .accessibilityIdentifier("vql.query.editor")
        }
    }
}

// MARK: - VQL Text Editor

/// Custom text editor for VQL with syntax highlighting
struct VQLTextEditor: NSViewRepresentable {
    @Binding var text: String
    var font: NSFont
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.font = font
        textView.isRichText = false
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.allowsUndo = true
        textView.delegate = context.coordinator
        textView.string = text
        
        // Set colors for dark/light mode
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.textColor = NSColor.textColor
        
        return scrollView
    }
    
    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        let textView = scrollView.documentView as! NSTextView
        
        if textView.string != text {
            let selectedRanges = textView.selectedRanges
            textView.string = text
            textView.selectedRanges = selectedRanges
        }
        
        // Apply simple syntax highlighting
        applySyntaxHighlighting(to: textView)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    private func applySyntaxHighlighting(to textView: NSTextView) {
        let text = textView.string
        let fullRange = NSRange(location: 0, length: text.utf16.count)
        
        // Reset to default
        textView.textStorage?.setAttributes([
            .foregroundColor: NSColor.textColor,
            .font: font
        ], range: fullRange)
        
        // VQL Keywords
        let keywords = ["SELECT", "FROM", "WHERE", "LET", "LIMIT", "ORDER", "BY", "GROUP", "ASC", "DESC", "AND", "OR", "NOT", "IN", "LIKE", "AS"]
        
        for keyword in keywords {
            let pattern = "\\b\(keyword)\\b"
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let matches = regex.matches(in: text, range: fullRange)
                for match in matches {
                    textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.systemBlue, range: match.range)
                }
            }
        }
        
        // Strings
        let stringPattern = #""[^"]*""#
        if let regex = try? NSRegularExpression(pattern: stringPattern) {
            let matches = regex.matches(in: text, range: fullRange)
            for match in matches {
                textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.systemGreen, range: match.range)
            }
        }
        
        // Comments
        let commentPattern = #"--.*$|/\*[\s\S]*?\*/"#
        if let regex = try? NSRegularExpression(pattern: commentPattern, options: .anchorsMatchLines) {
            let matches = regex.matches(in: text, range: fullRange)
            for match in matches {
                textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.systemGray, range: match.range)
            }
        }
        
        // Functions
        let functionPattern = #"\b\w+\("#
        if let regex = try? NSRegularExpression(pattern: functionPattern) {
            let matches = regex.matches(in: text, range: fullRange)
            for match in matches {
                let adjustedRange = NSRange(location: match.range.location, length: match.range.length - 1)
                textView.textStorage?.addAttribute(.foregroundColor, value: NSColor.systemPurple, range: adjustedRange)
            }
        }
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: VQLTextEditor
        
        init(_ parent: VQLTextEditor) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            parent.text = textView.string
        }
    }
}

// MARK: - VQL Results View

/// Bottom panel showing query results
struct VQLResultsView: View {
    @ObservedObject var viewModel: VQLEditorViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Results")
                    .font(.headline)
                
                Spacer()
                
                if let result = viewModel.results.first {
                    Text("\(result.rows.count) rows")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if let executionTime = viewModel.lastExecutionTime {
                    Text(String(format: "%.2fs", executionTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Content
            if viewModel.isExecuting {
                VStack {
                    ProgressView("Executing query...")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.lastError {
                VQLErrorView(error: error)
                    .accessibilityIdentifier("vql.error.view")
            } else if viewModel.results.isEmpty {
                VQLEmptyResultsView()
            } else {
                VQLResultsTable(results: viewModel.results)
                    .accessibilityIdentifier("vql.results.table")
            }
        }
    }
}

// MARK: - VQL Results Table

/// Table displaying query results
struct VQLResultsTable: View {
    let results: [VQLResult]
    
    var body: some View {
        if let result = results.first {
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(0..<result.rows.count, id: \.self) { rowIndex in
                            HStack(spacing: 0) {
                                ForEach(result.columns.indices, id: \.self) { colIndex in
                                    let value = rowIndex < result.rows.count && colIndex < result.rows[rowIndex].count
                                        ? result.rows[rowIndex][colIndex]
                                        : .null
                                    
                                    Text(value.stringValue)
                                        .font(.system(.body, design: .monospaced))
                                        .lineLimit(3)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .frame(minWidth: 120, alignment: .leading)
                                        .background(rowIndex % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05))
                                    
                                    Divider()
                                }
                            }
                            
                            Divider()
                        }
                    } header: {
                        HStack(spacing: 0) {
                            ForEach(result.columns, id: \.self) { column in
                                Text(column)
                                    .font(.headline)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 6)
                                    .frame(minWidth: 120, alignment: .leading)
                                    .background(Color(NSColor.controlBackgroundColor))
                                
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - VQL Empty Results

struct VQLEmptyResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "terminal")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Results")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Enter a VQL query and press ⌘Enter to execute")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - VQL Error View

struct VQLErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundColor(.red)
            
            Text("Query Error")
                .font(.headline)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Query History Sheet

struct QueryHistorySheet: View {
    @ObservedObject var viewModel: VQLEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Query History")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Done") { dismiss() }
                    .accessibilityIdentifier("vql.history.done.button")
            }
            .padding()
            
            Divider()
            
            if viewModel.queryHistory.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No query history")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(viewModel.queryHistory.indices, id: \.self) { index in
                        let entry = viewModel.queryHistory[index]
                        
                        Button(action: {
                            viewModel.queryText = entry.query
                            dismiss()
                        }) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(entry.query)
                                    .font(.system(.body, design: .monospaced))
                                    .lineLimit(2)
                                
                                Text(entry.timestamp, style: .relative)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("vql.history.entry.\(index)")
                    }
                    .onDelete { indexSet in
                        viewModel.queryHistory.remove(atOffsets: indexSet)
                    }
                }
            }
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - VQL Examples

enum VQLExamples: String, CaseIterable, Identifiable {
    case clientInfo = "client_info"
    case processes = "processes"
    case networkConnections = "network"
    case fileSystem = "filesystem"
    case users = "users"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .clientInfo: return "Client Info"
        case .processes: return "Running Processes"
        case .networkConnections: return "Network Connections"
        case .fileSystem: return "File System"
        case .users: return "User Accounts"
        }
    }
    
    var query: String {
        switch self {
        case .clientInfo:
            return "SELECT * FROM info()"
        case .processes:
            return "SELECT Pid, Name, Cmdline, Username FROM pslist()"
        case .networkConnections:
            return "SELECT Pid, Name, LocalAddr, RemoteAddr FROM netstat()"
        case .fileSystem:
            return "SELECT Name, Size, Mode FROM glob(globs='/tmp/*')"
        case .users:
            return "SELECT Name, Uid, Gid, Directory FROM Artifact.Linux.Sys.Users()"
        }
    }
}

// MARK: - VQL Editor ViewModel

@MainActor
class VQLEditorViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var queryText = ""
    @Published var results: [VQLResult] = []
    @Published var isExecuting = false
    @Published var lastError: String?
    @Published var lastExecutionTime: TimeInterval?
    @Published var showHistory = false
    @Published var queryHistory: [QueryHistoryEntry] = []
    
    // MARK: - Types
    
    struct QueryHistoryEntry: Identifiable {
        let id = UUID()
        let query: String
        let timestamp: Date
    }
    
    enum ExportFormat {
        case json
        case csv
    }
    
    // MARK: - Query Execution
    
    func executeQuery() {
        guard !queryText.isEmpty else { return }
        
        Task {
            await execute()
        }
    }
    
    private func execute() async {
        isExecuting = true
        lastError = nil
        
        let startTime = Date()
        
        do {
            let result = try await VelociraptorAPIClient.shared.executeQuery(vql: queryText)
            results = [result]
            lastExecutionTime = Date().timeIntervalSince(startTime)
            
            // Add to history
            addToHistory(queryText)
            
            Logger.shared.success("Query executed: \(result.rows.count) rows in \(String(format: "%.2f", lastExecutionTime ?? 0))s", component: "VQL")
        } catch {
            lastError = error.localizedDescription
            Logger.shared.error("Query failed: \(error)", component: "VQL")
        }
        
        isExecuting = false
    }
    
    // MARK: - History
    
    private func addToHistory(_ query: String) {
        let entry = QueryHistoryEntry(query: query, timestamp: Date())
        queryHistory.insert(entry, at: 0)
        
        // Keep last 50 queries
        if queryHistory.count > 50 {
            queryHistory = Array(queryHistory.prefix(50))
        }
    }
    
    // MARK: - Actions
    
    func clearResults() {
        results = []
        lastError = nil
        lastExecutionTime = nil
    }
    
    func exportResults(format: ExportFormat) {
        guard let result = results.first else { return }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = format == .json ? [.json] : [.commaSeparatedText]
        panel.nameFieldStringValue = "query_results.\(format == .json ? "json" : "csv")"
        
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            
            Task { @MainActor in
                do {
                    let content: String
                    
                    switch format {
                    case .json:
                        content = self.toJSON(result)
                    case .csv:
                        content = self.toCSV(result)
                    }
                    
                    try content.write(to: url, atomically: true, encoding: .utf8)
                    Logger.shared.success("Exported results to: \(url.path)", component: "VQL")
                } catch {
                    Logger.shared.error("Export failed: \(error)", component: "VQL")
                }
            }
        }
    }
    
    private func toJSON(_ result: VQLResult) -> String {
        var rows: [[String: String]] = []
        
        for row in result.rows {
            var dict: [String: String] = [:]
            for (index, column) in result.columns.enumerated() {
                if index < row.count {
                    dict[column] = row[index].stringValue
                }
            }
            rows.append(dict)
        }
        
        guard let data = try? JSONSerialization.data(withJSONObject: rows, options: .prettyPrinted),
              let json = String(data: data, encoding: .utf8) else {
            return "[]"
        }
        
        return json
    }
    
    private func toCSV(_ result: VQLResult) -> String {
        var lines: [String] = []
        
        // Header
        lines.append(result.columns.map { "\"\($0)\"" }.joined(separator: ","))
        
        // Rows
        for row in result.rows {
            let values = row.map { value in
                let str = value.stringValue.replacingOccurrences(of: "\"", with: "\"\"")
                return "\"\(str)\""
            }
            lines.append(values.joined(separator: ","))
        }
        
        return lines.joined(separator: "\n")
    }
}

// MARK: - Preview

#Preview {
    VQLEditorView()
        .frame(width: 800, height: 600)
}
