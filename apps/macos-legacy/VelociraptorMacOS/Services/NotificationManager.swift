//
//  NotificationManager.swift
//  VelociraptorMacOS
//
//  System notification management using UserNotifications framework
//

import Foundation
import UserNotifications
import AppKit

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
    
    /// Requests user permission for alert, sound, and badge notifications and updates the manager's published state.
    /// 
    /// If authorization is granted, `isAuthorized` and `isEnabled` are set to `true`; if denied they are set to `false`. On failure `lastError` is updated and the error is rethrown.
    /// - Throws: Any error produced by the system authorization request.
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
    
    /// Updates the manager's published authorization state from the system notification settings.
    /// 
    /// Queries the current UNUserNotificationCenter settings and updates `isAuthorized` and `isEnabled`:
    /// - `authorized` or `provisional` → `isAuthorized = true`, `isEnabled = true`
    /// - `denied` or `notDetermined` → `isAuthorized = false`, `isEnabled = false`
    /// - unknown future cases → `isAuthorized = false`
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
    
    /// Registers the app's notification categories and their actions with the system notification center.
    /// 
    /// Creates and registers categories for deployment, health, incident, and update notifications and associates each category with its relevant actions (view, dismiss, open GUI, stop service, restart service) so user interactions are available on delivered notifications.
    
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
    
    /// Schedules and delivers a user notification with the specified content and category.
    /// 
    /// If notifications are not enabled or authorization has not been granted, the call is a no-op and no notification is sent.
    /// - Parameters:
    ///   - title: The notification title.
    ///   - body: The notification body text.
    ///   - category: The notification category to attach (uses its identifier); defaults to `.deployment`.
    ///   - userInfo: Arbitrary payload delivered with the notification; values must be property-list compatible.
    ///   - delay: Number of seconds to wait before delivery; use `0` to deliver immediately.
    /// - Throws: An error from `UNUserNotificationCenter` if adding the notification request fails.
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
    
    /// Sends a "Deployment Started" user notification under the deployment category to indicate a deployment is in progress.
    func notifyDeploymentStarted() async {
        try? await send(
            title: "Deployment Started",
            body: "Velociraptor deployment is in progress...",
            category: .deployment
        )
    }
    
    /// Sends a "Deployment Complete" user notification announcing that Velociraptor is running and includes the GUI port in the notification's `userInfo`.
    /// - Parameter guiPort: TCP port where the local GUI is available; defaults to 8889.
    func notifyDeploymentComplete(guiPort: Int = 8889) async {
        try? await send(
            title: "Deployment Complete",
            body: "Velociraptor is now running. Access the GUI at port \(guiPort).",
            category: .deployment,
            userInfo: ["guiPort": guiPort]
        )
    }
    
    /// Sends a "Deployment Failed" user notification containing the provided error message.
    /// - Parameter error: The error message to include in the notification body.
    func notifyDeploymentFailed(error: String) async {
        try? await send(
            title: "Deployment Failed",
            body: error,
            category: .deployment
        )
    }
    
    /// Sends a "Service Stopped" user notification using the health category.
    func notifyServiceStopped() async {
        try? await send(
            title: "Service Stopped",
            body: "Velociraptor service has stopped running.",
            category: .health
        )
    }
    
    /// Sends a "Service Started" user notification.
    /// 
    /// The notification uses the health category with a predefined title ("Service Started") and body ("Velociraptor service is now running.").
    func notifyServiceStarted() async {
        try? await send(
            title: "Service Started",
            body: "Velociraptor service is now running.",
            category: .health
        )
    }
    
    /// Sends a health warning notification with the provided issue message.
    /// - Parameter issue: The warning message to display in the notification body.
    func notifyHealthWarning(issue: String) async {
        try? await send(
            title: "Health Warning",
            body: issue,
            category: .health
        )
    }
    
    /// Sends a critical health notification to the system notification center with the provided issue message.
    /// - Parameter issue: Description of the critical health issue to display in the notification body.
    func notifyHealthCritical(issue: String) async {
        try? await send(
            title: "Health Critical",
            body: issue,
            category: .health
        )
    }
    
    /// Posts a user notification indicating a collector was created.
    /// - Parameters:
    ///   - name: The collector's name shown in the notification body.
    ///   - path: Filesystem path of the created collector; included in the notification's `userInfo` under the `"path"` key.
    func notifyCollectorBuilt(name: String, path: String) async {
        try? await send(
            title: "Collector Built",
            body: "Collector '\(name)' has been created successfully.",
            category: .incident,
            userInfo: ["path": path]
        )
    }
    
    /// Sends a user notification indicating a Velociraptor update is available.
    /// - Parameter version: The version string displayed in the notification body.
    func notifyUpdateAvailable(version: String) async {
        try? await send(
            title: "Update Available",
            body: "Velociraptor \(version) is available for download.",
            category: .update
        )
    }
    
    // MARK: - Manage Notifications
    
    /// Removes all pending notification requests from the user notification center.
    ///
    /// This only clears pending (scheduled) requests; notifications already delivered to the notification center are not affected.
    func removeAllPending() {
        center.removeAllPendingNotificationRequests()
    }
    
    /// Removes all notifications that have been delivered and are currently visible in the system Notification Center.
    func removeAllDelivered() {
        center.removeAllDeliveredNotifications()
    }
    
    /// Get the current number of pending user notification requests.
    /// - Returns: The number of pending notification requests.
    func getPendingCount() async -> Int {
        let requests = await center.pendingNotificationRequests()
        return requests.count
    }
    
    /// Retrieves the number of notifications that have been delivered and are present in the notification center.
    /// - Returns: The count of delivered notifications.
    func getDeliveredCount() async -> Int {
        let notifications = await center.deliveredNotifications()
        return notifications.count
    }
}

// MARK: - Notification Delegate

final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate, @unchecked Sendable {
    nonisolated(unsafe) static let shared = NotificationDelegate()
    
    /// Handles user interactions with delivered notifications and performs the corresponding app actions.
    /// - Parameters:
    ///   - center: The notification center that delivered the response.
    ///   - response: The user's response; `response.notification.request.content.userInfo` may contain `"guiPort"` (Int) used by the `openGUI` action.
    ///   - completionHandler: Called after the response has been handled.
    /// 
    /// Actions handled:
    /// - `openGUI`: Opens the local web GUI at `https://127.0.0.1:<port>` using `guiPort` from `userInfo`, or `8889` if absent.
    /// - `view`: Brings the app to the foreground.
    /// - `stopService`: Requests the service to stop via `DeploymentManager.stopService()`.
    /// - `restartService`: Requests the service to restart via `DeploymentManager.restartService()`.
    /// 
    /// All action handling is performed on the main actor.
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let actionIdentifier = response.actionIdentifier
        // Extract values before Task to avoid sending mutable dictionary
        let guiPort = response.notification.request.content.userInfo["guiPort"] as? Int ?? 8889
        
        Task { @MainActor in
            switch actionIdentifier {
            case NotificationManager.Action.openGUI.rawValue:
                if let url = URL(string: "https://127.0.0.1:\(guiPort)") {
                    NSWorkspace.shared.open(url)
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
    
    /// Present the incoming notification as a banner with sound while the app is in the foreground.
    /// - Parameters:
    ///   - center: The notification center that delivered the notification.
    ///   - notification: The notification to present.
    ///   - completionHandler: Call with the desired `UNNotificationPresentationOptions` to control how the notification is shown (e.g., `.banner`, `.sound`).
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
}