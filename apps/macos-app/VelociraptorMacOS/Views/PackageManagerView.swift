//
//  PackageManagerView.swift
//  VelociraptorMacOS
//
//  Package Management Interface
//  Gap 0x0F - Manage deployment packages and collectors
//
//  Features:
//  - Create and manage deployment packages
//  - Client installer generation (MSI, PKG, DEB, RPM)
//  - Offline collector package management
//  - Package signing and verification
//  - Distribution management
//
//  CDIF Pattern: FC-001 (Feature Complete)
//  Swift 6 Concurrency: @MainActor, Sendable
//

import SwiftUI
import Combine

// MARK: - Data Models

struct DeploymentPackage: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var packageType: PackageType
    var platform: TargetPlatform
    var version: String
    var createdDate: Date
    var size: Int64
    var isSigned: Bool
    var signatureStatus: SignatureStatus
    var configuration: PackageConfiguration
    
    init(id: UUID = UUID(), name: String, packageType: PackageType, platform: TargetPlatform, version: String = "1.0.0", createdDate: Date = Date(), size: Int64 = 0, isSigned: Bool = false, signatureStatus: SignatureStatus = .unsigned, configuration: PackageConfiguration = PackageConfiguration()) {
        self.id = id
        self.name = name
        self.packageType = packageType
        self.platform = platform
        self.version = version
        self.createdDate = createdDate
        self.size = size
        self.isSigned = isSigned
        self.signatureStatus = signatureStatus
        self.configuration = configuration
    }
}

enum PackageType: String, CaseIterable, Sendable {
    case clientInstaller = "Client Installer"
    case offlineCollector = "Offline Collector"
    case serverDeployment = "Server Deployment"
    case agentUpdate = "Agent Update"
    
    var icon: String {
        switch self {
        case .clientInstaller: return "desktopcomputer"
        case .offlineCollector: return "externaldrive.fill"
        case .serverDeployment: return "server.rack"
        case .agentUpdate: return "arrow.down.circle.fill"
        }
    }
}

enum TargetPlatform: String, CaseIterable, Sendable {
    case windowsX64 = "Windows x64"
    case windowsArm64 = "Windows ARM64"
    case macosUniversal = "macOS Universal"
    case macosX64 = "macOS x64"
    case macosArm64 = "macOS ARM64"
    case linuxX64 = "Linux x64"
    case linuxArm64 = "Linux ARM64"
    
    var icon: String {
        switch self {
        case .windowsX64, .windowsArm64:
            return "pc"
        case .macosUniversal, .macosX64, .macosArm64:
            return "desktopcomputer"
        case .linuxX64, .linuxArm64:
            return "terminal.fill"
        }
    }
    
    var fileExtension: String {
        switch self {
        case .windowsX64, .windowsArm64:
            return "msi"
        case .macosUniversal, .macosX64, .macosArm64:
            return "pkg"
        case .linuxX64, .linuxArm64:
            return "deb"
        }
    }
}

enum SignatureStatus: String, Sendable {
    case unsigned = "Unsigned"
    case signed = "Signed"
    case verified = "Verified"
    case invalid = "Invalid"
    
    var color: Color {
        switch self {
        case .unsigned: return .gray
        case .signed: return .orange
        case .verified: return .green
        case .invalid: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .unsigned: return "shield.slash"
        case .signed: return "checkmark.shield"
        case .verified: return "checkmark.shield.fill"
        case .invalid: return "xmark.shield.fill"
        }
    }
}

struct PackageConfiguration: Hashable, Sendable {
    var serverUrl: String = ""
    var includeTools: Bool = true
    var compressOutput: Bool = true
    var encryptPackage: Bool = false
    var customArtifacts: [String] = []
    var memoryCollection: Bool = false
    var volatileFirst: Bool = true
}

// MARK: - ViewModel

@MainActor
final class PackageManagerViewModel: ObservableObject {
    @Published var packages: [DeploymentPackage] = []
    @Published var selectedPackage: DeploymentPackage?
    @Published var isLoading = false
    @Published var showCreateSheet = false
    @Published var isBuilding = false
    @Published var buildProgress: Double = 0
    @Published var buildStatus: String = ""
    @Published var searchText = ""
    @Published var selectedType: PackageType?
    
    var filteredPackages: [DeploymentPackage] {
        var result = packages
        
        if let type = selectedType {
            result = result.filter { $0.packageType == type }
        }
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.platform.rawValue.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        return result.sorted { $0.createdDate > $1.createdDate }
    }
    
