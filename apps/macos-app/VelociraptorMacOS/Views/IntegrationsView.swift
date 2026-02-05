//
//  IntegrationsView.swift
//  VelociraptorMacOS
//
//  External integrations management (SIEM, SOAR, ticketing)
//  Implements Gap 0x0D: Integrations
//

import SwiftUI

// MARK: - Integrations View

/// Main integrations management interface
struct IntegrationsView: View {
    @StateObject private var viewModel = IntegrationsViewModel()
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                IntegrationsHeader(viewModel: viewModel)
                
                // Connected integrations
                ConnectedIntegrationsSection(viewModel: viewModel)
                
                // Available integrations
                AvailableIntegrationsSection(viewModel: viewModel)
                
                // Webhook endpoints
                WebhooksSection(viewModel: viewModel)
            }
            .padding()
        }
        .navigationTitle("Integrations")
        .toolbar {
            IntegrationsToolbar(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showConfigureSheet) {
            if let integration = viewModel.selectedIntegration {
                ConfigureIntegrationSheet(integration: integration, viewModel: viewModel)
            }
        }
        .sheet(isPresented: $viewModel.showWebhookSheet) {
            AddWebhookSheet(viewModel: viewModel)
        }
        .accessibilityIdentifier("integrations_view")
    }
}

// MARK: - Header

struct IntegrationsHeader: View {
    @ObservedObject var viewModel: IntegrationsViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("External Integrations")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Connect Velociraptor to your security ecosystem")
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 16) {
                StatBadge(
                    value: "\(viewModel.connectedCount)",
                    label: "Connected",
                    color: .green
                )
                StatBadge(
                    value: "\(viewModel.webhooks.count)",
                    label: "Webhooks",
                    color: .blue
                )
            }
        }
    }
}

struct StatBadge: View {
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(color)
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(width: 80)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Connected Integrations Section

struct ConnectedIntegrationsSection: View {
    @ObservedObject var viewModel: IntegrationsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Connected")
                .font(.headline)
            
            if viewModel.connectedIntegrations.isEmpty {
                HStack {
                    Image(systemName: "link.circle")
                        .font(.title)
                        .foregroundColor(.secondary)
                    Text("No integrations connected yet")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(viewModel.connectedIntegrations) { integration in
                        ConnectedIntegrationCard(
                            integration: integration,
                            viewModel: viewModel
                        )
                    }
                }
            }
        }
    }
}

struct ConnectedIntegrationCard: View {
    let integration: Integration
    @ObservedObject var viewModel: IntegrationsViewModel
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: integration.type.icon)
                    .font(.title2)
                    .foregroundColor(integration.type.color)
                    .frame(width: 40, height: 40)
                    .background(integration.type.color.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(integration.name)
                        .font(.headline)
                    Text(integration.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                IntegrationStatusIndicator(status: integration.status)
            }
            
            // Connection info
            VStack(alignment: .leading, spacing: 4) {
                if let url = integration.endpoint {
                    HStack {
                        Image(systemName: "link")
                        Text(url)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                if let lastSync = integration.lastSync {
                    HStack {
                        Image(systemName: "clock")
                        Text("Last sync: \(lastSync, style: .relative) ago")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Configure") {
                    viewModel.selectedIntegration = integration
                    viewModel.showConfigureSheet = true
                }
                .buttonStyle(.borderless)
                
                Button("Test") {
                    Task { await viewModel.testConnection(integration) }
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Button("Disconnect") {
                    viewModel.disconnectIntegration(integration)
                }
                .buttonStyle(.borderless)
                .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? integration.type.color : Color.clear, lineWidth: 2)
        )
        .onHover { isHovered = $0 }
        .accessibilityIdentifier("connected_integration_\(integration.id)")
    }
}

struct IntegrationStatusIndicator: View {
    let status: IntegrationStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            Text(status.displayName)
                .font(.caption)
        }
    }
}

// MARK: - Available Integrations Section

struct AvailableIntegrationsSection: View {
    @ObservedObject var viewModel: IntegrationsViewModel
    @State private var selectedCategory: IntegrationType?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Available Integrations")
                    .font(.headline)
                
