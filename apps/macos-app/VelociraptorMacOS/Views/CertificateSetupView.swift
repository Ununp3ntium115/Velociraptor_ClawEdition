//
//  CertificateSetupView.swift
//  VelociraptorMacOS
//
//  Certificate pre-pull and mTLS configuration workflow
//  Enables secure connection to Velociraptor server using pre-pulled certificates
//
//  CDIF Pattern: Step-based wizard for certificate configuration
//  Swift 6 Concurrency: Strict mode compliant
//

import SwiftUI
import UniformTypeIdentifiers

// MARK: - Certificate Error

/// Errors that can occur during certificate operations
enum CertificateError: LocalizedError {
    case invalidConfiguration(String)
    case extractionFailed(String)
    case fileNotFound(String)
    case invalidCertificate(String)
    case keychainStorageFailed(String)
    case connectionTestFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidConfiguration(let details):
            return "Invalid configuration: \(details)"
        case .extractionFailed(let details):
            return "Certificate extraction failed: \(details)"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidCertificate(let details):
            return "Invalid certificate: \(details)"
        case .keychainStorageFailed(let details):
            return "Keychain storage failed: \(details)"
        case .connectionTestFailed(let details):
            return "Connection test failed: \(details)"
        }
    }
}

// MARK: - Certificate Setup View

/// Main view for certificate pre-pull and mTLS configuration
struct CertificateSetupView: View {
    @StateObject private var viewModel = CertificateSetupViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            CertificateSetupHeader(viewModel: viewModel)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    switch viewModel.currentStep {
                    case .source:
                        CertificateSourceStep(viewModel: viewModel)
                    case .extract:
                        CertificateExtractStep(viewModel: viewModel)
                    case .verify:
                        CertificateVerifyStep(viewModel: viewModel)
                    case .configure:
                        CertificateConfigureStep(viewModel: viewModel)
                    case .complete:
                        CertificateCompleteStep(viewModel: viewModel)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Navigation
            CertificateSetupFooter(viewModel: viewModel, dismiss: dismiss)
        }
        .frame(width: 600, height: 550)
        .accessibilityIdentifier("certificate.setup.view")
    }
}

// MARK: - Header

struct CertificateSetupHeader: View {
    @ObservedObject var viewModel: CertificateSetupViewModel
    
    let steps: [(id: CertificateSetupStep, title: String)] = [
        (.source, "Source"),
        (.extract, "Extract"),
        (.verify, "Verify"),
        (.configure, "Configure"),
        (.complete, "Complete")
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.title)
                    .foregroundColor(.accentColor)
                
