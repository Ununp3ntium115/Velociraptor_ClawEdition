//
//  EmergencyModeView.swift
//  VelociraptorMacOS
//
//  Emergency Forensic Mode with Liquid Glass UI
//  Based on EMERGENCY_BUTTON_CONCEPT.md
//
//  Features:
//  - Double-tap confirmation
//  - Liquid Glass aesthetics
//  - Countdown ring animation
//  - Claw shutter lockdown animation
//  - Port preservation (keeps DFIR streaming ports open)
//

import SwiftUI

// MARK: - Emergency Mode View

struct EmergencyModeView: View {
    @EnvironmentObject var appState: AppState
    @StateObject private var controller = EmergencyController()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background
            backgroundGradient
            
            // Main content based on phase
            VStack(spacing: 0) {
                // Header
                emergencyHeader
                
                Divider()
                    .opacity(0.5)
                
                // Phase-specific content
                phaseContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                
                Divider()
                    .opacity(0.5)
                
                // Footer with cancel button
                emergencyFooter
            }
            
            // Glass shield overlay for lockdown phases
            if controller.phase == .lockingDown || controller.phase == .running {
                GlassShield(phase: controller.phase, statusMessage: controller.statusMessage)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
            
            // Claw shutter animation
            if controller.phase == .lockingDown {
                ClawShutter()
                    .transition(.opacity)
            }
        }
        .frame(minWidth: 500, idealWidth: 600, maxWidth: 700,
               minHeight: 400, idealHeight: 500, maxHeight: 600)
        .accessibilityIdentifier(AccessibilityIdentifiers.EmergencyMode.sheet)
        .onAppear {
            // Enable mock mode for UI tests
            if ProcessInfo.processInfo.arguments.contains("-UITestMode") {
                controller.config.mockMode = true
            }
        }
    }
    
    // MARK: - Background
    
    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.1, green: 0.1, blue: 0.15),
                Color(red: 0.05, green: 0.05, blue: 0.1)
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    // MARK: - Header
    
    private var emergencyHeader: some View {
        VStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.red)
                .symbolRenderingMode(.hierarchical)
            
            Text("Emergency Forensic Mode")
                .font(.title.bold())
                .foregroundStyle(.white)
                .accessibilityIdentifier(AccessibilityIdentifiers.EmergencyMode.title)
            
            Text("Initiate rapid forensic lockdown and evidence collection")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 24)
    }
    
    // MARK: - Phase Content
    
    @ViewBuilder
    private var phaseContent: some View {
        switch controller.phase {
        case .idle:
            idleContent
        case .armed:
            armedContent
        case .confirming(let seconds):
            CountdownRing(secondsRemaining: seconds, total: controller.config.confirmCountdownSeconds)
        case .backupPrompt:
            BackupPromptView(
                onBackupNow: { controller.performBackup() },
                onSkip: { controller.skipBackup() }
            )
        case .lockingDown:
            lockingDownContent
        case .running:
            runningContent
        case .cancelled:
            cancelledContent
        }
    }
    
    // MARK: - Idle Content
    
    private var idleContent: some View {
        VStack(spacing: 24) {
            // Feature list
            VStack(alignment: .leading, spacing: 12) {
                FeatureRowView(icon: "shield.lefthalf.filled", title: "Port Lockdown", description: "Block non-essential network traffic")
                FeatureRowView(icon: "doc.text.magnifyingglass", title: "Evidence Collection", description: "Automated forensic artifact gathering")
                FeatureRowView(icon: "memorychip", title: "Memory Capture", description: "Volatile data preservation")
                FeatureRowView(icon: "network", title: "Network Preservation", description: "Keep DFIR streaming ports open")
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
            )
            .padding(.horizontal)
            
            // Emergency button
            EmergencyButton(
                phase: controller.phase,
                pulse: controller.pulseAnimation,
                onTap: { controller.handleTap() }
            )
            .accessibilityIdentifier(AccessibilityIdentifiers.EmergencyMode.deployButton)
        }
    }
    
    // MARK: - Armed Content
    
    private var armedContent: some View {
        VStack(spacing: 24) {
            Image(systemName: "hand.tap.fill")
                .font(.system(size: 64))
                .foregroundStyle(.orange)
                .symbolEffect(.pulse)
            
            Text("Tap Again to Confirm")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("The emergency lockdown will begin after confirmation")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            EmergencyButton(
                phase: controller.phase,
                pulse: false,
                onTap: { controller.handleTap() }
            )
        }
    }
    
    // MARK: - Locking Down Content
    
    private var lockingDownContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text("Initiating Lockdown...")
                .font(.headline)
                .foregroundStyle(.white)
            
            Text(controller.statusMessage)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Running Content
    
    private var runningContent: some View {
        VStack(spacing: 24) {
            // Status
            VStack(spacing: 12) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.green)
                
                Text("Forensic Mode Active")
                    .font(.title2.bold())
                    .foregroundStyle(.white)
            }
            
            // Progress
            VStack(spacing: 8) {
                ProgressView(value: controller.collectionProgress)
                    .progressViewStyle(.linear)
                    .tint(.green)
                
                Text(controller.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 32)
            
            // Port status
            HStack(spacing: 32) {
                VStack {
                    Text("\(controller.blockedPortCount)")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(.red)
                    Text("Ports Blocked")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                VStack {
                    Text("\(controller.activePorts.count)")
                        .font(.title.bold().monospacedDigit())
                        .foregroundStyle(.green)
                    Text("Ports Preserved")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
            )
        }
    }
    
    // MARK: - Cancelled Content
    
    private var cancelledContent: some View {
        VStack(spacing: 16) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            Text("Cancelled")
                .font(.title2.bold())
                .foregroundStyle(.white)
            
            Text("Emergency mode was cancelled")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Footer
    
    private var emergencyFooter: some View {
        HStack {
            Button("Cancel") {
                if controller.phase == .idle || controller.phase == .cancelled {
                    dismiss()
                } else {
                    controller.cancel()
                }
            }
            .keyboardShortcut(.escape, modifiers: [])
            .accessibilityIdentifier(AccessibilityIdentifiers.EmergencyMode.cancelButton)
            
            Spacer()
            
            if controller.phase == .running && controller.collectionProgress >= 1.0 {
                Button("Close") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}

// MARK: - Feature Row View

private struct FeatureRowView: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.red)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .foregroundStyle(.white)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Emergency Button

struct EmergencyButton: View {
    let phase: EmergencyPhase
    let pulse: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .symbolRenderingMode(.hierarchical)
                Text(buttonTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .frame(minWidth: 280)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.white)
        .background(buttonSurface)
        .overlay(armedOverlay)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .scaleEffect(scale)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: phase)
        .animation(.easeInOut(duration: 0.75), value: pulse)
    }
    
    private var buttonTitle: String {
        switch phase {
        case .idle: return "Initiate Emergency Mode"
        case .armed: return "Tap Again to Confirm"
        case .confirming: return "Initiating..."
        default: return "Emergency Mode"
        }
    }
    
    private var buttonSurface: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.red.opacity(phase.isHot ? 0.35 : 0.2))
            )
            .shadow(color: .red.opacity(phase.isHot ? 0.4 : 0.2), radius: phase.isHot ? 16 : 8, y: 4)
    }
    
    @ViewBuilder
    private var armedOverlay: some View {
        if case .armed = phase {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.orange, lineWidth: 2)
                .animation(.easeInOut(duration: 0.3).repeatForever(autoreverses: true), value: phase)
        }
    }
    
    private var scale: CGFloat {
        switch phase {
        case .idle: return pulse ? 1.02 : 1.0
        case .armed: return 1.05
        case .confirming: return 1.0
        default: return 1.0
        }
    }
}

