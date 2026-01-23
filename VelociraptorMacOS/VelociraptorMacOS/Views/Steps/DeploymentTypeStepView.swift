//
//  DeploymentTypeStepView.swift
//  VelociraptorMacOS
//
//  Deployment type selection step
//

import SwiftUI

struct DeploymentTypeStepView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Choose how you want to deploy Velociraptor:")
                .font(.body)
            
            // Deployment type options
            ForEach(AppState.DeploymentType.allCases) { type in
                DeploymentTypeCard(
                    type: type,
                    isSelected: appState.deploymentType == type,
                    action: {
                        appState.deploymentType = type
                        configViewModel.data.deploymentType = type.rawValue
                    }
                )
                .accessibilityId(accessibilityIdForType(type))
            }
            
            // Help text
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .foregroundColor(.yellow)
                    Text("Tip")
                        .font(.caption.bold())
                }
                
                Text("Not sure which to choose? Select **Standalone** for local analysis or **Server** if you need to manage multiple endpoints.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.yellow.opacity(0.1))
            .cornerRadius(8)
            .accessibilityId(AccessibilityIdentifiers.DeploymentType.tipBox)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Deployment Type Selection")
        .accessibilityId(AccessibilityIdentifiers.WizardStep.deploymentType)
    }
    
    /// Maps a deployment type to its corresponding accessibility identifier.
    /// - Parameter type: The deployment type to map.
    /// - Returns: The accessibility identifier string associated with `type`.
    private func accessibilityIdForType(_ type: AppState.DeploymentType) -> String {
        switch type {
        case .server:
            return AccessibilityIdentifiers.DeploymentType.serverCard
        case .standalone:
            return AccessibilityIdentifiers.DeploymentType.standaloneCard
        case .client:
            return AccessibilityIdentifiers.DeploymentType.clientCard
        }
    }
}

// MARK: - Deployment Type Card

struct DeploymentTypeCard: View {
    let type: AppState.DeploymentType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.secondary, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 14, height: 14)
                    }
                }
                
                // Icon
                Image(systemName: type.iconName)
                    .font(.title)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 40)
                
                // Content
                VStack(alignment: .leading, spacing: 8) {
                    Text(type.rawValue)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)
                    
                    // Use cases
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Best for:")
                            .font(.caption.bold())
                            .foregroundColor(.secondary)
                        
                        ForEach(type.useCases.prefix(3), id: \.self) { useCase in
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark")
                                    .font(.caption2)
                                    .foregroundColor(.green)
                                Text(useCase)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(type.rawValue) deployment")
        .accessibilityHint(type.description)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

#Preview {
    DeploymentTypeStepView()
        .environmentObject(AppState())
        .environmentObject(ConfigurationViewModel())
        .padding()
        .frame(width: 700)
}