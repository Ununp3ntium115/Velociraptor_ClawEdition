//
//  VQLEditorView.swift
//  VelociraptorMacOS
//
//  VQL query editor and execution terminal with MCP Integration
//  Gap: 0x04 - VQL Terminal
//  MCP Integration: AI-powered query generation and suggestions
//
//  CDIF Pattern: SwiftUI split view with editor, results, and MCP assistant
//

import SwiftUI
import Combine
import AppKit

// MARK: - VQL Editor View

/// Main VQL editor and terminal view with MCP integration
struct VQLEditorView: View {
    @StateObject private var viewModel = VQLEditorViewModel()
    @State private var dividerPosition: CGFloat = 0.5
    @State private var showMCPPanel = false
    
    var body: some View {
        HSplitView {
            // Left: Editor and Results
            VSplitView {
                // Top: Query Editor
                VQLQueryEditor(viewModel: viewModel)
                    .frame(minHeight: 150)
                
                // Bottom: Results
                VQLResultsView(viewModel: viewModel)
                    .frame(minHeight: 200)
            }
            .frame(minWidth: 500)
            
            // Right: MCP Assistant Panel (collapsible)
            if showMCPPanel {
                VQLMCPAssistantPane(viewModel: viewModel)
                    .frame(minWidth: 280, maxWidth: 400)
            }
        }
        .accessibilityIdentifier("vql.main")
        .navigationTitle("VQL Terminal")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showMCPPanel.toggle() }) {
                    Label("AI Assistant", systemImage: showMCPPanel ? "sparkles.rectangle.stack.fill" : "sparkles.rectangle.stack")
                }
                .accessibilityIdentifier("vql.mcp.toggle")
                .help("Toggle AI Assistant Panel")
            }
            
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
        .sheet(isPresented: $viewModel.showMCPQueryBuilder) {
            MCPQueryBuilderSheet(viewModel: viewModel)
        }
    }
}

// MARK: - MCP Assistant Pane

