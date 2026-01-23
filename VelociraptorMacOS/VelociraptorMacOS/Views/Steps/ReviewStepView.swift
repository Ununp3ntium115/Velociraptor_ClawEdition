//
//  ReviewStepView.swift
//  VelociraptorMacOS
//
//  Configuration review step
//

import SwiftUI

struct ReviewStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    @State private var showYAMLPreview = false
    @State private var isDeploying = false
    @State private var showDeployConfirmation = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review your configuration before deploying:")
                .font(.body)
            
            // Validation status
            if configViewModel.data.isValid {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Configuration is valid")
                            .font(.headline)
                            .foregroundColor(.green)
                        Text("All required fields have been configured correctly.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
                .accessibilityId(AccessibilityIdentifiers.Review.validationStatus)
            } else {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.title2)
                    
                    VStack(alignment: .leading) {
                        Text("Configuration has issues")
                            .font(.headline)
                            .foregroundColor(.orange)
                        Text("Please review the highlighted issues below.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Configuration summary
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ConfigSectionView(title: "Deployment", icon: "server.rack") {
                        ConfigRow("Type", value: configViewModel.data.deploymentType)
                        ConfigRow("Organization", value: configViewModel.data.organizationName)
                    }
                    
                    ConfigSectionView(title: "Certificate", icon: "lock.shield.fill") {
                        ConfigRow("Type", value: configViewModel.data.encryptionType.displayName)
                        if configViewModel.data.encryptionType == .custom {
                            ConfigRow("Certificate", value: configViewModel.data.customCertPath)
                            ConfigRow("Key", value: configViewModel.data.customKeyPath)
                        } else if configViewModel.data.encryptionType == .letsEncrypt {
                            ConfigRow("Domain", value: configViewModel.data.letsEncryptDomain)
                        }
                    }
                    
                    ConfigSectionView(title: "Security", icon: "shield.checkered") {
                        ConfigRow("Environment", value: configViewModel.data.environment.rawValue)
                        ConfigRow("Log Level", value: configViewModel.data.logLevel.rawValue)
                        ConfigRow("TLS 1.2+", value: configViewModel.data.enforceTLS12 ? "Enabled" : "Disabled")
                        ConfigRow("Validate Certs", value: configViewModel.data.validateCertificates ? "Enabled" : "Disabled")
                    }
                    
                    ConfigSectionView(title: "Storage", icon: "externaldrive.fill") {
                        ConfigRow("Datastore", value: configViewModel.data.datastoreDirectory)
                        ConfigRow("Logs", value: configViewModel.data.logsDirectory)
                        ConfigRow("Cache", value: configViewModel.data.cacheDirectory)
                    }
                    
                    ConfigSectionView(title: "Network", icon: "network") {
                        ConfigRow("Frontend", value: "\(configViewModel.data.bindAddress):\(configViewModel.data.bindPort)")
                        ConfigRow("GUI", value: "\(configViewModel.data.guiBindAddress):\(configViewModel.data.guiBindPort)")
                        ConfigRow("API", value: "\(configViewModel.data.apiBindAddress):\(configViewModel.data.apiBindPort)")
                    }
                    
                    ConfigSectionView(title: "Authentication", icon: "person.badge.key.fill") {
                        ConfigRow("Admin User", value: configViewModel.data.adminUsername)
                        ConfigRow("Password", value: String(repeating: "•", count: min(configViewModel.data.adminPassword.count, 12)))
                    }
                    
                    ConfigSectionView(title: "macOS", icon: "apple.logo") {
                        ConfigRow("Launch at Login", value: configViewModel.data.launchAtLogin ? "Yes" : "No")
                        ConfigRow("Use Keychain", value: configViewModel.data.useKeychain ? "Yes" : "No")
                        ConfigRow("Notifications", value: configViewModel.data.enableNotifications ? "Yes" : "No")
                    }
                }
            }
            .frame(maxHeight: 300)
            
            Divider()
            
            // Action buttons
            HStack(spacing: 16) {
                Button {
                    showYAMLPreview = true
                } label: {
                    Label("Preview YAML", systemImage: "doc.text")
                }
                .accessibilityId(AccessibilityIdentifiers.Review.previewYAMLButton)
                
                Button {
                    exportConfiguration()
                } label: {
                    Label("Export Config", systemImage: "square.and.arrow.up")
                }
                .accessibilityId(AccessibilityIdentifiers.Review.exportConfigButton)
                
                Spacer()
                
                Button {
                    showDeployConfirmation = true
                } label: {
                    Label("Deploy Now", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(!configViewModel.data.isValid || isDeploying)
                .accessibilityId(AccessibilityIdentifiers.Review.deployButton)
            }
            
            // Deployment progress
            if isDeploying {
                DeploymentProgressView()
                    .environmentObject(deploymentManager)
                    .accessibilityId(AccessibilityIdentifiers.Review.deploymentProgress)
            }
        }
        .accessibilityId(AccessibilityIdentifiers.WizardStep.review)
        .sheet(isPresented: $showYAMLPreview) {
            YAMLPreviewView(yaml: configViewModel.exportYAML())
                .accessibilityId(AccessibilityIdentifiers.Dialog.yamlPreview)
        }
        .confirmationDialog("Deploy Configuration", isPresented: $showDeployConfirmation) {
            Button("Deploy") {
                startDeployment()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will download Velociraptor, create configuration files, and install the service. Continue?")
        }
    }
    
    private func startDeployment() {
        isDeploying = true
        
        Task {
            do {
                try await deploymentManager.deploy(config: configViewModel.data)
                appState.nextStep()
            } catch {
                appState.displayError(error)
            }
            isDeploying = false
        }
    }
    
    private func exportConfiguration() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.yaml]
        panel.nameFieldStringValue = "velociraptor.config.yaml"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Task {
                    try? await configViewModel.saveConfiguration(to: url)
                }
            }
        }
    }
}

