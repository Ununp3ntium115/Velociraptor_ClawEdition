//
//  ClawBrandingView.swift
//  VelociraptorMacOS
//
//  Velociraptor Claw Edition branding logo component
//

import SwiftUI
import AppKit

/// A SwiftUI view displaying the Velociraptor Claw Edition logo.
/// Uses the app icon if available, otherwise shows a stylized SF Symbol representation.
struct ClawBrandingView: View {
    var size: CGFloat = 64
    var showText: Bool = true
    
    var body: some View {
        VStack(spacing: 8) {
            // Try to use the app icon first
            if let appIcon = NSApp.applicationIconImage {
                Image(nsImage: appIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: size, height: size)
                    .accessibilityIdentifier("claw.branding.logo")
            } else {
                // Fallback to stylized SF Symbol
                clawSymbol
            }
            
            if showText {
                VStack(spacing: 2) {
                    Text("Velociraptor")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Claw Edition")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .accessibilityIdentifier("claw.branding.text")
            }
        }
        .accessibilityIdentifier("claw.branding")
    }
    
    /// Stylized claw symbol using SF Symbols
    private var clawSymbol: some View {
        ZStack {
            // Background circle with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color.accentColor.opacity(0.8), Color.accentColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)
            
            // Claw icon (paw with claws)
            Image(systemName: "pawprint.fill")
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundStyle(.white)
            
            // Add "claw mark" detail
            HStack(spacing: size * 0.06) {
                ForEach(0..<3, id: \.self) { _ in
                    Capsule()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: size * 0.04, height: size * 0.25)
                        .rotationEffect(.degrees(-15))
                }
            }
            .offset(x: size * 0.15, y: -size * 0.15)
        }
        .accessibilityIdentifier("claw.branding.symbol")
    }
}

/// A smaller inline version for use in headers and navigation
struct ClawLogoInline: View {
    var size: CGFloat = 40
    
    var body: some View {
        if let appIcon = NSApp.applicationIconImage {
            Image(nsImage: appIcon)
                .resizable()
                .scaledToFit()
                .frame(width: size, height: size)
        } else {
            ZStack {
                Circle()
                    .fill(Color.accentColor)
                    .frame(width: size, height: size)
                
                Image(systemName: "pawprint.fill")
                    .font(.system(size: size * 0.5, weight: .semibold))
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview("Branding - Large") {
    ClawBrandingView(size: 128, showText: true)
        .padding()
}

#Preview("Branding - Small") {
    ClawBrandingView(size: 64, showText: false)
        .padding()
}

#Preview("Logo Inline") {
    HStack {
        ClawLogoInline(size: 40)
        VStack(alignment: .leading) {
            Text("Velociraptor Claw Edition")
                .font(.title2.bold())
            Text("Enterprise DFIR Platform")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    .padding()
}
