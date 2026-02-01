//
//  Strings.swift
//  VelociraptorMacOS
//
//  Type-safe localization strings accessor
//

import SwiftUI

/// Type-safe accessor for localized strings
/// Use: Text(Strings.Welcome.title)
@MainActor
enum Strings {
    // MARK: - App General
    enum App {
        nonisolated(unsafe) static let name = LocalizedStringKey("app.name")
        nonisolated(unsafe) static let tagline = LocalizedStringKey("app.tagline")
        nonisolated(unsafe) static let version = LocalizedStringKey("app.version")
        nonisolated(unsafe) static let copyright = LocalizedStringKey("app.copyright")
        nonisolated(unsafe) static let freeForAll = LocalizedStringKey("app.freeForAll")
    }
    
    // MARK: - Common Actions
    enum Action {
        nonisolated(unsafe) static let next = LocalizedStringKey("action.next")
        nonisolated(unsafe) static let back = LocalizedStringKey("action.back")
        nonisolated(unsafe) static let cancel = LocalizedStringKey("action.cancel")
        nonisolated(unsafe) static let finish = LocalizedStringKey("action.finish")
        nonisolated(unsafe) static let save = LocalizedStringKey("action.save")
        nonisolated(unsafe) static let open = LocalizedStringKey("action.open")
        nonisolated(unsafe) static let close = LocalizedStringKey("action.close")
        nonisolated(unsafe) static let browse = LocalizedStringKey("action.browse")
        nonisolated(unsafe) static let reset = LocalizedStringKey("action.reset")
        nonisolated(unsafe) static let deploy = LocalizedStringKey("action.deploy")
        nonisolated(unsafe) static let copy = LocalizedStringKey("action.copy")
        nonisolated(unsafe) static let export = LocalizedStringKey("action.export")
        nonisolated(unsafe) static let importConfig = LocalizedStringKey("action.import")
        nonisolated(unsafe) static let retry = LocalizedStringKey("action.retry")
        nonisolated(unsafe) static let continueAction = LocalizedStringKey("action.continue")
    }
    
    // MARK: - Wizard Steps
    enum WizardStep {
        nonisolated(unsafe) static let welcome = LocalizedStringKey("wizard.step.welcome")
        nonisolated(unsafe) static let deploymentType = LocalizedStringKey("wizard.step.deploymentType")
        nonisolated(unsafe) static let certificateSettings = LocalizedStringKey("wizard.step.certificateSettings")
        nonisolated(unsafe) static let securitySettings = LocalizedStringKey("wizard.step.securitySettings")
        nonisolated(unsafe) static let storageConfiguration = LocalizedStringKey("wizard.step.storageConfiguration")
        nonisolated(unsafe) static let networkConfiguration = LocalizedStringKey("wizard.step.networkConfiguration")
        nonisolated(unsafe) static let authentication = LocalizedStringKey("wizard.step.authentication")
        nonisolated(unsafe) static let review = LocalizedStringKey("wizard.step.review")
        nonisolated(unsafe) static let complete = LocalizedStringKey("wizard.step.complete")
    }
    
    // MARK: - Welcome Step
    enum Welcome {
        nonisolated(unsafe) static let title = LocalizedStringKey("welcome.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("welcome.description")
        nonisolated(unsafe) static let standardSetup = LocalizedStringKey("welcome.standardSetup")
        nonisolated(unsafe) static let standardSetupDescription = LocalizedStringKey("welcome.standardSetup.description")
        nonisolated(unsafe) static let emergencyMode = LocalizedStringKey("welcome.emergencyMode")
        nonisolated(unsafe) static let emergencyModeDescription = LocalizedStringKey("welcome.emergencyMode.description")
    }
    
    // MARK: - Deployment Type
    enum DeploymentType {
        nonisolated(unsafe) static let title = LocalizedStringKey("deploymentType.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("deploymentType.description")
        nonisolated(unsafe) static let server = LocalizedStringKey("deploymentType.server")
        nonisolated(unsafe) static let serverDescription = LocalizedStringKey("deploymentType.server.description")
        nonisolated(unsafe) static let standalone = LocalizedStringKey("deploymentType.standalone")
        nonisolated(unsafe) static let standaloneDescription = LocalizedStringKey("deploymentType.standalone.description")
        nonisolated(unsafe) static let client = LocalizedStringKey("deploymentType.client")
        nonisolated(unsafe) static let clientDescription = LocalizedStringKey("deploymentType.client.description")
    }
    
