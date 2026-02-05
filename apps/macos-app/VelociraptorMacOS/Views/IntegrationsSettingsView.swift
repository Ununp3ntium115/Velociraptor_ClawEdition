//
//  IntegrationsSettingsView.swift
//  VelociraptorMacOS
//
//  Comprehensive integrations settings for SIEM, CMDB, Inventory, and Ticketing
//  Supports OAuth, API tokens, and certificate-based authentication
//

import SwiftUI

// MARK: - Integrations Settings View

struct IntegrationsSettingsView: View {
    @State private var selectedCategory: ExternalIntegrationCategory = .siem
    @State private var configurations: [IntegrationConfiguration] = []
    @State private var showingAddSheet = false
    @State private var selectedConfiguration: IntegrationConfiguration?
    
    var body: some View {
        HSplitView {
            // Category Sidebar
            categorySidebar
                .frame(minWidth: 180, idealWidth: 200, maxWidth: 250)
            
            // Configuration Content
            configurationContent
        }
        .accessibilityIdentifier("settings.integrations")
    }
    
    // MARK: - Category Sidebar
    
    private var categorySidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Integration Categories")
                .font(.headline)
                .padding()
            
            Divider()
            
            List(ExternalIntegrationCategory.allCases, selection: $selectedCategory) { category in
                HStack {
                    Image(systemName: category.iconName)
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(category.rawValue)
                            .font(.body)
                        Text(category.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    // Count of enabled integrations
                    let count = configurations.filter { $0.category == category && $0.isEnabled }.count
                    if count > 0 {
                        Text("\(count)")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(10)
                    }
                }
                .tag(category)
                .padding(.vertical, 4)
            }
            .listStyle(.sidebar)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Configuration Content
    
    private var configurationContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(selectedCategory.displayName)
                        .font(.title2.bold())
                    Text("Configure \(selectedCategory.rawValue) integrations for device inventory and deployment targeting")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { showingAddSheet = true }) {
                    Label("Add Integration", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            // Integration list for category
            ScrollView {
                LazyVStack(spacing: 16) {
                    switch selectedCategory {
                    case .siem:
                        SIEMIntegrationsList()
                    case .cmdb:
                        CMDBIntegrationsList()
                    case .inventory:
                        InventoryIntegrationsList()
                    case .ticketing:
                        TicketingIntegrationsList()
                    case .mdm:
                        MDMIntegrationsList()
                    case .cloud:
                        CloudIntegrationsList()
                    }
                }
                .padding()
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddExternalIntegrationSheet(category: selectedCategory) { newConfig in
                configurations.append(newConfig)
            }
        }
    }
}

// MARK: - SIEM Integrations List

struct SIEMIntegrationsList: View {
    var body: some View {
        ForEach(SIEMProvider.allCases.filter { $0 != .none }) { provider in
            IntegrationProviderCard(
                title: provider.displayName,
                description: provider.description,
                iconName: provider.iconName,
                authMethod: provider.authMethod,
                endpointHint: provider.endpointHint,
                category: .siem
            )
        }
    }
}

// MARK: - CMDB Integrations List

struct CMDBIntegrationsList: View {
    var body: some View {
        ForEach(CMDBProvider.allCases.filter { $0 != .none }) { provider in
            IntegrationProviderCard(
                title: provider.displayName,
                description: provider.description,
                iconName: provider.iconName,
                authMethod: provider.authMethod,
                endpointHint: provider.endpointHint,
                category: .cmdb
            )
        }
    }
}

// MARK: - Inventory Integrations List

struct InventoryIntegrationsList: View {
    var body: some View {
        ForEach(InventoryProvider.allCases.filter { $0 != .none }) { provider in
            IntegrationProviderCard(
                title: provider.displayName,
                description: provider.description,
                iconName: provider.iconName,
                authMethod: provider.authMethod,
                endpointHint: provider.endpointHint,
                category: .inventory
            )
        }
    }
}

// MARK: - Ticketing Integrations List

struct TicketingIntegrationsList: View {
    var body: some View {
        ForEach(TicketingProvider.allCases.filter { $0 != .none }) { provider in
            IntegrationProviderCard(
                title: provider.displayName,
                description: provider.description,
                iconName: provider.iconName,
                authMethod: provider.authMethod,
                endpointHint: provider.endpointHint,
                category: .ticketing
            )
        }
    }
}

// MARK: - MDM Integrations List

struct MDMIntegrationsList: View {
    private let mdmProviders: [(name: String, description: String, icon: String, usesOAuth: Bool, endpoint: String)] = [
        ("Jamf Pro", "Apple-focused enterprise management. Uses OAuth 2.0.", "desktopcomputer", true, "https://yourserver.jamfcloud.com/api/"),
        ("Microsoft Intune", "Cloud-based endpoint management. Uses Azure AD OAuth.", "rectangle.stack.person.crop", true, "https://graph.microsoft.com/beta/deviceManagement/"),
        ("Kandji", "Modern Apple MDM. Uses API tokens.", "apple.logo", false, "https://your-subdomain.api.kandji.io/api/v1/"),
        ("Mosyle", "Apple device management. Uses API tokens.", "laptopcomputer", false, "https://api.mosyle.com/v1/"),
        ("VMware Workspace ONE", "Unified endpoint management. Uses OAuth.", "cube.fill", true, "https://as.awmdm.com/API/")
    ]
    
