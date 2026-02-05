//
//  AIChatView.swift
//  VelociraptorMacOS
//
//  AI-powered VQL assistance and DFIR chat interface
//  Integrates with configured AI providers for:
//  - VQL query generation and optimization
//  - Artifact analysis assistance
//  - Incident response guidance
//  - Evidence interpretation
//

import SwiftUI

// MARK: - AI Chat Message

struct AIChatMessage: Identifiable, Equatable {
    let id = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    var isLoading: Bool = false
    
    enum MessageRole: Equatable {
        case user
        case assistant
        case system
    }
}

// MARK: - AI Chat View Model

@MainActor
final class AIChatViewModel: ObservableObject {
    @Published var messages: [AIChatMessage] = []
    @Published var inputText: String = ""
    @Published var isLoading: Bool = false
    @Published var selectedProvider: String = "Claude"
    @Published var error: String?
    
    let providers = ["Claude", "OpenAI", "Google", "Apple Intelligence"]
    
    private let systemPrompt = """
    You are an expert DFIR (Digital Forensics and Incident Response) assistant integrated into Velociraptor Claw Edition.
    
    Your capabilities:
    - Generate and optimize VQL (Velociraptor Query Language) queries
    - Analyze forensic artifacts and evidence
    - Guide incident response procedures
    - Explain security findings and IOCs
    - Provide threat hunting recommendations
    
    Always provide:
    - Clear, actionable guidance
    - VQL examples when relevant (format with ```vql code blocks)
    - Safety considerations for forensic integrity
    - References to relevant Velociraptor artifacts
    
    Context: User is running Velociraptor for endpoint forensics and incident response.
    """
    
    init() {
        // Add welcome message
        messages.append(AIChatMessage(
            role: .assistant,
            content: "Welcome to Velociraptor AI Assistant! I can help you with:\n\n• **VQL Queries** - Generate and optimize Velociraptor queries\n• **Artifact Analysis** - Interpret forensic findings\n• **Incident Response** - Guide investigation workflows\n• **Threat Hunting** - Create detection strategies\n\nHow can I assist your investigation today?",
            timestamp: Date()
        ))
    }
    
    func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        
        let userMessage = AIChatMessage(
            role: .user,
            content: inputText,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        let query = inputText
        inputText = ""
        isLoading = true
        
        // Add loading placeholder
        let loadingMessage = AIChatMessage(
            role: .assistant,
            content: "",
            timestamp: Date(),
            isLoading: true
        )
        messages.append(loadingMessage)
        
        Task {
            await generateResponse(for: query)
        }
    }
    
    private func generateResponse(for query: String) async {
        // Simulate AI response (in production, call actual AI API)
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Remove loading message
        if let lastIndex = messages.indices.last, messages[lastIndex].isLoading {
            messages.remove(at: lastIndex)
        }
        
        let response = generateMockResponse(for: query)
        messages.append(AIChatMessage(
            role: .assistant,
            content: response,
            timestamp: Date()
        ))
        
        isLoading = false
    }
    
    private func generateMockResponse(for query: String) -> String {
        let lowercaseQuery = query.lowercased()
        
        if lowercaseQuery.contains("vql") || lowercaseQuery.contains("query") {
            return """
            Here's a VQL query for your request:
            
            ```vql
            SELECT * FROM Artifact.Windows.EventLogs.Evtx(
                startTime=timestamp(epoch=now() - 86400),
                accessor="auto"
            )
            WHERE EventData.LogonType = "10"
            LIMIT 1000
            ```
            
            This query:
            - Collects Windows Event Logs from the last 24 hours
            - Filters for remote logon events (Type 10 = RemoteInteractive)
            - Limits results to 1000 entries
            
            Would you like me to modify this query or explain any part in more detail?
            """
        } else if lowercaseQuery.contains("artifact") || lowercaseQuery.contains("collect") {
            return """
            For forensic collection, I recommend these Velociraptor artifacts:
            
            **Memory Analysis:**
            - `Windows.Memory.Acquisition` - Full memory dump
            - `Generic.Forensic.Timeline` - Timeline analysis
            
            **File System:**
            - `Windows.NTFS.MFT` - Master File Table analysis
            - `Windows.Forensics.Prefetch` - Application execution history
            
            **Registry:**
            - `Windows.Registry.Persistence` - Persistence mechanisms
            - `Windows.Registry.UserAssist` - User activity
            
            Shall I generate a collection pack with these artifacts?
            """
        } else if lowercaseQuery.contains("incident") || lowercaseQuery.contains("response") {
            return """
            ## Incident Response Workflow
            
            **1. Initial Triage**
            - Deploy Velociraptor to affected endpoints
            - Collect volatile data first (memory, network connections)
            
            **2. Evidence Preservation**
            - Create forensic images of critical systems
            - Document chain of custody
            
            **3. Analysis**
            - Hunt for IOCs across endpoints
            - Build timeline of events
            - Identify attack vectors
            
            **4. Containment**
            - Isolate affected systems
            - Block malicious IPs/domains
            
            What phase of the response are you currently in?
            """
        } else if lowercaseQuery.contains("ioc") || lowercaseQuery.contains("indicator") {
            return """
            To hunt for IOCs with Velociraptor:
            
            ```vql
            LET iocs = SELECT * FROM parse_csv(filename="/path/to/iocs.csv")
            
            SELECT * FROM foreach(
                row=iocs,
                query={
                    SELECT * FROM glob(globs=Row.filepath)
                    WHERE hash(path=FullPath).SHA256 = Row.hash
                }
            )
            ```
            
            This query:
            - Loads IOCs from a CSV file
            - Searches for matching files
            - Compares SHA256 hashes
            
            What type of IOCs are you looking for (hashes, IPs, domains)?
            """
        } else {
            return """
            I understand you're asking about: **\(query)**
            
            As your DFIR assistant, I can help with:
            - Writing VQL queries for evidence collection
            - Analyzing artifacts and findings
            - Planning incident response steps
            - Identifying threats and IOCs
            
            Could you provide more details about your specific need? For example:
            - What artifacts are you trying to collect?
            - What behavior are you investigating?
            - What platform are you targeting (Windows, macOS, Linux)?
            """
        }
    }
    