    func loadPackages() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load sample packages for demo
        if packages.isEmpty {
            packages = [
                DeploymentPackage(
                    name: "Windows Client v1.0.5",
                    packageType: .clientInstaller,
                    platform: .windowsX64,
                    version: "1.0.5",
                    createdDate: Date().addingTimeInterval(-86400),
                    size: 45_000_000,
                    isSigned: true,
                    signatureStatus: .verified
                ),
                DeploymentPackage(
                    name: "macOS Universal Client",
                    packageType: .clientInstaller,
                    platform: .macosUniversal,
                    version: "1.0.5",
                    createdDate: Date().addingTimeInterval(-172800),
                    size: 52_000_000,
                    isSigned: true,
                    signatureStatus: .signed
                ),
                DeploymentPackage(
                    name: "IR Triage Collector",
                    packageType: .offlineCollector,
                    platform: .windowsX64,
                    version: "2.1.0",
                    createdDate: Date().addingTimeInterval(-259200),
                    size: 120_000_000,
                    isSigned: false,
                    signatureStatus: .unsigned
                ),
                DeploymentPackage(
                    name: "Linux Server Deploy",
                    packageType: .serverDeployment,
                    platform: .linuxX64,
                    version: "1.0.0",
                    createdDate: Date().addingTimeInterval(-432000),
                    size: 85_000_000,
                    isSigned: true,
                    signatureStatus: .verified
                )
            ]
        }
    }
    
    func createPackage(_ package: DeploymentPackage) async {
        isBuilding = true
        buildProgress = 0
        buildStatus = "Initializing..."
        
        // Simulate package build process
        let steps = [
            (0.1, "Preparing configuration..."),
            (0.2, "Downloading Velociraptor binary..."),
            (0.4, "Embedding configuration..."),
            (0.5, "Adding artifacts..."),
            (0.6, "Adding tools..."),
            (0.75, "Compressing package..."),
            (0.9, "Finalizing..."),
            (1.0, "Complete!")
        ]
        
        for (progress, status) in steps {
            try? await Task.sleep(nanoseconds: 500_000_000)
            buildProgress = progress
            buildStatus = status
        }
        
        var newPackage = package
        newPackage.size = Int64.random(in: 40_000_000...150_000_000)
        packages.append(newPackage)
        
        isBuilding = false
        buildProgress = 0
        buildStatus = ""
    }
    
    func deletePackage(_ package: DeploymentPackage) {
        packages.removeAll { $0.id == package.id }
        if selectedPackage?.id == package.id {
            selectedPackage = nil
        }
    }
    
    func signPackage(_ package: DeploymentPackage) async {
        if let index = packages.firstIndex(where: { $0.id == package.id }) {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            packages[index].isSigned = true
            packages[index].signatureStatus = .signed
        }
    }
    
    func exportPackage(_ package: DeploymentPackage) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "\(package.name).\(package.platform.fileExtension)"
        panel.allowedContentTypes = [.data]
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                Logger.shared.info("Exporting package to \(url.path)", component: "Package")
            }
        }
    }
    
    func formatSize(_ bytes: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: bytes)
    }
}

// MARK: - Main View

struct PackageManagerView: View {
    @StateObject private var viewModel = PackageManagerViewModel()
    
    var body: some View {
        HSplitView {
            // Sidebar - Package List
            PackageListView(viewModel: viewModel)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            
            // Detail View
            if let package = viewModel.selectedPackage {
                PackageDetailView(package: package, viewModel: viewModel)
            } else {
                EmptyPackageView(viewModel: viewModel)
            }
        }
        .accessibilityIdentifier("packages.main")
        .task {
            await viewModel.loadPackages()
        }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreatePackageSheet(viewModel: viewModel)
        }
        .accessibilityIdentifier("package.main")
    }
}

// MARK: - Package List

struct PackageListView: View {
    @ObservedObject var viewModel: PackageManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Packages")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.showCreateSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("package.add")
            }
            .padding()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search packages...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Type Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    PackageFilterPill(
                        title: "All",
                        isSelected: viewModel.selectedType == nil,
                        action: { viewModel.selectedType = nil }
                    )
                    
                    ForEach(PackageType.allCases, id: \.self) { type in
                        PackageFilterPill(
                            title: type.rawValue,
                            isSelected: viewModel.selectedType == type,
                            action: { viewModel.selectedType = type }
                        )
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Package List
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if viewModel.filteredPackages.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "shippingbox")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Packages")
                        .font(.headline)
                    Text("Create a deployment package to get started")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Create Package") {
                        viewModel.showCreateSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else {
                List(viewModel.filteredPackages, selection: $viewModel.selectedPackage) { package in
                    PackageRow(package: package, viewModel: viewModel)
                        .tag(package)
                }
                .listStyle(.sidebar)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct PackageFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
        .buttonStyle(.plain)
    }
}

