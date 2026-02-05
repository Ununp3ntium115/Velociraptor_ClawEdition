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
                .accessibilityId(AccessibilityIdentifiers.Navigation.sidebar)
        } detail: {
            // Switch between wizard mode and other views
            switch appState.selectedSidebarItem {
            case .dashboard:
                DashboardView()
                    .environmentObject(configViewModel)
            case .wizard:
                wizardContent
            case .health:
                HealthMonitorView()
            case .incidentResponse:
                IncidentResponseView()
            case .integrations:
                IntegrationsSettingsView()
                    .accessibilityIdentifier("integrations.main")
            case .offlinePackages:
                OfflinePackageBuilderView()
                    .accessibilityIdentifier("offlinePackages.main")
            case .aiChat:
                AIChatView()
                    .accessibilityIdentifier("aiChat.main")
            case .terminal:
                TerminalView()
                    .accessibilityIdentifier("terminal.main")
            case .binaryLifecycle:
                BinaryLifecycleView()
                    .accessibilityIdentifier("binaryLifecycle.main")
            case .logs:
                LogsView()
            }
        }
        .navigationTitle("")
        .toolbar {
            MainToolbarContent()
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
                .accessibilityId(AccessibilityIdentifiers.EmergencyMode.sheet)
        }
        .sheet(isPresented: $appState.showAbout) {
            AboutView()
                .accessibilityId(AccessibilityIdentifiers.Dialog.about)
        }
    }
    
    /// Wizard content with header, steps, and navigation
    @ViewBuilder
    var wizardContent: some View {
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
                .accessibilityId(AccessibilityIdentifiers.Navigation.progressBar)
            
            // Navigation buttons
            NavigationButtonsView()
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            // Main navigation section
            Section("Main") {
                ForEach([AppState.SidebarItem.dashboard, .health, .incidentResponse, .integrations, .offlinePackages, .aiChat, .terminal, .binaryLifecycle, .logs], id: \.self) { item in
                    Button {
                        appState.selectedSidebarItem = item
                    } label: {
                        Label(item.rawValue, systemImage: item.iconName)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .background(appState.selectedSidebarItem == item ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
                }
            }
            
            // Configuration Wizard section
            Section("Configuration Wizard") {
                Button {
                    appState.selectedSidebarItem = .wizard
                } label: {
                    Label("Wizard", systemImage: "wand.and.stars")
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .background(appState.selectedSidebarItem == .wizard ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
                
                // Only show wizard steps when in wizard mode
                if appState.selectedSidebarItem == .wizard {
                    ForEach(AppState.WizardStep.allCases) { step in
                        SidebarStepRow(step: step, currentStep: appState.currentStep)
                            .onTapGesture {
                                if step.rawValue <= appState.currentStep.rawValue {
                                    appState.goToStep(step)
                                }
                            }
                    }
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
        case .aiConfiguration:
            AIConfigurationStepView()
        case .mdmConfiguration:
            MDMConfigurationStepView()
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
            .accessibilityId(AccessibilityIdentifiers.Navigation.emergencyButton)
            
            Spacer()
            
            // Back button
            Button {
                appState.previousStep()
            } label: {
                Text(Strings.Action.back)
            }
            .disabled(!appState.canGoBack || deploymentManager.isDeploying)
            .keyboardShortcut(.leftArrow, modifiers: [.command])
            .accessibilityId(AccessibilityIdentifiers.Navigation.backButton)
            
            // Next/Finish button
            Button {
                if appState.currentStep == .complete {
                    NSApplication.shared.terminate(nil)
                } else {
                    handleNextStep()
                }
            } label: {
                Text(appState.currentStep == .complete ? Strings.Action.finish : Strings.Action.next)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed || deploymentManager.isDeploying)
            .keyboardShortcut(.rightArrow, modifiers: [.command])
            .accessibilityId(AccessibilityIdentifiers.Navigation.nextButton)
            
            // Cancel button
            Button(role: .cancel) {
                showCancelConfirmation = true
            } label: {
                Text(Strings.Action.cancel)
            }
            .disabled(deploymentManager.isDeploying)
            .accessibilityId(AccessibilityIdentifiers.Navigation.cancelButton)
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
    
    /// Validate the current wizard step and advance to the next step if validation succeeds.
    /// 
    /// If validation fails, presents the first validation error via `appState.displayError(_:)` and does not change the current step.
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

struct MainToolbarContent: ToolbarContent {
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