                Text("Certificate Setup")
                    .font(.title2.bold())
            }
            
            // Step indicator
            HStack(spacing: 0) {
                ForEach(Array(steps.enumerated()), id: \.element.id) { index, step in
                    HStack(spacing: 4) {
                        Circle()
                            .fill(stepColor(for: step.id))
                            .frame(width: 24, height: 24)
                            .overlay {
                                if step.id.rawValue < viewModel.currentStep.rawValue {
                                    Image(systemName: "checkmark")
                                        .font(.caption2.bold())
                                        .foregroundColor(.white)
                                } else {
                                    Text("\(index + 1)")
                                        .font(.caption2.bold())
                                        .foregroundColor(step.id == viewModel.currentStep ? .white : .secondary)
                                }
                            }
                        
                        Text(step.title)
                            .font(.caption)
                            .foregroundColor(step.id.rawValue <= viewModel.currentStep.rawValue ? .primary : .secondary)
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(step.id.rawValue < viewModel.currentStep.rawValue ? Color.green : Color.secondary.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: 40)
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func stepColor(for step: CertificateSetupStep) -> Color {
        if step.rawValue < viewModel.currentStep.rawValue {
            return .green
        } else if step == viewModel.currentStep {
            return .accentColor
        } else {
            return .secondary.opacity(0.3)
        }
    }
}

// MARK: - Step 1: Certificate Source

struct CertificateSourceStep: View {
    @ObservedObject var viewModel: CertificateSetupViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Where are your certificates?")
                .font(.headline)
            
            Text("Choose how to provide the client certificates for mTLS authentication.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                CertificateSourceOption(
                    title: "Extract from Server Config",
                    description: "Extract certificates from an existing server.config.yaml file",
                    icon: "doc.text.fill",
                    isSelected: viewModel.certificateSource == .serverConfig,
                    action: { viewModel.certificateSource = .serverConfig }
                )
                .accessibilityIdentifier("cert.source.config")
                
                CertificateSourceOption(
                    title: "Import Certificate Files",
                    description: "Import separate .crt and .key files (PEM format)",
                    icon: "folder.fill",
                    isSelected: viewModel.certificateSource == .files,
                    action: { viewModel.certificateSource = .files }
                )
                .accessibilityIdentifier("cert.source.files")
                
                CertificateSourceOption(
                    title: "Download from Server",
                    description: "Connect to server and download client certificate pack",
                    icon: "arrow.down.circle.fill",
                    isSelected: viewModel.certificateSource == .download,
                    action: { viewModel.certificateSource = .download }
                )
                .accessibilityIdentifier("cert.source.download")
            }
            
            // File selection based on source
            if viewModel.certificateSource == .serverConfig {
                GroupBox("Server Configuration File") {
                    HStack {
                        TextField("Path to server.config.yaml", text: $viewModel.configFilePath)
                            .textFieldStyle(.roundedBorder)
                            .accessibilityIdentifier("cert.config.path")
                        
                        Button("Browse...") {
                            viewModel.showConfigFilePicker = true
                        }
                        .accessibilityIdentifier("cert.config.browse")
                    }
                }
            } else if viewModel.certificateSource == .files {
                GroupBox("Certificate Files") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Client Certificate:")
                                .frame(width: 120, alignment: .trailing)
                            TextField("Path to client.crt", text: $viewModel.clientCertPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...") {
                                viewModel.showClientCertPicker = true
                            }
                        }
                        
                        HStack {
                            Text("Client Key:")
                                .frame(width: 120, alignment: .trailing)
                            TextField("Path to client.key", text: $viewModel.clientKeyPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...") {
                                viewModel.showClientKeyPicker = true
                            }
                        }
                        
                        HStack {
                            Text("CA Certificate:")
                                .frame(width: 120, alignment: .trailing)
                            TextField("Path to ca.crt", text: $viewModel.caCertPath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...") {
                                viewModel.showCACertPicker = true
                            }
                        }
                    }
                }
            } else if viewModel.certificateSource == .download {
                GroupBox("Server Connection") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Server URL:")
                                .frame(width: 100, alignment: .trailing)
                            TextField("https://server:8889", text: $viewModel.serverURL)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("cert.server.url")
                        }
                        
                        HStack {
                            Text("API Key:")
                                .frame(width: 100, alignment: .trailing)
                            SecureField("Enter API key", text: $viewModel.apiKey)
                                .textFieldStyle(.roundedBorder)
                                .accessibilityIdentifier("cert.api.key")
                        }
                    }
                }
            }
        }
        .fileImporter(
            isPresented: $viewModel.showConfigFilePicker,
            allowedContentTypes: [.yaml, .text],
            onCompletion: { result in
                if case .success(let url) = result {
                    viewModel.configFilePath = url.path
                }
            }
        )
    }
}

struct CertificateSourceOption: View {
    let title: String
    let description: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(isSelected ? .white : .primary)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.white)
                }
            }
            .padding()
            .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Extract Certificates

struct CertificateExtractStep: View {
    @ObservedObject var viewModel: CertificateSetupViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Extracting Certificates")
                .font(.headline)
            
            if viewModel.isExtracting {
                VStack(spacing: 16) {
                    ProgressView()
                        .controlSize(.large)
                    
                    Text("Extracting certificates...")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
            } else if let certInfo = viewModel.extractedCertInfo {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title)
                        
                        Text("Certificates Extracted Successfully")
                            .font(.headline)
                    }
                    
                    GroupBox("Certificate Details") {
                        Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                            GridRow {
                                Text("Server CN:")
                                    .foregroundColor(.secondary)
                                Text(certInfo.serverCN)
                            }
                            
                            GridRow {
                                Text("Client Cert:")
                                    .foregroundColor(.secondary)
                                Text("\(certInfo.clientCertPEM.count) bytes")
                            }
                            
                            GridRow {
                                Text("Client Key:")
                                    .foregroundColor(.secondary)
                                Text("\(certInfo.clientKeyPEM.count) bytes")
                            }
                            
                            GridRow {
                                Text("CA Cert:")
                                    .foregroundColor(.secondary)
                                Text("\(certInfo.caCertPEM.count) bytes")
                            }
                            
                            if let expiration = certInfo.expirationDate {
                                GridRow {
                                    Text("Expires:")
                                        .foregroundColor(.secondary)
                                    Text(expiration, style: .date)
                                        .foregroundColor(certInfo.isValid ? .primary : .red)
                                }
                            }
                        }
                    }
                }
            } else if let error = viewModel.extractionError {
                VStack(spacing: 16) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.red)
                        .font(.title)
                    
                    Text("Extraction Failed")
                        .font(.headline)
                    
                    Text(error)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button("Try Again") {
                        Task { await viewModel.extractCertificates() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
            } else {
                VStack(spacing: 16) {
                    Text("Click 'Extract' to begin certificate extraction")
                        .foregroundColor(.secondary)
                    
                    Button("Extract Certificates") {
                        Task { await viewModel.extractCertificates() }
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("cert.extract.button")
                }
                .frame(maxWidth: .infinity, maxHeight: 200)
            }
        }
    }
}

