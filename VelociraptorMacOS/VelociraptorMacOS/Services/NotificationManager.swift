//
//  NotificationManager.swift
//  VelociraptorMacOS
//
//  System notification management using UserNotifications framework
//

import Foundation
import UserNotifications

/// Manages system notifications for Velociraptor events
@MainActor
class NotificationManager: ObservableObject {
    // MARK: - Singleton
    
    static let shared = NotificationManager()
    
    // MARK: - Published Properties
    
    /// Whether notifications are enabled
    @Published var isEnabled: Bool = false
    
    /// Whether authorization has been granted
    @Published var isAuthorized: Bool = false
    
    /// Last notification error
    @Published var lastError: Error?
    
    // MARK: - Private Properties
    
    private let center = UNUserNotificationCenter.current()
    
    // MARK: - Notification Categories
    
    enum Category: String {
        case deployment = "DEPLOYMENT"
        case health = "HEALTH"
        case incident = "INCIDENT"
        case update = "UPDATE"
        
        var identifier: String { rawValue }
    }
    
    // MARK: - Notification Actions
    
    enum Action: String {
        case view = "VIEW"
        case dismiss = "DISMISS"
        case openGUI = "OPEN_GUI"
        case stopService = "STOP_SERVICE"
        case restartService = "RESTART_SERVICE"
    }
    
    // MARK: - Initialization
    
    private init() {
        Task {
            await checkAuthorization()
            await registerCategories()
        }
    }
    
    // MARK: - Authorization
    
