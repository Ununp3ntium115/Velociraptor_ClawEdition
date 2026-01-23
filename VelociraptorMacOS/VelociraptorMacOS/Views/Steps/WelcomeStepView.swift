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
                Text("Welcome to the Velociraptor Configuration Wizard")
                    .font(.title3.bold())
                
                Text("""
                This wizard will guide you through creating a complete Velociraptor \
                configuration optimized for macOS. Whether you're setting up a server, \
                standalone instance, or client, we'll walk you through each step.
                """)
                .font(.body)
                .foregroundColor(.secondary)
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
                
                FeatureCard(
                    icon: "lock.shield.fill",
                    title: "Secure by Default",
                    description: "TLS encryption and Keychain integration"
                )
                
                FeatureCard(
                    icon: "checkmark.circle.fill",
                    title: "Real-time Validation",
                    description: "Input validation at every step"
                )
                
                FeatureCard(
                    icon: "doc.text.fill",
                    title: "YAML Configuration",
                    description: "Professional configuration file generation"
                )
            }
            
            Divider()
            
            // Quick start options
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Start Options")
                    .font(.headline)
                
                HStack(spacing: 16) {
                    QuickStartButton(
                        title: "Standard Setup",
                        description: "Walk through all configuration steps",
                        icon: "wand.and.stars",
                        action: { appState.nextStep() }
                    )
                    
                    QuickStartButton(
                        title: "Emergency Mode",
                        description: "Rapid deployment in under 3 minutes",
                        icon: "exclamationmark.triangle.fill",
                        isPrimary: true,
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
    let title: String
    let description: String
    let icon: String
    var isPrimary: Bool = false
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline.bold())
                    
                    Text(description)
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
    }
}

#Preview {
    WelcomeStepView()
        .environmentObject(AppState())
        .environmentObject(DeploymentManager())
        .padding()
        .frame(width: 700)
}
