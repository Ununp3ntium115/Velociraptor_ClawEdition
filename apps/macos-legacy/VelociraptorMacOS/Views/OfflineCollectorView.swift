//
//  OfflineCollectorView.swift
//  VelociraptorMacOS
//
//  Offline Collector Creation Wizard with MCP Integration
//  Gap: 0x09 - Offline Collector Creation
//
//  CDIF Pattern: Multi-step wizard with MCP-powered recommendations
//  Swift 6 Concurrency: Strict mode compliant
//

import SwiftUI

// MARK: - Offline Collector View

/// Main offline collector wizard interface
struct OfflineCollectorView: View {
    @StateObject private var viewModel = OfflineCollectorViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // Wizard Header
            CollectorWizardHeader(viewModel: viewModel)
            
            Divider()
            
            // Step Content
            CollectorWizardContent(viewModel: viewModel)
            
            Divider()
            
            // Navigation Footer
            CollectorWizardFooter(viewModel: viewModel)
        }
        .navigationTitle("Offline Collector")
        .accessibilityIdentifier("collector.view")
    }
}

// MARK: - Wizard Header

struct CollectorWizardHeader: View {
    @ObservedObject var viewModel: OfflineCollectorViewModel
    
    let steps = ["Package", "Platforms", "Artifacts", "Options", "Review"]
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Create Offline Collector")
                .font(.title2.bold())
            
            // Step Indicator
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(stepColor(for: index))
                                .frame(width: 32, height: 32)
                            
                            if index < viewModel.currentStep {
                                Image(systemName: "checkmark")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            } else {
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(index <= viewModel.currentStep ? .white : .secondary)
                            }
                        }
                        
                        Text(steps[index])
                            .font(.caption)
                            .foregroundColor(index <= viewModel.currentStep ? .primary : .secondary)
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < viewModel.currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(height: 2)
                                .frame(maxWidth: 60)
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private func stepColor(for index: Int) -> Color {
        if index < viewModel.currentStep {
            return .green
        } else if index == viewModel.currentStep {
            return .accentColor
        } else {
            return .secondary.opacity(0.3)
        }
    }
}

// MARK: - Wizard Content

struct CollectorWizardContent: View {
    @ObservedObject var viewModel: OfflineCollectorViewModel
    
    var body: some View {
        ScrollView {
            Group {
                switch viewModel.currentStep {
                case 0:
                    PackageInfoStep(viewModel: viewModel)
                case 1:
                    PlatformSelectionStep(viewModel: viewModel)
                case 2:
                    ArtifactSelectionStep(viewModel: viewModel)
                case 3:
                    CollectorOptionsStep(viewModel: viewModel)
                case 4:
                    ReviewStep(viewModel: viewModel)
                default:
                    EmptyView()
                }
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Step 1: Package Info

struct PackageInfoStep: View {
    @ObservedObject var viewModel: OfflineCollectorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Package Information")
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Package Name")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextField("Enter package name...", text: $viewModel.packageName)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("collector.package.name")
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Description")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $viewModel.packageDescription)
                    .frame(height: 100)
                    .border(Color.secondary.opacity(0.3))
                    .accessibilityIdentifier("collector.package.description")
            }
            
            // MCP Suggestion
            GroupBox {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AI Package Suggestions")
                            .font(.subheadline.bold())
                        Text("Get AI-powered recommendations for your incident type")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Menu("Select Incident Type") {
                        Button("Ransomware") { viewModel.applyMCPTemplate(for: "ransomware") }
                        Button("APT/Advanced Threat") { viewModel.applyMCPTemplate(for: "apt") }
                        Button("Malware Analysis") { viewModel.applyMCPTemplate(for: "malware") }
                        Button("Insider Threat") { viewModel.applyMCPTemplate(for: "insider_threat") }
                        Button("Data Exfiltration") { viewModel.applyMCPTemplate(for: "data_exfiltration") }
                        Button("General Triage") { viewModel.applyMCPTemplate(for: "general_triage") }
                    }
                    .accessibilityIdentifier("collector.mcp.template.menu")
                }
            }
            .accessibilityIdentifier("collector.mcp.suggestion")
            
            Spacer()
        }
    }
}

// MARK: - Step 2: Platform Selection

struct PlatformSelectionStep: View {
    @ObservedObject var viewModel: OfflineCollectorViewModel
    
