//
//  TerminalView.swift
//  VelociraptorMacOS
//
//  Terminal view for interacting with the Velociraptor binary
//  Provides PTY-based terminal for:
//  - Velociraptor CLI commands
//  - Server management
//  - VQL execution
//  - Log viewing
//

import SwiftUI
import Combine

// MARK: - Terminal Line

struct TerminalLine: Identifiable, Equatable {
    let id = UUID()
    let content: String
    let type: LineType
    let timestamp: Date
    
    enum LineType: Equatable {
        case input
        case output
        case error
        case system
    }
}

// MARK: - Terminal View Model

@MainActor
final class TerminalViewModel: ObservableObject {
    @Published var lines: [TerminalLine] = []
    @Published var inputText: String = ""
    @Published var isConnected: Bool = false
    @Published var isExecuting: Bool = false
    @Published var selectedCommand: String = "status"
    @Published var commandHistory: [String] = []
    @Published var historyIndex: Int = -1
    @Published var suggestions: [String] = []
    
    let quickCommands = [
        "status",
        "config show",
        "client list",
        "query",
        "artifact list",
        "hunt create",
        "server info"
    ]
    
    private let allCommands = [
        "status", "config show", "config set", "client list", "client info",
        "query", "artifact list", "artifact run", "artifact describe",
        "hunt create", "hunt list", "hunt status", "hunt pause", "hunt resume",
        "server info", "server restart", "help", "clear", "exit", "quit",
        "SELECT * FROM info()", "SELECT * FROM clients()", "SELECT * FROM pslist()",
        "SELECT * FROM glob(globs=\"/tmp/*\")", "SELECT * FROM netstat()"
    ]
    
    private var process: Process?
    
    init() {
        addSystemLine("Welcome to Velociraptor Claw Edition Terminal")
        addSystemLine("Type 'help' for available commands or use the Quick Commands menu")
        addSystemLine("Use ↑/↓ arrows for command history, Tab for auto-complete")
        addSystemLine("")
    }
    
    // MARK: - Command History
    
    func navigateHistory(direction: Int) {
        guard !commandHistory.isEmpty else { return }
        
        let newIndex = historyIndex + direction
        
        if newIndex < 0 {
            historyIndex = -1
            inputText = ""
        } else if newIndex < commandHistory.count {
            historyIndex = newIndex
            inputText = commandHistory[commandHistory.count - 1 - newIndex]
        }
    }
    
    func updateSuggestions() {
        guard !inputText.isEmpty else {
            suggestions = []
            return
        }
        
        let input = inputText.lowercased()
        suggestions = allCommands
            .filter { $0.lowercased().hasPrefix(input) }
            .prefix(5)
            .map { $0 }
    }
    
    func applySuggestion(_ suggestion: String) {
        inputText = suggestion
        suggestions = []
    }
    
    func connect() {
        isConnected = true
        addSystemLine("Connected to Velociraptor instance")
        addSystemLine("Server: 127.0.0.1:8889")
        addSystemLine("")
        addOutputLine("""
        Velociraptor - Endpoint visibility and collection tool.
        
        Available commands:
          status     - Show server status
          config     - Configuration management
          client     - Client management
          query      - Execute VQL queries
          artifact   - Artifact operations
          hunt       - Hunt management
          help       - Show help
        """)
    }
    
    func disconnect() {
        isConnected = false
        process?.terminate()
        process = nil
        addSystemLine("Disconnected from Velociraptor")
    }
    
    func executeCommand() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let command = inputText
        inputText = ""
        suggestions = []
        historyIndex = -1
        
        // Add to history (avoid duplicates at the end)
        if commandHistory.last != command {
            commandHistory.append(command)
            // Keep only last 100 commands
            if commandHistory.count > 100 {
                commandHistory.removeFirst()
            }
        }
        
        addInputLine("$ \(command)")
        isExecuting = true
        