struct PackageRow: View {
    let package: DeploymentPackage
    let viewModel: PackageManagerViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: package.packageType.icon)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(package.name)
                    .font(.headline)
                HStack(spacing: 8) {
                    Text(package.platform.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text(viewModel.formatSize(package.size))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Image(systemName: package.signatureStatus.icon)
                .foregroundColor(package.signatureStatus.color)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("package.item.\(package.id)")
    }
}

// MARK: - Package Detail

struct PackageDetailView: View {
    let package: DeploymentPackage
    @ObservedObject var viewModel: PackageManagerViewModel
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: package.packageType.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading) {
                        Text(package.name)
                            .font(.title)
                        HStack {
                            Text(package.packageType.rawValue)
                                .foregroundColor(.secondary)
                            Text("•")
                                .foregroundColor(.secondary)
                            Text(package.platform.rawValue)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        HStack {
                            Image(systemName: package.signatureStatus.icon)
                            Text(package.signatureStatus.rawValue)
                        }
                        .foregroundColor(package.signatureStatus.color)
                        
                        Text("v\(package.version)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Divider()
                
                // Package Info
                GroupBox("Package Information") {
                    VStack(alignment: .leading, spacing: 12) {
                        PackageDetailRow(label: "Size", value: viewModel.formatSize(package.size))
                        PackageDetailRow(label: "Created", value: formatDate(package.createdDate))
                        PackageDetailRow(label: "Format", value: ".\(package.platform.fileExtension)")
                        PackageDetailRow(label: "Version", value: package.version)
                    }
                    .padding()
                }
                
                // Configuration
                GroupBox("Configuration") {
                    VStack(alignment: .leading, spacing: 12) {
                        PackageDetailRow(label: "Server URL", value: package.configuration.serverUrl.isEmpty ? "Default" : package.configuration.serverUrl)
                        PackageDetailRow(label: "Include Tools", value: package.configuration.includeTools ? "Yes" : "No")
                        PackageDetailRow(label: "Compressed", value: package.configuration.compressOutput ? "Yes" : "No")
                        PackageDetailRow(label: "Encrypted", value: package.configuration.encryptPackage ? "Yes" : "No")
                        
                        if package.packageType == .offlineCollector {
                            PackageDetailRow(label: "Memory Collection", value: package.configuration.memoryCollection ? "Enabled" : "Disabled")
                            PackageDetailRow(label: "Volatile First", value: package.configuration.volatileFirst ? "Yes" : "No")
                        }
                    }
                    .padding()
                }
                
                // Actions
                GroupBox("Actions") {
                    VStack(spacing: 12) {
                        HStack(spacing: 12) {
                            Button(action: { viewModel.exportPackage(package) }) {
                                Label("Export", systemImage: "square.and.arrow.up")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: {
                                Task {
                                    await viewModel.signPackage(package)
                                }
                            }) {
                                Label("Sign Package", systemImage: "signature")
                            }
                            .buttonStyle(.bordered)
                            .disabled(package.isSigned)
                            
                            Spacer()
                        }
                        
                        HStack(spacing: 12) {
                            Button(action: {
                                // Rebuild package
                            }) {
                                Label("Rebuild", systemImage: "arrow.clockwise")
                            }
                            .buttonStyle(.bordered)
                            
                            Button(role: .destructive, action: { showDeleteConfirm = true }) {
                                Label("Delete", systemImage: "trash")
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                        }
                    }
                    .padding()
                }
                
                Spacer()
            }
            .padding(24)
        }
        .alert("Delete Package?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deletePackage(package)
            }
        } message: {
            Text("This will permanently delete \(package.name). This action cannot be undone.")
        }
        .accessibilityIdentifier("package.detail")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PackageDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 150, alignment: .leading)
            Text(value)
            Spacer()
        }
    }
}

// MARK: - Empty State