    let platforms: [(id: String, name: String, icon: String)] = [
        ("windows_x64", "Windows 64-bit", "desktopcomputer"),
        ("windows_x86", "Windows 32-bit", "desktopcomputer"),
        ("windows_arm64", "Windows ARM64", "desktopcomputer"),
        ("linux_x64", "Linux 64-bit", "terminal"),
        ("linux_arm64", "Linux ARM64", "terminal"),
        ("macos_x64", "macOS Intel", "laptopcomputer"),
        ("macos_arm64", "macOS Apple Silicon", "laptopcomputer"),
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Target Platforms")
                .font(.headline)
            
            Text("Select the platforms where this collector will run")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 200, maximum: 300))
            ], spacing: 12) {
                ForEach(platforms, id: \.id) { platform in
                    PlatformCard(
                        id: platform.id,
                        name: platform.name,
                        icon: platform.icon,
                        isSelected: viewModel.selectedPlatforms.contains(platform.id),
                        onToggle: { viewModel.togglePlatform(platform.id) }
                    )
                }
            }
            
            // Quick Select
            HStack {
                Button("Select All Windows") {
                    viewModel.selectPlatforms(matching: "windows")
                }
                .buttonStyle(.bordered)
                
                Button("Select All Unix") {
                    viewModel.selectPlatforms(matching: "linux", "macos")
                }
                .buttonStyle(.bordered)
                
                Button("Clear All") {
                    viewModel.selectedPlatforms.removeAll()
                }
                .buttonStyle(.bordered)
            }
            
            Spacer()
        }
    }
}

struct PlatformCard: View {
    let id: String
    let name: String
    let icon: String
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        Button(action: onToggle) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isSelected ? .white : .accentColor)
                
                Text(name)
                    .font(.body)
                    .foregroundColor(isSelected ? .white : .primary)
                
                Spacer()
                
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .padding()
            .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("collector.platform.\(id)")
    }
}

// MARK: - Step 3: Artifact Selection

struct ArtifactSelectionStep: View {
    @ObservedObject var viewModel: OfflineCollectorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Artifacts to Collect")
                    .font(.headline)
                
                Spacer()
                
                Text("\(viewModel.selectedArtifacts.count) selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search artifacts...", text: $viewModel.artifactSearchQuery)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("collector.artifacts.search")
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            
            // Artifact List
            List(viewModel.filteredArtifacts, selection: $viewModel.selectedArtifacts) { artifact in
                HStack {
                    Toggle(isOn: Binding(
                        get: { viewModel.selectedArtifacts.contains(artifact.name) },
                        set: { isSelected in
                            if isSelected {
                                viewModel.selectedArtifacts.insert(artifact.name)
                            } else {
                                viewModel.selectedArtifacts.remove(artifact.name)
                            }
                        }
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(artifact.name)
                                .font(.headline)
                            
                            if let description = artifact.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .accessibilityIdentifier("collector.artifact.\(artifact.name)")
            }
            .listStyle(.inset)
            .frame(minHeight: 300)
            
            // Quick Add from MCP
            GroupBox {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple)
                    
                    Text("Add Recommended Artifacts")
                        .font(.subheadline)
                    
                    Spacer()
                    
                    Button("Get Recommendations") {
                        Task { await viewModel.getMCPArtifactRecommendations() }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(viewModel.isLoadingRecommendations)
                    .accessibilityIdentifier("collector.mcp.recommendations")
                }
            }
        }
    }
}

// MARK: - Step 4: Options

struct CollectorOptionsStep: View {
    @ObservedObject var viewModel: OfflineCollectorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Collector Options")
                .font(.headline)
            
