//
//  EmergencyLockdownView.swift
//  VelociraptorMacOS
//
//  Full-Screen Emergency Lockdown View with Deep Space Aesthetics
//  Velociraptor Claw Edition - Cinematic forensic mode activation
//
//  Features:
//  - Full-screen overlay with particle field background
//  - Three Liquid Glass panels (ARMING, COUNTDOWN, FORENSIC MODE)
//  - Cinematic countdown with circular ring depletion
//  - Smooth state transitions with morphing animations
//  - VoiceOver accessibility support
//

import SwiftUI

// MARK: - Lockdown Phase

/// Visual phases for the lockdown overlay
enum LockdownPhase: Equatable {
    case arming
    case countdown(seconds: Int)
    case lockingDown
    case lockedDown
    case cancelled
    
    var isActive: Bool {
        switch self {
        case .cancelled: return false
        default: return true
        }
    }
}

// MARK: - Emergency Lockdown View

struct EmergencyLockdownView: View {
    @Binding var phase: LockdownPhase
    @Binding var isPresented: Bool
    var onCancel: () -> Void
    
    @State private var showContent = false
    @State private var particleTime: TimeInterval = 0
    
    // Animation states
    @State private var ringProgress: Double = 1.0
    @State private var countdownScale: CGFloat = 1.0
    @State private var panelOpacity: Double = 0
    @State private var leftPanelOffset: CGFloat = -100
    @State private var rightPanelOffset: CGFloat = 100
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Deep space background with particle field
                DeepSpaceBackground(time: particleTime)
                    .ignoresSafeArea()
                
