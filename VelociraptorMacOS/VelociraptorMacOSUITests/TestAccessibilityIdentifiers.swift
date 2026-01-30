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
    
    // MARK: - Certificate Settings
    enum CertificateSettings {
        static let selfSignedCard = "certificate.card.selfSigned"
        static let customCard = "certificate.card.custom"
        static let letsEncryptCard = "certificate.card.letsEncrypt"
        static let expirationPicker = "certificate.picker.expiration"
        static let organizationField = "certificate.field.organization"
        static let certPathField = "certificate.field.certPath"
        static let keyPathField = "certificate.field.keyPath"
        static let domainField = "certificate.field.domain"
        static let browseCertButton = "certificate.button.browseCert"
        static let browseKeyButton = "certificate.button.browseKey"
    }
    
    // MARK: - Security Settings
    enum SecuritySettings {
        static let environmentPicker = "security.picker.environment"
        static let logLevelPicker = "security.picker.logLevel"
        static let debugLoggingToggle = "security.toggle.debugLogging"
        static let enforceTLSToggle = "security.toggle.enforceTLS"
        static let validateCertsToggle = "security.toggle.validateCerts"
        static let restrictVQLToggle = "security.toggle.restrictVQL"
        static let useKeychainToggle = "security.toggle.useKeychain"
        static let notificationsToggle = "security.toggle.notifications"
        static let launchAtLoginToggle = "security.toggle.launchAtLogin"
        static let autoUpdateToggle = "security.toggle.autoUpdate"
    }
    
    // MARK: - Network Configuration
    enum NetworkConfiguration {
        static let frontendAddressField = "network.field.frontendAddress"
        static let frontendPortField = "network.field.frontendPort"
        static let guiAddressField = "network.field.guiAddress"
        static let guiPortField = "network.field.guiPort"
        static let apiAddressField = "network.field.apiAddress"
        static let apiPortField = "network.field.apiPort"
        static let portStatus = "network.status.port"
        static let presetStandardButton = "network.button.presetStandard"
        static let presetDevelopmentButton = "network.button.presetDevelopment"
        static let presetCustomButton = "network.button.presetCustom"
        static let portConflictWarning = "network.warning.portConflict"
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
        static let sheetContainer = "emergency.sheet.container"
        static let title = "emergency.title"
        static let deployButton = "emergency.button.deploy"
        static let cancelButton = "emergency.button.cancel"
        static let progressIndicator = "emergency.progress"
        static let progressView = "emergency.view.progress"
        static let successView = "emergency.view.success"
        static let errorView = "emergency.view.error"
        static let retryButton = "emergency.button.retry"
    }
    
    // MARK: - Incident Response
    enum IncidentResponse {
        static let categoryList = "incidentResponse.list.categories"
        static let incidentList = "incidentResponse.list.incidents"
        static let detailsPanel = "incidentResponse.panel.details"
        static let buildButton = "incidentResponse.button.build"
        static let resetButton = "incidentResponse.button.reset"
        static let generateButton = "incidentResponse.button.generate"
        static let exportButton = "incidentResponse.button.export"
        static let searchField = "incidentResponse.field.search"
        static let priorityFilter = "incidentResponse.filter.priority"
    }
    
    // MARK: - Settings
    enum Settings {
        static let window = "settings.window"
        static let generalTab = "settings.tab.general"
        static let securityTab = "settings.tab.security"
        static let advancedTab = "settings.tab.advanced"
        static let launchAtLogin = "settings.toggle.launchAtLogin"
        static let checkForUpdates = "settings.toggle.checkForUpdates"
        static let enableNotifications = "settings.toggle.enableNotifications"
        static let themePicker = "settings.picker.theme"
        static let openLogFile = "settings.button.openLogFile"
        static let clearLogs = "settings.button.clearLogs"
        static let exportLogs = "settings.button.exportLogs"
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
