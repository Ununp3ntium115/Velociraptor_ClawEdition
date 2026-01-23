//
//  EmergencyModeView.swift
//  VelociraptorMacOS
//
//  Emergency rapid deployment view
//

import SwiftUI

struct EmergencyModeView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var isDeploying = false
    @State private var deploymentComplete = false
    @State private var error: Error?
    
    var body: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.red)
                
                Text("EMERGENCY DEPLOYMENT")
                    .font(.title.bold())
                    .foregroundColor(.red)
                
                Text("Rapid deployment for active incident response")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            if deploymentComplete {
                // Success state
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.green)
                    
                    Text("Deployment Complete!")
                        .font(.headline)
                    
                    Text("Velociraptor is now running and ready for use.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Web Interface:")
                                .font(.caption.bold())
                            Link("https://127.0.0.1:8889", destination: URL(string: "https://127.0.0.1:8889")!)
                                .font(.caption)
                        }
                        
                        HStack {
                            Text("Username:")
                                .font(.caption.bold())
                            Text("admin")
                                .font(.caption.monospaced())
                        }
                        
                        Text("Password was generated and saved to Keychain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                    
                    HStack(spacing: 16) {
                        Button("Open Web Interface") {
                            if let url = URL(string: "https://127.0.0.1:8889") {
                                NSWorkspace.shared.open(url)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Close") {
                            dismiss()
                        }
                    }
                }
            } else if isDeploying {
                // Deploying state
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    
                    Text(deploymentManager.statusMessage)
                        .font(.subheadline)
                    
                    ProgressView(value: deploymentManager.progress)
                        .progressViewStyle(.linear)
                        .frame(width: 300)
                    
                    Text("Estimated time: 2-3 minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let error = error {
                // Error state
                VStack(spacing: 16) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.red)
                    
                    Text("Deployment Failed")
                        .font(.headline)
                    
                    Text(error.localizedDescription)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    HStack(spacing: 16) {
                        Button("Try Again") {
                            self.error = nil
                            startEmergencyDeployment()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            } else {
                // Initial state
                VStack(alignment: .leading, spacing: 16) {
                    Text("This will perform a rapid deployment with default settings:")
                        .font(.subheadline)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        EmergencyFeatureRow(icon: "checkmark.circle.fill", text: "Standalone deployment mode")
                        EmergencyFeatureRow(icon: "checkmark.circle.fill", text: "Self-signed certificate")
                        EmergencyFeatureRow(icon: "checkmark.circle.fill", text: "Default ports (8889 for GUI)")
                        EmergencyFeatureRow(icon: "checkmark.circle.fill", text: "Auto-generated secure password")
                        EmergencyFeatureRow(icon: "checkmark.circle.fill", text: "Data stored in ~/EmergencyVelociraptor")
                    }
                    
                    Divider()
                    
                    HStack {
                        Image(systemName: "clock.fill")
                            .foregroundColor(.orange)
                        Text("Estimated deployment time: 2-3 minutes")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .foregroundColor(.orange)
                        Text("This is intended for emergency situations. For production use, complete the full configuration wizard.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                HStack(spacing: 16) {
                    Button("Cancel", role: .cancel) {
                        dismiss()
                    }
                    
                    Button {
                        startEmergencyDeployment()
                    } label: {
                        Label("Deploy Now", systemImage: "bolt.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                }
            }
        }
        .padding(32)
        .frame(width: 500)
    }
    
    private func startEmergencyDeployment() {
        isDeploying = true
        
        Task {
            do {
                try await deploymentManager.emergencyDeploy()
                deploymentComplete = true
            } catch {
                self.error = error
            }
            isDeploying = false
        }
    }
}

struct EmergencyFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.green)
                .frame(width: 20)
            
            Text(text)
                .font(.subheadline)
        }
    }
}

#Preview {
    EmergencyModeView()
        .environmentObject(AppState())
        .environmentObject(DeploymentManager())
}