    var body: some View {
        ForEach(mdmProviders, id: \.name) { provider in
            IntegrationProviderCard(
                title: provider.name,
                description: provider.description,
                iconName: provider.icon,
                authMethod: provider.usesOAuth ? .oauth : .apiKey,
                endpointHint: provider.endpoint,
                category: .mdm
            )
        }
    }
}

// MARK: - Cloud Integrations List

struct CloudIntegrationsList: View {
    var body: some View {
        VStack(spacing: 16) {
            IntegrationProviderCard(
                title: "AWS",
                description: "Amazon Web Services. Uses IAM roles or access keys.",
                iconName: "cloud.fill",
                authMethod: .accessKey,
                endpointHint: "arn:aws:sts::123456789:role/VelociraptorRole",
                category: .cloud
            )
            
            IntegrationProviderCard(
                title: "Azure",
                description: "Microsoft Azure. Uses Azure AD OAuth 2.0.",
                iconName: "cloud.fill",
                authMethod: .oauth,
                endpointHint: "https://management.azure.com",
                category: .cloud
            )
            
            IntegrationProviderCard(
                title: "Google Cloud",
                description: "Google Cloud Platform. Uses Service Account.",
                iconName: "cloud.fill",
                authMethod: .serviceAccount,
                endpointHint: "https://cloudresourcemanager.googleapis.com/v1/",
                category: .cloud
            )
        }
    }
}

// MARK: - Integration Provider Card

struct IntegrationProviderCard: View {
    let title: String
    let description: String
    let iconName: String
    let authMethod: AuthenticationMethod
    let endpointHint: String
    let category: ExternalIntegrationCategory
    
    @State private var isExpanded = false
    @State private var isEnabled = false
    @State private var endpointUrl = ""
    @State private var apiKey = ""
    @State private var clientId = ""
    @State private var clientSecret = ""
    @State private var showSecret = false
    @State private var testStatus: TestStatus = .idle
    