            GroupBox("Output Format") {
                Picker("Format", selection: $viewModel.outputFormat) {
                    Text("ZIP Archive").tag(CollectorOutputFormat.zip)
                    Text("Encrypted ZIP").tag(CollectorOutputFormat.encryptedZip)
                    Text("Directory").tag(CollectorOutputFormat.directory)
                }
                .pickerStyle(.radioGroup)
                .accessibilityIdentifier("collector.output.format")
                
                if viewModel.outputFormat == .encryptedZip {
                    HStack {
                        Text("Encryption Password:")
                        SecureField("Enter password", text: $viewModel.encryptionPassword)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 200)
                            .accessibilityIdentifier("collector.encryption.password")
                    }
                    .padding(.top, 8)
                }
            }
            
            GroupBox("Memory Collection") {
                Toggle("Include Memory Acquisition", isOn: $viewModel.includeMemory)
                    .accessibilityIdentifier("collector.include.memory")
                
                if viewModel.includeMemory {
                    Text("Warning: Memory acquisition significantly increases package size and collection time")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
            }
            
            GroupBox("Collection Options") {
                VStack(alignment: .leading, spacing: 8) {
                    Toggle("Collect volatile data first", isOn: $viewModel.volatileFirst)
                        .accessibilityIdentifier("collector.volatile.first")
                    
                    Toggle("Hash collected files", isOn: $viewModel.hashFiles)
                        .accessibilityIdentifier("collector.hash.files")
                    
                    Toggle("Compress large files", isOn: $viewModel.compressFiles)
                        .accessibilityIdentifier("collector.compress.files")
                    
                    Toggle("Generate chain of custody log", isOn: $viewModel.chainOfCustody)
                        .accessibilityIdentifier("collector.chain.custody")
                }
            }
            
            GroupBox("Timeout") {
                HStack {
                    Text("Maximum collection time:")
                    TextField("Minutes", value: $viewModel.timeoutMinutes, format: .number)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 80)
                        .accessibilityIdentifier("collector.timeout")
                    Text("minutes")
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Step 5: Review

struct ReviewStep: View {
    @ObservedObject var viewModel: OfflineCollectorViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Review Configuration")
                .font(.headline)
            
            GroupBox("Package Details") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Name:")
                            .foregroundColor(.secondary)
                        Text(viewModel.packageName.isEmpty ? "(not set)" : viewModel.packageName)
                    }
                    
                    GridRow {
                        Text("Description:")
                            .foregroundColor(.secondary)
                        Text(viewModel.packageDescription.isEmpty ? "(not set)" : viewModel.packageDescription)
                            .lineLimit(2)
                    }
                }
            }
            
            GroupBox("Target Platforms (\(viewModel.selectedPlatforms.count))") {
                FlowLayout(spacing: 8) {
                    ForEach(Array(viewModel.selectedPlatforms), id: \.self) { platform in
                        Text(platform)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.accentColor.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            
            GroupBox("Artifacts (\(viewModel.selectedArtifacts.count))") {
                ScrollView {
                    FlowLayout(spacing: 8) {
                        ForEach(Array(viewModel.selectedArtifacts).sorted(), id: \.self) { artifact in
                            Text(artifact)
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.green.opacity(0.2))
                                .cornerRadius(4)
                        }
                    }
                }
                .frame(maxHeight: 100)
            }
            
            GroupBox("Options") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Output Format:")
                            .foregroundColor(.secondary)
                        Text(viewModel.outputFormat.displayName)
                    }
                    
                    GridRow {
                        Text("Include Memory:")
                            .foregroundColor(.secondary)
                        Text(viewModel.includeMemory ? "Yes" : "No")
                    }
                    
                    GridRow {
                        Text("Timeout:")
                            .foregroundColor(.secondary)
                        Text("\(viewModel.timeoutMinutes) minutes")
                    }
                }
            }
            
            if viewModel.isCreating {
                HStack {
                    ProgressView()
                    Text("Creating collector package...")
                }
            }
            
            Spacer()
        }
    }
}

// MARK: - Wizard Footer

struct CollectorWizardFooter: View {
    @ObservedObject var viewModel: OfflineCollectorViewModel
    
    var body: some View {
        HStack {
            if viewModel.currentStep > 0 {
                Button("Back") {
                    viewModel.previousStep()
                }
                .accessibilityIdentifier("collector.back.button")
            }
            
            Spacer()
            
            if viewModel.currentStep < 4 {
                Button("Next") {
                    viewModel.nextStep()
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canProceed)
                .accessibilityIdentifier("collector.next.button")
            } else {
                Button("Create Collector") {
                    Task { await viewModel.createCollector() }
                }
                .buttonStyle(.borderedProminent)
                .disabled(!viewModel.canCreate || viewModel.isCreating)
                .accessibilityIdentifier("collector.create.button")
            }
        }
        .padding()
    }
}

// MARK: - Models

enum CollectorOutputFormat: String, CaseIterable {
    case zip = "zip"
    case encryptedZip = "encrypted_zip"
    case directory = "directory"
    
    var displayName: String {
        switch self {
        case .zip: return "ZIP Archive"
        case .encryptedZip: return "Encrypted ZIP"
        case .directory: return "Directory"
        }
    }
}

// MARK: - View Model

@MainActor
class OfflineCollectorViewModel: ObservableObject {
    // MARK: - Wizard State
    
    @Published var currentStep: Int = 0
    @Published var isCreating: Bool = false
    @Published var isLoadingRecommendations: Bool = false
    
    // MARK: - Step 1: Package Info
    
    @Published var packageName: String = ""
    @Published var packageDescription: String = ""
    
    // MARK: - Step 2: Platforms
    
    @Published var selectedPlatforms: Set<String> = []
    
    // MARK: - Step 3: Artifacts
    
    @Published var allArtifacts: [Artifact] = []
    @Published var selectedArtifacts: Set<String> = []
    @Published var artifactSearchQuery: String = ""
    
    // MARK: - Step 4: Options
    
    @Published var outputFormat: CollectorOutputFormat = .zip
    @Published var encryptionPassword: String = ""
    @Published var includeMemory: Bool = false
    @Published var volatileFirst: Bool = true
    @Published var hashFiles: Bool = true
    @Published var compressFiles: Bool = true
    @Published var chainOfCustody: Bool = true
    @Published var timeoutMinutes: Int = 60
    
