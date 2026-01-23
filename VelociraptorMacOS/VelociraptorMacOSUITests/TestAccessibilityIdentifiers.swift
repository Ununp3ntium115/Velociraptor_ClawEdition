//
//  TestAccessibilityIdentifiers.swift
//  VelociraptorMacOSUITests
//
//  Copy of accessibility identifiers for test target
//  (Test target cannot access main app's internal types directly)
//

import Foundation

/// Accessibility identifiers for UI testing
/// These must match the identifiers used in the main app's AccessibilityIdentifiers.swift
enum TestIDs {
    // MARK: - Navigation
    enum Navigation {
        static let sidebar = "navigation.sidebar"
        static let nextButton = "navigation.button.next"
        static let backButton = "navigation.button.back"
        static let cancelButton = "navigation.button.cancel"
        static let emergencyButton = "navigation.button.emergency"
        static let progressBar = "navigation.progressBar"
    }
    
    // MARK: - Wizard Steps
    enum WizardStep {
        static let welcome = "wizard.step.welcome"
        static let deploymentType = "wizard.step.deploymentType"
        static let certificateSettings = "wizard.step.certificateSettings"
        static let securitySettings = "wizard.step.securitySettings"
        static let storageConfiguration = "wizard.step.storageConfiguration"
        static let networkConfiguration = "wizard.step.networkConfiguration"
        static let authentication = "wizard.step.authentication"
        static let review = "wizard.step.review"
        static let complete = "wizard.step.complete"
    }
    
    // MARK: - Storage Configuration
    enum StorageConfiguration {
        static let datastorePathField = "storage.field.datastorePath"
        static let logsPathField = "storage.field.logsPath"
        static let cachePathField = "storage.field.cachePath"
        static let browseDatastoreButton = "storage.button.browseDatastore"
        static let browseLogsButton = "storage.button.browseLogs"
        static let browseCacheButton = "storage.button.browseCache"
        static let resetDatastoreButton = "storage.button.resetDatastore"
        static let sizePicker = "storage.picker.size"
        static let diskSpaceInfo = "storage.info.diskSpace"
    }
    
    // MARK: - Authentication
    enum Authentication {
        static let usernameField = "auth.field.username"
        static let passwordField = "auth.field.password"
        static let confirmPasswordField = "auth.field.confirmPassword"
        static let showPasswordButton = "auth.button.showPassword"
        static let showConfirmButton = "auth.button.showConfirm"
        static let passwordStrengthIndicator = "auth.indicator.passwordStrength"
        static let organizationField = "auth.field.organization"
        static let saveToKeychainToggle = "auth.toggle.saveToKeychain"
        static let generatePasswordButton = "auth.button.generatePassword"
    }
    
    // MARK: - Review Step
    enum Review {
        static let validationStatus = "review.status.validation"
        static let previewYAMLButton = "review.button.previewYAML"
        static let exportConfigButton = "review.button.exportConfig"
        static let deployButton = "review.button.deploy"
        static let deploymentProgress = "review.progress.deployment"
    }
    
    // MARK: - Complete Step
    enum Complete {
        static let successIcon = "complete.icon.success"
        static let openGUIButton = "complete.button.openGUI"
        static let viewLogsButton = "complete.button.viewLogs"
        static let openDataFolderButton = "complete.button.openDataFolder"
        static let copyConfigPathButton = "complete.button.copyConfigPath"
        static let serviceStatus = "complete.status.service"
        static let stopServiceButton = "complete.button.stopService"
        static let startServiceButton = "complete.button.startService"
    }
    
    // MARK: - Emergency Mode
    enum EmergencyMode {
        static let sheet = "emergency.sheet"
        static let title = "emergency.title"
        static let deployButton = "emergency.button.deploy"
        static let cancelButton = "emergency.button.cancel"
        static let progressIndicator = "emergency.progress"
        static let successView = "emergency.view.success"
        static let errorView = "emergency.view.error"
        static let retryButton = "emergency.button.retry"
    }
    
    // MARK: - Incident Response
    enum IncidentResponse {
        static let categoryList = "ir.list.categories"
        static let incidentList = "ir.list.incidents"
        static let detailsPanel = "ir.panel.details"
        static let buildButton = "ir.button.build"
        static let resetButton = "ir.button.reset"
    }
    
    // MARK: - Settings
    enum Settings {
        static let window = "settings.window"
        static let generalTab = "settings.tab.general"
        static let securityTab = "settings.tab.security"
        static let advancedTab = "settings.tab.advanced"
        static let launchAtLoginToggle = "settings.toggle.launchAtLogin"
        static let checkUpdatesToggle = "settings.toggle.checkUpdates"
        static let notificationsToggle = "settings.toggle.notifications"
        static let themePicker = "settings.picker.theme"
    }
    
    // MARK: - Deployment Type
    enum DeploymentType {
        static let serverCard = "deploymentType.card.server"
        static let standaloneCard = "deploymentType.card.standalone"
        static let clientCard = "deploymentType.card.client"
        static let tipBox = "deploymentType.tipBox"
    }
    
    // MARK: - Dialogs
    enum Dialog {
        static let yamlPreview = "dialog.yamlPreview"
        static let cancelConfirmation = "dialog.cancelConfirmation"
    }
}