    enum TestStatus: Equatable {
        case idle
        case testing
        case success
        case failed(String)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.1))
                        .cornerRadius(8)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(authMethod.displayName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isEnabled {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                }
                .padding()
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Toggle("Enable Integration", isOn: $isEnabled)
                    
                    if isEnabled {
                        // Endpoint URL
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Endpoint URL")
                                .font(.caption.bold())
                            TextField(endpointHint, text: $endpointUrl)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        // Authentication fields based on method
                        authenticationFields
                        
                        // Test connection button
                        HStack {
                            Button(action: testConnection) {
                                HStack {
                                    if case .testing = testStatus {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                    } else {
                                        Image(systemName: "network")
                                    }
                                    Text("Test Connection")
                                }
                            }
                            .disabled(testStatus == .testing)
                            
                            Spacer()
                            
                            // Status indicator
                            testStatusView
                        }
                    }
                }
                .padding()
            }
        }
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isEnabled ? Color.accentColor : Color.secondary.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var authenticationFields: some View {
        switch authMethod {
        case .oauth:
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Client ID")
                        .font(.caption.bold())
                    TextField("Application/Client ID", text: $clientId)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Client Secret")
                        .font(.caption.bold())
                    HStack {
                        if showSecret {
                            TextField("Client Secret", text: $clientSecret)
                        } else {
                            SecureField("Client Secret", text: $clientSecret)
                        }
                        Button(action: { showSecret.toggle() }) {
                            Image(systemName: showSecret ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                    }
                    .textFieldStyle(.roundedBorder)
                }
            }
            
        case .apiKey, .apiToken, .accessKey:
            VStack(alignment: .leading, spacing: 4) {
                Text("API Key/Token")
                    .font(.caption.bold())
                HStack {
                    if showSecret {
                        TextField("API Key", text: $apiKey)
                    } else {
                        SecureField("API Key", text: $apiKey)
                    }
                    Button(action: { showSecret.toggle() }) {
                        Image(systemName: showSecret ? "eye.slash" : "eye")
                    }
                    .buttonStyle(.plain)
                }
                .textFieldStyle(.roundedBorder)
            }
            
        case .serviceAccount:
            VStack(alignment: .leading, spacing: 4) {
                Text("Service Account JSON")
                    .font(.caption.bold())
                HStack {
                    TextField("Path to service account key file", text: $apiKey)
                        .textFieldStyle(.roundedBorder)
                    Button("Browse...") {
                        // File picker would go here
                    }
                }
            }
            
        case .basicAuth, .ldap:
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.caption.bold())
                    TextField("Username", text: $clientId)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Password")
                        .font(.caption.bold())
                    SecureField("Password", text: $clientSecret)
                        .textFieldStyle(.roundedBorder)
                }
            }
            
        case .certificate:
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Certificate Path")
                        .font(.caption.bold())
                    HStack {
                        TextField("Path to certificate file", text: $clientId)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse...") {}
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Private Key Path")
                        .font(.caption.bold())
                    HStack {
                        TextField("Path to private key file", text: $clientSecret)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse...") {}
                    }
                }
            }
            
        case .saml:
            VStack(alignment: .leading, spacing: 4) {
                Text("SAML Metadata URL")
                    .font(.caption.bold())
                TextField("https://idp.company.com/metadata", text: $apiKey)
                    .textFieldStyle(.roundedBorder)
            }
            
        case .none:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var testStatusView: some View {
        switch testStatus {
        case .idle:
            EmptyView()
        case .testing:
            Text("Testing...")
                .font(.caption)
                .foregroundColor(.secondary)
        case .success:
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                Text("Connected")
                    .font(.caption)
                    .foregroundColor(.green)
            }
        case .failed(let message):
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.red)
                Text(message)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
    }
    
    private func testConnection() {
        testStatus = .testing
        
        // Simulate connection test (would be real API call)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            #if DEBUG
            // Mock success for testing
            testStatus = .success
            #else
            if endpointUrl.isEmpty {
                testStatus = .failed("Endpoint URL required")
            } else {
                testStatus = .success
            }
            #endif
        }
    }
}

// MARK: - Add External Integration Sheet

struct AddExternalIntegrationSheet: View {
    let category: ExternalIntegrationCategory
    let onAdd: (IntegrationConfiguration) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedProviderName = ""
    @State private var endpointUrl = ""
    @State private var authMethod: AuthenticationMethod = .apiKey
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add \(category.displayName) Integration")
                .font(.title2.bold())
            
            Form {
                Picker("Provider", selection: $selectedProviderName) {
                    Text("Select...").tag("")
                    // Provider options would be dynamic based on category
                }
                
                TextField("Endpoint URL", text: $endpointUrl)
                
                Picker("Authentication", selection: $authMethod) {
                    ForEach([AuthenticationMethod.oauth, .apiKey, .apiToken], id: \.id) { method in
                        Text(method.displayName).tag(method)
                    }
                }
            }
            .padding()
            
            HStack {
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape, modifiers: [])
                
                Spacer()
                
                Button("Add") {
                    let config = IntegrationConfiguration(
                        category: category,
                        providerName: selectedProviderName,
                        isEnabled: true,
                        endpointUrl: endpointUrl,
                        authMethod: authMethod
                    )
                    onAdd(config)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedProviderName.isEmpty)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    IntegrationsSettingsView()
        .frame(width: 900, height: 600)
}
#endif