                Spacer()
                
                // Category filter
                Picker("Category", selection: $selectedCategory) {
                    Text("All").tag(nil as IntegrationType?)
                    ForEach(IntegrationType.allCases) { type in
                        Text(type.displayName).tag(type as IntegrationType?)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 150)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(viewModel.availableIntegrations(category: selectedCategory)) { template in
                    AvailableIntegrationCard(
                        template: template,
                        viewModel: viewModel
                    )
                }
            }
        }
    }
}

struct AvailableIntegrationCard: View {
    let template: IntegrationTemplate
    @ObservedObject var viewModel: IntegrationsViewModel
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: template.type.icon)
                    .font(.title2)
                    .foregroundColor(template.type.color)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(template.name)
                        .font(.headline)
                    Text(template.type.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Text(template.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Spacer()
            
            Button("Connect") {
                viewModel.connectIntegration(template: template)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(height: 150)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onHover { isHovered = $0 }
        .accessibilityIdentifier("available_integration_\(template.id)")
    }
}

// MARK: - Webhooks Section

struct WebhooksSection: View {
    @ObservedObject var viewModel: IntegrationsViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Webhook Endpoints")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.showWebhookSheet = true }) {
                    Label("Add Webhook", systemImage: "plus")
                }
            }
            
            if viewModel.webhooks.isEmpty {
                HStack {
                    Image(systemName: "arrow.up.arrow.down.circle")
                        .font(.title)
                        .foregroundColor(.secondary)
                    VStack(alignment: .leading) {
                        Text("No webhooks configured")
                            .foregroundColor(.secondary)
                        Text("Webhooks allow external systems to receive events from Velociraptor")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
            } else {
                VStack(spacing: 8) {
                    ForEach(viewModel.webhooks) { webhook in
                        WebhookRow(webhook: webhook, viewModel: viewModel)
                    }
                }
            }
        }
    }
}

struct WebhookRow: View {
    let webhook: Webhook
    @ObservedObject var viewModel: IntegrationsViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(webhook.name)
                    .font(.headline)
                
                HStack {
                    Text(webhook.url)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                    
                    Text("•")
                    
                    Text(webhook.eventsDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { webhook.isEnabled },
                set: { viewModel.toggleWebhook(webhook, enabled: $0) }
            ))
            .labelsHidden()
            
            Menu {
                Button("Test") {
                    Task { await viewModel.testWebhook(webhook) }
                }
                Button("Edit") {
                    viewModel.editWebhook(webhook)
                }
                Divider()
                Button("Delete", role: .destructive) {
                    viewModel.deleteWebhook(webhook)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .accessibilityIdentifier("webhook_\(webhook.id)")
    }
}

// MARK: - Toolbar

struct IntegrationsToolbar: ToolbarContent {
    @ObservedObject var viewModel: IntegrationsViewModel
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { Task { await viewModel.refreshAll() } }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
        }
    }
}

// MARK: - Configure Integration Sheet

struct ConfigureIntegrationSheet: View {
    let integration: Integration
    @ObservedObject var viewModel: IntegrationsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String
    @State private var endpoint: String
    @State private var apiKey: String
    @State private var username: String
    @State private var password: String
    @State private var syncInterval: Int
    @State private var enabledEvents: Set<IntegrationEvent>
    