// MARK: - Step 3: Verify Certificates

struct CertificateVerifyStep: View {
    @ObservedObject var viewModel: CertificateSetupViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Verify Certificates")
                .font(.headline)
            
            Text("Test the connection to the Velociraptor server using the extracted certificates.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            GroupBox("Server Connection Test") {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Server URL:")
                        TextField("https://127.0.0.1:8889", text: $viewModel.serverURL)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    HStack {
                        Button("Test Connection") {
                            Task { await viewModel.testConnection() }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.isTesting)
                        .accessibilityIdentifier("cert.test.connection")
                        
                        if viewModel.isTesting {
                            ProgressView()
                                .controlSize(.small)
                        }
                    }
                }
            }
            
            if let result = viewModel.connectionTestResult {
                GroupBox {
                    HStack {
                        Image(systemName: result.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result.success ? .green : .red)
                            .font(.title2)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(result.success ? "Connection Successful" : "Connection Failed")
                                .font(.headline)
                            
                            Text(result.message)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            if let serverVersion = result.serverVersion {
                                Text("Server Version: \(serverVersion)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Step 4: Configure mTLS

struct CertificateConfigureStep: View {
    @ObservedObject var viewModel: CertificateSetupViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Configure mTLS")
                .font(.headline)
            
            Text("Save the certificates and configure the application for mTLS authentication.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            GroupBox("Certificate Storage") {
                VStack(alignment: .leading, spacing: 12) {
                    Toggle("Store in Keychain", isOn: $viewModel.storeInKeychain)
                        .accessibilityIdentifier("cert.store.keychain")
                    
                    if viewModel.storeInKeychain {
                        Text("Certificates will be securely stored in the macOS Keychain")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        HStack {
                            Text("Storage Path:")
                            TextField("Path", text: $viewModel.certificateStoragePath)
                                .textFieldStyle(.roundedBorder)
                            Button("Browse...") {
                                // Show folder picker
                            }
                        }
                    }
                }
            }
            
            GroupBox("API Client Configuration") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Set as default connection", isOn: $viewModel.setAsDefault)
                    Toggle("Auto-connect on launch", isOn: $viewModel.autoConnect)
                    Toggle("Remember server URL", isOn: $viewModel.rememberServerURL)
                }
            }
            
            if viewModel.isConfiguring {
                HStack {
                    ProgressView()
                    Text("Configuring...")
                }
            }
        }
    }
}

// MARK: - Step 5: Complete

struct CertificateCompleteStep: View {
    @ObservedObject var viewModel: CertificateSetupViewModel
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 64))
                .foregroundColor(.green)
            
            Text("Certificate Setup Complete")
                .font(.title2.bold())
            
            Text("Your certificates have been configured and the API client is ready for mTLS authentication.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            GroupBox("Connection Summary") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Server:")
                            .foregroundColor(.secondary)
                        Text(viewModel.serverURL)
                    }
                    
                    GridRow {
                        Text("Authentication:")
                            .foregroundColor(.secondary)
                        Text("mTLS (Client Certificate)")
                    }
                    
                    GridRow {
                        Text("Storage:")
                            .foregroundColor(.secondary)
                        Text(viewModel.storeInKeychain ? "macOS Keychain" : "File System")
                    }
                    
                    GridRow {
                        Text("Status:")
                            .foregroundColor(.secondary)
                        HStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("Connected")
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Footer

struct CertificateSetupFooter: View {
    @ObservedObject var viewModel: CertificateSetupViewModel
    let dismiss: DismissAction
    
    var body: some View {
        HStack {
            Button("Cancel") {
                dismiss()
            }
            
            Spacer()
            
            if viewModel.currentStep != .source {
                Button("Back") {
                    viewModel.previousStep()
                }
                .accessibilityIdentifier("cert.back.button")
            }
            
            if viewModel.currentStep == .complete {
                Button("Done") {
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("cert.done.button")
            } else {
                Button("Next") {
                    Task { await viewModel.nextStep() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canProceed)
                .accessibilityIdentifier("cert.next.button")
            }
        }
        .padding()
    }
}

// MARK: - Models

enum CertificateSetupStep: Int, CaseIterable {
    case source = 0
    case extract = 1
    case verify = 2
    case configure = 3
    case complete = 4
}

enum CertificateSource: String {
    case serverConfig
    case files
    case download
}

struct ConnectionTestResult {
    let success: Bool
    let message: String
    let serverVersion: String?
}

// MARK: - View Model

@MainActor
class CertificateSetupViewModel: ObservableObject {
    // MARK: - Step State
    
    @Published var currentStep: CertificateSetupStep = .source
    
    // MARK: - Source Selection
    
    @Published var certificateSource: CertificateSource = .serverConfig
    @Published var configFilePath: String = ""
    @Published var clientCertPath: String = ""
    @Published var clientKeyPath: String = ""
    @Published var caCertPath: String = ""
    @Published var serverURL: String = "https://127.0.0.1:8889"
    @Published var apiKey: String = ""
    
    // MARK: - File Pickers
    
    @Published var showConfigFilePicker = false
    @Published var showClientCertPicker = false
    @Published var showClientKeyPicker = false
    @Published var showCACertPicker = false
    
    // MARK: - Extraction
    
    @Published var isExtracting = false
    @Published var extractedCertInfo: CertificateInfo?
    @Published var extractionError: String?
    
    // MARK: - Verification
    
    @Published var isTesting = false
    @Published var connectionTestResult: ConnectionTestResult?
    
    // MARK: - Configuration
    
    @Published var storeInKeychain = true
    @Published var certificateStoragePath = ""
    @Published var setAsDefault = true
    @Published var autoConnect = true
    @Published var rememberServerURL = true
    @Published var isConfiguring = false
    
    // MARK: - Computed Properties
    
    var canProceed: Bool {
        switch currentStep {
        case .source:
            switch certificateSource {
            case .serverConfig:
                return !configFilePath.isEmpty
            case .files:
                return !clientCertPath.isEmpty && !clientKeyPath.isEmpty && !caCertPath.isEmpty
            case .download:
                return !serverURL.isEmpty && !apiKey.isEmpty
            }
        case .extract:
            return extractedCertInfo != nil
        case .verify:
            return connectionTestResult?.success == true
        case .configure:
            return true
        case .complete:
            return true
        }
    }
    
    // MARK: - Navigation
    
    func nextStep() async {
        switch currentStep {
        case .source:
            currentStep = .extract
            if extractedCertInfo == nil {
                await extractCertificates()
            }
        case .extract:
            currentStep = .verify
        case .verify:
            currentStep = .configure
        case .configure:
            await configureMTLS()
            currentStep = .complete
        case .complete:
            break
        }
    }
    
    func previousStep() {
        guard currentStep.rawValue > 0,
              let previous = CertificateSetupStep(rawValue: currentStep.rawValue - 1) else {
            return
        }
        currentStep = previous
    }
    
    // MARK: - Certificate Operations
    
    func extractCertificates() async {
        isExtracting = true
        extractionError = nil
        
        defer { isExtracting = false }
        
        do {
            let bridge = VelociraptorBinaryBridge.shared
            
            switch certificateSource {
            case .serverConfig:
                extractedCertInfo = try await bridge.extractCertificates(from: configFilePath)
                
            case .files:
                // Read certificate files directly
                let clientCert = try String(contentsOfFile: clientCertPath, encoding: .utf8)
                let clientKey = try String(contentsOfFile: clientKeyPath, encoding: .utf8)
                let caCert = try String(contentsOfFile: caCertPath, encoding: .utf8)
                
                extractedCertInfo = CertificateInfo(
                    clientCertPEM: clientCert,
                    clientKeyPEM: clientKey,
                    caCertPEM: caCert,
                    serverCN: "VelociraptorServer",
                    expirationDate: nil
                )
                
            case .download:
                // Download certificates from server
                // This would require initial API key auth to download client certs
                throw BinaryBridgeError.certificateExtractionFailed("Download not yet implemented")
            }
            
            Logger.shared.success("Certificates extracted successfully", component: "CertSetup")
            
        } catch {
            extractionError = error.localizedDescription
            Logger.shared.error("Certificate extraction failed: \(error)", component: "CertSetup")
        }
    }
    
    func testConnection() async {
        isTesting = true
        connectionTestResult = nil
        
        defer { isTesting = false }
        
        guard let certInfo = extractedCertInfo else {
            connectionTestResult = ConnectionTestResult(
                success: false,
                message: "No certificates available",
                serverVersion: nil
            )
            return
        }
        
        do {
            // Write temp certs
            let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("velociraptor-certs-test")
            try? FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            
            let certPath = tempDir.appendingPathComponent("client.crt")
            let keyPath = tempDir.appendingPathComponent("client.key")
            let caPath = tempDir.appendingPathComponent("ca.crt")
            
            try certInfo.clientCertPEM.write(to: certPath, atomically: true, encoding: .utf8)
            try certInfo.clientKeyPEM.write(to: keyPath, atomically: true, encoding: .utf8)
            try certInfo.caCertPEM.write(to: caPath, atomically: true, encoding: .utf8)
            
            // Configure API client with mTLS credentials
            guard let serverURLObj = URL(string: serverURL) else {
                throw CertificateError.invalidConfiguration("Invalid server URL")
            }
            
            // Store certificates in UserDefaults for API client to use
            UserDefaults.standard.set(certPath.path, forKey: "mTLS.clientCertPath")
            UserDefaults.standard.set(keyPath.path, forKey: "mTLS.clientKeyPath")
            UserDefaults.standard.set(caPath.path, forKey: "mTLS.caCertPath")
            UserDefaults.standard.set(serverURL, forKey: "velociraptorServerURL")
            
            // Configure API client with basic authentication (mTLS handled by URLSession)
            try await VelociraptorAPIClient.shared.configure(
                serverURL: serverURLObj,
                apiKey: "mtls-authenticated"  // Placeholder for mTLS auth
            )
            
            // Test connection
            let connected = try await VelociraptorAPIClient.shared.testConnection()
            
            if connected {
                let serverInfo = try await VelociraptorAPIClient.shared.getServerInfo()
                connectionTestResult = ConnectionTestResult(
                    success: true,
                    message: "Successfully connected to server",
                    serverVersion: serverInfo.version
                )
            } else {
                connectionTestResult = ConnectionTestResult(
                    success: false,
                    message: "Connection test failed",
                    serverVersion: nil
                )
            }
            
        } catch {
            connectionTestResult = ConnectionTestResult(
                success: false,
                message: error.localizedDescription,
                serverVersion: nil
            )
        }
    }
    
    func configureMTLS() async {
        isConfiguring = true
        defer { isConfiguring = false }
        
        guard let certInfo = extractedCertInfo else { return }
        
        do {
            if storeInKeychain {
                // Store certificates in Keychain
                let keychain = KeychainManager()
                try keychain.storeCertificate(
                    certInfo.clientCertPEM,
                    forKey: "velociraptor-client-cert"
                )
                try keychain.storeCertificate(
                    certInfo.clientKeyPEM,
                    forKey: "velociraptor-client-key"
                )
                try keychain.storeCertificate(
                    certInfo.caCertPEM,
                    forKey: "velociraptor-ca-cert"
                )
            } else {
                // Write to file system
                let storageDir = URL(fileURLWithPath: certificateStoragePath)
                try? FileManager.default.createDirectory(at: storageDir, withIntermediateDirectories: true)
                
                try certInfo.clientCertPEM.write(
                    to: storageDir.appendingPathComponent("client.crt"),
                    atomically: true,
                    encoding: .utf8
                )
                try certInfo.clientKeyPEM.write(
                    to: storageDir.appendingPathComponent("client.key"),
                    atomically: true,
                    encoding: .utf8
                )
                try certInfo.caCertPEM.write(
                    to: storageDir.appendingPathComponent("ca.crt"),
                    atomically: true,
                    encoding: .utf8
                )
            }
            
            // Save preferences
            if rememberServerURL {
                UserDefaults.standard.set(serverURL, forKey: "velociraptor-server-url")
            }
            UserDefaults.standard.set(autoConnect, forKey: "velociraptor-auto-connect")
            
            Logger.shared.success("mTLS configuration complete", component: "CertSetup")
            
        } catch {
            Logger.shared.error("mTLS configuration failed: \(error)", component: "CertSetup")
        }
    }
}

// MARK: - Keychain Extension

extension KeychainManager {
    func storeCertificate(_ pem: String, forKey key: String) throws {
        // Store as generic password
        let data = pem.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.velocidex.velociraptor.certificates",
            kSecValueData as String: data
        ]
        
        // Delete existing
        SecItemDelete(query as CFDictionary)
        
        // Add new
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw KeychainManager.KeychainError.unexpectedStatus(status)
        }
    }
    
    func retrieveCertificate(forKey key: String) throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrService as String: "com.velocidex.velociraptor.certificates",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let pem = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return pem
    }
}

// MARK: - Preview

#Preview {
    CertificateSetupView()
}
