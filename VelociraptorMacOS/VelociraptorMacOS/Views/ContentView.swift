//
//  ContentView.swift
//  VelociraptorMacOS
//
//  Main content view with navigation sidebar
//

import SwiftUI

/// Main content view with sidebar navigation and step-based content
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var deploymentManager: DeploymentManager
    @EnvironmentObject var keychainManager: KeychainManager
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
        } detail: {
            VStack(spacing: 0) {
                // Header
                HeaderView()
                
                Divider()
                
                // Main content area
                ScrollView {
                    StepContentView()
                        .padding()
                }
                
                Divider()
                
                // Progress bar
                ProgressView(value: appState.wizardProgress)
                    .progressViewStyle(.linear)
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                
                // Navigation buttons
                NavigationButtonsView()
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
            }
        }
        .navigationTitle("")
        .toolbar {
            ToolbarContent()
        }
        .alert("Error", isPresented: $appState.showError) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(appState.errorMessage ?? "An unknown error occurred")
        }
        .sheet(isPresented: $appState.showEmergencyMode) {
            EmergencyModeView()
        }
        .sheet(isPresented: $appState.showAbout) {
            AboutView()
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List(selection: Binding(
            get: { appState.currentStep },
            set: { if let step = $0 { appState.goToStep(step) } }
        )) {
            Section("Configuration Wizard") {
                ForEach(AppState.WizardStep.allCases) { step in
                    SidebarStepRow(step: step, currentStep: appState.currentStep)
                        .tag(step)
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
}

struct SidebarStepRow: View {
    let step: AppState.WizardStep
    let currentStep: AppState.WizardStep
    
    var isCompleted: Bool {
        step.rawValue < currentStep.rawValue
    }
    
    var isCurrent: Bool {
        step == currentStep
    }
    
    var isAccessible: Bool {
        step.rawValue <= currentStep.rawValue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 28, height: 28)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.caption.bold())
                        .foregroundColor(isCurrent ? .white : .secondary)
                }
            }
            
            // Step info
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(isAccessible ? .primary : .secondary)
            }
            
            Spacer()
            
            // Current indicator
            if isCurrent {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .opacity(isAccessible ? 1.0 : 0.5)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .accentColor
        } else {
            return Color(NSColor.separatorColor)
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 16) {
            // Logo
            Image(systemName: "shield.checkered")
                .font(.system(size: 40))
                .foregroundColor(.accentColor)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("VELOCIRAPTOR")
                    .font(.title.bold())
                
                Text("DFIR Framework Configuration Wizard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Current step info
            VStack(alignment: .trailing, spacing: 4) {
                Text("Step \(appState.currentStep.rawValue + 1) of \(AppState.WizardStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(appState.currentStep.title)
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.05))
    }
}

// MARK: - Step Content View

struct StepContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Step header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: appState.currentStep.iconName)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text(appState.currentStep.title)
                        .font(.title2.bold())
                }
                
                Text(appState.currentStep.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Step-specific content
            stepContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch appState.currentStep {
        case .welcome:
            WelcomeStepView()
        case .deploymentType:
            DeploymentTypeStepView()
        case .certificateSettings:
            CertificateSettingsStepView()
        case .securitySettings:
            SecuritySettingsStepView()
        case .storageConfiguration:
            StorageConfigurationStepView()
        case .networkConfiguration:
            NetworkConfigurationStepView()
        case .authentication:
            AuthenticationStepView()
        case .review:
            ReviewStepView()
        case .complete:
            CompleteStepView()
        }
    }
}

// MARK: - Navigation Buttons View

struct NavigationButtonsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    @State private var showCancelConfirmation = false
    
    var body: some View {
        HStack {
            // Emergency mode button
            Button {
                appState.showEmergencyMode = true
            } label: {
                Label("Emergency Mode", systemImage: "exclamationmark.triangle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .help("Rapid emergency deployment")
            
            Spacer()
            
            // Back button
            Button("Back") {
                appState.previousStep()
            }
            .disabled(!appState.canGoBack || deploymentManager.isDeploying)
            .keyboardShortcut(.leftArrow, modifiers: [.command])
            
            // Next/Finish button
            Button(appState.currentStep == .complete ? "Finish" : "Next") {
                if appState.currentStep == .complete {
                    NSApplication.shared.terminate(nil)
                } else {
                    handleNextStep()
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed || deploymentManager.isDeploying)
            .keyboardShortcut(.rightArrow, modifiers: [.command])
            
            // Cancel button
            Button("Cancel", role: .cancel) {
                showCancelConfirmation = true
            }
            .disabled(deploymentManager.isDeploying)
        }
        .confirmationDialog("Cancel Configuration?", isPresented: $showCancelConfirmation) {
            Button("Cancel Configuration", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
            Button("Continue Editing", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel? Any unsaved changes will be lost.")
        }
    }
    
    private var canProceed: Bool {
        configViewModel.validateStep(appState.currentStep)
    }
    
    private func handleNextStep() {
        // Validate current step
        guard configViewModel.validateStep(appState.currentStep) else {
            let errors = configViewModel.errorsForStep(appState.currentStep)
            if let firstError = errors.first {
                appState.displayError(message: firstError.localizedDescription)
            }
            return
        }
        
        appState.nextStep()
    }
}

// MARK: - Toolbar Content

struct ToolbarContent: ToolbarContent {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if deploymentManager.isDeploying {
                ProgressView()
                    .controlSize(.small)
            }
            
            Button {
                // Open incident response window
                if let url = URL(string: "velociraptormacos://incident-response") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Incident Response", systemImage: "exclamationmark.shield.fill")
            }
            .help("Open Incident Response Collector")
        }
        
        ToolbarItemGroup(placement: .secondaryAction) {
            Menu {
                Button("Check Health") {
                    // Health check action
                }
                
                Button("View Logs") {
                    // View logs action
                }
                
                Divider()
                
                Button("Reset to Defaults") {
                    // Reset action
                }
            } label: {
                Label("Actions", systemImage: "ellipsis.circle")
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shield.checkered")
                .font(.system(size: 64))
                .foregroundColor(.accentColor)
            
            Text("Velociraptor")
                .font(.largeTitle.bold())
            
            Text("DFIR Framework for macOS")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Version 5.0.5")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Free For All First Responders")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            Text("© 2026 Velocidex Enterprises")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 400)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ConfigurationViewModel())
        .environmentObject(DeploymentManager())
        .environmentObject(KeychainManager())
        .environmentObject(IncidentResponseViewModel())
}