    init(integration: Integration, viewModel: IntegrationsViewModel) {
        self.integration = integration
        self.viewModel = viewModel
        _name = State(initialValue: integration.name)
        _endpoint = State(initialValue: integration.endpoint ?? "")
        _apiKey = State(initialValue: "")
        _username = State(initialValue: "")
        _password = State(initialValue: "")
        _syncInterval = State(initialValue: 60)
        _enabledEvents = State(initialValue: Set(integration.enabledEvents))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: integration.type.icon)
                    .font(.title)
                    .foregroundColor(integration.type.color)
                Text("Configure \(integration.name)")
                    .font(.headline)
            }
            
            Form {
                Section("Connection") {
                    TextField("Name", text: $name)
                    TextField("Endpoint URL", text: $endpoint)
                }
                
                Section("Authentication") {
                    SecureField("API Key", text: $apiKey)
                    TextField("Username", text: $username)
                    SecureField("Password", text: $password)
                }
                
                Section("Sync Settings") {
                    Picker("Sync Interval", selection: $syncInterval) {
                        Text("1 minute").tag(1)
                        Text("5 minutes").tag(5)
                        Text("15 minutes").tag(15)
                        Text("1 hour").tag(60)
                    }
                }
                
                Section("Events") {
                    ForEach(IntegrationEvent.allCases) { event in
                        Toggle(event.displayName, isOn: Binding(
                            get: { enabledEvents.contains(event) },
                            set: { if $0 { enabledEvents.insert(event) } else { enabledEvents.remove(event) } }
                        ))
                    }
                }
            }
            .frame(height: 400)
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Save") {
                    viewModel.updateIntegration(
                        integration,
                        name: name,
                        endpoint: endpoint,
                        events: Array(enabledEvents)
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 500)
        .accessibilityIdentifier("configure_integration_sheet")
    }
}

// MARK: - Add Webhook Sheet

struct AddWebhookSheet: View {
    @ObservedObject var viewModel: IntegrationsViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var url = ""
    @State private var secret = ""
    @State private var selectedEvents: Set<IntegrationEvent> = []
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Webhook")
                .font(.headline)
            
            Form {
                TextField("Name", text: $name)
                TextField("Webhook URL", text: $url)
                SecureField("Secret (optional)", text: $secret)
                
                Section("Events to Send") {
                    ForEach(IntegrationEvent.allCases) { event in
                        Toggle(event.displayName, isOn: Binding(
                            get: { selectedEvents.contains(event) },
                            set: { if $0 { selectedEvents.insert(event) } else { selectedEvents.remove(event) } }
                        ))
                    }
                }
            }
            .frame(height: 350)
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add Webhook") {
                    viewModel.addWebhook(
                        name: name,
                        url: url,
                        secret: secret.isEmpty ? nil : secret,
                        events: Array(selectedEvents)
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || url.isEmpty || selectedEvents.isEmpty)
            }
        }
        .padding()
        .frame(width: 450)
        .accessibilityIdentifier("add_webhook_sheet")
    }
}

// MARK: - Models

enum IntegrationType: String, CaseIterable, Identifiable {
    case siem, soar, ticketing, notification, storage, custom
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .siem: return "SIEM"
        case .soar: return "SOAR"
        case .ticketing: return "Ticketing"
        case .notification: return "Notification"
        case .storage: return "Storage"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .siem: return "shield.checkered"
        case .soar: return "gearshape.2"
        case .ticketing: return "ticket"
        case .notification: return "bell"
        case .storage: return "externaldrive"
        case .custom: return "puzzlepiece"
        }
    }
    
    var color: Color {
        switch self {
        case .siem: return .blue
        case .soar: return .purple
        case .ticketing: return .orange
        case .notification: return .green
        case .storage: return .cyan
        case .custom: return .gray
        }
    }
}

enum IntegrationStatus: String {
    case connected, disconnected, error, syncing
    
    var displayName: String {
        switch self {
        case .connected: return "Connected"
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        case .syncing: return "Syncing"
        }
    }
    
    var color: Color {
        switch self {
        case .connected: return .green
        case .disconnected: return .gray
        case .error: return .red
        case .syncing: return .blue
        }
    }
}

enum IntegrationEvent: String, CaseIterable, Identifiable {
    case huntCreated, huntCompleted, clientOnline, clientOffline, alertGenerated, artifactCollected
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .huntCreated: return "Hunt Created"
        case .huntCompleted: return "Hunt Completed"
        case .clientOnline: return "Client Online"
        case .clientOffline: return "Client Offline"
        case .alertGenerated: return "Alert Generated"
        case .artifactCollected: return "Artifact Collected"
        }
    }
}

