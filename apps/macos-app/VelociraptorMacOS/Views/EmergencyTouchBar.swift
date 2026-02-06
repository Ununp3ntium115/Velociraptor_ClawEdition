//
//  EmergencyTouchBar.swift
//  VelociraptorMacOS
//
//  Touch Bar integration for Emergency Mode
//  Provides always-visible emergency button in the Touch Bar
//

import SwiftUI
import AppKit

// MARK: - Touch Bar Item Identifiers

extension NSTouchBarItem.Identifier {
    static let emergencyButton = NSTouchBarItem.Identifier("com.velocidex.claw.emergency")
    static let statusIndicator = NSTouchBarItem.Identifier("com.velocidex.claw.status")
    static let quickActions = NSTouchBarItem.Identifier("com.velocidex.claw.quickActions")
}

// MARK: - Emergency Touch Bar Provider

/// Provides the Touch Bar with an always-visible Emergency Mode button
@MainActor
final class EmergencyTouchBarProvider: NSObject, NSTouchBarDelegate, ObservableObject {
    
    // MARK: - Shared Instance
    
    static let shared = EmergencyTouchBarProvider()
    
    // MARK: - Published Properties
    
    @Published var phase: EmergencyPhase = .idle
    @Published var isArmed: Bool = false
    @Published var pulseAnimation: Bool = false
    
    // MARK: - Callbacks
    
    var onEmergencyTap: (() -> Void)?
    var onQuickActionTap: ((QuickAction) -> Void)?
    
    // MARK: - Observers
    
    var phaseObserver: Any?
    
    // MARK: - Quick Actions
    
    enum QuickAction: String, CaseIterable {
        case collectArtifacts = "Collect Artifacts"
        case runVQL = "Run VQL"
        case viewLogs = "View Logs"
    }
    
    // MARK: - Touch Bar Creation
    
    func makeTouchBar() -> NSTouchBar {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.defaultItemIdentifiers = [
            .emergencyButton,
            .flexibleSpace,
            .statusIndicator,
            .flexibleSpace,
            .quickActions
        ]
        return touchBar
    }
    
    // MARK: - NSTouchBarDelegate
    
    nonisolated func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        switch identifier {
        case .emergencyButton:
            return MainActor.assumeIsolated {
                makeEmergencyButtonItem()
            }
        case .statusIndicator:
            return MainActor.assumeIsolated {
                makeStatusIndicatorItem()
            }
        case .quickActions:
            return MainActor.assumeIsolated {
                makeQuickActionsItem()
            }
        default:
            return nil
        }
    }
    
    // MARK: - Emergency Button Item
    
    private func makeEmergencyButtonItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .emergencyButton)
        
        // Create SwiftUI view for the button
        let hostingView = NSHostingView(
            rootView: EmergencyTouchBarButton(
                phase: phase,
                isArmed: isArmed,
                onTap: { [weak self] in
                    self?.onEmergencyTap?()
                }
            )
        )
        
        hostingView.frame = NSRect(x: 0, y: 0, width: 150, height: 30)
        item.view = hostingView
        item.customizationLabel = "Emergency Mode"
        
        return item
    }
    
    // MARK: - Status Indicator Item
    
    private func makeStatusIndicatorItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .statusIndicator)
        
        let hostingView = NSHostingView(
            rootView: StatusIndicatorView(phase: phase)
        )
        
        hostingView.frame = NSRect(x: 0, y: 0, width: 100, height: 30)
        item.view = hostingView
        item.customizationLabel = "Status"
        
        return item
    }
    
    // MARK: - Quick Actions Item
    
    private func makeQuickActionsItem() -> NSTouchBarItem {
        let item = NSCustomTouchBarItem(identifier: .quickActions)
        
        let hostingView = NSHostingView(
            rootView: QuickActionsView(
                onAction: { [weak self] action in
                    self?.onQuickActionTap?(action)
                }
            )
        )
        
        hostingView.frame = NSRect(x: 0, y: 0, width: 200, height: 30)
        item.view = hostingView
        item.customizationLabel = "Quick Actions"
        
        return item
    }
    
    // MARK: - Update Methods
    
    func updatePhase(_ newPhase: EmergencyPhase) {
        self.phase = newPhase
        self.isArmed = newPhase.isHot
    }
    
    func startPulse() {
        Task { @MainActor in
            while phase == .idle {
                pulseAnimation = true
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                pulseAnimation = false
                try? await Task.sleep(nanoseconds: 1_500_000_000)
            }
        }
    }
}

