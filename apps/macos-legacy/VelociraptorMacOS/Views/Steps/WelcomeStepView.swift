//
//  WelcomeStepView.swift
//  VelociraptorMacOS
//
//  Welcome step of the configuration wizard
//

import SwiftUI

struct WelcomeStepView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Welcome message
            VStack(alignment: .leading, spacing: 16) {
                Text(Strings.Welcome.title)
                    .font(.title3.bold())
                    .accessibilityId(AccessibilityIdentifiers.Welcome.title)
                
                Text(Strings.Welcome.description)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .accessibilityId(AccessibilityIdentifiers.Welcome.description)
            }
            
            Divider()
            
            // Features grid
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                FeatureCard(
                    icon: "server.rack",
                    title: "Multi-Deployment Modes",
                    description: "Server, Standalone, or Client configurations"
                )
                .accessibilityId("\(AccessibilityIdentifiers.Welcome.featureCard).deployment")
                
                FeatureCard(
                    icon: "lock.shield.fill",
                    title: "Secure by Default",
                    description: "TLS encryption and Keychain integration"
                )
                .accessibilityId("\(AccessibilityIdentifiers.Welcome.featureCard).security")
                
                FeatureCard(
                    icon: "checkmark.circle.fill",
                    title: "Real-time Validation",
                    description: "Input validation at every step"
                )
                .accessibilityId("\(AccessibilityIdentifiers.Welcome.featureCard).validation")
                
                FeatureCard(
                    icon: "doc.text.fill",
                    title: "YAML Configuration",
                    description: "Professional configuration file generation"
                )
                .accessibilityId("\(AccessibilityIdentifiers.Welcome.featureCard).yaml")
            }
            
            Divider()
            
            // Quick start options
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Start Options")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    QuickStartButton(
                        titleKey: Strings.Welcome.standardSetup,
                        descriptionKey: Strings.Welcome.standardSetupDescription,
                        icon: "wand.and.stars",
                        accessibilityId: AccessibilityIdentifiers.Welcome.standardSetupButton,
                        action: { appState.nextStep() }
                    )
                    
                    QuickStartButton(
                        titleKey: Strings.Welcome.emergencyMode,
                        descriptionKey: Strings.Welcome.emergencyModeDescription,
                        icon: "exclamationmark.triangle.fill",
                        isPrimary: true,
                        accessibilityId: AccessibilityIdentifiers.Welcome.emergencyModeButton,
                        action: { appState.showEmergencyMode = true }
                    )
                }
            }
            
            // System info
            if let version = deploymentManager.installedVersion {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("Velociraptor \(version) is already installed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Welcome to Velociraptor Configuration Wizard")
        .accessibilityId(AccessibilityIdentifiers.WizardStep.welcome)
    }
}

// MARK: - Feature Card

struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Quick Start Button

struct QuickStartButton: View {
    let titleKey: LocalizedStringKey
    let descriptionKey: LocalizedStringKey
    let icon: String
    var isPrimary: Bool = false
    var accessibilityId: String = ""
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(titleKey)
                        .font(.subheadline.bold())
                    
                    Text(descriptionKey)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(isPrimary ? Color.red.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isPrimary ? Color.red : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
    }
}

#Preview {
    WelcomeStepView()
        .environmentObject(AppState())
        .environmentObject(DeploymentManager())
        .padding()
        .frame(width: 700)
}
