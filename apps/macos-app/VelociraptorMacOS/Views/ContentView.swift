//
//  ContentView.swift
//  VelociraptorMacOS
//
//  Main content view with navigation sidebar
//

import SwiftUI

/// Main content view with sidebar navigation and step-based content
struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var deploymentManager: DeploymentManager
    @EnvironmentObject var keychainManager: KeychainManager
    @EnvironmentObject var apiClient: VelociraptorAPIClient
    @EnvironmentObject var webSocketService: WebSocketService
    
    var body: some View {
        NavigationSplitView {
            SidebarView()
                .accessibilityId(AccessibilityIdentifiers.Navigation.sidebar)
        } detail: {
            // Switch between wizard mode and other views - matches Electron feature set
            switch appState.selectedSidebarItem {
            // Core
            case .wizard:
                wizardContent
            case .dashboard:
                DashboardView()
                    .environmentObject(configViewModel)
                    .environmentObject(apiClient)
                    .environmentObject(webSocketService)
            case .terminal:
                TerminalView()
                    .accessibilityIdentifier("terminal.main")
            
            // Investigation
            case .clients:
                ClientsView()
                    .accessibilityIdentifier("clients.main")
            case .hunt:
                HuntManagerView()
                    .accessibilityIdentifier("hunt.main")
            case .artifacts:
                ArtifactManagerView()
                    .accessibilityIdentifier("artifacts.main")
            case .notebooks:
                NotebooksView()
                    .accessibilityIdentifier("notebooks.main")
            case .vfs:
                VFSBrowserView()
                    .accessibilityIdentifier("vfs.main")
            case .evidence:
                EvidenceView()
                    .accessibilityIdentifier("evidence.main")
            case .labels:
                LabelsView()
                    .accessibilityIdentifier("labels.main")
            
            // Operations
            case .incidentResponse:
                IncidentResponseView()
            case .health:
                HealthMonitorView()
            case .orchestration:
                OrchestrationView()
                    .accessibilityIdentifier("orchestration.main")
            case .training:
                TrainingView()
                    .accessibilityIdentifier("training.main")
            
            // Tools & Packages
            case .tools:
                ToolsManagerView()
                    .accessibilityIdentifier("tools.main")
            case .packages:
                PackageManagerView()
                    .accessibilityIdentifier("packages.main")
            case .offlinePackages:
                OfflinePackageBuilderView()
                    .accessibilityIdentifier("offlinePackages.main")
            
            // Integrations & AI
            case .integrations:
                IntegrationsSettingsView()
                    .accessibilityIdentifier("integrations.main")
            case .aiChat:
                AIChatView()
                    .accessibilityIdentifier("aiChat.main")
            
            // Reports & Logs
            case .reports:
                ReportsView()
                    .accessibilityIdentifier("reports.main")
            case .logs:
                LogsView()
            case .timeline:
                TimelineView()
                    .accessibilityIdentifier("timeline.main")
            
            // System
            case .binaryLifecycle:
                BinaryLifecycleView()
                    .accessibilityIdentifier("binaryLifecycle.main")
            case .settings:
                SettingsView()
                    .accessibilityIdentifier("settings.main")
            }
        }
        .navigationTitle("")
        .toolbar {
            MainToolbarContent()
        }
        .alert("Error", isPresented: $appState.showError) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            Text(appState.errorMessage ?? "An unknown error occurred")
        }
        .sheet(isPresented: $appState.showEmergencyMode) {
            EmergencyModeView()
                .accessibilityId(AccessibilityIdentifiers.EmergencyMode.sheet)
        }
        .sheet(isPresented: $appState.showAbout) {
            AboutView()
                .accessibilityId(AccessibilityIdentifiers.Dialog.about)
        }
        // Touch Bar Integration - Emergency Button always visible
        .touchBar(TouchBar {
            TouchBarButton(appState: appState)
        })
    }
    
    /// Wizard content with header, steps, and navigation
    @ViewBuilder
    var wizardContent: some View {
        VStack(spacing: 0) {
            // Header
            HeaderView()
            
            Divider()
            
            // Main content area
            ScrollView {
                StepContentView()
                    .padding()
            }
            
            Divider()
            
            // Progress bar
            ProgressView(value: appState.wizardProgress)
                .progressViewStyle(.linear)
                .padding(.horizontal)
                .padding(.vertical, 4)
                .accessibilityId(AccessibilityIdentifiers.Navigation.progressBar)
            
            // Navigation buttons
            NavigationButtonsView()
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
        }
    }
}