// MARK: - Countdown Ring

struct CountdownRing: View {
    let secondsRemaining: Int
    let total: Int
    
    var progress: Double {
        Double(secondsRemaining) / Double(total)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(.white.opacity(0.12), lineWidth: 12)
                
                // Progress ring
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(
                        AngularGradient(
                            colors: [.red, .orange, .red],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.15), value: progress)
                
                // Countdown number
                Text("\(secondsRemaining)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .contentTransition(.numericText())
            }
            .frame(width: 140, height: 140)
            
            Text("Initiating forensic safety protocol...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Glass Shield Overlay

struct GlassShield: View {
    let phase: EmergencyPhase
    let statusMessage: String
    
    var body: some View {
        ZStack {
            // Frosted background
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea()
            
            // Content card
            VStack(spacing: 16) {
                Image(systemName: phase == .running ? "lock.shield.fill" : "shield.lefthalf.filled")
                    .font(.system(size: 48, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(phase == .running ? .green : .orange)
                
                Text(phase == .running ? "Forensic Mode Active" : "Locking Down")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                
                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 400)
            }
            .padding(28)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .strokeBorder(.white.opacity(0.1), lineWidth: 1)
                    )
            )
            .shadow(radius: 20)
        }
    }
}

// MARK: - Claw Shutter Animation

struct ClawShutter: View {
    @State private var close = false
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Left shutter (claw)
                ClawShape(isLeft: true)
                    .fill(.regularMaterial)
                    .frame(width: geo.size.width * 0.55)
                    .offset(x: close ? geo.size.width * 0.025 : -geo.size.width * 0.6)
                
                // Right shutter (claw)
                ClawShape(isLeft: false)
                    .fill(.regularMaterial)
                    .frame(width: geo.size.width * 0.55)
                    .offset(x: close ? geo.size.width * 0.45 : geo.size.width * 1.1)
            }
            .ignoresSafeArea()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.5)) {
                close = true
            }
            
            // Open after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    close = false
                }
            }
        }
    }
}