    func clearChat() {
        messages.removeAll()
        messages.append(AIChatMessage(
            role: .assistant,
            content: "Chat cleared. How can I help you with your investigation?",
            timestamp: Date()
        ))
    }
}

// MARK: - AI Chat View

struct AIChatView: View {
    @StateObject private var viewModel = AIChatViewModel()
    @State private var showingSettings = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            chatHeader
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatMessageView(message: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            Divider()
            
            // Input area
            chatInput
        }
        .accessibilityIdentifier("ai.chat.main")
        .sheet(isPresented: $showingSettings) {
            AIChatSettingsSheet(viewModel: viewModel)
        }
    }
    
    // MARK: - Header
    
    private var chatHeader: some View {
        HStack {
            Image(systemName: "brain.head.profile")
                .font(.title2)
                .foregroundStyle(.purple)
            
            VStack(alignment: .leading, spacing: 2) {
                Text("AI Assistant")
                    .font(.headline)
                Text("VQL & DFIR Guidance")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Picker("Provider", selection: $viewModel.selectedProvider) {
                ForEach(viewModel.providers, id: \.self) { provider in
                    Text(provider).tag(provider)
                }
            }
            .pickerStyle(.menu)
            .frame(width: 150)
            
            Button(action: { showingSettings = true }) {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            
            Button(action: viewModel.clearChat) {
                Image(systemName: "trash")
            }
            .buttonStyle(.borderless)
            .help("Clear Chat")
        }
        .padding()
    }
    
    // MARK: - Input
    
    private var chatInput: some View {
        HStack(spacing: 12) {
            TextField("Ask about VQL, artifacts, or incident response...", text: $viewModel.inputText)
                .textFieldStyle(.roundedBorder)
                .onSubmit {
                    viewModel.sendMessage()
                }
                .accessibilityIdentifier("ai.chat.input")
            
            Button(action: viewModel.sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(viewModel.inputText.isEmpty ? .secondary : Color.purple)
            }
            .buttonStyle(.borderless)
            .disabled(viewModel.inputText.isEmpty || viewModel.isLoading)
            .accessibilityIdentifier("ai.chat.send")
        }
        .padding()
    }
}

// MARK: - Chat Message View

struct ChatMessageView: View {
    let message: AIChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if message.role == .user {
                Spacer()
            }
            
            if message.role == .assistant {
                avatarView
            }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if message.isLoading {
                    HStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Thinking...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(bubbleBackground)
                } else {
                    Text(LocalizedStringKey(message.content))
                        .textSelection(.enabled)
                        .padding()
                        .background(bubbleBackground)
                }
                
                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            if message.role == .user {
                userAvatarView
            }
            
            if message.role == .assistant {
                Spacer()
            }
        }
    }
    
    private var avatarView: some View {
        Image(systemName: "brain.head.profile")
            .font(.title3)
            .foregroundStyle(.purple)
            .frame(width: 32, height: 32)
            .background(Color.purple.opacity(0.1))
            .clipShape(Circle())
    }
    
    private var userAvatarView: some View {
        Image(systemName: "person.circle.fill")
            .font(.title3)
            .foregroundStyle(.blue)
            .frame(width: 32, height: 32)
    }
    
    private var bubbleBackground: some View {
        Group {
            if message.role == .user {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.blue.opacity(0.15))
            } else {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.purple.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.purple.opacity(0.2), lineWidth: 1)
                    )
            }
        }
    }
}

// MARK: - AI Chat Settings Sheet

struct AIChatSettingsSheet: View {
    @ObservedObject var viewModel: AIChatViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var apiKey: String = ""
    @State private var modelName: String = "claude-sonnet-4-20250514"
    @State private var temperature: Double = 0.7
    @State private var maxTokens: Int = 4096
    
    var body: some View {
        VStack(spacing: 20) {
            Text("AI Settings")
                .font(.title2.bold())
            
            Form {
                Section("Provider") {
                    Picker("AI Provider", selection: $viewModel.selectedProvider) {
                        ForEach(viewModel.providers, id: \.self) { provider in
                            Text(provider).tag(provider)
                        }
                    }
                }
                
                Section("API Configuration") {
                    SecureField("API Key", text: $apiKey)
                    TextField("Model", text: $modelName)
                }
                
                Section("Parameters") {
                    Slider(value: $temperature, in: 0...1, step: 0.1) {
                        Text("Temperature: \(temperature, specifier: "%.1f")")
                    }
                    
                    Stepper("Max Tokens: \(maxTokens)", value: $maxTokens, in: 256...8192, step: 256)
                }
                
                Section("Context") {
                    Text("System prompt configures the AI for DFIR and VQL assistance.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Save") {
                    // Save settings
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .frame(width: 450, height: 450)
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    AIChatView()
        .frame(width: 600, height: 600)
}
#endif
