//
//  CommonViews.swift
//  VelociraptorMacOS
//
//  Reusable view components extracted from step views
//

import SwiftUI

// MARK: - Step Section Header

/// Reusable header for step sections with icon and description
struct StepSectionHeader: View {
    let title: String
    let icon: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            Text(description)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Card View

/// Reusable card component for selection options
struct SelectionCard<Content: View>: View {
    let isSelected: Bool
    let action: () -> Void
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        Button(action: action) {
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Labeled Text Field

/// Text field with label and optional help text
struct LabeledTextField: View {
    let label: String
    @Binding var text: String
    var placeholder: String = ""
    var helpText: String? = nil
    var isSecure: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            if isSecure {
                SecureField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
            
            if let helpText = helpText {
                Text(helpText)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Labeled Picker

/// Picker with label and description
struct LabeledPicker<SelectionValue: Hashable, Content: View>: View {
    let label: String
    @Binding var selection: SelectionValue
    var description: String? = nil
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Picker(label, selection: $selection) {
                content()
            }
            .labelsHidden()
            
            if let description = description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Toggle Row

/// Toggle with label and description in a row layout
struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool
    var description: String? = nil
    var icon: String? = nil
    
    var body: some View {
        Toggle(isOn: $isOn) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let description = description {
                        Text(description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .toggleStyle(.switch)
    }
}

// MARK: - Info Box

/// Information box with icon and styled background
struct InfoBox: View {
    let message: String
    var icon: String = "info.circle.fill"
    var style: InfoBoxStyle = .info
    
    enum InfoBoxStyle {
        case info, warning, success, error
        
        var backgroundColor: Color {
            switch self {
            case .info: return Color.blue.opacity(0.1)
            case .warning: return Color.orange.opacity(0.1)
            case .success: return Color.green.opacity(0.1)
            case .error: return Color.red.opacity(0.1)
            }
        }
        
        var foregroundColor: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .success: return .green
            case .error: return .red
            }
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(style.foregroundColor)
            
            Text(message)
                .font(.subheadline)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(style.backgroundColor)
        )
    }
}

// MARK: - Path Field

/// Text field with browse button for file/folder paths
struct PathField: View {
    let label: String
    @Binding var path: String
    var placeholder: String = ""
    var isDirectory: Bool = true
    var onBrowse: (() -> Void)? = nil
    var onReset: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            HStack {
                TextField(placeholder, text: $path)
                    .textFieldStyle(.roundedBorder)
                
                if let onBrowse = onBrowse {
                    Button(action: onBrowse) {
                        Image(systemName: "folder")
                    }
                    .help("Browse...")
                }
                
                if let onReset = onReset {
                    Button(action: onReset) {
                        Image(systemName: "arrow.counterclockwise")
                    }
                    .help("Reset to default")
                }
            }
        }
    }
}

// MARK: - Progress Step View

/// Step indicator for multi-step processes
struct ProgressStepView: View {
    let steps: [String]
    let currentStep: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(spacing: 4) {
                    // Step indicator
                    ZStack {
                        Circle()
                            .fill(stepColor(for: index))
                            .frame(width: 24, height: 24)
                        
                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(index == currentStep ? .white : .secondary)
                        }
                    }
                    
                    Text(step)
                        .font(.caption)
                        .foregroundColor(index <= currentStep ? .primary : .secondary)
                }
                
                // Connector line (except for last step)
                if index < steps.count - 1 {
                    Rectangle()
                        .fill(index < currentStep ? Color.green : Color.secondary.opacity(0.3))
                        .frame(height: 2)
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
    
    private func stepColor(for index: Int) -> Color {
        if index < currentStep {
            return .green
        } else if index == currentStep {
            return .accentColor
        } else {
            return Color.secondary.opacity(0.3)
        }
    }
}

// MARK: - Quick Action Button

/// Styled button for quick actions
struct QuickActionButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    var style: ButtonStyle = .primary
    var accessibilityId: String? = nil
    
    enum ButtonStyle {
        case primary, secondary, destructive
        
        var tint: Color {
            switch self {
            case .primary: return .accentColor
            case .secondary: return .secondary
            case .destructive: return .red
            }
        }
    }
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: icon)
        }
        .buttonStyle(.bordered)
        .tint(style.tint)
        .modifier(OptionalAccessibilityId(id: accessibilityId))
    }
}

// MARK: - Optional Accessibility ID Modifier

struct OptionalAccessibilityId: ViewModifier {
    let id: String?
    
    func body(content: Content) -> some View {
        if let id = id {
            content.accessibilityIdentifier(id)
        } else {
            content
        }
    }
}

// MARK: - View Extension for Accessibility

extension View {
    /// Shorthand for accessibilityIdentifier
    func accessibilityId(_ id: String) -> some View {
        self.accessibilityIdentifier(id)
    }
}

// MARK: - Previews

#Preview("Step Section Header") {
    StepSectionHeader(
        title: "Storage Configuration",
        icon: "externaldrive.fill",
        description: "Configure where Velociraptor stores data"
    )
    .padding()
}

#Preview("Selection Card") {
    VStack {
        SelectionCard(isSelected: true) {
            // Selection action
        } content: {
            Label("Server Deployment", systemImage: "server.rack")
        }
        
        SelectionCard(isSelected: false) {
            // Selection action
        } content: {
            Label("Standalone", systemImage: "desktopcomputer")
        }
    }
    .padding()
}

#Preview("Info Box Styles") {
    VStack(spacing: 12) {
        InfoBox(message: "This is an info message", style: .info)
        InfoBox(message: "This is a warning", icon: "exclamationmark.triangle.fill", style: .warning)
        InfoBox(message: "Success!", icon: "checkmark.circle.fill", style: .success)
        InfoBox(message: "Error occurred", icon: "xmark.circle.fill", style: .error)
    }
    .padding()
}
