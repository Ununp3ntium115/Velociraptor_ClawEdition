//
//  Strings.swift
//  VelociraptorMacOS
//
//  Type-safe localization strings accessor
//

import SwiftUI

/// Type-safe accessor for localized strings
/// Use: Text(Strings.Welcome.title)
enum Strings {
    // MARK: - App General
    enum App {
        static let name = LocalizedStringKey("app.name")
        static let tagline = LocalizedStringKey("app.tagline")
        static let version = LocalizedStringKey("app.version")
        static let copyright = LocalizedStringKey("app.copyright")
        static let freeForAll = LocalizedStringKey("app.freeForAll")
    }
    
    // MARK: - Common Actions
    enum Action {
        static let next = LocalizedStringKey("action.next")
        static let back = LocalizedStringKey("action.back")
        static let cancel = LocalizedStringKey("action.cancel")
        static let finish = LocalizedStringKey("action.finish")
        static let save = LocalizedStringKey("action.save")
        static let open = LocalizedStringKey("action.open")
        static let close = LocalizedStringKey("action.close")
        static let browse = LocalizedStringKey("action.browse")
        static let reset = LocalizedStringKey("action.reset")
        static let deploy = LocalizedStringKey("action.deploy")
        static let copy = LocalizedStringKey("action.copy")
        static let export = LocalizedStringKey("action.export")
        static let importConfig = LocalizedStringKey("action.import")
        static let retry = LocalizedStringKey("action.retry")
        static let continueAction = LocalizedStringKey("action.continue")
    }
    
    // MARK: - Wizard Steps
    enum WizardStep {
        static let welcome = LocalizedStringKey("wizard.step.welcome")
        static let deploymentType = LocalizedStringKey("wizard.step.deploymentType")
        static let certificateSettings = LocalizedStringKey("wizard.step.certificateSettings")
        static let securitySettings = LocalizedStringKey("wizard.step.securitySettings")
        static let storageConfiguration = LocalizedStringKey("wizard.step.storageConfiguration")
        static let networkConfiguration = LocalizedStringKey("wizard.step.networkConfiguration")
        static let authentication = LocalizedStringKey("wizard.step.authentication")
        static let review = LocalizedStringKey("wizard.step.review")
        static let complete = LocalizedStringKey("wizard.step.complete")
    }
    
    // MARK: - Welcome Step
    enum Welcome {
        static let title = LocalizedStringKey("welcome.title")
        static let description = LocalizedStringKey("welcome.description")
        static let standardSetup = LocalizedStringKey("welcome.standardSetup")
        static let standardSetupDescription = LocalizedStringKey("welcome.standardSetup.description")
        static let emergencyMode = LocalizedStringKey("welcome.emergencyMode")
        static let emergencyModeDescription = LocalizedStringKey("welcome.emergencyMode.description")
    }
    
    // MARK: - Deployment Type
    enum DeploymentType {
        static let title = LocalizedStringKey("deploymentType.title")
        static let description = LocalizedStringKey("deploymentType.description")
        static let server = LocalizedStringKey("deploymentType.server")
        static let serverDescription = LocalizedStringKey("deploymentType.server.description")
        static let standalone = LocalizedStringKey("deploymentType.standalone")
        static let standaloneDescription = LocalizedStringKey("deploymentType.standalone.description")
        static let client = LocalizedStringKey("deploymentType.client")
        static let clientDescription = LocalizedStringKey("deploymentType.client.description")
    }
    
    // MARK: - Certificate Settings
    enum Certificate {
        static let title = LocalizedStringKey("certificate.title")
        static let description = LocalizedStringKey("certificate.description")
        static let selfSigned = LocalizedStringKey("certificate.selfSigned")
        static let selfSignedDescription = LocalizedStringKey("certificate.selfSigned.description")
        static let custom = LocalizedStringKey("certificate.custom")
        static let customDescription = LocalizedStringKey("certificate.custom.description")
        static let letsEncrypt = LocalizedStringKey("certificate.letsEncrypt")
        static let letsEncryptDescription = LocalizedStringKey("certificate.letsEncrypt.description")
        static let expiration = LocalizedStringKey("certificate.expiration")
        static let organization = LocalizedStringKey("certificate.organization")
        static let path = LocalizedStringKey("certificate.path")
        static let keyPath = LocalizedStringKey("certificate.keyPath")
        static let domain = LocalizedStringKey("certificate.domain")
    }
    
    // MARK: - Security Settings
    enum Security {
        static let title = LocalizedStringKey("security.title")
        static let description = LocalizedStringKey("security.description")
        static let environment = LocalizedStringKey("security.environment")
        static let logLevel = LocalizedStringKey("security.logLevel")
        static let enableDebugLogging = LocalizedStringKey("security.enableDebugLogging")
        static let enforceTLS = LocalizedStringKey("security.enforceTLS")
        static let validateCerts = LocalizedStringKey("security.validateCerts")
        static let restrictVQL = LocalizedStringKey("security.restrictVQL")
        static let useKeychain = LocalizedStringKey("security.useKeychain")
        static let enableNotifications = LocalizedStringKey("security.enableNotifications")
        static let launchAtLogin = LocalizedStringKey("security.launchAtLogin")
        static let autoCheckUpdates = LocalizedStringKey("security.autoCheckUpdates")
    }
    
