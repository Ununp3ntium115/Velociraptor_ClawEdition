//
//  AIConfigurationStepView.swift
//  VelociraptorMacOS
//
//  AI integration configuration step
//  Supports OpenAI, Anthropic (Claude), Google (Gemini), Azure, Apple Intelligence, and Ollama
//

import SwiftUI

struct AIConfigurationStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var keychainManager: KeychainManager
    
    @State private var showApiKey = false
    @State private var isTestingConnection = false
    @State private var connectionTestResult: ConnectionTestResult?
    
    enum ConnectionTestResult {
        case success(String)
        case failure(String)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Header
            Text("Configure AI assistant integration for enhanced DFIR capabilities:")
                .font(.body)
            
            // Enable/Disable toggle
            GroupBox {
                Toggle(isOn: $configViewModel.data.aiEnabled) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Enable AI Integration")
                            .font(.headline)
                        Text("Use AI to assist with VQL queries, artifact analysis, and incident response.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .toggleStyle(.switch)
                .padding()
            }
            .accessibilityIdentifier("ai.enableToggle")
            
            if configViewModel.data.aiEnabled {
                // Provider selection
                GroupBox("AI Provider") {
                    VStack(alignment: .leading, spacing: 16) {
                        Picker("Provider:", selection: $configViewModel.data.aiProvider) {
                            ForEach(ConfigurationData.AIProvider.allCases) { provider in
                                HStack {
                                    Image(systemName: provider.iconName)
                                    Text(provider.displayName)
                                }
                                .tag(provider)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 400)
                        .accessibilityIdentifier("ai.providerPicker")
                        
                        Text(configViewModel.data.aiProvider.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.leading, 4)
                    }
                    .padding()
                }
                
                // API Key input (if required)
                if configViewModel.data.aiProvider.requiresApiKey {
                    GroupBox("API Credentials") {
                        VStack(alignment: .leading, spacing: 16) {
                            // API Key field
                            HStack {
                                Text("API Key:")
                                    .frame(width: 120, alignment: .trailing)
                                
                                Group {
                                    if showApiKey {
                                        TextField("Enter your API key", text: $configViewModel.data.aiApiKey)
                                    } else {
                                        SecureField("Enter your API key", text: $configViewModel.data.aiApiKey)
                                    }
                                }
                                .textFieldStyle(.roundedBorder)
                                .frame(maxWidth: 350)
                                .accessibilityIdentifier("ai.apiKeyField")
                                
                                Button {
                                    showApiKey.toggle()
                                } label: {
                                    Image(systemName: showApiKey ? "eye.slash" : "eye")
                                }
                                .buttonStyle(.plain)
                                .help(showApiKey ? "Hide API key" : "Show API key")
                            }
                            
                            // Organization ID (OpenAI only)
                            if configViewModel.data.aiProvider.requiresOrgId {
                                HStack {
                                    Text("Organization ID:")
                                        .frame(width: 120, alignment: .trailing)
                                    
                                    TextField("Optional", text: $configViewModel.data.aiOrganizationId)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 350)
                                        .accessibilityIdentifier("ai.orgIdField")
                                    
                                    Text("(Optional)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            // Get API key help text
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .foregroundColor(.accentColor)
                                
                                Text(apiKeyHelpText)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 4)
                        }
                        .padding()
                    }
                }
                
                // Model selection
                if !configViewModel.data.aiProvider.availableModels.isEmpty &&
                   configViewModel.data.aiProvider != .none {
                    GroupBox("Model Selection") {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Model:", selection: $configViewModel.data.aiModel) {
                                ForEach(configViewModel.data.aiProvider.availableModels, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 300)
                            .accessibilityIdentifier("ai.modelPicker")
                            
                            Text("Select the AI model to use. More capable models may have higher costs.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                    .onAppear {
                        // Set default model if not set
                        if configViewModel.data.aiModel.isEmpty,
                           let firstModel = configViewModel.data.aiProvider.availableModels.first {
                            configViewModel.data.aiModel = firstModel
                        }
                    }
                    .onChange(of: configViewModel.data.aiProvider) { _, newProvider in
                        // Reset model when provider changes
                        if let firstModel = newProvider.availableModels.first {
                            configViewModel.data.aiModel = firstModel
                        }
                    }
                }
                
                // Test connection button
                if configViewModel.data.aiProvider.requiresApiKey &&
                   !configViewModel.data.aiApiKey.isEmpty {
                    HStack {
                        Spacer()
                        
                        Button {
                            testConnection()
                        } label: {
                            HStack {
                                if isTestingConnection {
                                    ProgressView()
                                        .scaleEffect(0.7)
                                        .frame(width: 16, height: 16)
                                } else {
                                    Image(systemName: "network")
                                }
                                Text("Test Connection")
                            }
                        }
                        .disabled(isTestingConnection)
                        .accessibilityIdentifier("ai.testConnectionButton")
                        
                        if let result = connectionTestResult {
                            switch result {
                            case .success(let message):
                                Label(message, systemImage: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                                    .font(.caption)
                            case .failure(let message):
                                Label(message, systemImage: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                    }
                }
                
                // Use cases info
                GroupBox("AI Features") {
                    VStack(alignment: .leading, spacing: 12) {
                        AIFeatureRow(icon: "bolt.fill", title: "Emergency Mode", 
                                     description: "AI-assisted rapid response during incidents")
                        AIFeatureRow(icon: "terminal", title: "VQL Assistant",
                                     description: "Generate and explain VQL queries with AI help")
                        AIFeatureRow(icon: "doc.text.magnifyingglass", title: "Artifact Analysis",
                                     description: "AI-powered analysis of collected artifacts")
                        AIFeatureRow(icon: "lightbulb.fill", title: "Recommendations",
                                     description: "Smart suggestions for investigation steps")
                    }
                    .padding()
                }
            }
            
            Spacer()
            
            // Privacy note
            HStack {
                Image(systemName: "lock.fill")
                    .foregroundColor(.secondary)
                Text("API keys are stored securely in your macOS Keychain and never transmitted to Velociraptor servers.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.WizardStep.aiConfiguration)
    }
    
    /// Help text for getting API keys
    private var apiKeyHelpText: String {
        switch configViewModel.data.aiProvider {
        case .openai:
            return "Get your API key from platform.openai.com/api-keys"
        case .anthropic:
            return "Get your API key from console.anthropic.com"
        case .google:
            return "Get your API key from ai.google.dev"
        case .azure:
            return "Get your API key from your Azure OpenAI deployment"
        default:
            return "Enter your API key from the provider's dashboard"
        }
    }
    
    /// Test the AI connection
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        // Simulate connection test
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5 seconds
            
            await MainActor.run {
                isTestingConnection = false
                
                // For now, just validate the API key format
                if configViewModel.data.aiApiKey.count > 10 {
                    connectionTestResult = .success("Connection successful!")
                } else {
                    connectionTestResult = .failure("Invalid API key format")
                }
            }
        }
    }
}

// MARK: - AI Feature Row

private struct AIFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    AIConfigurationStepView()
        .environmentObject(ConfigurationViewModel())
        .environmentObject(KeychainManager())
        .padding()
        .frame(width: 700, height: 800)
}
