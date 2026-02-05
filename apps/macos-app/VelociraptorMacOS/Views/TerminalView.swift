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
    
    let quickCommands = [
        "status",
        "config show",
        "client list",
        "query",
        "artifact list",
        "hunt create",
        "server info"
    ]
    
    private var process: Process?
    
    init() {
        addSystemLine("Welcome to Velociraptor Claw Edition Terminal")
        addSystemLine("Type 'help' for available commands or use the Quick Commands menu")
        addSystemLine("")
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
                .disabled(!viewModel.isConnected)
                .accessibilityIdentifier("terminal.input")
            
            if viewModel.isExecuting {
                ProgressView()
                    .scaleEffect(0.7)
            }
        }
        .padding()
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Terminal Line View

struct TerminalLineView: View {
    let line: TerminalLine
    
    var body: some View {
        Text(line.content)
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(lineColor)
            .textSelection(.enabled)
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

// MARK: - Preview

#if DEBUG
#Preview {
    TerminalView()
        .frame(width: 700, height: 500)
}
#endif