    // MARK: - Computed Properties
    
    var filteredArtifacts: [Artifact] {
        if artifactSearchQuery.isEmpty {
            return allArtifacts
        }
        return allArtifacts.filter {
            $0.name.localizedCaseInsensitiveContains(artifactSearchQuery) ||
            ($0.description?.localizedCaseInsensitiveContains(artifactSearchQuery) ?? false)
        }
    }
    
    var canProceed: Bool {
        switch currentStep {
        case 0: return !packageName.isEmpty
        case 1: return !selectedPlatforms.isEmpty
        case 2: return !selectedArtifacts.isEmpty
        case 3: return outputFormat != .encryptedZip || !encryptionPassword.isEmpty
        default: return true
        }
    }
    
    var canCreate: Bool {
        !packageName.isEmpty &&
        !selectedPlatforms.isEmpty &&
        !selectedArtifacts.isEmpty
    }
    
    // MARK: - Methods
    
    init() {
        loadArtifacts()
    }
    
    func loadArtifacts() {
        Task {
            do {
                allArtifacts = try await VelociraptorAPIClient.shared.listArtifacts()
            } catch {
                Logger.shared.error("Failed to load artifacts: \(error)", component: "Collector")
            }
        }
    }
    
    func nextStep() {
        guard currentStep < 4 else { return }
        currentStep += 1
    }
    
    func previousStep() {
        guard currentStep > 0 else { return }
        currentStep -= 1
    }
    
    func togglePlatform(_ platform: String) {
        if selectedPlatforms.contains(platform) {
            selectedPlatforms.remove(platform)
        } else {
            selectedPlatforms.insert(platform)
        }
    }
    
    func selectPlatforms(matching prefixes: String...) {
        for prefix in prefixes {
            let matching = ["windows_x64", "windows_x86", "windows_arm64", "linux_x64", "linux_arm64", "macos_x64", "macos_arm64"]
                .filter { $0.hasPrefix(prefix) }
            selectedPlatforms.formUnion(matching)
        }
    }
    
    func applyMCPTemplate(for incidentType: String) {
        // Pre-populate based on incident type using MCP recommendations
        switch incidentType {
        case "ransomware":
            packageName = "Ransomware-IR-\(Date().formatted(.dateTime.year().month().day()))"
            packageDescription = "Offline collector for ransomware incident response"
            selectedArtifacts = ["Windows.KapeFiles.Targets", "Windows.EventLogs.Evtx", "Windows.System.Amcache", "Windows.Forensics.Prefetch", "Windows.Network.Netstat"]
        case "apt":
            packageName = "APT-Hunt-\(Date().formatted(.dateTime.year().month().day()))"
            packageDescription = "Offline collector for APT/advanced threat hunting"
            selectedArtifacts = ["Windows.System.Pslist", "Windows.Detection.Autoruns", "Windows.EventLogs.PowerShell", "Windows.Registry.NTUser", "Windows.System.Services"]
        case "malware":
            packageName = "Malware-Triage-\(Date().formatted(.dateTime.year().month().day()))"
            packageDescription = "Offline collector for malware analysis"
            selectedArtifacts = ["Windows.System.Pslist", "Windows.Detection.Yara.Process", "Windows.Forensics.Prefetch", "Windows.System.Amcache"]
        default:
            packageName = "Triage-\(Date().formatted(.dateTime.year().month().day()))"
            packageDescription = "General triage collection"
            selectedArtifacts = ["Generic.Client.Info", "Windows.System.Pslist", "Windows.Network.Netstat"]
        }
        
        selectedPlatforms = ["windows_x64"]
        Logger.shared.info("Applied MCP template: \(incidentType)", component: "Collector")
    }
    
    func getMCPArtifactRecommendations() async {
        isLoadingRecommendations = true
        defer { isLoadingRecommendations = false }
        
        // Simulate MCP call - in production would call the MCP server
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Add recommended artifacts
        let recommended = ["Windows.KapeFiles.Targets", "Windows.EventLogs.Evtx", "Windows.Forensics.Usn", "Windows.System.Amcache"]
        selectedArtifacts.formUnion(recommended)
        
        Logger.shared.success("Added \(recommended.count) recommended artifacts", component: "Collector")
    }
    
    func createCollector() async {
        isCreating = true
        defer { isCreating = false }
        
        // Build the collector package
        Logger.shared.info("Creating offline collector: \(packageName)", component: "Collector")
        
        // Simulate creation - in production would call the API
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        Logger.shared.success("Offline collector created successfully", component: "Collector")
    }
}

// MARK: - Preview

#Preview {
    OfflineCollectorView()
        .frame(width: 800, height: 700)
}