    /// Request notification authorization from the user
    func requestAuthorization() async throws {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            isEnabled = granted
            
            if granted {
                Logger.shared.info("Notification authorization granted", component: "Notifications")
            } else {
                Logger.shared.warning("Notification authorization denied", component: "Notifications")
            }
        } catch {
            lastError = error
            Logger.shared.error("Failed to request notification authorization: \(error)", component: "Notifications")
            throw error
        }
    }
    
    /// Check current authorization status
    func checkAuthorization() async {
        let settings = await center.notificationSettings()
        
        switch settings.authorizationStatus {
        case .authorized, .provisional:
            isAuthorized = true
            isEnabled = true
        case .denied:
            isAuthorized = false
            isEnabled = false
        case .notDetermined:
            isAuthorized = false
            isEnabled = false
        @unknown default:
            isAuthorized = false
        }
    }
    
    // MARK: - Category Registration
    
    private func registerCategories() async {
        // Deployment actions
        let viewAction = UNNotificationAction(
            identifier: Action.view.rawValue,
            title: "View Details",
            options: [.foreground]
        )
        
        let dismissAction = UNNotificationAction(
            identifier: Action.dismiss.rawValue,
            title: "Dismiss",
            options: []
        )
        
        let openGUIAction = UNNotificationAction(
            identifier: Action.openGUI.rawValue,
            title: "Open Web GUI",
            options: [.foreground]
        )
        
        let stopServiceAction = UNNotificationAction(
            identifier: Action.stopService.rawValue,
            title: "Stop Service",
            options: [.destructive]
        )
        
        let restartServiceAction = UNNotificationAction(
            identifier: Action.restartService.rawValue,
            title: "Restart Service",
            options: [.foreground]
        )
        
        // Categories
        let deploymentCategory = UNNotificationCategory(
            identifier: Category.deployment.identifier,
            actions: [openGUIAction, viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let healthCategory = UNNotificationCategory(
            identifier: Category.health.identifier,
            actions: [restartServiceAction, stopServiceAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        let incidentCategory = UNNotificationCategory(
            identifier: Category.incident.identifier,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: [.hiddenPreviewsShowTitle]
        )
        
        let updateCategory = UNNotificationCategory(
            identifier: Category.update.identifier,
            actions: [viewAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([
            deploymentCategory,
            healthCategory,
            incidentCategory,
            updateCategory
        ])
    }
    
    // MARK: - Send Notifications
    
    /// Send a notification
    func send(
        title: String,
        body: String,
        category: Category = .deployment,
        userInfo: [String: Any] = [:],
        delay: TimeInterval = 0
    ) async throws {
        guard isEnabled && isAuthorized else {
            Logger.shared.warning("Notifications not enabled/authorized", component: "Notifications")
            return
        }
        
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category.identifier
        content.userInfo = userInfo
        
        let trigger: UNNotificationTrigger?
        if delay > 0 {
            trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        } else {
            trigger = nil
        }
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        try await center.add(request)
        Logger.shared.debug("Sent notification: \(title)", component: "Notifications")
    }
    
    // MARK: - Convenience Methods
    
    /// Notify deployment started
    func notifyDeploymentStarted() async {
        try? await send(
            title: "Deployment Started",
            body: "Velociraptor deployment is in progress...",
            category: .deployment
        )
    }
    
    /// Notify deployment completed
    func notifyDeploymentComplete(guiPort: Int = 8889) async {
        try? await send(
            title: "Deployment Complete",
            body: "Velociraptor is now running. Access the GUI at port \(guiPort).",
            category: .deployment,
            userInfo: ["guiPort": guiPort]
        )
    }
    
    /// Notify deployment failed
    func notifyDeploymentFailed(error: String) async {
        try? await send(
            title: "Deployment Failed",
            body: error,
            category: .deployment
        )
    }
    
    /// Notify service stopped
    func notifyServiceStopped() async {
        try? await send(
            title: "Service Stopped",
            body: "Velociraptor service has stopped running.",
            category: .health
        )
    }
    
    /// Notify service started
    func notifyServiceStarted() async {
        try? await send(
            title: "Service Started",
            body: "Velociraptor service is now running.",
            category: .health
        )
    }
    
    /// Notify health warning
    func notifyHealthWarning(issue: String) async {
        try? await send(
            title: "Health Warning",
            body: issue,
            category: .health
        )
    }
    
    /// Notify health critical
    func notifyHealthCritical(issue: String) async {
        try? await send(
            title: "Health Critical",
            body: issue,
            category: .health
        )
    }
    
    /// Notify collector built
    func notifyCollectorBuilt(name: String, path: String) async {
        try? await send(
            title: "Collector Built",
            body: "Collector '\(name)' has been created successfully.",
            category: .incident,
            userInfo: ["path": path]
        )
    }
    
    /// Notify update available
    func notifyUpdateAvailable(version: String) async {
        try? await send(
            title: "Update Available",
            body: "Velociraptor \(version) is available for download.",
            category: .update
        )
    }
    
    // MARK: - Manage Notifications
    
    /// Remove all pending notifications
    func removeAllPending() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// Remove all delivered notifications
    func removeAllDelivered() {
        center.removeAllDeliveredNotifications()
    }
    
    /// Get pending notification count
    func getPendingCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
    
    /// Get delivered notification count
    func getDeliveredCount() async -> Int {
        let notifications = await center.deliveredNotifications()
        return notifications.count
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        let userInfo = response.notification.request.content.userInfo
        
        Task { @MainActor in
            switch actionIdentifier {
            case NotificationManager.Action.openGUI.rawValue:
                if let port = userInfo["guiPort"] as? Int {
                    if let url = URL(string: "https://127.0.0.1:\(port)") {
                        NSWorkspace.shared.open(url)
                    }
                } else {
                    if let url = URL(string: "https://127.0.0.1:8889") {
                        NSWorkspace.shared.open(url)
                    }
                }
                
            case NotificationManager.Action.view.rawValue:
                // Bring app to foreground
                NSApp.activate(ignoringOtherApps: true)
                
            case NotificationManager.Action.stopService.rawValue:
                let manager = DeploymentManager()
                try? await manager.stopService()
                
            case NotificationManager.Action.restartService.rawValue:
                let manager = DeploymentManager()
                try? await manager.restartService()
                
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}
