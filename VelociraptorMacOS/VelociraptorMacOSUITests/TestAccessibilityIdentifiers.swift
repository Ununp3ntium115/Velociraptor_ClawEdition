//
//  TestAccessibilityIdentifiers.swift
//  VelociraptorMacOSUITests
//
//  Copy of accessibility identifiers for test target
//  (Test target cannot access main app's internal types directly)
//
//  IMPORTANT: Keep this file in sync with AccessibilityIdentifiers.swift
//  Last synced: 2026-01-23
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
    
    // MARK: - Welcome Step
    enum Welcome {
        static let title = "welcome.title"
        static let description = "welcome.description"
        static let standardSetupButton = "welcome.button.standardSetup"
        static let emergencyModeButton = "welcome.button.emergencyMode"
        static let featureCard = "welcome.featureCard"
    }
    
    // MARK: - Deployment Type
    enum DeploymentType {
        static let serverCard = "deploymentType.card.server"
        static let standaloneCard = "deploymentType.card.standalone"
        static let clientCard = "deploymentType.card.client"
        static let tipBox = "deploymentType.tipBox"
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
    
    // MARK: - Storage Configuration
    enum StorageConfiguration {
        static let datastorePathField = "storage.field.datastorePath"
        static let logsPathField = "storage.field.logsPath"
        static let cachePathField = "storage.field.cachePath"
        static let browseDatastoreButton = "storage.button.browseDatastore"
        static let browseLogsButton = "storage.button.browseLogs"
        static let browseCacheButton = "storage.button.browseCache"
        static let resetDatastoreButton = "storage.button.resetDatastore"
        static let resetLogsButton = "storage.button.resetLogs"
        static let resetCacheButton = "storage.button.resetCache"
        static let sizePicker = "storage.picker.size"
        static let diskSpaceInfo = "storage.info.diskSpace"
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
        static let usernameValidation = "auth.validation.username"
        static let passwordRequirements = "auth.requirements.password"
    }
    
    // MARK: - Review Step
    enum Review {
        static let validationStatus = "review.status.validation"
        static let configSummary = "review.summary.config"
        static let previewYAMLButton = "review.button.previewYAML"
        static let exportConfigButton = "review.button.exportConfig"
        static let deployButton = "review.button.deploy"
        static let deploymentProgress = "review.progress.deployment"
        static let stepIndicator = "review.indicator.step"
    }
    
    // MARK: - Complete Step
    enum Complete {
        static let successIcon = "complete.icon.success"
        static let accessInfo = "complete.info.access"
        static let openGUIButton = "complete.button.openGUI"
        static let viewLogsButton = "complete.button.viewLogs"
        static let openDataFolderButton = "complete.button.openDataFolder"
        static let copyConfigPathButton = "complete.button.copyConfigPath"
        static let serviceStatus = "complete.status.service"
        static let stopServiceButton = "complete.button.stopService"
        static let startServiceButton = "complete.button.startService"
        static let nextSteps = "complete.list.nextSteps"
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
        static let window = "ir.window"
        static let categoryList = "ir.list.categories"
        static let incidentList = "ir.list.incidents"
        static let detailsPanel = "ir.panel.details"
        static let artifactsList = "ir.list.artifacts"
        static let configPanel = "ir.panel.config"
        static let outputPathField = "ir.field.outputPath"
        static let browseOutputButton = "ir.button.browseOutput"
        static let offlineModeToggle = "ir.toggle.offlineMode"
        static let portablePackageToggle = "ir.toggle.portablePackage"
        static let encryptPackageToggle = "ir.toggle.encryptPackage"
        static let includeToolsToggle = "ir.toggle.includeTools"
        static let compressOutputToggle = "ir.toggle.compressOutput"
        static let buildButton = "ir.button.build"
        static let resetButton = "ir.button.reset"
        static let buildProgress = "ir.progress.build"
        // Legacy aliases for backward compatibility
        static let generateButton = "ir.button.build"
        static let exportButton = "ir.button.browseOutput"
        static let searchField = "ir.field.search"
        static let priorityFilter = "ir.filter.priority"
    }
    
    // MARK: - Health Monitor
    enum HealthMonitor {
        static let window = "health.window"
        static let refreshButton = "health.button.refresh"
        static let overallStatus = "health.status.overall"
        static let serviceStatus = "health.status.service"
        static let networkStatus = "health.status.network"
        static let diskStatus = "health.status.disk"
        static let memoryStatus = "health.status.memory"
        static let guiPortStatus = "health.status.guiPort"
        static let frontendPortStatus = "health.status.frontendPort"
        static let metricsPanel = "health.panel.metrics"
        static let logsPanel = "health.panel.logs"
        static let viewLogsButton = "health.button.viewLogs"
        static let exportDiagnosticsButton = "health.button.exportDiagnostics"
        static let stopServiceButton = "health.button.stopService"
        static let startServiceButton = "health.button.startService"
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
        static let openLogsFolderButton = "settings.button.openLogsFolder"
        static let clearOldLogsButton = "settings.button.clearOldLogs"
        static let useKeychainToggle = "settings.toggle.useKeychain"
        static let viewKeychainButton = "settings.button.viewKeychain"
        static let enforceTLSToggle = "settings.toggle.enforceTLS"
        static let deleteCredentialsButton = "settings.button.deleteCredentials"
        static let debugLoggingToggle = "settings.toggle.debugLogging"
        static let verboseOutputToggle = "settings.toggle.verboseOutput"
        static let developerModeToggle = "settings.toggle.developerMode"
        static let openDevConsoleButton = "settings.button.openDevConsole"
        static let exportDiagnosticsButton = "settings.button.exportDiagnostics"
        static let resetAllButton = "settings.button.resetAll"
        static let clearCacheButton = "settings.button.clearCache"
        // Legacy aliases
        static let launchAtLogin = "settings.toggle.launchAtLogin"
        static let checkForUpdates = "settings.toggle.checkUpdates"
        static let enableNotifications = "settings.toggle.notifications"
        static let openLogFile = "settings.button.openLogsFolder"
        static let clearLogs = "settings.button.clearOldLogs"
        static let exportLogs = "settings.button.exportDiagnostics"
    }
    
    // MARK: - Menu Items
    enum Menu {
        static let newConfiguration = "menu.file.newConfiguration"
        static let openConfiguration = "menu.file.openConfiguration"
        static let saveConfiguration = "menu.file.saveConfiguration"
        static let emergencyDeployment = "menu.file.emergencyDeployment"
        static let velociraptorHelp = "menu.help.velociraptorHelp"
        static let troubleshooting = "menu.help.troubleshooting"
        static let reportIssue = "menu.help.reportIssue"
        static let about = "menu.about"
    }
    
    // MARK: - Dialogs
    enum Dialog {
        static let about = "dialog.about"
        static let yamlPreview = "dialog.yamlPreview"
        static let cancelConfirmation = "dialog.cancelConfirmation"
        static let deployConfirmation = "dialog.deployConfirmation"
        static let deleteCredentialsConfirmation = "dialog.deleteCredentialsConfirmation"
        static let error = "dialog.error"
    }
}