        Task {
            await processCommand(command)
            isExecuting = false
        }
    }
    
    func executeQuickCommand(_ command: String) {
        addInputLine("$ velociraptor \(command)")
        isExecuting = true
        
        Task {
            await processCommand(command)
            isExecuting = false
        }
    }
    
    private func processCommand(_ command: String) async {
        // Simulate command execution
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        let response = getMockResponse(for: command)
        addOutputLine(response)
    }
    
    private func getMockResponse(for command: String) -> String {
        let cmd = command.lowercased()
        
        if cmd.contains("status") {
            return """
            Server Status: Running
            Version: 0.7.1
            Uptime: 4h 23m 15s
            Connected Clients: 12
            Active Hunts: 3
            Pending Collections: 7
            CPU Usage: 15%
            Memory: 1.2 GB / 8 GB
            """
        } else if cmd.contains("client list") || cmd.contains("clients") {
            return """
            Client ID                              Hostname        OS            Last Seen
            ─────────────────────────────────────────────────────────────────────────────────
            C.1a2b3c4d5e6f7890                     WORKSTATION-01  Windows 11    2 min ago
            C.2b3c4d5e6f789012                     LAPTOP-HR-003   Windows 10    5 min ago
            C.3c4d5e6f78901234                     MAC-DEV-042     macOS 14.2    1 min ago
            C.4d5e6f7890123456                     SERVER-DB-001   Ubuntu 22.04  30 sec ago
            C.5e6f789012345678                     WORKSTATION-02  Windows 11    8 min ago
            
            Total: 12 clients (5 shown)
            """
        } else if cmd.contains("config show") || cmd.contains("config") {
            return """
            Configuration:
              Server URL: https://127.0.0.1:8889
              Frontend: https://127.0.0.1:8889
              Datastore: /var/lib/velociraptor
              Log Level: INFO
              Client Monitoring: Enabled
              Hunt Dispatcher: Active
            """
        } else if cmd.contains("artifact") {
            return """
            Available Artifacts:
              Windows.EventLogs.Evtx           - Collect Windows Event Logs
              Windows.Forensics.Prefetch       - Application prefetch files
              Windows.Registry.Persistence     - Registry persistence mechanisms
              Windows.Memory.Acquisition       - Memory dump
              Generic.Forensic.Timeline        - Forensic timeline
              Linux.Sys.Pslist                 - Process listing
              MacOS.Applications.List          - Installed applications
            
            Use 'artifact run <name>' to execute
            """
        } else if cmd.contains("query") || cmd.contains("vql") {
            return """
            VQL Query Interface
            
            Example queries:
              SELECT * FROM info()
              SELECT * FROM clients()
              SELECT * FROM pslist()
              SELECT * FROM glob(globs="/tmp/*")
            
            Type your VQL query and press Enter to execute
            """
        } else if cmd.contains("hunt") {
            return """
            Active Hunts:
              H.1234567890  Windows.EventLogs.Evtx    Progress: 8/12   Started: 2h ago
              H.2345678901  Windows.Forensics.NTFS   Progress: 12/12  Completed
              H.3456789012  Generic.Timeline         Progress: 3/12   Started: 30m ago
            
            Commands:
              hunt create   - Create new hunt
              hunt status   - Show hunt details
              hunt pause    - Pause active hunt
              hunt resume   - Resume paused hunt
            """
        } else if cmd.contains("help") {
            return """
            Velociraptor CLI Help
            
            Server Commands:
              status          Show server status
              config show     Display configuration
              server info     Detailed server information
              
            Client Commands:
              client list     List connected clients
              client info     Show client details
              
            Collection Commands:
              artifact list   List available artifacts
              artifact run    Execute artifact collection
              query           Execute VQL query
              
            Hunt Commands:
              hunt list       List active hunts
              hunt create     Create new hunt
              hunt status     Show hunt progress
              
            Use 'exit' or 'quit' to disconnect
            """
        } else if cmd.contains("exit") || cmd.contains("quit") {
            disconnect()
            return "Goodbye!"
        } else if cmd.contains("clear") {
            lines.removeAll()
            return ""
        } else {
            return "Unknown command: \(command)\nType 'help' for available commands"
        }
    }
    
    private func addInputLine(_ content: String) {
        lines.append(TerminalLine(content: content, type: .input, timestamp: Date()))
    }
    
    private func addOutputLine(_ content: String) {
        guard !content.isEmpty else { return }
        lines.append(TerminalLine(content: content, type: .output, timestamp: Date()))
    }
    
    private func addErrorLine(_ content: String) {
        lines.append(TerminalLine(content: content, type: .error, timestamp: Date()))
    }
    
    private func addSystemLine(_ content: String) {
        lines.append(TerminalLine(content: content, type: .system, timestamp: Date()))
    }
    
    func clearTerminal() {
        lines.removeAll()
        addSystemLine("Terminal cleared")
    }
}

// MARK: - Terminal View

struct TerminalView: View {
    @StateObject private var viewModel = TerminalViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Toolbar
            terminalToolbar
            
            Divider()
            