// MARK: - Touch Bar Emergency Button State

/// Represents the visual and functional states of the Emergency Touch Bar button
enum EmergencyButtonState: String, CaseIterable {
    case idle           // Default state - red button with subtle pulse
    case armed          // First tap - orange glow, awaiting confirmation
    case confirming     // Second tap confirmed - countdown animation
    case lockedDown     // Forensic mode active - green checkmark
    
    /// VoiceOver label for each state
    var accessibilityLabel: String {
        switch self {
        case .idle:
            return "Emergency button. Double tap to arm, then tap again to activate forensic mode."
        case .armed:
            return "Emergency button armed. Tap again within 3 seconds to confirm activation."
        case .confirming:
            return "Activating forensic mode. Countdown in progress."
        case .lockedDown:
            return "Forensic mode is active. System locked for evidence preservation."
        }
    }
    
    /// Display text for the button
    var buttonText: String {
        switch self {
        case .idle:
            return "EMERGENCY"
        case .armed:
            return "TAP AGAIN TO CONFIRM"
        case .confirming:
            return "ACTIVATING..."
        case .lockedDown:
            return "FORENSIC MODE ACTIVE"
        }
    }
    
    /// SF Symbol icon for each state
    var iconName: String {
        switch self {
        case .idle:
            return "exclamationmark.triangle.fill"
        case .armed:
            return "hand.tap.fill"
        case .confirming:
            return "timer"
        case .lockedDown:
            return "checkmark.shield.fill"
        }
    }
}

// MARK: - Touch Bar Button View

struct TouchBarButton: View {
    @ObservedObject var appState: AppState
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    // State management
    @State private var buttonState: EmergencyButtonState = .idle
    @State private var armTimestamp: Date?
    
    // Animation states
    @State private var isPulsing = false
    @State private var glowIntensity: CGFloat = 0.3
    @State private var countdownProgress: CGFloat = 1.0
    @State private var countdownValue: Int = 3
    @State private var ringRotation: Double = 0
    
    // Timeout configuration
    private let armTimeoutSeconds: TimeInterval = 3.0
    private let countdownDurationSeconds: Int = 3
    
    var body: some View {
        HStack(spacing: 12) {
            // Emergency Button - Liquid Glass Design
            emergencyButton
            
            Spacer()
            
            // Status Indicator - Center
            statusIndicator
            
            Spacer()
            
            // Quick Action Buttons - Right
            quickActionButtons
        }
        .frame(maxWidth: .infinity)
        .onChange(of: appState.showEmergencyMode) { _, newValue in
            if newValue {
                withAnimation(.easeInOut(duration: 0.3)) {
                    buttonState = .lockedDown
                }
            } else if buttonState == .lockedDown {
                withAnimation(.easeInOut(duration: 0.3)) {
                    buttonState = .idle
                }
            }
        }
    }
    
    // MARK: - Emergency Button with Liquid Glass Styling
    