struct IntegrationTemplate: Identifiable {
    let id: String
    let name: String
    let type: IntegrationType
    let description: String
    let configFields: [String]
}

struct Integration: Identifiable {
    var id: String
    var name: String
    let type: IntegrationType
    var status: IntegrationStatus
    var endpoint: String?
    var lastSync: Date?
    var enabledEvents: [IntegrationEvent]
}

struct Webhook: Identifiable {
    let id: String
    var name: String
    var url: String
    var secret: String?
    var events: [IntegrationEvent]
    var isEnabled: Bool
    var lastTriggered: Date?
    
    var eventsDescription: String {
        if events.count == IntegrationEvent.allCases.count {
            return "All events"
        } else {
            return "\(events.count) events"
        }
    }
}

// MARK: - View Model

@MainActor
class IntegrationsViewModel: ObservableObject {
    @Published var integrations: [Integration] = Integration.sampleIntegrations
    @Published var webhooks: [Webhook] = Webhook.sampleWebhooks
    
    @Published var selectedIntegration: Integration?
    @Published var showConfigureSheet = false
    @Published var showWebhookSheet = false
    
    let templates: [IntegrationTemplate] = IntegrationTemplate.allTemplates
    
    var connectedIntegrations: [Integration] {
        integrations.filter { $0.status == .connected || $0.status == .syncing }
    }
    
    var connectedCount: Int {
        connectedIntegrations.count
    }
    
    func availableIntegrations(category: IntegrationType?) -> [IntegrationTemplate] {
        let connected = Set(integrations.map { $0.name })
        var available = templates.filter { !connected.contains($0.name) }
        
        if let category = category {
            available = available.filter { $0.type == category }
        }
        
        return available
    }
    
    func connectIntegration(template: IntegrationTemplate) {
        let integration = Integration(
            id: UUID().uuidString,
            name: template.name,
            type: template.type,
            status: .connected,
            endpoint: nil,
            lastSync: Date(),
            enabledEvents: IntegrationEvent.allCases
        )
        integrations.append(integration)
        selectedIntegration = integration
        showConfigureSheet = true
    }
    
    func disconnectIntegration(_ integration: Integration) {
        integrations.removeAll { $0.id == integration.id }
    }
    
    func updateIntegration(_ integration: Integration, name: String, endpoint: String, events: [IntegrationEvent]) {
        guard let index = integrations.firstIndex(where: { $0.id == integration.id }) else { return }
        integrations[index].name = name
        integrations[index].endpoint = endpoint.isEmpty ? nil : endpoint
        integrations[index].enabledEvents = events
    }
    
    func testConnection(_ integration: Integration) async {
        guard let index = integrations.firstIndex(where: { $0.id == integration.id }) else { return }
        integrations[index].status = .syncing
        
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        integrations[index].status = .connected
        integrations[index].lastSync = Date()
    }
    
    func refreshAll() async {
        for i in integrations.indices {
            integrations[i].status = .syncing
        }
        
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        for i in integrations.indices {
            integrations[i].status = .connected
            integrations[i].lastSync = Date()
        }
    }
    
    func addWebhook(name: String, url: String, secret: String?, events: [IntegrationEvent]) {
        let webhook = Webhook(
            id: UUID().uuidString,
            name: name,
            url: url,
            secret: secret,
            events: events,
            isEnabled: true,
            lastTriggered: nil
        )
        webhooks.append(webhook)
    }
    
    func toggleWebhook(_ webhook: Webhook, enabled: Bool) {
        guard let index = webhooks.firstIndex(where: { $0.id == webhook.id }) else { return }
        webhooks[index].isEnabled = enabled
    }
    
    func testWebhook(_ webhook: Webhook) async {
        print("Testing webhook: \(webhook.name)")
    }
    
    func editWebhook(_ webhook: Webhook) {
        // TODO: Edit webhook
    }
    
    func deleteWebhook(_ webhook: Webhook) {
        webhooks.removeAll { $0.id == webhook.id }
    }
}

// MARK: - Sample Data