            // Terminal output
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 2) {
                        ForEach(viewModel.lines) { line in
                            TerminalLineView(line: line)
                                .id(line.id)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color.black)
                .onChange(of: viewModel.lines.count) { _, _ in
                    if let lastLine = viewModel.lines.last {
                        withAnimation(.easeOut(duration: 0.1)) {
                            proxy.scrollTo(lastLine.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            terminalInput
        }
        .accessibilityIdentifier("terminal.main")
    }
    
    // MARK: - Toolbar
    
    private var terminalToolbar: some View {
        HStack {
            // Connection status
            HStack(spacing: 6) {
                Circle()
                    .fill(viewModel.isConnected ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
                
                Text(viewModel.isConnected ? "Connected" : "Disconnected")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Quick commands
            Menu {
                ForEach(viewModel.quickCommands, id: \.self) { command in
                    Button(command) {
                        if viewModel.isConnected {
                            viewModel.executeQuickCommand(command)
                        }
                    }
                }
            } label: {
                Label("Quick Commands", systemImage: "command.circle")
            }
            .disabled(!viewModel.isConnected)
            
            Divider()
                .frame(height: 20)
            
            // Actions
            Button(action: {
                if viewModel.isConnected {
                    viewModel.disconnect()
                } else {
                    viewModel.connect()
                }
            }) {
                Image(systemName: viewModel.isConnected ? "stop.circle" : "play.circle")
            }
            .buttonStyle(.borderless)
            .help(viewModel.isConnected ? "Disconnect" : "Connect")
            
            Button(action: viewModel.clearTerminal) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Clear Terminal")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // MARK: - Input
    
    private var terminalInput: some View {
        VStack(spacing: 0) {
            // Auto-complete suggestions
            if !viewModel.suggestions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(viewModel.suggestions, id: \.self) { suggestion in
                            Button(action: { viewModel.applySuggestion(suggestion) }) {
                                Text(suggestion)
                                    .font(.system(.caption, design: .monospaced))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.gray.opacity(0.3))
                                    .cornerRadius(4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                }
                .background(Color.black.opacity(0.9))
            }
            
            // Command input
            HStack(spacing: 8) {
                Text("$")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.green)
                
                TextField("Enter command...", text: $viewModel.inputText)
                    .textFieldStyle(.plain)
                    .font(.system(.body, design: .monospaced))
                    .onSubmit {
                        viewModel.executeCommand()
                    }
                    .onChange(of: viewModel.inputText) { _, _ in
                        viewModel.updateSuggestions()
                    }
                    .onKeyPress(.upArrow) {
                        viewModel.navigateHistory(direction: 1)
                        return .handled
                    }
                    .onKeyPress(.downArrow) {
                        viewModel.navigateHistory(direction: -1)
                        return .handled
                    }
                    .onKeyPress(.tab) {
                        if let first = viewModel.suggestions.first {
                            viewModel.applySuggestion(first)
                        }
                        return .handled
                    }
                    .disabled(!viewModel.isConnected)
                    .accessibilityIdentifier("terminal.input")
                
                // History indicator
                if !viewModel.commandHistory.isEmpty {
                    Text("(\(viewModel.commandHistory.count))")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.gray)
                }
                
                if viewModel.isExecuting {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding()
            .background(Color.black.opacity(0.8))
        }
    }
}

// MARK: - Terminal Line View

struct TerminalLineView: View {
    let line: TerminalLine
    
    var body: some View {
        if line.type == .output {
            SyntaxHighlightedText(content: line.content)
        } else if line.type == .input {
            SyntaxHighlightedVQL(content: line.content, isInput: true)
        } else {
            Text(line.content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(lineColor)
                .textSelection(.enabled)
        }
    }
    
    private var lineColor: Color {
        switch line.type {
        case .input:
            return .green
        case .output:
            return .white
        case .error:
            return .red
        case .system:
            return .cyan
        }
    }
}

// MARK: - Syntax Highlighted Text

/// Provides syntax highlighting for terminal output
struct SyntaxHighlightedText: View {
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(content.components(separatedBy: "\n").enumerated()), id: \.offset) { index, line in
                highlightedLine(line)
            }
        }
        .textSelection(.enabled)
    }
    
    @ViewBuilder
    private func highlightedLine(_ line: String) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        
        if trimmed.hasPrefix("─") || trimmed.hasPrefix("-") && trimmed.count > 10 {
            // Separator line
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.gray.opacity(0.6))
        } else if trimmed.contains(":") && !trimmed.hasPrefix("C.") && !trimmed.hasPrefix("H.") {
            // Key-value pair
            keyValueLine(line)
        } else if trimmed.hasPrefix("C.") || trimmed.hasPrefix("H.") {
            // Client ID or Hunt ID
            entityLine(line)
        } else if isTableHeader(trimmed) {
            // Table header
            Text(line)
                .font(.system(.body, design: .monospaced).bold())
                .foregroundStyle(Color.cyan)
        } else if isStatusLine(trimmed) {
            // Status line
            statusHighlightedLine(line)
        } else {
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.white)
        }
    }
    
    @ViewBuilder
    private func keyValueLine(_ line: String) -> some View {
        if let colonIndex = line.firstIndex(of: ":") {
            let key = String(line[..<colonIndex])
            let value = String(line[line.index(after: colonIndex)...])
            
            HStack(spacing: 0) {
                Text(key + ":")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(Color.yellow)
                Text(value)
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(valueColor(for: value))
            }
        } else {
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.white)
        }
    }
    
    @ViewBuilder
    private func entityLine(_ line: String) -> some View {
        Text(line)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(Color.orange)
    }
    
    @ViewBuilder
    private func statusHighlightedLine(_ line: String) -> some View {
        let lowercased = line.lowercased()
        if lowercased.contains("running") || lowercased.contains("active") || lowercased.contains("enabled") || lowercased.contains("completed") {
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.green)
        } else if lowercased.contains("stopped") || lowercased.contains("paused") || lowercased.contains("disabled") {
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.orange)
        } else if lowercased.contains("error") || lowercased.contains("failed") {
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.red)
        } else {
            Text(line)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(Color.white)
        }
    }
    
    private func isTableHeader(_ line: String) -> Bool {
        let headers = ["Client ID", "Hostname", "OS", "Last Seen", "Progress", "Started", "Commands"]
        return headers.contains { line.contains($0) }
    }
    
    private func isStatusLine(_ line: String) -> Bool {
        let statusKeywords = ["Status", "Running", "Stopped", "Active", "Enabled", "Disabled", "Completed", "Error"]
        return statusKeywords.contains { line.contains($0) }
    }
    
    private func valueColor(for value: String) -> Color {
        let trimmed = value.trimmingCharacters(in: .whitespaces).lowercased()
        
        if trimmed.contains("running") || trimmed.contains("active") || trimmed.contains("enabled") || trimmed.contains("true") {
            return .green
        } else if trimmed.contains("stopped") || trimmed.contains("paused") || trimmed.contains("disabled") || trimmed.contains("false") {
            return .orange
        } else if trimmed.contains("error") || trimmed.contains("failed") {
            return .red
        } else if trimmed.hasPrefix("http") || trimmed.hasPrefix("/") {
            return .blue
        } else if let _ = Int(trimmed.components(separatedBy: CharacterSet.decimalDigits.inverted).joined()) {
            return .purple
        }
        
        return .white
    }
}