/// AI-powered VQL assistant panel
struct VQLMCPAssistantPane: View {
    @ObservedObject var viewModel: VQLEditorViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple)
                Text("AI Assistant")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Natural Language Query Input
                    GroupBox("Generate VQL") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Describe what you want to find:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $viewModel.mcpPrompt)
                                .frame(height: 80)
                                .border(Color.secondary.opacity(0.3))
                                .accessibilityIdentifier("vql.mcp.prompt.input")
                            
                            Button("Generate Query") {
                                Task { await viewModel.generateVQLFromPrompt() }
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.mcpPrompt.isEmpty || viewModel.isGenerating)
                            .accessibilityIdentifier("vql.mcp.generate.button")
                            
                            if viewModel.isGenerating {
                                HStack {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                    Text("Generating...")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    
                    // Quick Templates
                    GroupBox("Quick Templates") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(MCPQueryTemplate.allCases) { template in
                                Button(action: {
                                    viewModel.applyMCPTemplate(template)
                                }) {
                                    HStack {
                                        Image(systemName: template.icon)
                                            .foregroundColor(template.color)
                                            .frame(width: 20)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(template.title)
                                                .font(.subheadline)
                                            Text(template.description)
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.right")
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 4)
                                .accessibilityIdentifier("vql.mcp.template.\(template.rawValue)")
                            }
                        }
                    }
                    
                    // Query Explanation
                    if !viewModel.queryText.isEmpty {
                        GroupBox("Query Explanation") {
                            VStack(alignment: .leading, spacing: 8) {
                                Button("Explain Current Query") {
                                    Task { await viewModel.explainQuery() }
                                }
                                .buttonStyle(.bordered)
                                .disabled(viewModel.isExplaining)
                                .accessibilityIdentifier("vql.mcp.explain.button")
                                
                                if let explanation = viewModel.queryExplanation {
                                    Text(explanation)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    
                    // Optimization Suggestions
                    if !viewModel.optimizationSuggestions.isEmpty {
                        GroupBox("Optimization Suggestions") {
                            ForEach(viewModel.optimizationSuggestions, id: \.self) { suggestion in
                                HStack(alignment: .top) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text(suggestion)
                                        .font(.caption)
                                }
                            }
                        }
                    }
                    
                    // Recent MCP Suggestions
                    if !viewModel.mcpSuggestions.isEmpty {
                        GroupBox("Suggested Queries") {
                            ForEach(viewModel.mcpSuggestions, id: \.query) { suggestion in
                                Button(action: {
                                    viewModel.queryText = suggestion.query
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(suggestion.title)
                                            .font(.subheadline)
                                        Text(suggestion.query)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .lineLimit(2)
                                    }
                                }
                                .buttonStyle(.plain)
                                .padding(.vertical, 4)
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .accessibilityIdentifier("vql.mcp.pane")
    }
}

// MARK: - MCP Query Builder Sheet

struct MCPQueryBuilderSheet: View {
    @ObservedObject var viewModel: VQLEditorViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Query Builder")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    GroupBox("Investigation Context") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Incident Type", selection: $viewModel.mcpIncidentType) {
                                Text("Malware Analysis").tag("malware")
                                Text("Lateral Movement").tag("lateral_movement")
                                Text("Data Exfiltration").tag("exfiltration")
                                Text("Persistence").tag("persistence")
                                Text("Privilege Escalation").tag("privesc")
                                Text("Credential Theft").tag("credential_theft")
                            }
                            .accessibilityIdentifier("vql.mcp.incident.type")
                            
                            Picker("Time Range", selection: $viewModel.mcpTimeRange) {
                                Text("Last Hour").tag("1h")
                                Text("Last 24 Hours").tag("24h")
                                Text("Last 7 Days").tag("7d")
                                Text("Last 30 Days").tag("30d")
                                Text("Custom").tag("custom")
                            }
                            .accessibilityIdentifier("vql.mcp.time.range")
                            
                            TextField("Known IOCs (comma-separated)", text: $viewModel.mcpKnownIOCs)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("vql.mcp.known.iocs")
                        }
                    }
                    
                    GroupBox("Target Artifacts") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(MCPTargetArtifact.allCases) { artifact in
                                Toggle(isOn: Binding(
                                    get: { viewModel.mcpSelectedArtifacts.contains(artifact) },
                                    set: { isOn in
                                        if isOn {
                                            viewModel.mcpSelectedArtifacts.insert(artifact)
                                        } else {
                                            viewModel.mcpSelectedArtifacts.remove(artifact)
                                        }
                                    }
                                )) {
                                    HStack {
                                        Image(systemName: artifact.icon)
                                            .foregroundColor(.accentColor)
                                        Text(artifact.displayName)
                                    }
                                }
                            }
                        }
                    }
                    
                    Button("Generate Investigation Queries") {
                        Task {
                            await viewModel.generateInvestigationQueries()
                            dismiss()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isGenerating)
                }
                .padding()
            }
        }
        .frame(width: 500, height: 600)
        .accessibilityIdentifier("vql.mcp.builder.sheet")
    }
}

// MARK: - MCP Templates

enum MCPQueryTemplate: String, CaseIterable, Identifiable {
    case suspiciousProcesses = "suspicious_processes"
    case networkConnections = "network_connections"
    case fileChanges = "file_changes"
    case registryModifications = "registry_modifications"
    case userActivity = "user_activity"
    case persistenceMechanisms = "persistence"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .suspiciousProcesses: return "Suspicious Processes"
        case .networkConnections: return "Network Connections"
        case .fileChanges: return "File System Changes"
        case .registryModifications: return "Registry Modifications"
        case .userActivity: return "User Activity"
        case .persistenceMechanisms: return "Persistence Mechanisms"
        }
    }
    
    var description: String {
        switch self {
        case .suspiciousProcesses: return "Find unusual or encoded processes"
        case .networkConnections: return "Active and historical connections"
        case .fileChanges: return "Recently created/modified files"
        case .registryModifications: return "Registry key changes"
        case .userActivity: return "User logons and actions"
        case .persistenceMechanisms: return "Autoruns and scheduled tasks"
        }
    }
    
    var icon: String {
        switch self {
        case .suspiciousProcesses: return "gearshape.fill"
        case .networkConnections: return "network"
        case .fileChanges: return "folder.fill"
        case .registryModifications: return "gearshape.2.fill"
        case .userActivity: return "person.fill"
        case .persistenceMechanisms: return "arrow.clockwise"
        }
    }
    
    var color: Color {
        switch self {
        case .suspiciousProcesses: return .purple
        case .networkConnections: return .green
        case .fileChanges: return .blue
        case .registryModifications: return .orange
        case .userActivity: return .red
        case .persistenceMechanisms: return .yellow
        }
    }
    
    var query: String {
        switch self {
        case .suspiciousProcesses:
            return """
            SELECT Pid, Name, Cmdline, Username, CreateTime
            FROM pslist()
            WHERE Cmdline =~ "powershell.*-enc|cmd.*-c|wscript|cscript"
            ORDER BY CreateTime DESC
            """
        case .networkConnections:
            return """
            SELECT Pid, Name, LocalAddr, RemoteAddr, Status
            FROM netstat()
            WHERE Status = "ESTABLISHED" OR Status = "LISTEN"
            """
        case .fileChanges:
            return """
            SELECT FullPath, Size, Mtime, Atime
            FROM glob(globs='C:/Users/*/AppData/**')
            WHERE Mtime > now() - 86400
            ORDER BY Mtime DESC
            LIMIT 100
            """
        case .registryModifications:
            return """
            SELECT Key, Value, Type, ModTime
            FROM Artifact.Windows.Registry.RecentKeys()
            ORDER BY ModTime DESC
            LIMIT 100
            """
        case .userActivity:
            return """
            SELECT TimeGenerated, UserName, LogonType, IpAddress
            FROM Artifact.Windows.EventLogs.Evtx(
                FileName='C:/Windows/System32/winevt/Logs/Security.evtx',
                IdFilter='4624,4625'
            )
            ORDER BY TimeGenerated DESC
            LIMIT 100
            """
        case .persistenceMechanisms:
            return """
            SELECT Entry, Location, Command, User
            FROM Artifact.Windows.Detection.Autoruns()
            WHERE Enabled = true
            """
        }
    }
}

