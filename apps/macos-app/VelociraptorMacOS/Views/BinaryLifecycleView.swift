//
//  BinaryLifecycleView.swift
//  VelociraptorMacOS
//
//  Provides UI for managing Velociraptor binary lifecycle:
//  - Start/Stop/Restart
//  - Spin Down
//  - Uninstall
//

import SwiftUI

struct BinaryLifecycleView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    @State private var showUninstallAlert = false
    @State private var keepConfigOnUninstall = true
    @State private var keepDataOnUninstall = true
    @State private var isProcessing = false
    @State private var lastActionResult: String?
    @State private var showResultAlert = false
    @State private var installationStatus: (installed: Bool, version: String?) = (false, nil)
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                headerSection
                
                Divider()
                
                // Status Section
                statusSection
                
                Divider()
                
                // Actions Section
                actionsSection
                
                Divider()
                
                // Danger Zone
                dangerZoneSection
            }
            .padding(24)
        }
        .accessibilityIdentifier("binary.lifecycle.main")
        .onAppear {
            refreshStatus()
        }
        .alert("Uninstall Velociraptor", isPresented: $showUninstallAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Uninstall", role: .destructive) {
                Task {
                    await performUninstall()
                }
            }
        } message: {
            Text("This will remove the Velociraptor binary from your system. This action cannot be undone.")
        }
        .alert("Action Complete", isPresented: $showResultAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(lastActionResult ?? "Operation completed")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack(spacing: 16) {
            Image(systemName: "cpu")
                .font(.system(size: 32))
                .foregroundStyle(Color.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Binary Lifecycle Manager")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Manage the Velociraptor DFIR binary installation and service")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            // Refresh Button
            Button {
                refreshStatus()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .disabled(isProcessing)
            .accessibilityIdentifier("binary.lifecycle.refresh")
        }
        .accessibilityIdentifier("binary.lifecycle.header")
    }
    
    // MARK: - Status Section
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Status")
                .font(.headline)
            
            HStack(spacing: 24) {
                // Installation Status
                statusCard(
                    title: "Installation",
                    value: installationStatus.version ?? "Not Installed",
                    icon: installationStatus.installed ? "checkmark.circle.fill" : "xmark.circle.fill",
                    color: installationStatus.installed ? .green : .secondary
                )
                
                // Service Status
                statusCard(
                    title: "Service",
                    value: deploymentManager.isRunning ? "Running" : "Stopped",
                    icon: deploymentManager.isRunning ? "circle.fill" : "circle",
                    color: deploymentManager.isRunning ? .green : .secondary
                )
                
                // Deployment Status
                statusCard(
                    title: "Deployment",
                    value: deploymentManager.isDeploying ? "In Progress" : "Ready",
                    icon: deploymentManager.isDeploying ? "arrow.triangle.2.circlepath" : "checkmark.seal",
                    color: deploymentManager.isDeploying ? .orange : .blue
                )
            }
            
            // Status Message
            if !deploymentManager.statusMessage.isEmpty {
                HStack {
                    if isProcessing || deploymentManager.isDeploying {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(deploymentManager.statusMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 8)
            }
        }
        .accessibilityIdentifier("binary.lifecycle.status")
    }
    
    private func statusCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(8)
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service Control")
                .font(.headline)
            
            HStack(spacing: 16) {
                // Stop Button (if running)
                if deploymentManager.isRunning {
                    actionButton(
                        title: "Stop Service",
                        icon: "stop.fill",
                        color: .orange,
                        action: stopService
                    )
                }
                
                // Restart Button
                actionButton(
                    title: "Restart",
                    icon: "arrow.clockwise",
                    color: .blue,
                    action: restartService
                )
                .disabled(!deploymentManager.isRunning)
                
                // Spin Down Button
                actionButton(
                    title: "Spin Down",
                    icon: "power",
                    color: .purple,
                    action: spinDown
                )
                .disabled(!installationStatus.installed)
            }
            
            // Info text
            Text("Spin Down gracefully stops all Velociraptor processes and unloads the launch agent.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityIdentifier("binary.lifecycle.actions")
    }
    
    private func actionButton(title: String, icon: String, color: Color, action: @escaping () async -> Void) -> some View {
        Button {
            Task {
                isProcessing = true
                await action()
                refreshStatus()
                isProcessing = false
            }
        } label: {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(color.opacity(0.1))
            .foregroundStyle(color)
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .disabled(isProcessing)
        .accessibilityIdentifier("binary.lifecycle.\(title.lowercased().replacingOccurrences(of: " ", with: "."))")
    }
    
    // MARK: - Danger Zone Section
    
    private var dangerZoneSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Danger Zone")
                .font(.headline)
                .foregroundStyle(.red)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Uninstall Velociraptor")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text("Remove the Velociraptor binary, configuration, and data files from your system.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Uninstall") {
                        showUninstallAlert = true
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.red)
                    .disabled(isProcessing || !installationStatus.installed)
                    .accessibilityIdentifier("binary.lifecycle.uninstall.button")
                }
                
                // Options
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Keep configuration files", isOn: $keepConfigOnUninstall)
                        .accessibilityIdentifier("binary.lifecycle.keep.config")
                    Toggle("Keep data files", isOn: $keepDataOnUninstall)
                        .accessibilityIdentifier("binary.lifecycle.keep.data")
                }
                .padding(.top, 8)
            }
            .padding()
            .background(Color.red.opacity(0.05))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .accessibilityIdentifier("binary.lifecycle.danger")
    }
    
    // MARK: - Actions
    
    private func refreshStatus() {
        installationStatus = deploymentManager.checkInstallation()
    }
    
    private func stopService() async {
        do {
            try await deploymentManager.stopService()
            lastActionResult = "Service stopped successfully"
            showResultAlert = true
        } catch {
            lastActionResult = "Failed to stop service: \(error.localizedDescription)"
            showResultAlert = true
        }
    }
    
    private func restartService() async {
        do {
            try await deploymentManager.restartService()
            lastActionResult = "Service restarted successfully"
            showResultAlert = true
        } catch {
            lastActionResult = "Failed to restart service: \(error.localizedDescription)"
            showResultAlert = true
        }
    }
    
    private func spinDown() async {
        do {
            let result = try await deploymentManager.spinDown()
            lastActionResult = result.message
            showResultAlert = true
        } catch {
            lastActionResult = "Failed to spin down: \(error.localizedDescription)"
            showResultAlert = true
        }
    }
    
    private func performUninstall() async {
        isProcessing = true
        defer { isProcessing = false }
        
        do {
            let result = try await deploymentManager.uninstall(
                keepConfig: keepConfigOnUninstall,
                keepData: keepDataOnUninstall
            )
            lastActionResult = result.message
            refreshStatus()
            showResultAlert = true
        } catch {
            lastActionResult = "Failed to uninstall: \(error.localizedDescription)"
            showResultAlert = true
        }
    }
}

#Preview {
    BinaryLifecycleView()
        .environmentObject(AppState())
        .environmentObject(DeploymentManager())
        .frame(width: 800, height: 600)
}