// MARK: - Emergency Touch Bar Button View

struct EmergencyTouchBarButton: View {
    let phase: EmergencyPhase
    let isArmed: Bool
    let onTap: () -> Void
    
    @State private var isPulsing = false
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: buttonIcon)
                    .font(.system(size: 12, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                
                Text(buttonText)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(buttonBackground)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .scaleEffect(isPulsing ? 1.02 : 1.0)
        }
        .buttonStyle(.plain)
        .onAppear {
            startIdlePulse()
        }
        .onChange(of: phase) { _, newPhase in
            if newPhase == .idle {
                startIdlePulse()
            } else {
                isPulsing = false
            }
        }
        .accessibilityIdentifier("touchbar.emergency.button")
    }
    
    private var buttonIcon: String {
        switch phase {
        case .idle:
            return "exclamationmark.triangle.fill"
        case .armed:
            return "hand.tap.fill"
        case .confirming:
            return "timer"
        case .backupPrompt:
            return "arrow.triangle.2.circlepath"
        case .lockingDown:
            return "lock.fill"
        case .running:
            return "waveform.path.ecg"
        case .cancelled:
            return "xmark.circle.fill"
        }
    }
    
    private var buttonText: String {
        switch phase {
        case .idle:
            return "Emergency"
        case .armed:
            return "Tap Again"
        case .confirming(let seconds):
            return "\(seconds)s..."
        case .backupPrompt:
            return "Backup?"
        case .lockingDown:
            return "Locking..."
        case .running:
            return "ACTIVE"
        case .cancelled:
            return "Cancelled"
        }
    }
    
    private var buttonBackground: some ShapeStyle {
        switch phase {
        case .idle:
            return AnyShapeStyle(Color.red.opacity(0.7))
        case .armed:
            return AnyShapeStyle(Color.orange)
        case .confirming:
            return AnyShapeStyle(Color.red)
        case .lockingDown, .running:
            return AnyShapeStyle(
                LinearGradient(
                    colors: [.red, .orange],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        default:
            return AnyShapeStyle(Color.gray)
        }
    }
    
    private func startIdlePulse() {
        guard phase == .idle else { return }
        
        Task { @MainActor in
            while phase == .idle {
                withAnimation(.easeInOut(duration: 1.2)) {
                    isPulsing = true
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
                withAnimation(.easeInOut(duration: 1.2)) {
                    isPulsing = false
                }
                try? await Task.sleep(nanoseconds: 1_200_000_000)
            }
        }
    }
}

// MARK: - Status Indicator View

struct StatusIndicatorView: View {
    let phase: EmergencyPhase
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.system(size: 10))
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .accessibilityIdentifier("touchbar.status.indicator")
    }
    
    private var statusColor: Color {
        switch phase {
        case .idle:
            return .green
        case .armed, .confirming:
            return .orange
        case .lockingDown, .running:
            return .red
        case .backupPrompt:
            return .yellow
        case .cancelled:
            return .gray
        }
    }
    
    private var statusText: String {
        switch phase {
        case .idle:
            return "Ready"
        case .armed:
            return "Armed"
        case .confirming:
            return "Confirming"
        case .backupPrompt:
            return "Backup"
        case .lockingDown:
            return "Locking"
        case .running:
            return "FORENSIC MODE"
        case .cancelled:
            return "Cancelled"
        }
    }
}