    // MARK: - Certificate Settings
    enum Certificate {
        nonisolated(unsafe) static let title = LocalizedStringKey("certificate.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("certificate.description")
        nonisolated(unsafe) static let selfSigned = LocalizedStringKey("certificate.selfSigned")
        nonisolated(unsafe) static let selfSignedDescription = LocalizedStringKey("certificate.selfSigned.description")
        nonisolated(unsafe) static let custom = LocalizedStringKey("certificate.custom")
        nonisolated(unsafe) static let customDescription = LocalizedStringKey("certificate.custom.description")
        nonisolated(unsafe) static let letsEncrypt = LocalizedStringKey("certificate.letsEncrypt")
        nonisolated(unsafe) static let letsEncryptDescription = LocalizedStringKey("certificate.letsEncrypt.description")
        nonisolated(unsafe) static let expiration = LocalizedStringKey("certificate.expiration")
        nonisolated(unsafe) static let organization = LocalizedStringKey("certificate.organization")
        nonisolated(unsafe) static let path = LocalizedStringKey("certificate.path")
        nonisolated(unsafe) static let keyPath = LocalizedStringKey("certificate.keyPath")
        nonisolated(unsafe) static let domain = LocalizedStringKey("certificate.domain")
    }
    
    // MARK: - Security Settings
    enum Security {
        nonisolated(unsafe) static let title = LocalizedStringKey("security.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("security.description")
        nonisolated(unsafe) static let environment = LocalizedStringKey("security.environment")
        nonisolated(unsafe) static let logLevel = LocalizedStringKey("security.logLevel")
        nonisolated(unsafe) static let enableDebugLogging = LocalizedStringKey("security.enableDebugLogging")
        nonisolated(unsafe) static let enforceTLS = LocalizedStringKey("security.enforceTLS")
        nonisolated(unsafe) static let validateCerts = LocalizedStringKey("security.validateCerts")
        nonisolated(unsafe) static let restrictVQL = LocalizedStringKey("security.restrictVQL")
        nonisolated(unsafe) static let useKeychain = LocalizedStringKey("security.useKeychain")
        nonisolated(unsafe) static let enableNotifications = LocalizedStringKey("security.enableNotifications")
        nonisolated(unsafe) static let launchAtLogin = LocalizedStringKey("security.launchAtLogin")
        nonisolated(unsafe) static let autoCheckUpdates = LocalizedStringKey("security.autoCheckUpdates")
    }
    
    // MARK: - Storage Configuration
    enum Storage {
        nonisolated(unsafe) static let title = LocalizedStringKey("storage.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("storage.description")
        nonisolated(unsafe) static let datastore = LocalizedStringKey("storage.datastore")
        nonisolated(unsafe) static let datastoreDescription = LocalizedStringKey("storage.datastore.description")
        nonisolated(unsafe) static let logs = LocalizedStringKey("storage.logs")
        nonisolated(unsafe) static let logsDescription = LocalizedStringKey("storage.logs.description")
        nonisolated(unsafe) static let cache = LocalizedStringKey("storage.cache")
        nonisolated(unsafe) static let cacheDescription = LocalizedStringKey("storage.cache.description")
    }
    
    // MARK: - Network Configuration
    enum Network {
        nonisolated(unsafe) static let title = LocalizedStringKey("network.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("network.description")
        nonisolated(unsafe) static let frontend = LocalizedStringKey("network.frontend")
        nonisolated(unsafe) static let gui = LocalizedStringKey("network.gui")
        nonisolated(unsafe) static let api = LocalizedStringKey("network.api")
        nonisolated(unsafe) static let address = LocalizedStringKey("network.address")
        nonisolated(unsafe) static let port = LocalizedStringKey("network.port")
    }
    