enum MCPTargetArtifact: String, CaseIterable, Identifiable {
    case processes = "processes"
    case network = "network"
    case filesystem = "filesystem"
    case registry = "registry"
    case eventLogs = "eventlogs"
    case memory = "memory"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .processes: return "Processes"
        case .network: return "Network"
        case .filesystem: return "File System"
        case .registry: return "Registry"
        case .eventLogs: return "Event Logs"
        case .memory: return "Memory"
        }
    }
    
    var icon: String {
        switch self {
        case .processes: return "gearshape"
        case .network: return "network"
        case .filesystem: return "folder"
        case .registry: return "list.bullet.rectangle"
        case .eventLogs: return "doc.text"
        case .memory: return "memorychip"
        }
    }
}

struct MCPQuerySuggestion {
    let title: String
    let query: String
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
                
                if let result = viewModel.results.first,
                   let rows = result.rows {
                    Text("\(rows.count) rows")
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
    
    private var rows: [[VQLValue]] {
        results.first?.rows ?? []
    }
    
    private var columns: [String] {
        results.first?.columns ?? []
    }
    
    var body: some View {
        if !rows.isEmpty && !columns.isEmpty {
            ScrollView([.horizontal, .vertical]) {
                LazyVStack(alignment: .leading, spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        ForEach(0..<rows.count, id: \.self) { rowIndex in
                            rowView(at: rowIndex)
                            Divider()
                        }
                    } header: {
                        headerView
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func rowView(at rowIndex: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(columns.indices, id: \.self) { colIndex in
                cellView(rowIndex: rowIndex, colIndex: colIndex)
                Divider()
            }
        }
    }
    
    @ViewBuilder
    private func cellView(rowIndex: Int, colIndex: Int) -> some View {
        let value = getValue(rowIndex: rowIndex, colIndex: colIndex)
        let bgColor: Color = rowIndex % 2 == 0 ? Color.clear : Color.secondary.opacity(0.05)
        
        Text(value.stringValue)
            .font(.system(.body, design: .monospaced))
            .lineLimit(3)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minWidth: 120, alignment: .leading)
            .background(bgColor)
    }
    
    private func getValue(rowIndex: Int, colIndex: Int) -> VQLValue {
        guard rowIndex < rows.count, colIndex < rows[rowIndex].count else {
            return .null
        }
        return rows[rowIndex][colIndex]
    }
    
    @ViewBuilder
    private var headerView: some View {
        HStack(spacing: 0) {
            ForEach(columns, id: \.self) { column in
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
    
    // MARK: - MCP Integration Properties
    
    @Published var showMCPQueryBuilder = false
    @Published var mcpPrompt = ""
    @Published var isGenerating = false
    @Published var isExplaining = false
    @Published var queryExplanation: String?
    @Published var optimizationSuggestions: [String] = []
    @Published var mcpSuggestions: [MCPQuerySuggestion] = []
    
    // MCP Query Builder State
    @Published var mcpIncidentType = "malware"
    @Published var mcpTimeRange = "24h"
    @Published var mcpKnownIOCs = ""
    @Published var mcpSelectedArtifacts: Set<MCPTargetArtifact> = [.processes, .network]
    
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
            
            // Analyze query for optimization suggestions
            await analyzeQueryForOptimization()
            
            Logger.shared.success("Query executed: \((result.rows ?? []).count) rows in \(String(format: "%.2f", lastExecutionTime ?? 0))s", component: "VQL")
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
    
    // MARK: - MCP Integration Methods
    
    /// Generate VQL from natural language prompt using MCP
    func generateVQLFromPrompt() async {
        guard !mcpPrompt.isEmpty else { return }
        
        isGenerating = true
        defer { isGenerating = false }
        
        Logger.shared.info("Generating VQL from prompt: \(mcpPrompt)", component: "MCP")
        
        // Simulate MCP call - in production would use velociraptor_generate_vql tool
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Generate query based on prompt keywords
        let generatedQuery = generateQueryFromPromptKeywords(mcpPrompt)
        queryText = generatedQuery
        
        Logger.shared.success("Generated VQL query from prompt", component: "MCP")
        
        // Clear prompt
        mcpPrompt = ""
    }
    
    private func generateQueryFromPromptKeywords(_ prompt: String) -> String {
        let lowercased = prompt.lowercased()
        
        if lowercased.contains("process") || lowercased.contains("running") {
            return """
            SELECT Pid, Name, Cmdline, Username, CreateTime
            FROM pslist()
            ORDER BY CreateTime DESC
            """
        } else if lowercased.contains("network") || lowercased.contains("connection") {
            return """
            SELECT Pid, Name, LocalAddr, RemoteAddr, Status
            FROM netstat()
            WHERE Status = "ESTABLISHED"
            """
        } else if lowercased.contains("file") || lowercased.contains("download") {
            return """
            SELECT FullPath, Size, Mtime
            FROM glob(globs='C:/Users/*/Downloads/**')
            ORDER BY Mtime DESC
            LIMIT 50
            """
        } else if lowercased.contains("login") || lowercased.contains("logon") || lowercased.contains("authentication") {
            return """
            SELECT TimeGenerated, UserName, LogonType, IpAddress
            FROM Artifact.Windows.EventLogs.Evtx(
                FileName='C:/Windows/System32/winevt/Logs/Security.evtx',
                IdFilter='4624,4625'
            )
            ORDER BY TimeGenerated DESC
            LIMIT 100
            """
        } else if lowercased.contains("registry") {
            return """
            SELECT Key, Value, Type, ModTime
            FROM Artifact.Windows.Registry.RecentKeys()
            LIMIT 100
            """
        } else if lowercased.contains("powershell") || lowercased.contains("suspicious") {
            return """
            SELECT Pid, Name, Cmdline, Username
            FROM pslist()
            WHERE Name =~ "powershell|pwsh|cmd"
            """
        } else {
            return """
            -- Generated for: \(prompt)
            SELECT * FROM info()
            """
        }
    }
    
    /// Apply a predefined MCP template
    func applyMCPTemplate(_ template: MCPQueryTemplate) {
        queryText = template.query
        Logger.shared.info("Applied MCP template: \(template.title)", component: "MCP")
    }
    
    /// Explain the current query using MCP
    func explainQuery() async {
        guard !queryText.isEmpty else { return }
        
        isExplaining = true
        defer { isExplaining = false }
        
        // Simulate MCP explanation
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        queryExplanation = generateQueryExplanation(queryText)
        Logger.shared.info("Generated query explanation", component: "MCP")
    }
    
    private func generateQueryExplanation(_ query: String) -> String {
        if query.contains("pslist()") {
            return "This query lists running processes on the system. It retrieves process information including PID, name, command line, and owner."
        } else if query.contains("netstat()") {
            return "This query shows network connections. It displays local and remote addresses along with connection status."
        } else if query.contains("glob(") {
            return "This query searches the file system using glob patterns. It finds files matching the specified pattern and returns their metadata."
        } else if query.contains("EventLogs.Evtx") {
            return "This query reads Windows Event Logs from EVTX files. It filters events by ID to find specific security events like logons."
        } else if query.contains("Registry") {
            return "This query reads Windows Registry data. It retrieves keys, values, and modification timestamps."
        } else {
            return "This VQL query retrieves data from the specified source and applies any filters or transformations defined."
        }
    }
    
    /// Analyze query for optimization suggestions
    private func analyzeQueryForOptimization() async {
        optimizationSuggestions = []
        
        if !queryText.contains("LIMIT") && queryText.contains("FROM") {
            optimizationSuggestions.append("Consider adding a LIMIT clause to prevent returning too many results")
        }
        
        if queryText.contains("SELECT *") {
            optimizationSuggestions.append("Specify exact columns instead of SELECT * for better performance")
        }
        
        if queryText.contains("glob(") && !queryText.contains("LIMIT") {
            optimizationSuggestions.append("Glob operations can be expensive - add LIMIT and specific path filters")
        }
    }
    
    /// Generate multiple investigation queries based on context
    func generateInvestigationQueries() async {
        isGenerating = true
        defer { isGenerating = false }
        
        Logger.shared.info("Generating investigation queries for: \(mcpIncidentType)", component: "MCP")
        
        // Simulate MCP generation
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Generate suggestions based on incident type
        mcpSuggestions = generateSuggestionsForIncident(mcpIncidentType)
        
        // Apply the first suggestion
        if let firstSuggestion = mcpSuggestions.first {
            queryText = firstSuggestion.query
        }
        
        Logger.shared.success("Generated \(mcpSuggestions.count) investigation queries", component: "MCP")
    }
    
    private func generateSuggestionsForIncident(_ incidentType: String) -> [MCPQuerySuggestion] {
        switch incidentType {
        case "malware":
            return [
                MCPQuerySuggestion(
                    title: "Suspicious Processes",
                    query: "SELECT Pid, Name, Cmdline FROM pslist() WHERE Cmdline =~ '-enc|-e |hidden|bypass'"
                ),
                MCPQuerySuggestion(
                    title: "Recent Executables",
                    query: "SELECT FullPath, Size, Mtime FROM glob(globs='C:/Users/**/AppData/**/*.exe') WHERE Mtime > now() - 86400"
                ),
                MCPQuerySuggestion(
                    title: "Network Beacons",
                    query: "SELECT Pid, Name, RemoteAddr FROM netstat() WHERE Status = 'ESTABLISHED' AND RemoteAddr != '127.0.0.1'"
                ),
            ]
        case "lateral_movement":
            return [
                MCPQuerySuggestion(
                    title: "Remote Logons",
                    query: "SELECT TimeGenerated, UserName, LogonType, IpAddress FROM Artifact.Windows.EventLogs.Evtx(FileName='C:/Windows/System32/winevt/Logs/Security.evtx', IdFilter='4624') WHERE LogonType IN (3, 10)"
                ),
                MCPQuerySuggestion(
                    title: "PSExec Usage",
                    query: "SELECT * FROM Artifact.Windows.Detection.PSexec()"
                ),
                MCPQuerySuggestion(
                    title: "WMI Activity",
                    query: "SELECT * FROM pslist() WHERE Name =~ 'wmiprvse|wmic'"
                ),
            ]
        case "persistence":
            return [
                MCPQuerySuggestion(
                    title: "Autoruns",
                    query: "SELECT Entry, Location, Command, User FROM Artifact.Windows.Detection.Autoruns()"
                ),
                MCPQuerySuggestion(
                    title: "Scheduled Tasks",
                    query: "SELECT TaskName, Command, LastRun, NextRun FROM Artifact.Windows.System.ScheduledTasks()"
                ),
                MCPQuerySuggestion(
                    title: "Services",
                    query: "SELECT Name, DisplayName, PathName, StartMode FROM Artifact.Windows.System.Services()"
                ),
            ]
        default:
            return [
                MCPQuerySuggestion(
                    title: "System Info",
                    query: "SELECT * FROM info()"
                ),
                MCPQuerySuggestion(
                    title: "Running Processes",
                    query: "SELECT Pid, Name, Cmdline FROM pslist()"
                ),
            ]
        }
    }
    
    // MARK: - Actions
    
    func clearResults() {
        results = []
        lastError = nil
        lastExecutionTime = nil
        queryExplanation = nil
        optimizationSuggestions = []
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
        let resultRows = result.rows ?? []
        let resultColumns = result.columns ?? []
        var rows: [[String: String]] = []
        
        for row in resultRows {
            var dict: [String: String] = [:]
            for (index, column) in resultColumns.enumerated() {
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
        let resultRows = result.rows ?? []
        let resultColumns = result.columns ?? []
        var lines: [String] = []
        
        // Header
        lines.append(resultColumns.map { "\"\($0)\"" }.joined(separator: ","))
        
        // Rows
        for row in resultRows {
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