// MARK: - Quick Actions View

struct QuickActionsView: View {
    let onAction: (EmergencyTouchBarProvider.QuickAction) -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(EmergencyTouchBarProvider.QuickAction.allCases, id: \.self) { action in
                Button(action: { onAction(action) }) {
                    Image(systemName: iconFor(action))
                        .font(.system(size: 12))
                }
                .buttonStyle(.plain)
                .help(action.rawValue)
                .accessibilityIdentifier("touchbar.quickaction.\(action.rawValue.lowercased().replacingOccurrences(of: " ", with: "."))")
            }
        }
    }
    
    private func iconFor(_ action: EmergencyTouchBarProvider.QuickAction) -> String {
        switch action {
        case .collectArtifacts:
            return "doc.text.magnifyingglass"
        case .runVQL:
            return "terminal"
        case .viewLogs:
            return "list.bullet.rectangle"
        }
    }
}

// MARK: - Touch Bar Window Controller

/// Manages Touch Bar for the main application window
final class TouchBarWindowController: NSWindowController {
    
    private let touchBarProvider = EmergencyTouchBarProvider.shared
    
    override func makeTouchBar() -> NSTouchBar? {
        return touchBarProvider.makeTouchBar()
    }
}

// MARK: - App Delegate Extension for Touch Bar

extension AppDelegate {
    
    /// Configures the application Touch Bar with Emergency Mode integration
    @MainActor
    func configureTouchBar() {
        let controller = AppDelegate.sharedEmergencyController
        let touchBarProvider = EmergencyTouchBarProvider.shared
        
        // Wire Touch Bar tap to EmergencyController
        touchBarProvider.onEmergencyTap = { [weak controller] in
            Task { @MainActor in
                controller?.handleTap()
            }
        }
        
        // Wire quick actions
        touchBarProvider.onQuickActionTap = { action in
            Task { @MainActor in
                // Post notification for quick actions to be handled by appropriate views
                NotificationCenter.default.post(
                    name: Notification.Name("QuickActionTriggered"),
                    object: action
                )
                Logger.shared.info("Quick action triggered: \(action.rawValue)", component: "TouchBar")
            }
        }
        
        // Subscribe to EmergencyController phase changes
        touchBarProvider.phaseObserver = NotificationCenter.default.addObserver(
            forName: Notification.Name("EmergencyPhaseChanged"),
            object: nil,
            queue: .main
        ) { [weak touchBarProvider] notification in
            if let phase = notification.userInfo?["phase"] as? EmergencyPhase {
                Task { @MainActor in
                    touchBarProvider?.updatePhase(phase)
                }
            }
        }
        
        // Initial sync
        touchBarProvider.updatePhase(controller.phase)
        
        // Start idle pulse animation
        touchBarProvider.startPulse()
        
        Logger.shared.info("Touch Bar wired to EmergencyController", component: "TouchBar")
    }
}

// MARK: - Preview

#Preview("Touch Bar Button - Idle") {
    EmergencyTouchBarButton(phase: .idle, isArmed: false, onTap: {})
        .padding()
        .frame(width: 200, height: 50)
}

#Preview("Touch Bar Button - Armed") {
    EmergencyTouchBarButton(phase: .armed(firstTapAt: Date()), isArmed: true, onTap: {})
        .padding()
        .frame(width: 200, height: 50)
}

#Preview("Touch Bar Button - Running") {
    EmergencyTouchBarButton(phase: .running, isArmed: true, onTap: {})
        .padding()
        .frame(width: 200, height: 50)
}

#Preview("Status Indicator") {
    VStack(spacing: 10) {
        StatusIndicatorView(phase: .idle)
        StatusIndicatorView(phase: .armed(firstTapAt: Date()))
        StatusIndicatorView(phase: .running)
    }
    .padding()
}
