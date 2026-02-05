//
//  CompleteStepView.swift
//  VelociraptorMacOS
//
//  Deployment complete step
//

import SwiftUI

struct CompleteStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    @State private var copied = false
    
    var body: some View {
        VStack(spacing: 32) {
            // Success indicator
            VStack(spacing: 16) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .accessibilityId(AccessibilityIdentifiers.Complete.successIcon)
                
                Text("Deployment Complete!")
                    .font(.title.bold())
                
                Text("Velociraptor has been successfully deployed on your Mac.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Divider()
            
            // Access information
            GroupBox("Access Information") {
                VStack(alignment: .leading, spacing: 16) {
                    AccessInfoRow(
                        icon: "globe",
                        label: "Web Interface",
                        value: "https://\(configViewModel.data.guiBindAddress):\(configViewModel.data.guiBindPort)",
                        isLink: true
                    )
                    
                    AccessInfoRow(
                        icon: "person.fill",
                        label: "Username",
                        value: configViewModel.data.adminUsername
                    )
                    
                    AccessInfoRow(
                        icon: "key.fill",
                        label: "Password",
                        value: "••••••••",
                        note: "Use the password you configured"
                    )
                    
                    if let version = deploymentManager.installedVersion {
                        AccessInfoRow(
                            icon: "info.circle",
                            label: "Version",
                            value: version
                        )
                    }
                }
                .padding()
            }
            
            // Quick actions
            GroupBox("Quick Actions") {
                HStack(spacing: 16) {
                    QuickActionButton(
                        title: "Open Web GUI",
                        icon: "safari",
                        color: .blue,
                        accessibilityId: AccessibilityIdentifiers.Complete.openGUIButton
                    ) {
                        openWebGUI()
                    }
                    
                    QuickActionButton(
                        title: "View Logs",
                        icon: "doc.text.magnifyingglass",
                        color: .orange,
                        accessibilityId: AccessibilityIdentifiers.Complete.viewLogsButton
                    ) {
                        openLogsFolder()
                    }
                    
                    QuickActionButton(
                        title: "Open Data Folder",
                        icon: "folder",
                        color: .purple,
                        accessibilityId: AccessibilityIdentifiers.Complete.openDataFolderButton
                    ) {
                        openDataFolder()
                    }
                    
                    QuickActionButton(
                        title: "Copy Config Path",
                        icon: copied ? "checkmark" : "doc.on.doc",
                        color: .green,
                        accessibilityId: AccessibilityIdentifiers.Complete.copyConfigPathButton
                    ) {
                        copyConfigPath()
                    }
                }
                .padding()
            }
            
            // Service status
            GroupBox("Service Status") {
                HStack {
                    if deploymentManager.isRunning {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                        Text("Velociraptor is running")
                            .font(.subheadline)
                    } else {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.red)
                        Text("Velociraptor is not running")
                            .font(.subheadline)
                    }
                    
                    Spacer()
                    
                    if deploymentManager.isRunning {
                        Button("Stop Service") {
                            Task {
                                try? await deploymentManager.stopService()
                            }
                        }
                        .accessibilityId(AccessibilityIdentifiers.Complete.stopServiceButton)
                    } else {
                        Button("Start Service") {
                            Task {
                                try? await deploymentManager.restartService()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .accessibilityId(AccessibilityIdentifiers.Complete.startServiceButton)
                    }
                }
                .padding()
            }
            .accessibilityId(AccessibilityIdentifiers.Complete.serviceStatus)
            
            // Next steps
            VStack(alignment: .leading, spacing: 12) {
                Text("Next Steps:")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    NextStepRow(number: 1, text: "Open the web interface and log in with your admin credentials")
                    NextStepRow(number: 2, text: "Create additional user accounts if needed")
                    NextStepRow(number: 3, text: "Configure artifact collection for your investigation")
                    NextStepRow(number: 4, text: "Deploy clients to target endpoints")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityId(AccessibilityIdentifiers.Complete.nextSteps)
        }
        .padding()
        .accessibilityId(AccessibilityIdentifiers.WizardStep.complete)
    }
    
    /// Opens the application's web administration interface in the user's default browser.
    /// 
    /// Builds an HTTPS URL from the current configuration's `guiBindAddress` and `guiBindPort` and opens it using the system workspace.
    private func openWebGUI() {
        let urlString = "https://\(configViewModel.data.guiBindAddress):\(configViewModel.data.guiBindPort)"
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
    
    /// Opens the configured logs directory in Finder.
    /// The directory path is taken from `configViewModel.data.logsDirectory`.
    private func openLogsFolder() {
        let url = URL(fileURLWithPath: configViewModel.data.logsDirectory)
        NSWorkspace.shared.open(url)
    }
    
    /// Opens the configured datastore directory in Finder.
    /// 
    /// Reads the `datastoreDirectory` path from `configViewModel.data` and asks the system to open that folder.
    private func openDataFolder() {
        let url = URL(fileURLWithPath: configViewModel.data.datastoreDirectory)
        NSWorkspace.shared.open(url)
    }
    
    /// Copies the server configuration file path from the configuration view model to the system clipboard and temporarily marks the UI as copied.
    /// 
    /// The copied indicator is set to `true` immediately and is reset to `false` after 2 seconds.
    private func copyConfigPath() {
        let path = configViewModel.data.datastoreDirectory + "/config/server.config.yaml"
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(path, forType: .string)
        copied = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            copied = false
        }
    }
}

// MARK: - Access Info Row

struct AccessInfoRow: View {
    let icon: String
    let label: String
    let value: String
    var isLink: Bool = false
    var note: String?
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(label + ":")
                .font(.subheadline)
                .frame(width: 100, alignment: .trailing)
            
            if isLink {
                Link(value, destination: URL(string: value)!)
                    .font(.subheadline.monospaced())
            } else {
                Text(value)
                    .font(.subheadline.monospaced())
            }
            
            if let note = note {
                Text("(\(note))")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var accessibilityId: String = ""
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
    }
}

// MARK: - Next Step Row

struct NextStepRow: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number).")
                .font(.subheadline.bold())
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

#Preview {
    CompleteStepView()
        .environmentObject(ConfigurationViewModel())
        .environmentObject(DeploymentManager())
        .padding()
        .frame(width: 700)
}