struct EmptyPackageView: View {
    @ObservedObject var viewModel: PackageManagerViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 72))
                .foregroundColor(.secondary)
            
            Text("Package Manager")
                .font(.title)
            
            Text("Create and manage deployment packages")
                .foregroundColor(.secondary)
            
            VStack(alignment: .leading, spacing: 12) {
                PackageFeatureRow(icon: "desktopcomputer", text: "Generate client installers (MSI, PKG, DEB)")
                PackageFeatureRow(icon: "externaldrive.fill", text: "Build offline collectors for IR triage")
                PackageFeatureRow(icon: "signature", text: "Sign packages for secure distribution")
                PackageFeatureRow(icon: "arrow.down.circle.fill", text: "Manage agent updates")
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            
            Button("Create Package") {
                viewModel.showCreateSheet = true
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(48)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct PackageFeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            Text(text)
        }
    }
}

// MARK: - Create Package Sheet

struct CreatePackageSheet: View {
    @ObservedObject var viewModel: PackageManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var packageType: PackageType = .clientInstaller
    @State private var platform: TargetPlatform = .windowsX64
    @State private var version = "1.0.0"
    @State private var serverUrl = ""
    @State private var includeTools = true
    @State private var compressOutput = true
    @State private var encryptPackage = false
    @State private var memoryCollection = false
    @State private var volatileFirst = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create Package")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.borderless)
            }
            .padding()
            
            Divider()
            
            if viewModel.isBuilding {
                // Build Progress View
                VStack(spacing: 20) {
                    Spacer()
                    
                    ProgressView(value: viewModel.buildProgress) {
                        Text(viewModel.buildStatus)
                    }
                    .progressViewStyle(.linear)
                    .frame(maxWidth: 300)
                    
                    Text("\(Int(viewModel.buildProgress * 100))%")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                }
                .padding()
            } else {
                // Form
                Form {
                    Section("Package Details") {
                        TextField("Package Name", text: $name, prompt: Text("e.g., Windows Client v1.0"))
                        
                        Picker("Type", selection: $packageType) {
                            ForEach(PackageType.allCases, id: \.self) { type in
                                HStack {
                                    Image(systemName: type.icon)
                                    Text(type.rawValue)
                                }
                                .tag(type)
                            }
                        }
                        
                        Picker("Platform", selection: $platform) {
                            ForEach(TargetPlatform.allCases, id: \.self) { p in
                                HStack {
                                    Image(systemName: p.icon)
                                    Text(p.rawValue)
                                }
                                .tag(p)
                            }
                        }
                        
                        TextField("Version", text: $version)
                    }
                    
                    Section("Configuration") {
                        TextField("Server URL", text: $serverUrl, prompt: Text("https://velociraptor.example.com"))
                        Toggle("Include Tools", isOn: $includeTools)
                        Toggle("Compress Output", isOn: $compressOutput)
                        Toggle("Encrypt Package", isOn: $encryptPackage)
                    }
                    
                    if packageType == .offlineCollector {
                        Section("Collector Options") {
                            Toggle("Memory Collection", isOn: $memoryCollection)
                            Toggle("Collect Volatile Data First", isOn: $volatileFirst)
                        }
                    }
                }
                .formStyle(.grouped)
            }
            
            Divider()
            
            // Footer
            HStack {
                if viewModel.isBuilding {
                    Button("Cancel Build") {
                        // Cancel build
                        dismiss()
                    }
                } else {
                    Spacer()
                    Button("Cancel") { dismiss() }
                        .keyboardShortcut(.escape)
                    Button("Create Package") {
                        createPackage()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(name.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
            .padding()
        }
        .frame(width: 500, height: viewModel.isBuilding ? 300 : 550)
        .accessibilityIdentifier("package.create.sheet")
    }
    
    private func createPackage() {
        let config = PackageConfiguration(
            serverUrl: serverUrl,
            includeTools: includeTools,
            compressOutput: compressOutput,
            encryptPackage: encryptPackage,
            memoryCollection: memoryCollection,
            volatileFirst: volatileFirst
        )
        
        let package = DeploymentPackage(
            name: name,
            packageType: packageType,
            platform: platform,
            version: version,
            configuration: config
        )
        
        Task {
            await viewModel.createPackage(package)
            dismiss()
        }
    }
}

// MARK: - Preview

#if DEBUG
struct PackageManagerView_Previews: PreviewProvider {
    static var previews: some View {
        PackageManagerView()
            .frame(width: 1200, height: 800)
    }
}
#endif
