//
//  AuthenticationStepView.swift
//  VelociraptorMacOS
//
//  Authentication configuration step
//

import SwiftUI

struct AuthenticationStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var keychainManager: KeychainManager
    
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    @State private var saveToKeychain = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Configure administrator credentials:")
                .font(.body)
            
            // Admin Username
            GroupBox("Administrator Account") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Username:")
                            .frame(width: 120, alignment: .trailing)
                        
                        TextField("admin", text: $configViewModel.data.adminUsername)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 250)
                            .textContentType(.username)
                        
                        UsernameValidationView(username: configViewModel.data.adminUsername)
                    }
                    
                    Text("The admin account has full access to all Velociraptor features.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Password
            GroupBox("Password") {
                VStack(alignment: .leading, spacing: 16) {
                    // Password field
                    HStack {
                        Text("Password:")
                            .frame(width: 120, alignment: .trailing)
                        
                        Group {
                            if showPassword {
                                TextField("Password", text: $configViewModel.data.adminPassword)
                            } else {
                                SecureField("Password", text: $configViewModel.data.adminPassword)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)
                        .textContentType(.newPassword)
                        
                        Button {
                            showPassword.toggle()
                        } label: {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                        .help(showPassword ? "Hide password" : "Show password")
                    }
                    
                    // Password strength indicator
                    PasswordStrengthView(password: configViewModel.data.adminPassword)
                        .padding(.leading, 124)
                    
                    // Confirm password field
                    HStack {
                        Text("Confirm:")
                            .frame(width: 120, alignment: .trailing)
                        
                        Group {
                            if showConfirmPassword {
                                TextField("Confirm password", text: $configViewModel.data.confirmPassword)
                            } else {
                                SecureField("Confirm password", text: $configViewModel.data.confirmPassword)
                            }
                        }
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 250)
                        .textContentType(.newPassword)
                        
                        Button {
                            showConfirmPassword.toggle()
                        } label: {
                            Image(systemName: showConfirmPassword ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                        
                        // Match indicator
                        if !configViewModel.data.confirmPassword.isEmpty {
                            if configViewModel.data.adminPassword == configViewModel.data.confirmPassword {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    // Password requirements
                    PasswordRequirementsView(password: configViewModel.data.adminPassword)
                        .padding(.leading, 124)
                }
                .padding()
            }
            
            // Organization
            GroupBox("Organization") {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Text("Organization Name:")
                            .frame(width: 120, alignment: .trailing)
                        
                        TextField("VelociraptorOrg", text: $configViewModel.data.organizationName)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 300)
                    }
                    
                    Text("This name will appear in generated certificates and configurations.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            
            // Keychain option
            if configViewModel.data.useKeychain {
                GroupBox("macOS Keychain") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Save credentials to Keychain", isOn: $saveToKeychain)
                            .toggleStyle(.switch)
                        
                        if saveToKeychain {
                            HStack {
                                Image(systemName: "lock.shield.fill")
                                    .foregroundColor(.green)
                                Text("Your credentials will be securely stored in the macOS Keychain")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding()
                }
            }
            
            // Generate random password button
            HStack {
                Spacer()
                
                Button {
                    let password = generateSecurePassword()
                    configViewModel.data.adminPassword = password
                    configViewModel.data.confirmPassword = password
                } label: {
                    Label("Generate Secure Password", systemImage: "key.fill")
                }
            }
        }
    }
    
    private func generateSecurePassword() -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let numbers = "0123456789"
        let special = "!@#$%^&*"
        let all = letters + numbers + special
        
        var password = ""
        
        // Ensure at least one of each type
        password += String(letters.randomElement()!)
        password += String(letters.uppercased().randomElement()!)
        password += String(numbers.randomElement()!)
        password += String(special.randomElement()!)
        
        // Fill remaining with random characters
        for _ in 0..<12 {
            password += String(all.randomElement()!)
        }
        
        // Shuffle
        return String(password.shuffled())
    }
}

// MARK: - Username Validation View

struct UsernameValidationView: View {
    let username: String
    
    var isValid: Bool {
        username.count >= 3 &&
        username.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
    }
    
    var body: some View {
        if username.isEmpty {
            Text("Required")
                .font(.caption)
                .foregroundColor(.secondary)
        } else if isValid {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.green)
        } else {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundColor(.red)
                .help("Username must be at least 3 characters, letters/numbers/underscore only")
        }
    }
}

// MARK: - Password Strength View

struct PasswordStrengthView: View {
    let password: String
    
    var strength: ConfigurationData.PasswordStrength {
        let score = calculateScore()
        switch score {
        case 0..<30: return .weak
        case 30..<60: return .medium
        case 60..<80: return .strong
        default: return .veryStrong
        }
    }
    
    var score: Int {
        calculateScore()
    }
    
    private func calculateScore() -> Int {
        var score = 0
        
        // Length scoring
        score += min(password.count * 4, 40)
        
        // Character variety
        if password.contains(where: { $0.isUppercase }) { score += 15 }
        if password.contains(where: { $0.isLowercase }) { score += 15 }
        if password.contains(where: { $0.isNumber }) { score += 15 }
        if password.contains(where: { !$0.isLetter && !$0.isNumber }) { score += 15 }
        
        return min(score, 100)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                            .cornerRadius(4)
                        
                        Rectangle()
                            .fill(strengthColor)
                            .frame(width: geometry.size.width * CGFloat(score) / 100, height: 8)
                            .cornerRadius(4)
                    }
                }
                .frame(width: 150, height: 8)
                
                Text(strength.rawValue)
                    .font(.caption.bold())
                    .foregroundColor(strengthColor)
            }
        }
    }
    
    private var strengthColor: Color {
        switch strength {
        case .weak: return .red
        case .medium: return .orange
        case .strong: return .green
        case .veryStrong: return .blue
        }
    }
}

// MARK: - Password Requirements View

struct PasswordRequirementsView: View {
    let password: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            RequirementRow("At least 8 characters", met: password.count >= 8)
            RequirementRow("Contains uppercase letter", met: password.contains(where: { $0.isUppercase }))
            RequirementRow("Contains lowercase letter", met: password.contains(where: { $0.isLowercase }))
            RequirementRow("Contains number", met: password.contains(where: { $0.isNumber }))
        }
    }
}

struct RequirementRow: View {
    let text: String
    let met: Bool
    
    init(_ text: String, met: Bool) {
        self.text = text
        self.met = met
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundColor(met ? .green : .secondary)
            
            Text(text)
                .font(.caption)
                .foregroundColor(met ? .primary : .secondary)
        }
    }
}

#Preview {
    AuthenticationStepView()
        .environmentObject(ConfigurationViewModel())
        .environmentObject(KeychainManager())
        .padding()
        .frame(width: 700)
}