// MARK: - Claw Shape

struct ClawShape: Shape {
    let isLeft: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        if isLeft {
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: rect.width * 0.8, y: 0))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height * 0.5))
            path.addLine(to: CGPoint(x: rect.width * 0.8, y: rect.height))
            path.addLine(to: CGPoint(x: 0, y: rect.height))
        } else {
            path.move(to: CGPoint(x: rect.width, y: 0))
            path.addLine(to: CGPoint(x: rect.width * 0.2, y: 0))
            path.addLine(to: CGPoint(x: 0, y: rect.height * 0.5))
            path.addLine(to: CGPoint(x: rect.width * 0.2, y: rect.height))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height))
        }
        
        path.closeSubpath()
        return path
    }
}

// MARK: - Backup Prompt View

struct BackupPromptView: View {
    var onBackupNow: () -> Void
    var onSkip: () -> Void
    
    @State private var animate = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Animated icon
            ZStack {
                HStack(spacing: 12) {
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "doc.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white.opacity(0.7))
                            .offset(y: animate ? -8 : 8)
                            .animation(
                                .easeInOut(duration: 0.8)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.1),
                                value: animate
                            )
                    }
                }
                .offset(x: animate ? -30 : 30)
                .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animate)
                
                Image(systemName: "lock.square.stack.fill")
                    .font(.system(size: 44, weight: .semibold))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(.orange)
            }
            .frame(height: 80)
            .onAppear { animate = true }
            
            Text("Backup Before Lockdown?")
                .font(.title3.bold())
                .foregroundStyle(.white)
            
            Text("Lockdown reduces system writes and may restrict some external connections. Creating a backup ensures data integrity.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            
            HStack(spacing: 16) {
                Button("Backup Now", action: onBackupNow)
                    .buttonStyle(.borderedProminent)
                    .tint(.orange)
                
                Button("Skip & Continue", action: onSkip)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    EmergencyModeView()
        .environmentObject(AppState())
        .frame(width: 600, height: 500)
}
#endif