extension IntegrationTemplate {
    static let allTemplates: [IntegrationTemplate] = [
        // SIEM
        IntegrationTemplate(id: "splunk", name: "Splunk", type: .siem, description: "Forward events and artifacts to Splunk", configFields: ["endpoint", "token"]),
        IntegrationTemplate(id: "elastic", name: "Elastic SIEM", type: .siem, description: "Send data to Elastic Security", configFields: ["endpoint", "apiKey"]),
        IntegrationTemplate(id: "sentinel", name: "Microsoft Sentinel", type: .siem, description: "Integrate with Azure Sentinel", configFields: ["workspaceId", "sharedKey"]),
        IntegrationTemplate(id: "qradar", name: "IBM QRadar", type: .siem, description: "Forward to QRadar SIEM", configFields: ["endpoint", "token"]),
        
        // SOAR
        IntegrationTemplate(id: "xsoar", name: "Cortex XSOAR", type: .soar, description: "Automate response with XSOAR", configFields: ["endpoint", "apiKey"]),
        IntegrationTemplate(id: "phantom", name: "Splunk SOAR", type: .soar, description: "Orchestrate with Splunk SOAR", configFields: ["endpoint", "token"]),
        IntegrationTemplate(id: "swimlane", name: "Swimlane", type: .soar, description: "Connect to Swimlane SOAR", configFields: ["endpoint", "apiKey"]),
        
        // Ticketing
        IntegrationTemplate(id: "servicenow", name: "ServiceNow", type: .ticketing, description: "Create incidents in ServiceNow", configFields: ["instance", "username", "password"]),
        IntegrationTemplate(id: "jira", name: "Jira", type: .ticketing, description: "Create issues in Jira", configFields: ["endpoint", "email", "token"]),
        IntegrationTemplate(id: "pagerduty", name: "PagerDuty", type: .ticketing, description: "Send alerts to PagerDuty", configFields: ["routingKey"]),
        
        // Notification
        IntegrationTemplate(id: "slack", name: "Slack", type: .notification, description: "Send notifications to Slack", configFields: ["webhookUrl"]),
        IntegrationTemplate(id: "teams", name: "Microsoft Teams", type: .notification, description: "Post to Teams channels", configFields: ["webhookUrl"]),
        IntegrationTemplate(id: "email", name: "Email (SMTP)", type: .notification, description: "Send email notifications", configFields: ["server", "port", "username", "password"]),
        
        // Storage
        IntegrationTemplate(id: "s3", name: "AWS S3", type: .storage, description: "Store artifacts in S3", configFields: ["bucket", "accessKey", "secretKey"]),
        IntegrationTemplate(id: "azure-blob", name: "Azure Blob", type: .storage, description: "Store in Azure Blob Storage", configFields: ["account", "container", "key"]),
        IntegrationTemplate(id: "gcs", name: "Google Cloud Storage", type: .storage, description: "Store in GCS", configFields: ["bucket", "credentials"]),
    ]
}

extension Integration {
    static let sampleIntegrations: [Integration] = [
        Integration(
            id: "int-1",
            name: "Splunk",
            type: .siem,
            status: .connected,
            endpoint: "https://splunk.company.com:8088",
            lastSync: Date().addingTimeInterval(-300),
            enabledEvents: [.huntCompleted, .alertGenerated]
        ),
        Integration(
            id: "int-2",
            name: "Slack",
            type: .notification,
            status: .connected,
            endpoint: nil,
            lastSync: Date().addingTimeInterval(-60),
            enabledEvents: [.huntCreated, .huntCompleted, .alertGenerated]
        ),
    ]
}

extension Webhook {
    static let sampleWebhooks: [Webhook] = [
        Webhook(
            id: "wh-1",
            name: "Security Alerts",
            url: "https://api.company.com/security/webhooks/velociraptor",
            secret: "secret123",
            events: [.alertGenerated, .huntCompleted],
            isEnabled: true,
            lastTriggered: Date().addingTimeInterval(-3600)
        ),
    ]
}

// MARK: - Preview

#Preview {
    IntegrationsView()
        .frame(width: 1000, height: 800)
}