                // Red tint overlay (~30% opacity)
                Color.red
                    .opacity(redTintOpacity)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.5), value: phase)
                
                // Main content: Three glass panels
                if showContent {
                    VStack(spacing: 0) {
                        Spacer()
                        
                        HStack(spacing: 24) {
                            // Left panel: ARMING status
                            armingPanel
                                .offset(x: leftPanelOffset)
                                .opacity(panelOpacity)
                            
                            // Center panel: Countdown
                            countdownPanel(geometry: geometry)
                                .opacity(panelOpacity)
                            
                            // Right panel: FORENSIC MODE status
                            forensicPanel
                                .offset(x: rightPanelOffset)
                                .opacity(panelOpacity)
                        }
                        .padding(.horizontal, 40)
                        
                        Spacer()
                        
                        // Cancel button
                        if canCancel {
                            cancelButton
                                .padding(.bottom, 60)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .ignoresSafeArea()
        .onAppear {
            startAnimations()
        }
        .onChange(of: phase) { _, newPhase in
            handlePhaseChange(newPhase)
        }
        .accessibilityIdentifier("emergency.lockdown.fullscreen")
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityDescription)
    }
    
    // MARK: - Red Tint Opacity
    
    private var redTintOpacity: Double {
        switch phase {
        case .arming: return 0.15
        case .countdown: return 0.25
        case .lockingDown: return 0.35
        case .lockedDown: return 0.1
        case .cancelled: return 0.0
        }
    }
    
    // MARK: - Can Cancel
    
    private var canCancel: Bool {
        switch phase {
        case .arming, .countdown: return true
        default: return false
        }
    }
    
    // MARK: - Arming Panel
    
    private var armingPanel: some View {
        GlassPanel {
            VStack(spacing: 16) {
                // Shield icon with pulse animation
                Image(systemName: armingIconName)
                    .font(.system(size: 44, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(armingIconColor)
                    .symbolEffect(.pulse, options: .repeating, isActive: phase == .arming)
                
                Text(armingTitle)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(2)
                
                Text(armingSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 180, height: 200)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Arming status: \(armingTitle)")
    }
    
    private var armingIconName: String {
        switch phase {
        case .arming: return "shield.lefthalf.filled"
        case .countdown: return "shield.fill"
        case .lockingDown: return "shield.checkered"
        case .lockedDown: return "checkmark.shield.fill"
        case .cancelled: return "xmark.shield"
        }
    }
    
    private var armingIconColor: Color {
        switch phase {
        case .arming: return .orange
        case .countdown: return .red
        case .lockingDown: return .orange
        case .lockedDown: return .green
        case .cancelled: return .gray
        }
    }
    
    private var armingTitle: String {
        switch phase {
        case .arming: return "ARMING"
        case .countdown: return "ARMED"
        case .lockingDown: return "ENGAGING"
        case .lockedDown: return "SECURED"
        case .cancelled: return "CANCELLED"
        }
    }
    
    private var armingSubtitle: String {
        switch phase {
        case .arming: return "Preparing lockdown\nprotocols..."
        case .countdown: return "Waiting for\nconfirmation"
        case .lockingDown: return "Applying security\nmeasures..."
        case .lockedDown: return "All systems\nlocked down"
        case .cancelled: return "Operation\naborted"
        }
    }
    
    // MARK: - Countdown Panel
    
    private func countdownPanel(geometry: GeometryProxy) -> some View {
        GlassPanel(prominent: true) {
            VStack(spacing: 20) {
                Text(countdownHeader)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .tracking(3)
                
                // Large countdown with ring
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    
                    // Progress ring (depletes as countdown progresses)
                    Circle()
                        .trim(from: 0, to: ringProgress)
                        .stroke(
                            AngularGradient(
                                colors: ringGradientColors,
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1), value: ringProgress)
                    
                    // Countdown number with morphing transition
                    Group {
                        switch phase {
                        case .countdown(let seconds):
                            Text("\(seconds)")
                                .font(.system(size: 72, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .contentTransition(.numericText(countsDown: true))
                                .scaleEffect(countdownScale)
                                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: seconds)
                        case .arming:
                            Image(systemName: "hand.tap")
                                .font(.system(size: 48))
                                .foregroundStyle(.orange)
                                .opacity(countdownScale) // Pulse effect instead of symbolEffect
                        case .lockingDown:
                            ProgressView()
                                .scaleEffect(2)
                                .tint(.orange)
                        case .lockedDown:
                            Image(systemName: "lock.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.green)
                        case .cancelled:
                            Image(systemName: "xmark")
                                .font(.system(size: 48))
                                .foregroundStyle(.gray)
                        }
                    }
                }
                .frame(width: 160, height: 160)
                
                Text(countdownMessage)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            .frame(width: 260, height: 320)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(countdownAccessibilityLabel)
    }
    
    private var countdownHeader: String {
        switch phase {
        case .arming: return "PREPARING"
        case .countdown: return "INITIATING IN"
        case .lockingDown: return "LOCKING DOWN"
        case .lockedDown: return "LOCKDOWN ACTIVE"
        case .cancelled: return "CANCELLED"
        }
    }
    
    private var countdownMessage: String {
        switch phase {
        case .arming: return "Tap again to confirm\nemergency lockdown"
        case .countdown(let seconds): return "\(seconds) second\(seconds == 1 ? "" : "s") remaining"
        case .lockingDown: return "Blocking network ports\nPreserving forensic data"
        case .lockedDown: return "System is now in\nforensic collection mode"
        case .cancelled: return "Lockdown cancelled\nReturning to normal"
        }
    }
    
    private var countdownAccessibilityLabel: String {
        switch phase {
        case .countdown(let seconds):
            return "Countdown: \(seconds) seconds remaining"
        default:
            return countdownHeader
        }
    }
    
    private var ringGradientColors: [Color] {
        switch phase {
        case .arming: return [.orange, .yellow, .orange]
        case .countdown: return [.red, .orange, .red]
        case .lockingDown: return [.orange, .red, .orange]
        case .lockedDown: return [.green, .mint, .green]
        case .cancelled: return [.gray, .gray.opacity(0.5), .gray]
        }
    }
    
    // MARK: - Forensic Panel
    
    private var forensicPanel: some View {
        GlassPanel {
            VStack(spacing: 16) {
                // Status icon
                Image(systemName: forensicIconName)
                    .font(.system(size: 44, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(forensicIconColor)
                    .symbolEffect(.variableColor, options: .repeating, isActive: phase == .lockedDown)
                
                Text(forensicTitle)
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundStyle(.white)
                    .tracking(2)
                
                Text(forensicSubtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 180, height: 200)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Forensic mode status: \(forensicTitle)")
    }
    
    private var forensicIconName: String {
        switch phase {
        case .arming, .countdown: return "doc.text.magnifyingglass"
        case .lockingDown: return "externaldrive.badge.timemachine"
        case .lockedDown: return "internaldrive.fill"
        case .cancelled: return "xmark.circle"
        }
    }
    
    private var forensicIconColor: Color {
        switch phase {
        case .arming, .countdown: return .blue.opacity(0.7)
        case .lockingDown: return .orange
        case .lockedDown: return .green
        case .cancelled: return .gray
        }
    }
    
    private var forensicTitle: String {
        switch phase {
        case .arming, .countdown: return "STANDBY"
        case .lockingDown: return "CAPTURING"
        case .lockedDown: return "ACTIVE"
        case .cancelled: return "OFFLINE"
        }
    }
    
    private var forensicSubtitle: String {
        switch phase {
        case .arming, .countdown: return "Forensic collection\nready to engage"
        case .lockingDown: return "Preserving volatile\nmemory & artifacts"
        case .lockedDown: return "Evidence collection\nin progress"
        case .cancelled: return "Collection\ndisabled"
        }
    }
    
    // MARK: - Cancel Button
    
    private var cancelButton: some View {
        Button(action: {
            withAnimation(.easeOut(duration: 0.3)) {
                onCancel()
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                Text("CANCEL")
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .tracking(1)
            }
            .foregroundStyle(.white.opacity(0.8))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay(
                        Capsule()
                            .strokeBorder(.white.opacity(0.15), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.escape, modifiers: [])
        .accessibilityIdentifier(AccessibilityIdentifiers.EmergencyMode.cancelButton)
        .accessibilityLabel("Cancel lockdown")
        .accessibilityHint("Press to abort the emergency lockdown sequence")
    }
    
    // MARK: - Accessibility
    
    private var accessibilityDescription: String {
        switch phase {
        case .arming:
            return "Emergency lockdown arming. Tap again to confirm or press Escape to cancel."
        case .countdown(let seconds):
            return "Emergency lockdown in \(seconds) seconds. Press Escape to cancel."
        case .lockingDown:
            return "Emergency lockdown in progress. Securing system."
        case .lockedDown:
            return "Forensic mode active. System is locked down for evidence collection."
        case .cancelled:
            return "Emergency lockdown cancelled."
        }
    }
    
    // MARK: - Animations
    
    private func startAnimations() {
        // Start particle animation
        withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
            particleTime = 1000
        }
        
        // Animate panels in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
            showContent = true
            panelOpacity = 1
            leftPanelOffset = 0
            rightPanelOffset = 0
        }
        
        // Set initial ring progress based on phase
        if case .countdown(let seconds) = phase {
            ringProgress = Double(seconds) / 5.0
        }
    }
    
    private func handlePhaseChange(_ newPhase: LockdownPhase) {
        // Update ring progress for countdown
        if case .countdown(let seconds) = newPhase {
            withAnimation(.linear(duration: 1)) {
                ringProgress = Double(seconds) / 5.0
            }
            
            // Pulse the countdown number
            countdownScale = 1.1
            withAnimation(.spring(response: 0.2, dampingFraction: 0.5)) {
                countdownScale = 1.0
            }
            
            // VoiceOver announcement
            announceForVoiceOver("Countdown: \(seconds)")
        }
        
        // Handle lockdown completion
        if case .lockedDown = newPhase {
            withAnimation(.easeInOut(duration: 0.5)) {
                ringProgress = 1.0
            }
            announceForVoiceOver("Forensic mode is now active")
        }
        
        // Handle cancellation - fade out
        if case .cancelled = newPhase {
            withAnimation(.easeOut(duration: 0.5)) {
                panelOpacity = 0
                leftPanelOffset = -50
                rightPanelOffset = 50
            }
            
            // Dismiss after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                isPresented = false
            }
        }
    }
    
    private func announceForVoiceOver(_ message: String) {
        DispatchQueue.main.async {
            NSAccessibility.post(element: NSApp as Any, notification: .announcementRequested, userInfo: [
                .announcement: message,
                .priority: NSAccessibilityPriorityLevel.high
            ])
        }
    }
}

// MARK: - Glass Panel Component

private struct GlassPanel<Content: View>: View {
    let prominent: Bool
    let content: Content
    
    init(prominent: Bool = false, @ViewBuilder content: () -> Content) {
        self.prominent = prominent
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.25), .white.opacity(0.05)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(color: .black.opacity(0.3), radius: prominent ? 30 : 20, y: 10)
            )
    }
}

// MARK: - Deep Space Background

private struct DeepSpaceBackground: View {
    let time: TimeInterval
    
    var body: some View {
        Canvas { context, size in
            // Draw gradient background
            let gradient = Gradient(colors: [
                Color(red: 0.02, green: 0.02, blue: 0.05),
                Color(red: 0.05, green: 0.03, blue: 0.1),
                Color(red: 0.03, green: 0.02, blue: 0.08)
            ])
            
            context.fill(
                Path(CGRect(origin: .zero, size: size)),
                with: .linearGradient(
                    gradient,
                    startPoint: .zero,
                    endPoint: CGPoint(x: size.width, y: size.height)
                )
            )
            
            // Draw star field particles
            drawParticles(context: context, size: size, time: time)
        }
    }
    
    private func drawParticles(context: GraphicsContext, size: CGSize, time: TimeInterval) {
        // Deterministic pseudo-random star positions
        let starCount = 150
        
        for i in 0..<starCount {
            // Generate deterministic positions using simple hash
            let seed = Double(i) * 1.618033988749
            let baseX = (seed.truncatingRemainder(dividingBy: 1.0)) * size.width
            let baseY = ((seed * 2.718281828).truncatingRemainder(dividingBy: 1.0)) * size.height
            
            // Add subtle movement
            let speed = 0.5 + (seed.truncatingRemainder(dividingBy: 0.5))
            let offsetX = sin(time * speed + Double(i)) * 2
            let offsetY = cos(time * speed * 0.7 + Double(i)) * 2
            
            let x = baseX + offsetX
            let y = baseY + offsetY
            
            // Star brightness varies
            let baseBrightness = 0.3 + (seed * 0.7).truncatingRemainder(dividingBy: 0.7)
            let twinkle = sin(time * 2 + Double(i) * 0.5) * 0.2 + 0.8
            let brightness = baseBrightness * twinkle
            
            // Star size
            let starSize = 1.0 + (seed.truncatingRemainder(dividingBy: 2.0))
            
            // Draw star with glow
            let starPath = Path(ellipseIn: CGRect(
                x: x - starSize / 2,
                y: y - starSize / 2,
                width: starSize,
                height: starSize
            ))
            
            // Different star colors
            let colorIndex = i % 4
            let starColor: Color = switch colorIndex {
            case 0: Color.white
            case 1: Color(red: 0.9, green: 0.95, blue: 1.0)
            case 2: Color(red: 1.0, green: 0.9, blue: 0.85)
            default: Color(red: 0.85, green: 0.9, blue: 1.0)
            }
            
            context.fill(starPath, with: .color(starColor.opacity(brightness)))
            
            // Add subtle glow to brighter stars
            if baseBrightness > 0.6 {
                let glowSize = starSize * 3
                let glowPath = Path(ellipseIn: CGRect(
                    x: x - glowSize / 2,
                    y: y - glowSize / 2,
                    width: glowSize,
                    height: glowSize
                ))
                context.fill(glowPath, with: .color(starColor.opacity(brightness * 0.15)))
            }
        }
        
        // Draw a few larger nebula-like particles
        for i in 0..<10 {
            let seed = Double(i + 1000) * 3.14159
            let x = (seed.truncatingRemainder(dividingBy: 1.0)) * size.width
            let y = ((seed * 2.5).truncatingRemainder(dividingBy: 1.0)) * size.height
            let nebulaSize = 50 + (seed.truncatingRemainder(dividingBy: 100))
            
            let pulse = sin(time * 0.3 + Double(i)) * 0.3 + 0.5
            
            let nebulaPath = Path(ellipseIn: CGRect(
                x: x - nebulaSize / 2,
                y: y - nebulaSize / 2,
                width: nebulaSize,
                height: nebulaSize * 0.6
            ))
            
            let nebulaColor = i % 2 == 0
                ? Color.red.opacity(0.02 * pulse)
                : Color.purple.opacity(0.015 * pulse)
            
            context.fill(nebulaPath, with: .color(nebulaColor))
        }
    }
}

// MARK: - Preview Provider

#if DEBUG
struct EmergencyLockdownView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            // Arming state
            EmergencyLockdownView(
                phase: .constant(.arming),
                isPresented: .constant(true),
                onCancel: {}
            )
            .previewDisplayName("Arming")
            
            // Countdown state
            EmergencyLockdownView(
                phase: .constant(.countdown(seconds: 3)),
                isPresented: .constant(true),
                onCancel: {}
            )
            .previewDisplayName("Countdown")
            
            // Locked down state
            EmergencyLockdownView(
                phase: .constant(.lockedDown),
                isPresented: .constant(true),
                onCancel: {}
            )
            .previewDisplayName("Locked Down")
        }
    }
}
#endif