// MARK: - Config Section View

struct ConfigSectionView<Content: View>: View {
    let title: String
    let icon: String
    let content: () -> Content
    
    init(title: String, icon: String, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.icon = icon
        self.content = content
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline.bold())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                content()
            }
            .padding(.leading, 24)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Config Row

struct ConfigRow: View {
    let label: String
    let value: String
    
    init(_ label: String, value: String) {
        self.label = label
        self.value = value
    }
    
    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .trailing)
            
            Text(value)
                .font(.caption.monospaced())
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

// MARK: - YAML Preview View

struct YAMLPreviewView: View {
    let yaml: String
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Configuration Preview")
                    .font(.headline)
                
                Spacer()
                
                Button {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(yaml, forType: .string)
                } label: {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                Text(yaml)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
        }
        .frame(width: 600, height: 500)
    }
}

// MARK: - Deployment Progress View

struct DeploymentProgressView: View {
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                ProgressView()
                    .controlSize(.small)
                
                Text(deploymentManager.statusMessage)
                    .font(.subheadline)
            }
            
            ProgressView(value: deploymentManager.progress)
                .progressViewStyle(.linear)
            
            // Step status
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                ForEach(DeploymentManager.DeploymentStep.allCases) { step in
                    DeploymentStepIndicator(
                        step: step,
                        status: deploymentManager.stepStatus[step] ?? .pending
                    )
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct DeploymentStepIndicator: View {
    let step: DeploymentManager.DeploymentStep
    let status: DeploymentManager.StepStatus
    
    var body: some View {
        HStack(spacing: 4) {
            statusIcon
                .font(.caption)
            
            Text(step.rawValue)
                .font(.caption2)
                .lineLimit(1)
        }
        .foregroundColor(statusColor)
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        switch status {
        case .pending:
            Image(systemName: "circle")
        case .inProgress:
            ProgressView()
                .controlSize(.mini)
        case .completed:
            Image(systemName: "checkmark.circle.fill")
        case .failed:
            Image(systemName: "xmark.circle.fill")
        case .skipped:
            Image(systemName: "minus.circle")
        }
    }
    
    private var statusColor: Color {
        switch status {
        case .pending: return .secondary
        case .inProgress: return .accentColor
        case .completed: return .green
        case .failed: return .red
        case .skipped: return .secondary
        }
    }
}

#Preview {
    ReviewStepView()
        .environmentObject(ConfigurationViewModel())
        .environmentObject(AppState())
        .environmentObject(DeploymentManager())
        .padding()
        .frame(width: 700)
}