    // MARK: - Authentication
    enum Auth {
        nonisolated(unsafe) static let title = LocalizedStringKey("auth.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("auth.description")
        nonisolated(unsafe) static let username = LocalizedStringKey("auth.username")
        nonisolated(unsafe) static let password = LocalizedStringKey("auth.password")
        nonisolated(unsafe) static let confirmPassword = LocalizedStringKey("auth.confirmPassword")
        nonisolated(unsafe) static let organization = LocalizedStringKey("auth.organization")
        nonisolated(unsafe) static let saveToKeychain = LocalizedStringKey("auth.saveToKeychain")
        nonisolated(unsafe) static let generatePassword = LocalizedStringKey("auth.generatePassword")
    }
    
    // MARK: - Review Step
    enum Review {
        nonisolated(unsafe) static let title = LocalizedStringKey("review.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("review.description")
        nonisolated(unsafe) static let validationSuccess = LocalizedStringKey("review.validation.success")
        nonisolated(unsafe) static let validationWarning = LocalizedStringKey("review.validation.warning")
        nonisolated(unsafe) static let previewYAML = LocalizedStringKey("review.preview.yaml")
        nonisolated(unsafe) static let exportConfig = LocalizedStringKey("review.export.config")
        nonisolated(unsafe) static let deployNow = LocalizedStringKey("review.deploy.now")
    }
    
    // MARK: - Complete Step
    enum Complete {
        nonisolated(unsafe) static let title = LocalizedStringKey("complete.title")
        nonisolated(unsafe) static let description = LocalizedStringKey("complete.description")
        nonisolated(unsafe) static let openGUI = LocalizedStringKey("complete.action.openGUI")
        nonisolated(unsafe) static let viewLogs = LocalizedStringKey("complete.action.viewLogs")
        nonisolated(unsafe) static let openDataFolder = LocalizedStringKey("complete.action.openDataFolder")
        nonisolated(unsafe) static let copyConfigPath = LocalizedStringKey("complete.action.copyConfigPath")
        nonisolated(unsafe) static let startService = LocalizedStringKey("complete.service.start")
        nonisolated(unsafe) static let stopService = LocalizedStringKey("complete.service.stop")
    }
    
    // MARK: - Emergency Mode
    enum Emergency {
        nonisolated(unsafe) static let title = LocalizedStringKey("emergency.title")
        nonisolated(unsafe) static let subtitle = LocalizedStringKey("emergency.subtitle")
        nonisolated(unsafe) static let deployNow = LocalizedStringKey("emergency.deploy.now")
        nonisolated(unsafe) static let success = LocalizedStringKey("emergency.success")
        nonisolated(unsafe) static let failure = LocalizedStringKey("emergency.failure")
    }
    
    // MARK: - Incident Response
    enum IncidentResponse {
        nonisolated(unsafe) static let title = LocalizedStringKey("ir.title")
        nonisolated(unsafe) static let selectIncident = LocalizedStringKey("ir.selectIncident")
        nonisolated(unsafe) static let buildCollector = LocalizedStringKey("ir.buildCollector")
        nonisolated(unsafe) static let reset = LocalizedStringKey("ir.reset")
    }
    
    // MARK: - Settings
    enum Settings {
        nonisolated(unsafe) static let title = LocalizedStringKey("settings.title")
        nonisolated(unsafe) static let general = LocalizedStringKey("settings.general")
        nonisolated(unsafe) static let security = LocalizedStringKey("settings.security")
        nonisolated(unsafe) static let advanced = LocalizedStringKey("settings.advanced")
        nonisolated(unsafe) static let launchAtLogin = LocalizedStringKey("settings.launchAtLogin")
        nonisolated(unsafe) static let checkUpdates = LocalizedStringKey("settings.checkUpdates")
        nonisolated(unsafe) static let notifications = LocalizedStringKey("settings.notifications")
    }
    
    // MARK: - Errors
    enum Error {
        nonisolated(unsafe) static let general = LocalizedStringKey("error.general")
        nonisolated(unsafe) static let networkUnavailable = LocalizedStringKey("error.network.unavailable")
        nonisolated(unsafe) static let invalidConfiguration = LocalizedStringKey("error.config.invalid")
        nonisolated(unsafe) static let deploymentFailed = LocalizedStringKey("error.deployment.failed")
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