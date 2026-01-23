//
//  AppState.swift
//  VelociraptorMacOS
//
//  Global application state management
//

import SwiftUI
import Combine

/// Global application state observable object
/// Manages wizard navigation, UI state, and cross-view communication
@MainActor
class AppState: ObservableObject {
    // MARK: - Wizard Navigation
    
    /// Current wizard step
    @Published var currentStep: WizardStep = .welcome
    
    /// Wizard step history for back navigation
    @Published var stepHistory: [WizardStep] = []
    
    // MARK: - Deployment State
    
    /// Currently selected deployment type
    @Published var deploymentType: DeploymentType = .standalone
    
    /// Whether deployment is in progress
    @Published var isDeploying: Bool = false
    
    /// Deployment progress (0.0 to 1.0)
    @Published var deploymentProgress: Double = 0.0
    
    /// Current deployment status message
    @Published var deploymentStatus: String = ""
    
    // MARK: - Error Handling
    
    /// Current error message to display
    @Published var errorMessage: String?
    
    /// Whether to show error alert
    @Published var showError: Bool = false
    
    /// Last error that occurred
    @Published var lastError: Error?
    
    // MARK: - UI State
    
    /// Show about dialog
    @Published var showAbout: Bool = false
    
    /// Show open panel
    @Published var showOpenPanel: Bool = false
    
    /// Show save panel
    @Published var showSavePanel: Bool = false
    
    /// Show emergency mode dialog
    @Published var showEmergencyMode: Bool = false
    
    /// Show preferences window
    @Published var showPreferences: Bool = false
    
    /// Selected sidebar item
    @Published var selectedSidebarItem: SidebarItem = .wizard
    
    // MARK: - Enums
    
    /// Wizard steps enumeration
    enum WizardStep: Int, CaseIterable, Identifiable {
        case welcome = 0
        case deploymentType = 1
        case certificateSettings = 2
        case securitySettings = 3
        case storageConfiguration = 4
        case networkConfiguration = 5
        case authentication = 6
        case review = 7
        case complete = 8
        
        var id: Int { rawValue }
        
        /// Display title for the step
        var title: String {
            switch self {
            case .welcome: return "Welcome"
            case .deploymentType: return "Deployment Type"
            case .certificateSettings: return "Certificate Settings"
            case .securitySettings: return "Security Settings"
            case .storageConfiguration: return "Storage Configuration"
            case .networkConfiguration: return "Network Configuration"
            case .authentication: return "Authentication"
            case .review: return "Review & Generate"
            case .complete: return "Complete"
            }
        }
        
        /// Short description for the step
        var description: String {
            switch self {
            case .welcome: return "Welcome to the configuration wizard"
            case .deploymentType: return "Choose your deployment type"
            case .certificateSettings: return "Configure SSL/TLS certificates"
            case .securitySettings: return "Set security and environment options"
            case .storageConfiguration: return "Configure data storage locations"
            case .networkConfiguration: return "Set network bindings and ports"
            case .authentication: return "Configure admin credentials"
            case .review: return "Review and generate configuration"
            case .complete: return "Configuration complete"
            }
        }
        
        /// SF Symbol icon name
        var iconName: String {
            switch self {
            case .welcome: return "hand.wave.fill"
            case .deploymentType: return "server.rack"
            case .certificateSettings: return "lock.shield.fill"
            case .securitySettings: return "shield.checkered"
            case .storageConfiguration: return "externaldrive.fill"
            case .networkConfiguration: return "network"
            case .authentication: return "person.badge.key.fill"
            case .review: return "checklist"
            case .complete: return "checkmark.seal.fill"
            }
        }
        
        /// Whether this step can be skipped
        var isSkippable: Bool {
            switch self {
            case .certificateSettings, .securitySettings: return true
            default: return false
            }
        }
    }
    
    /// Deployment type options
    enum DeploymentType: String, CaseIterable, Identifiable {
        case server = "Server"
        case standalone = "Standalone"
        case client = "Client"
        
        var id: String { rawValue }
        
        /// Display description
        var description: String {
            switch self {
            case .server:
                return "Full server deployment with client management capabilities. Ideal for centralized DFIR operations."
            case .standalone:
                return "Single-node deployment for local analysis. Perfect for individual investigators and testing."
            case .client:
                return "Client-only configuration for connecting to an existing server. Used for endpoint deployment."
            }
        }
        
        /// SF Symbol icon
        var iconName: String {
            switch self {
            case .server: return "server.rack"
            case .standalone: return "desktopcomputer"
            case .client: return "laptopcomputer"
            }
        }
        
        /// Recommended use cases
        var useCases: [String] {
            switch self {
            case .server:
                return [
                    "Enterprise DFIR operations",
                    "Multi-endpoint investigations",
                    "Centralized artifact collection",
                    "Team collaboration"
                ]
            case .standalone:
                return [
                    "Individual investigations",
                    "Local testing and development",
                    "Offline forensic analysis",
                    "Training and education"
                ]
            case .client:
                return [
                    "Endpoint deployment",
                    "Remote collection agents",
                    "Distributed investigations"
                ]
            }
        }
    }
    
    /// Sidebar navigation items
    enum SidebarItem: String, CaseIterable, Identifiable {
        case wizard = "Configuration Wizard"
        case incidentResponse = "Incident Response"
        case health = "Health Monitor"
        case logs = "Logs"
        
        var id: String { rawValue }
        
        var iconName: String {
            switch self {
            case .wizard: return "wand.and.stars"
            case .incidentResponse: return "exclamationmark.shield.fill"
            case .health: return "heart.text.square.fill"
            case .logs: return "doc.text.magnifyingglass"
            }
        }
    }
    
    // MARK: - Navigation Methods
    
    /// Move to the next wizard step
    func nextStep() {
        guard let next = WizardStep(rawValue: currentStep.rawValue + 1) else { return }
        stepHistory.append(currentStep)
        currentStep = next
    }
    
    /// Move to the previous wizard step
    func previousStep() {
        if let previous = stepHistory.popLast() {
            currentStep = previous
        } else if let previous = WizardStep(rawValue: currentStep.rawValue - 1) {
            currentStep = previous
        }
    }
    
    /// Jump to a specific step (only if already visited)
    func goToStep(_ step: WizardStep) {
        guard step.rawValue <= currentStep.rawValue else { return }
        currentStep = step
    }
    
    /// Reset wizard to beginning
    func resetWizard() {
        currentStep = .welcome
        stepHistory.removeAll()
        deploymentProgress = 0.0
        deploymentStatus = ""
        isDeploying = false
    }
    
    // MARK: - Error Handling
    
    /// Display an error to the user
    func displayError(_ error: Error) {
        lastError = error
        errorMessage = error.localizedDescription
        showError = true
        Logger.shared.error("Error displayed: \(error.localizedDescription)", component: "AppState")
    }
    
    /// Display a custom error message
    func displayError(message: String) {
        errorMessage = message
        showError = true
        Logger.shared.error("Error displayed: \(message)", component: "AppState")
    }
    
    /// Clear current error
    func clearError() {
        errorMessage = nil
        showError = false
        lastError = nil
    }
    
    // MARK: - Computed Properties
    
    /// Whether back navigation is available
    var canGoBack: Bool {
        currentStep.rawValue > 0 && currentStep != .complete
    }
    
    /// Whether forward navigation is available
    var canGoNext: Bool {
        currentStep.rawValue < WizardStep.allCases.count - 1
    }
    
    /// Progress through the wizard (0.0 to 1.0)
    var wizardProgress: Double {
        Double(currentStep.rawValue) / Double(WizardStep.allCases.count - 1)
    }
}