    // MARK: - Storage Configuration
    enum Storage {
        static let title = LocalizedStringKey("storage.title")
        static let description = LocalizedStringKey("storage.description")
        static let datastore = LocalizedStringKey("storage.datastore")
        static let datastoreDescription = LocalizedStringKey("storage.datastore.description")
        static let logs = LocalizedStringKey("storage.logs")
        static let logsDescription = LocalizedStringKey("storage.logs.description")
        static let cache = LocalizedStringKey("storage.cache")
        static let cacheDescription = LocalizedStringKey("storage.cache.description")
    }
    
    // MARK: - Network Configuration
    enum Network {
        static let title = LocalizedStringKey("network.title")
        static let description = LocalizedStringKey("network.description")
        static let frontend = LocalizedStringKey("network.frontend")
        static let gui = LocalizedStringKey("network.gui")
        static let api = LocalizedStringKey("network.api")
        static let address = LocalizedStringKey("network.address")
        static let port = LocalizedStringKey("network.port")
    }
    
    // MARK: - Authentication
    enum Auth {
        static let title = LocalizedStringKey("auth.title")
        static let description = LocalizedStringKey("auth.description")
        static let username = LocalizedStringKey("auth.username")
        static let password = LocalizedStringKey("auth.password")
        static let confirmPassword = LocalizedStringKey("auth.confirmPassword")
        static let organization = LocalizedStringKey("auth.organization")
        static let saveToKeychain = LocalizedStringKey("auth.saveToKeychain")
        static let generatePassword = LocalizedStringKey("auth.generatePassword")
    }
    
    // MARK: - Review Step
    enum Review {
        static let title = LocalizedStringKey("review.title")
        static let description = LocalizedStringKey("review.description")
        static let validationSuccess = LocalizedStringKey("review.validation.success")
        static let validationWarning = LocalizedStringKey("review.validation.warning")
        static let previewYAML = LocalizedStringKey("review.preview.yaml")
        static let exportConfig = LocalizedStringKey("review.export.config")
        static let deployNow = LocalizedStringKey("review.deploy.now")
    }
    
    // MARK: - Complete Step
    enum Complete {
        static let title = LocalizedStringKey("complete.title")
        static let description = LocalizedStringKey("complete.description")
        static let openGUI = LocalizedStringKey("complete.action.openGUI")
        static let viewLogs = LocalizedStringKey("complete.action.viewLogs")
        static let openDataFolder = LocalizedStringKey("complete.action.openDataFolder")
        static let copyConfigPath = LocalizedStringKey("complete.action.copyConfigPath")
        static let startService = LocalizedStringKey("complete.service.start")
        static let stopService = LocalizedStringKey("complete.service.stop")
    }
    
    // MARK: - Emergency Mode
    enum Emergency {
        static let title = LocalizedStringKey("emergency.title")
        static let subtitle = LocalizedStringKey("emergency.subtitle")
        static let deployNow = LocalizedStringKey("emergency.deploy.now")
        static let success = LocalizedStringKey("emergency.success")
        static let failure = LocalizedStringKey("emergency.failure")
    }
    
    // MARK: - Incident Response
    enum IncidentResponse {
        static let title = LocalizedStringKey("ir.title")
        static let selectIncident = LocalizedStringKey("ir.selectIncident")
        static let buildCollector = LocalizedStringKey("ir.buildCollector")
        static let reset = LocalizedStringKey("ir.reset")
    }
    
    // MARK: - Settings
    enum Settings {
        static let title = LocalizedStringKey("settings.title")
        static let general = LocalizedStringKey("settings.general")
        static let security = LocalizedStringKey("settings.security")
        static let advanced = LocalizedStringKey("settings.advanced")
        static let launchAtLogin = LocalizedStringKey("settings.launchAtLogin")
        static let checkUpdates = LocalizedStringKey("settings.checkUpdates")
        static let notifications = LocalizedStringKey("settings.notifications")
    }
    
    // MARK: - Errors
    enum Error {
        static let general = LocalizedStringKey("error.general")
        static let networkUnavailable = LocalizedStringKey("error.network.unavailable")
        static let invalidConfiguration = LocalizedStringKey("error.config.invalid")
        static let deploymentFailed = LocalizedStringKey("error.deployment.failed")
    }
}

// MARK: - String Extension for non-SwiftUI contexts

extension String {
    /// Fetches the localized string for a localization key.
    /// - Parameter key: The lookup key from the app's localization tables (e.g., Localizable.strings).
    /// - Returns: The localized string for `key`, or `key` itself if no translation is found.
    static func localized(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }
}