    private var emergencyButton: some View {
        Button {
            handleEmergencyTap()
        } label: {
            ZStack {
                // Liquid Glass Background Layer
                liquidGlassBackground
                
                // Content Layer
                HStack(spacing: 6) {
                    // Icon with state-based animation
                    ZStack {
                        if buttonState == .confirming {
                            // Countdown ring animation
                            Circle()
                                .trim(from: 0, to: countdownProgress)
                                .stroke(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 2, lineCap: .round)
                                )
                                .frame(width: 16, height: 16)
                                .rotationEffect(.degrees(ringRotation - 90))
                            
                            Text("\(countdownValue)")
                                .font(.system(size: 8, weight: .heavy, design: .rounded))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: buttonState.iconName)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(iconGradient)
                                .shadow(color: iconGlowColor.opacity(0.6), radius: reduceMotion ? 0 : 4)
                        }
                    }
                    .frame(width: 18, height: 18)
                    
                    // Text Label
                    Text(buttonState.buttonText)
                        .font(.system(size: buttonState == .armed ? 9 : 11, weight: .bold, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .foregroundColor(.white)
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            // Outer glow effect
            .shadow(
                color: outerGlowColor.opacity(reduceMotion ? 0.3 : glowIntensity),
                radius: reduceMotion ? 2 : (buttonState == .armed ? 8 : 4)
            )
            .scaleEffect(reduceMotion ? 1.0 : (isPulsing ? 1.04 : 1.0))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("touchbar.emergency.button")
        .accessibilityLabel(buttonState.accessibilityLabel)
        .accessibilityAddTraits(buttonState == .lockedDown ? .isSelected : [])
        .accessibilityHint(buttonState == .idle ? "Initiates emergency forensic lockdown" : "")
        .onAppear {
            startAnimations()
        }
        .onDisappear {
            stopAnimations()
        }
    }
    
    // MARK: - Liquid Glass Background
    
    private var liquidGlassBackground: some View {
        ZStack {
            // Base material layer - ultra thin for glass effect
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
            
            // Gradient overlay based on state
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(backgroundGradient)
                .opacity(0.85)
            
            // Subtle neon edge highlight
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: edgeGradientColors,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .opacity(reduceMotion ? 0.5 : (buttonState == .armed ? 0.9 : 0.6))
            
            // Inner glow layer
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .strokeBorder(
                    innerGlowColor.opacity(reduceMotion ? 0.1 : 0.25),
                    lineWidth: 2
                )
                .blur(radius: 2)
                .padding(1)
        }
    }
    
    // MARK: - Status Indicator
    
    private var statusIndicator: some View {
        HStack(spacing: 6) {
            // Animated status dot
            ZStack {
                Circle()
                    .fill(statusDotColor.opacity(0.3))
                    .frame(width: 12, height: 12)
                    .blur(radius: 2)
                
                Circle()
                    .fill(statusDotColor)
                    .frame(width: 8, height: 8)
                    .shadow(color: statusDotColor.opacity(0.5), radius: 2)
            }
            
            Text(statusLabelText)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .accessibilityIdentifier("touchbar.status")
        .accessibilityLabel("Status: \(statusLabelText)")
    }
    
    // MARK: - Quick Action Buttons
    
    private var quickActionButtons: some View {
        HStack(spacing: 6) {
            TouchBarQuickActionButton(
                icon: "doc.text.magnifyingglass",
                label: "Collect",
                accessibilityId: "touchbar.collect",
                action: { appState.selectedSidebarItem = .incidentResponse }
            )
            
            TouchBarQuickActionButton(
                icon: "terminal",
                label: "VQL",
                accessibilityId: "touchbar.vql",
                action: { appState.selectedSidebarItem = .terminal }
            )
            
            TouchBarQuickActionButton(
                icon: "list.bullet.rectangle",
                label: "Logs",
                accessibilityId: "touchbar.logs",
                action: { appState.selectedSidebarItem = .logs }
            )
        }
    }
    
    // MARK: - Computed Properties for Styling
    
    private var backgroundGradient: LinearGradient {
        switch buttonState {
        case .idle:
            return LinearGradient(
                colors: [
                    Color.red.opacity(0.9),
                    Color.red.opacity(0.7),
                    Color(red: 0.6, green: 0.1, blue: 0.1)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .armed:
            return LinearGradient(
                colors: [
                    Color.orange,
                    Color(red: 1.0, green: 0.6, blue: 0.0),
                    Color(red: 0.9, green: 0.4, blue: 0.0)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .confirming:
            return LinearGradient(
                colors: [
                    Color.orange.opacity(0.8),
                    Color.red.opacity(0.8)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .lockedDown:
            return LinearGradient(
                colors: [
                    Color.green.opacity(0.9),
                    Color(red: 0.2, green: 0.7, blue: 0.3),
                    Color(red: 0.1, green: 0.5, blue: 0.2)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    private var edgeGradientColors: [Color] {
        switch buttonState {
        case .idle:
            return [
                Color.red.opacity(0.8),
                Color.pink.opacity(0.6),
                Color.red.opacity(0.4)
            ]
        case .armed:
            return [
                Color.yellow,
                Color.orange,
                Color(red: 1.0, green: 0.5, blue: 0.0)
            ]
        case .confirming:
            return [
                Color.orange,
                Color.red,
                Color.orange
            ]
        case .lockedDown:
            return [
                Color.green.opacity(0.8),
                Color.mint.opacity(0.6),
                Color.green.opacity(0.4)
            ]
        }
    }
    
    private var iconGradient: LinearGradient {
        LinearGradient(
            colors: [.white, .white.opacity(0.9)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
    
    private var iconGlowColor: Color {
        switch buttonState {
        case .idle: return .red
        case .armed: return .orange
        case .confirming: return .yellow
        case .lockedDown: return .green
        }
    }
    
    private var innerGlowColor: Color {
        switch buttonState {
        case .idle: return .pink
        case .armed: return .yellow
        case .confirming: return .orange
        case .lockedDown: return .mint
        }
    }
    
    private var outerGlowColor: Color {
        switch buttonState {
        case .idle: return .red
        case .armed: return .orange
        case .confirming: return .red
        case .lockedDown: return .green
        }
    }
    
    private var statusDotColor: Color {
        switch buttonState {
        case .idle:
            return appState.showEmergencyMode ? .red : .green
        case .armed:
            return .orange
        case .confirming:
            return .yellow
        case .lockedDown:
            return .green
        }
    }
    
    private var statusLabelText: String {
        switch buttonState {
        case .idle:
            return appState.showEmergencyMode ? "FORENSIC MODE" : "Ready"
        case .armed:
            return "ARMED - \(Int(armTimeoutSeconds))s"
        case .confirming:
            return "ACTIVATING..."
        case .lockedDown:
            return "LOCKED DOWN"
        }
    }
    
    // MARK: - Tap Handler with Two-Tap Arming Flow
    
    private func handleEmergencyTap() {
        switch buttonState {
        case .idle:
            // First tap: Arm the button
            armButton()
            
        case .armed:
            // Second tap within timeout: Start confirmation countdown
            if let timestamp = armTimestamp,
               Date().timeIntervalSince(timestamp) < armTimeoutSeconds {
                startConfirmationCountdown()
            } else {
                // Timeout expired, reset to idle
                resetToIdle()
            }
            
        case .confirming:
            // Already confirming, ignore additional taps
            break
            
        case .lockedDown:
            // Already locked down - could toggle off or show status
            break
        }
    }
    
    private func armButton() {
        armTimestamp = Date()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            buttonState = .armed
            glowIntensity = 0.7
        }
        
        // Auto-reset after timeout if not confirmed
        Task { @MainActor in
            try? await Task.sleep(for: .seconds(armTimeoutSeconds))
            if buttonState == .armed {
                resetToIdle()
            }
        }
    }
    
    private func startConfirmationCountdown() {
        withAnimation(.easeInOut(duration: 0.2)) {
            buttonState = .confirming
            countdownValue = countdownDurationSeconds
            countdownProgress = 1.0
        }
        
        // Animate the countdown ring
        if !reduceMotion {
            withAnimation(.linear(duration: Double(countdownDurationSeconds))) {
                ringRotation = 360
            }
        }
        
        // Countdown timer
        Task { @MainActor in
            for i in stride(from: countdownDurationSeconds, through: 1, by: -1) {
                countdownValue = i
                
                withAnimation(.linear(duration: 1.0)) {
                    countdownProgress = CGFloat(i - 1) / CGFloat(countdownDurationSeconds)
                }
                
                try? await Task.sleep(for: .seconds(1))
            }
            
            // Countdown complete - activate forensic mode
            activateForensicMode()
        }
    }
    
    private func activateForensicMode() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            buttonState = .lockedDown
            glowIntensity = 0.5
        }
        
        appState.showEmergencyMode = true
        armTimestamp = nil
        ringRotation = 0
    }
    
    private func resetToIdle() {
        withAnimation(.easeOut(duration: 0.3)) {
            buttonState = .idle
            glowIntensity = 0.3
            countdownProgress = 1.0
            countdownValue = countdownDurationSeconds
            ringRotation = 0
        }
        armTimestamp = nil
    }
    
    // MARK: - Animation Control
    
    private func startAnimations() {
        guard !reduceMotion else { return }
        
        // Subtle pulse animation for idle state
        Task { @MainActor in
            while true {
                if buttonState == .idle {
                    withAnimation(.easeInOut(duration: 1.2)) {
                        isPulsing = true
                        glowIntensity = 0.5
                    }
                    try? await Task.sleep(for: .seconds(1.2))
                    
                    withAnimation(.easeInOut(duration: 1.2)) {
                        isPulsing = false
                        glowIntensity = 0.3
                    }
                    try? await Task.sleep(for: .seconds(1.2))
                } else if buttonState == .armed {
                    // Faster pulse for armed state
                    withAnimation(.easeInOut(duration: 0.5)) {
                        glowIntensity = 0.9
                    }
                    try? await Task.sleep(for: .seconds(0.5))
                    
                    withAnimation(.easeInOut(duration: 0.5)) {
                        glowIntensity = 0.5
                    }
                    try? await Task.sleep(for: .seconds(0.5))
                } else {
                    try? await Task.sleep(for: .seconds(0.5))
                }
            }
        }
    }
    
    private func stopAnimations() {
        isPulsing = false
    }
}

// MARK: - Touch Bar Quick Action Button

/// Reusable quick action button with Liquid Glass styling for Touch Bar
struct TouchBarQuickActionButton: View {
    let icon: String
    let label: String
    let accessibilityId: String
    let action: () -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .medium))
                Text(label)
                    .font(.system(size: 8, weight: .medium, design: .rounded))
            }
            .foregroundColor(isHovered ? .white : .secondary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .opacity(isHovered ? 0.8 : 0.4)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6, style: .continuous)
                    .strokeBorder(
                        Color.white.opacity(isHovered ? 0.3 : 0.1),
                        lineWidth: 0.5
                    )
            )
        }
        .buttonStyle(.plain)
        .help(label)
        .accessibilityIdentifier(accessibilityId)
        .accessibilityLabel(label)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Sidebar View

struct SidebarView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        List {
            // Main navigation section
            Section("Main") {
                ForEach([AppState.SidebarItem.dashboard, .health, .incidentResponse, .integrations, .offlinePackages, .aiChat, .terminal, .binaryLifecycle, .logs], id: \.self) { item in
                    Button {
                        appState.selectedSidebarItem = item
                    } label: {
                        Label(item.rawValue, systemImage: item.iconName)
                    }
                    .buttonStyle(.plain)
                    .padding(.vertical, 4)
                    .background(appState.selectedSidebarItem == item ? Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(6)
                }
            }
            
            // Configuration Wizard section
            Section("Configuration Wizard") {
                Button {
                    appState.selectedSidebarItem = .wizard
                } label: {
                    Label("Wizard", systemImage: "wand.and.stars")
                }
                .buttonStyle(.plain)
                .padding(.vertical, 4)
                .background(appState.selectedSidebarItem == .wizard ? Color.accentColor.opacity(0.2) : Color.clear)
                .cornerRadius(6)
                
                // Only show wizard steps when in wizard mode
                if appState.selectedSidebarItem == .wizard {
                    ForEach(AppState.WizardStep.allCases) { step in
                        SidebarStepRow(step: step, currentStep: appState.currentStep)
                            .onTapGesture {
                                if step.rawValue <= appState.currentStep.rawValue {
                                    appState.goToStep(step)
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }
}

struct SidebarStepRow: View {
    let step: AppState.WizardStep
    let currentStep: AppState.WizardStep
    
    var isCompleted: Bool {
        step.rawValue < currentStep.rawValue
    }
    
    var isCurrent: Bool {
        step == currentStep
    }
    
    var isAccessible: Bool {
        step.rawValue <= currentStep.rawValue
    }
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator
            ZStack {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 28, height: 28)
                
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                } else {
                    Text("\(step.rawValue + 1)")
                        .font(.caption.bold())
                        .foregroundColor(isCurrent ? .white : .secondary)
                }
            }
            
            // Step info
            VStack(alignment: .leading, spacing: 2) {
                Text(step.title)
                    .font(.subheadline)
                    .fontWeight(isCurrent ? .semibold : .regular)
                    .foregroundColor(isAccessible ? .primary : .secondary)
            }
            
            Spacer()
            
            // Current indicator
            if isCurrent {
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .opacity(isAccessible ? 1.0 : 0.5)
    }
    
    private var backgroundColor: Color {
        if isCompleted {
            return .green
        } else if isCurrent {
            return .accentColor
        } else {
            return Color(NSColor.separatorColor)
        }
    }
}

// MARK: - Header View

struct HeaderView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        HStack(spacing: 16) {
            // Velociraptor Claw Edition Logo
            ClawLogoInline(size: 44)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text("VELOCIRAPTOR")
                        .font(.title.bold())
                    Text("CLAW EDITION")
                        .font(.title3.bold())
                        .foregroundStyle(.secondary)
                }
                
                Text("DFIR Platform Configuration Wizard")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Current step info
            VStack(alignment: .trailing, spacing: 4) {
                Text("Step \(appState.currentStep.rawValue + 1) of \(AppState.WizardStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(appState.currentStep.title)
                    .font(.headline)
            }
        }
        .padding()
        .background(Color.accentColor.opacity(0.05))
    }
}

// MARK: - Step Content View

struct StepContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Step header
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: appState.currentStep.iconName)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    Text(appState.currentStep.title)
                        .font(.title2.bold())
                }
                
                Text(appState.currentStep.description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            // Step-specific content
            stepContent
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var stepContent: some View {
        switch appState.currentStep {
        case .welcome:
            WelcomeStepView()
        case .deploymentType:
            DeploymentTypeStepView()
        case .certificateSettings:
            CertificateSettingsStepView()
        case .securitySettings:
            SecuritySettingsStepView()
        case .storageConfiguration:
            StorageConfigurationStepView()
        case .networkConfiguration:
            NetworkConfigurationStepView()
        case .authentication:
            AuthenticationStepView()
        case .aiConfiguration:
            AIConfigurationStepView()
        case .mdmConfiguration:
            MDMConfigurationStepView()
        case .review:
            ReviewStepView()
        case .complete:
            CompleteStepView()
        }
    }
}

// MARK: - Navigation Buttons View

struct NavigationButtonsView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    @State private var showCancelConfirmation = false
    
    var body: some View {
        HStack {
            // Emergency mode button
            Button {
                appState.showEmergencyMode = true
            } label: {
                Label("Emergency Mode", systemImage: "exclamationmark.triangle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
            .help("Rapid emergency deployment")
            .accessibilityId(AccessibilityIdentifiers.Navigation.emergencyButton)
            
            Spacer()
            
            // Back button
            Button {
                appState.previousStep()
            } label: {
                Text(Strings.Action.back)
            }
            .disabled(!appState.canGoBack || deploymentManager.isDeploying)
            .keyboardShortcut(.leftArrow, modifiers: [.command])
            .accessibilityId(AccessibilityIdentifiers.Navigation.backButton)
            
            // Next/Finish button
            Button {
                if appState.currentStep == .complete {
                    NSApplication.shared.terminate(nil)
                } else {
                    handleNextStep()
                }
            } label: {
                Text(appState.currentStep == .complete ? Strings.Action.finish : Strings.Action.next)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed || deploymentManager.isDeploying)
            .keyboardShortcut(.rightArrow, modifiers: [.command])
            .accessibilityId(AccessibilityIdentifiers.Navigation.nextButton)
            
            // Cancel button
            Button(role: .cancel) {
                showCancelConfirmation = true
            } label: {
                Text(Strings.Action.cancel)
            }
            .disabled(deploymentManager.isDeploying)
            .accessibilityId(AccessibilityIdentifiers.Navigation.cancelButton)
        }
        .confirmationDialog("Cancel Configuration?", isPresented: $showCancelConfirmation) {
            Button("Cancel Configuration", role: .destructive) {
                NSApplication.shared.terminate(nil)
            }
            Button("Continue Editing", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel? Any unsaved changes will be lost.")
        }
    }
    
    private var canProceed: Bool {
        configViewModel.validateStep(appState.currentStep)
    }
    
    /// Validate the current wizard step and advance to the next step if validation succeeds.
    /// 
    /// If validation fails, presents the first validation error via `appState.displayError(_:)` and does not change the current step.
    private func handleNextStep() {
        // Validate current step
        guard configViewModel.validateStep(appState.currentStep) else {
            let errors = configViewModel.errorsForStep(appState.currentStep)
            if let firstError = errors.first {
                appState.displayError(message: firstError.localizedDescription)
            }
            return
        }
        
        appState.nextStep()
    }
}

// MARK: - Toolbar Content

struct MainToolbarContent: ToolbarContent {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var deploymentManager: DeploymentManager
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            if deploymentManager.isDeploying {
                ProgressView()
                    .controlSize(.small)
            }
            
            Button {
                // Open incident response window
                if let url = URL(string: "velociraptormacos://incident-response") {
                    NSWorkspace.shared.open(url)
                }
            } label: {
                Label("Incident Response", systemImage: "exclamationmark.shield.fill")
            }
            .help("Open Incident Response Collector")
        }
        
        ToolbarItemGroup(placement: .secondaryAction) {
            Menu {
                Button("Check Health") {
                    // Health check action
                }
                
                Button("View Logs") {
                    // View logs action
                }
                
                Divider()
                
                Button("Reset to Defaults") {
                    // Reset action
                }
            } label: {
                Label("Actions", systemImage: "ellipsis.circle")
            }
        }
    }
}

// MARK: - About View

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            ClawLogoInline(size: 80)
            
            HStack(spacing: 8) {
                Text("Velociraptor")
                    .font(.largeTitle.bold())
                Text("Claw Edition")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            Text("DFIR Platform for macOS")
                .font(.title3)
                .foregroundColor(.secondary)
            
            Text("Version 5.0.5")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Divider()
            
            Text("Free For All First Responders")
                .font(.headline)
                .foregroundColor(.accentColor)
            
            Text("© 2026 Velocidex Enterprises")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Close") {
                dismiss()
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(width: 400)
    }
}

// MARK: - Preview

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(ConfigurationViewModel())
        .environmentObject(DeploymentManager())
        .environmentObject(KeychainManager())
        .environmentObject(IncidentResponseViewModel())
}