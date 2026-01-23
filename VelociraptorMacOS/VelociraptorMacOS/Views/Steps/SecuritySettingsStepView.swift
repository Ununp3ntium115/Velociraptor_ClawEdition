//
//  SecuritySettingsStepView.swift
//  VelociraptorMacOS
//
//  Security and environment settings step
//

import SwiftUI

struct SecuritySettingsStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Configure security and environment settings:")
                .font(.body)
            
            // Environment Selection
            GroupBox("Environment") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Environment:", selection: $configViewModel.data.environment) {
                        ForEach(ConfigurationData.Environment.allCases) { env in
                            Text(env.rawValue).tag(env)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityId(AccessibilityIdentifiers.SecuritySettings.environmentPicker)
                    
                    Text(configViewModel.data.environment.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Logging Settings
            GroupBox("Logging") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Log Level:")
                            .frame(width: 100, alignment: .trailing)
                        
                        Picker("", selection: $configViewModel.data.logLevel) {
                            ForEach(ConfigurationData.LogLevel.allCases) { level in
                                HStack {
                                    Text(level.rawValue)
                                }
                                .tag(level)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 150)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.logLevelPicker)
                        
                        Text(configViewModel.data.logLevel.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Toggle("Enable Debug Logging", isOn: $configViewModel.data.enableDebugLogging)
                        .toggleStyle(.switch)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.debugLoggingToggle)
                    
                    if configViewModel.data.enableDebugLogging {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text("Debug logging may expose sensitive information. Use only for troubleshooting.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
            }
            
            // Security Options
            GroupBox("Security Options") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Enforce TLS 1.2 or Higher", isOn: $configViewModel.data.enforceTLS12)
                        .toggleStyle(.switch)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.enforceTLSToggle)
                    
                    Toggle("Validate SSL Certificates", isOn: $configViewModel.data.validateCertificates)
                        .toggleStyle(.switch)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.validateCertsToggle)
                    
                    if !configViewModel.data.validateCertificates {
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.red)
                            Text("Disabling certificate validation is insecure. Only use for testing.")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }
                    
                    Toggle("Restrict VQL Capabilities", isOn: $configViewModel.data.restrictVQL)
                        .toggleStyle(.switch)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.restrictVQLToggle)
                    
                    if configViewModel.data.restrictVQL {
                        Text("Some VQL plugins will be disabled for enhanced security.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            // macOS-specific options
            GroupBox("macOS Integration") {
                VStack(alignment: .leading, spacing: 16) {
                    Toggle("Store Credentials in Keychain", isOn: $configViewModel.data.useKeychain)
                        .toggleStyle(.switch)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.useKeychainToggle)
                    
                    Toggle("Enable System Notifications", isOn: $configViewModel.data.enableNotifications)
                        .toggleStyle(.switch)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.notificationsToggle)
                    
                    Toggle("Launch at Login", isOn: $configViewModel.data.launchAtLogin)
                        .toggleStyle(.switch)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.launchAtLoginToggle)
                    
                    Toggle("Auto-check for Updates", isOn: $configViewModel.data.autoCheckUpdates)
                        .toggleStyle(.switch)
                        .accessibilityId(AccessibilityIdentifiers.SecuritySettings.autoUpdateToggle)
                }
                .padding()
            }
        }
        .accessibilityId(AccessibilityIdentifiers.WizardStep.securitySettings)
    }
}

#Preview {
    SecuritySettingsStepView()
        .environmentObject(ConfigurationViewModel())
        .padding()
        .frame(width: 700)
}
