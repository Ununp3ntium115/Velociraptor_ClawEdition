//
//  CertificateSettingsStepView.swift
//  VelociraptorMacOS
//
//  Certificate and encryption settings step
//

import SwiftUI

struct CertificateSettingsStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    @State private var showCertFilePicker = false
    @State private var showKeyFilePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Configure SSL/TLS certificate settings for secure communication:")
                .font(.body)
            
            // Encryption type options
            ForEach(ConfigurationData.EncryptionType.allCases) { type in
                CertificateTypeCard(
                    type: type,
                    isSelected: configViewModel.data.encryptionType == type,
                    action: { configViewModel.data.encryptionType = type }
                )
                .accessibilityId(accessibilityIdForType(type))
            }
            
            // Additional settings based on selection
            switch configViewModel.data.encryptionType {
            case .selfSigned:
                SelfSignedSettingsView()
                    .environmentObject(configViewModel)
                
            case .custom:
                CustomCertificateSettingsView(
                    showCertFilePicker: $showCertFilePicker,
                    showKeyFilePicker: $showKeyFilePicker
                )
                .environmentObject(configViewModel)
                
            case .letsEncrypt:
                LetsEncryptSettingsView()
                    .environmentObject(configViewModel)
            }
        }
        .fileImporter(
            isPresented: $showCertFilePicker,
            allowedContentTypes: [.x509Certificate, .item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                configViewModel.data.customCertPath = url.path
            }
        }
        .fileImporter(
            isPresented: $showKeyFilePicker,
            allowedContentTypes: [.item],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                configViewModel.data.customKeyPath = url.path
            }
        }
        .accessibilityId(AccessibilityIdentifiers.WizardStep.certificateSettings)
    }
    
    private func accessibilityIdForType(_ type: ConfigurationData.EncryptionType) -> String {
        switch type {
        case .selfSigned:
            return AccessibilityIdentifiers.CertificateSettings.selfSignedCard
        case .custom:
            return AccessibilityIdentifiers.CertificateSettings.customCard
        case .letsEncrypt:
            return AccessibilityIdentifiers.CertificateSettings.letsEncryptCard
        }
    }
}

// MARK: - Certificate Type Card

struct CertificateTypeCard: View {
    let type: ConfigurationData.EncryptionType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Radio button
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.secondary, lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 12, height: 12)
                    }
                }
                
                Image(systemName: type.iconName)
                    .font(.title2)
                    .foregroundColor(isSelected ? .accentColor : .secondary)
                    .frame(width: 32)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                    
                    Text(type.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                Spacer()
                
                if type == .selfSigned {
                    Text("Recommended")
                        .font(.caption2.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.2))
                        .foregroundColor(.green)
                        .cornerRadius(4)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor.opacity(0.1) : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Self-Signed Settings

struct SelfSignedSettingsView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    let expirationOptions = ["30 Days", "90 Days", "1 Year", "2 Years", "5 Years"]
    
    var body: some View {
        GroupBox("Self-Signed Certificate Options") {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Certificate Expiration:")
                        .frame(width: 150, alignment: .trailing)
                    
                    Picker("", selection: $configViewModel.data.certificateExpiration) {
                        ForEach(expirationOptions, id: \.self) { option in
                            Text(option).tag(option)
                        }
                    }
                    .labelsHidden()
                    .frame(width: 200)
                    .accessibilityId(AccessibilityIdentifiers.CertificateSettings.expirationPicker)
                }
                
                HStack {
                    Text("Organization Name:")
                        .frame(width: 150, alignment: .trailing)
                    
                    TextField("Organization", text: $configViewModel.data.organizationName)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                        .accessibilityId(AccessibilityIdentifiers.CertificateSettings.organizationField)
                }
                
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("Self-signed certificates are suitable for testing and internal use. Clients will need to trust this certificate.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

// MARK: - Custom Certificate Settings

struct CustomCertificateSettingsView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @Binding var showCertFilePicker: Bool
    @Binding var showKeyFilePicker: Bool
    
    var body: some View {
        GroupBox("Custom Certificate Files") {
            VStack(alignment: .leading, spacing: 16) {
                // Certificate file
                VStack(alignment: .leading, spacing: 4) {
                    Text("Certificate File (.pem, .crt):")
                        .font(.subheadline)
                    
                    HStack {
                        TextField("Path to certificate file", text: $configViewModel.data.customCertPath)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityId(AccessibilityIdentifiers.CertificateSettings.certPathField)
                        
                        Button("Browse...") {
                            showCertFilePicker = true
                        }
                        .accessibilityId(AccessibilityIdentifiers.CertificateSettings.browseCertButton)
                    }
                    
                    if !configViewModel.data.customCertPath.isEmpty {
                        if FileManager.default.fileExists(atPath: configViewModel.data.customCertPath) {
                            Label("File found", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("File not found", systemImage: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                // Private key file
                VStack(alignment: .leading, spacing: 4) {
                    Text("Private Key File (.pem, .key):")
                        .font(.subheadline)
                    
                    HStack {
                        TextField("Path to private key file", text: $configViewModel.data.customKeyPath)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityId(AccessibilityIdentifiers.CertificateSettings.keyPathField)
                        
                        Button("Browse...") {
                            showKeyFilePicker = true
                        }
                        .accessibilityId(AccessibilityIdentifiers.CertificateSettings.browseKeyButton)
                    }
                    
                    if !configViewModel.data.customKeyPath.isEmpty {
                        if FileManager.default.fileExists(atPath: configViewModel.data.customKeyPath) {
                            Label("File found", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        } else {
                            Label("File not found", systemImage: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                }
                
                HStack {
                    Image(systemName: "lock.shield.fill")
                        .foregroundColor(.orange)
                    Text("Ensure your private key is kept secure and has appropriate file permissions.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

// MARK: - Let's Encrypt Settings

struct LetsEncryptSettingsView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    var body: some View {
        GroupBox("Let's Encrypt (AutoCert)") {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text("Domain Name:")
                        .frame(width: 120, alignment: .trailing)
                    
                    TextField("example.com", text: $configViewModel.data.letsEncryptDomain)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 300)
                        .accessibilityId(AccessibilityIdentifiers.CertificateSettings.domainField)
                }
                
                HStack {
                    Text("Cache Directory:")
                        .frame(width: 120, alignment: .trailing)
                    
                    TextField("Certificate cache", text: $configViewModel.data.letsEncryptCacheDir)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Requirements:")
                            .font(.caption.bold())
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        BulletPoint("Domain must point to this server's public IP")
                        BulletPoint("Port 80 must be accessible from the internet")
                        BulletPoint("Valid email address for certificate notifications")
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding()
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    init(_ text: String) {
        self.text = text
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
            Text(text)
        }
    }
}

#Preview {
    CertificateSettingsStepView()
        .environmentObject(ConfigurationViewModel())
        .padding()
        .frame(width: 700)
}