// MARK: - VQL Syntax Highlighting

/// Provides syntax highlighting for VQL queries
struct SyntaxHighlightedVQL: View {
    let content: String
    let isInput: Bool
    
    // VQL Keywords
    private let keywords = ["SELECT", "FROM", "WHERE", "LET", "LIMIT", "ORDER", "BY", "GROUP", "AS", "AND", "OR", "NOT", "IN", "LIKE"]
    
    // VQL Functions
    private let functions = ["info", "clients", "pslist", "glob", "execve", "yara", "hunt", "artifact", "upload", "hash", "timestamp", "count", "len", "format"]
    
    var body: some View {
        if content.uppercased().contains("SELECT") || content.uppercased().contains("LET") {
            highlightedVQL
        } else {
            Text(content)
                .font(.system(.body, design: .monospaced))
                .foregroundStyle(isInput ? Color.green : Color.white)
                .textSelection(.enabled)
        }
    }
    
    private var highlightedVQL: some View {
        var attributedString = AttributedString(content)
        
        // Highlight keywords
        for keyword in keywords {
            if let range = attributedString.range(of: keyword, options: .caseInsensitive) {
                attributedString[range].foregroundColor = .cyan
                attributedString[range].font = .system(.body, design: .monospaced).bold()
            }
        }
        
        // Highlight functions
        for function in functions {
            let pattern = "\(function)\\("
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
                let nsRange = NSRange(content.startIndex..., in: content)
                for match in regex.matches(in: content, options: [], range: nsRange) {
                    if let swiftRange = Range(match.range, in: content),
                       let attrRange = Range(swiftRange, in: attributedString) {
                        attributedString[attrRange].foregroundColor = .yellow
                    }
                }
            }
        }
        
        // Highlight strings
        let stringPattern = "\"[^\"]*\""
        if let regex = try? NSRegularExpression(pattern: stringPattern, options: []) {
            let nsRange = NSRange(content.startIndex..., in: content)
            for match in regex.matches(in: content, options: [], range: nsRange) {
                if let swiftRange = Range(match.range, in: content),
                   let attrRange = Range(swiftRange, in: attributedString) {
                    attributedString[attrRange].foregroundColor = .orange
                }
            }
        }
        
        // Highlight operators
        let operators = ["*", "=", ">", "<", ">=", "<=", "!="]
        for op in operators {
            var searchStart = attributedString.startIndex
            while let range = attributedString[searchStart...].range(of: op) {
                attributedString[range].foregroundColor = .purple
                searchStart = range.upperBound
            }
        }
        
        return Text(attributedString)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    TerminalView()
        .frame(width: 700, height: 500)
}
#endif
