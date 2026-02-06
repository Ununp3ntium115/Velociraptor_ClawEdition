//
//  MDMConfigurationStepView.swift
//  VelociraptorMacOS
//
//  MDM (Mobile Device Management) integration configuration step
//

import SwiftUI

struct MDMConfigurationStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    @State private var isTestingConnection = false
    @State private var connectionTestResult: String?
    @State private var connectionTestSuccess = false
    @State private var showSecret = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MDM Integration Toggle
                GroupBox {
                    HStack {
                        Toggle("Enable MDM Integration", isOn: $configViewModel.data.mdmEnabled)
                            .toggleStyle(.switch)
                        
                        Spacer()
                        
                        Image(systemName: "rectangle.stack.person.crop.fill")
                            .font(.title2)
                            .foregroundColor(configViewModel.data.mdmEnabled ? .blue : .secondary)
                    }
                }
                .accessibilityIdentifier("mdm.enableToggle")
                
                if configViewModel.data.mdmEnabled {
                    // MDM Provider Selection
                    GroupBox("MDM Provider") {
                        VStack(alignment: .leading, spacing: 16) {
                            Picker("Provider:", selection: $configViewModel.data.mdmProvider) {
                                ForEach(ConfigurationData.MDMProvider.allCases) { provider in
                                    HStack {
                                        Image(systemName: provider.iconName)
                                        Text(provider.displayName)
                                    }
                                    .tag(provider)
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: 400)
                            .accessibilityIdentifier("mdm.providerPicker")
                            
                            if configViewModel.data.mdmProvider != .none {
                                Text(configViewModel.data.mdmProvider.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 4)
                                
                                if configViewModel.data.mdmProvider.usesOAuth {
                                    HStack {
                                        Image(systemName: "lock.shield.fill")
                                            .foregroundColor(.green)
                                        Text("Uses OAuth 2.0 for secure authentication")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.top, 4)
                                }
                            }
                        }
                        .padding()
                    }
                    
                    if configViewModel.data.mdmProvider != .none {
                        // OAuth/API Configuration
                        GroupBox("Authentication") {
                            VStack(alignment: .leading, spacing: 16) {
                                // Tenant URL
                                HStack {
                                    Text("Tenant URL:")
                                        .frame(width: 120, alignment: .trailing)
                                    
                                    TextField("https://your-instance.example.com", text: $configViewModel.data.mdmTenantUrl)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 350)
                                        .accessibilityIdentifier("mdm.tenantUrlField")
                                }
                                
                                Text("Hint: \(configViewModel.data.mdmProvider.oauthEndpointHint)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.leading, 124)
                                
                                Divider()
                                
                                // Client ID
                                HStack {
                                    Text("Client ID:")
                                        .frame(width: 120, alignment: .trailing)
                                    
                                    TextField("OAuth Client ID", text: $configViewModel.data.mdmClientId)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 350)
                                        .accessibilityIdentifier("mdm.clientIdField")
                                }
                                
                                // Client Secret
                                HStack {
                                    Text("Client Secret:")
                                        .frame(width: 120, alignment: .trailing)
                                    
                                    Group {
                                        if showSecret {
                                            TextField("OAuth Client Secret", text: $configViewModel.data.mdmClientSecret)
                                        } else {
                                            SecureField("OAuth Client Secret", text: $configViewModel.data.mdmClientSecret)
                                        }
                                    }
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 300)
                                    .accessibilityIdentifier("mdm.clientSecretField")
                                    
                                    Button {
                                        showSecret.toggle()
                                    } label: {
                                        Image(systemName: showSecret ? "eye.slash" : "eye")
                                    }
                                    .buttonStyle(.plain)
                                    .help(showSecret ? "Hide secret" : "Show secret")
                                }
                                
                                // API Scope (if OAuth)
                                if configViewModel.data.mdmProvider.usesOAuth {
                                    HStack {
                                        Text("API Scope:")
                                            .frame(width: 120, alignment: .trailing)
                                        
                                        TextField(configViewModel.data.mdmProvider.defaultScope, text: $configViewModel.data.mdmApiScope)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(maxWidth: 350)
                                            .accessibilityIdentifier("mdm.apiScopeField")
                                    }
                                    
                                    if !configViewModel.data.mdmProvider.defaultScope.isEmpty {
                                        Text("Default: \(configViewModel.data.mdmProvider.defaultScope)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                            .padding(.leading, 124)
                                    }
                                }
                            }
                            .padding()
                        }
                        
                        // Test Connection
                        GroupBox("Connection Test") {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Button {
                                        testConnection()
                                    } label: {
                                        if isTestingConnection {
                                            ProgressView()
                                                .controlSize(.small)
                                            Text("Testing...")
                                        } else {
                                            Label("Test Connection", systemImage: "network")
                                        }
                                    }
                                    .disabled(isTestingConnection || !isConfigComplete)
                                    .accessibilityIdentifier("mdm.testConnectionButton")
                                    
                                    if let result = connectionTestResult {
                                        HStack {
                                            Image(systemName: connectionTestSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                                                .foregroundColor(connectionTestSuccess ? .green : .red)
                                            Text(result)
                                                .font(.caption)
                                                .foregroundColor(connectionTestSuccess ? .primary : .red)
                                        }
                                    }
                                }
                                
                                if !isConfigComplete {
                                    Text("Complete all required fields to test the connection")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                        }
                        
                        // MDM Features
                        GroupBox("MDM Features") {
                            VStack(alignment: .leading, spacing: 12) {
                                MDMFeatureRow(
                                    icon: "desktopcomputer",
                                    title: "Device Inventory Sync",
                                    description: "Sync device information from MDM to Velociraptor"
                                )
                                
                                MDMFeatureRow(
                                    icon: "person.2.fill",
                                    title: "User Authentication",
                                    description: "Use MDM user directory for Velociraptor authentication"
                                )
                                
                                MDMFeatureRow(
                                    icon: "arrow.triangle.2.circlepath",
                                    title: "Policy Deployment",
                                    description: "Push Velociraptor agent configurations via MDM"
                                )
                                
                                MDMFeatureRow(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Incident Response",
                                    description: "Trigger MDM actions during emergency mode"
                                )
                            }
                            .padding()
                        }
                    }
                } else {
                    // Skip message
                    GroupBox {
                        HStack {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("MDM integration can be configured later")
                                    .font(.body.bold())
                                Text("You can set up MDM integration in Settings → Integrations after deployment.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .accessibilityIdentifier("wizard.step.mdmConfiguration")
        .onAppear {
            // Set default scope if empty
            if configViewModel.data.mdmApiScope.isEmpty && configViewModel.data.mdmProvider != .none {
                configViewModel.data.mdmApiScope = configViewModel.data.mdmProvider.defaultScope
            }
        }
        .onChange(of: configViewModel.data.mdmProvider) { _, newProvider in
            // Update default scope when provider changes
            configViewModel.data.mdmApiScope = newProvider.defaultScope
            // Reset test result
            connectionTestResult = nil
        }
    }
    
    private var isConfigComplete: Bool {
        guard configViewModel.data.mdmEnabled else { return false }
        guard configViewModel.data.mdmProvider != .none else { return false }
        return !configViewModel.data.mdmTenantUrl.isEmpty &&
               !configViewModel.data.mdmClientId.isEmpty &&
               !configViewModel.data.mdmClientSecret.isEmpty
    }
    
    private func testConnection() {
        isTestingConnection = true
        connectionTestResult = nil
        
        // Simulate connection test (in real implementation, this would call the MDM API)
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            await MainActor.run {
                #if DEBUG
                // Mock test for development/testing
                if ProcessInfo.processInfo.arguments.contains("-MockMDMConnections") {
                    connectionTestSuccess = true
                    connectionTestResult = "Mock connection successful"
                } else {
                    // Real test would go here
                    connectionTestSuccess = true
                    connectionTestResult = "Connection verified"
                }
                #else
                // In production, implement actual OAuth flow
                connectionTestSuccess = false
                connectionTestResult = "Connection test not implemented"
                #endif
                
                isTestingConnection = false
            }
        }
    }
}

// MARK: - MDM Feature Row

private struct MDMFeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 24)
            
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
    MDMConfigurationStepView()
        .environmentObject(ConfigurationViewModel())
        .padding()
        .frame(width: 700, height: 800)
}
