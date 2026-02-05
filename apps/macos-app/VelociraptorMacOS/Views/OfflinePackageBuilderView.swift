//
//  OfflinePackageBuilderView.swift
//  VelociraptorMacOS
//
//  Offline Package Builder - Creates ISO, USB, MSI, RPM packages for deployment
//  Supports Windows VM (Parallels), Linux RPM, and macOS package creation
//

import SwiftUI

// MARK: - Package Format

enum PackageFormat: String, CaseIterable, Identifiable {
    case iso = "ISO Image"
    case usb = "USB Package"
    case msi = "MSI Installer"
    case rpm = "RPM Package"
    case deb = "DEB Package"
    case pkg = "macOS PKG"
    case portable = "Portable Executable"
    case intune = "Intune Package"
    case jamf = "Jamf Package"
    case sccm = "SCCM Package"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .iso: return "opticaldisc"
        case .usb: return "externaldrive.connected.to.line.below"
        case .msi: return "shippingbox"
        case .rpm, .deb: return "terminal"
        case .pkg: return "macwindow"
        case .portable: return "arrow.down.app"
        case .intune: return "rectangle.stack.person.crop"
        case .jamf: return "desktopcomputer"
        case .sccm: return "server.rack"
        }
    }
    
    var description: String {
        switch self {
        case .iso: return "Bootable ISO image for CD/DVD or VM deployment"
        case .usb: return "Portable USB drive package with autorun"
        case .msi: return "Windows Installer for Group Policy deployment"
        case .rpm: return "Red Hat/CentOS/Fedora package"
        case .deb: return "Debian/Ubuntu package"
        case .pkg: return "macOS installer package"
        case .portable: return "Self-extracting portable executable"
        case .intune: return "Microsoft Intune deployment package"
        case .jamf: return "Jamf Pro deployment package"
        case .sccm: return "System Center Configuration Manager package"
        }
    }
    
    var supportedPlatforms: [PackageTargetPlatform] {
        switch self {
        case .iso: return [.windows, .linux, .macOS]
        case .usb: return [.windows, .linux, .macOS]
        case .msi, .portable, .sccm: return [.windows]
        case .rpm, .deb: return [.linux]
        case .pkg, .jamf: return [.macOS]
        case .intune: return [.windows, .macOS]
        }
    }
}

// MARK: - Package Target Platform

enum PackageTargetPlatform: String, CaseIterable, Identifiable {
    case windows = "Windows"
    case linux = "Linux"
    case macOS = "macOS"
    
    var id: String { rawValue }
    
    var iconName: String {
        switch self {
        case .windows: return "pc"
        case .linux: return "terminal"
        case .macOS: return "desktopcomputer"
        }
    }
}

// MARK: - Offline Package Builder View

struct OfflinePackageBuilderView: View {
    @StateObject private var viewModel = OfflinePackageBuilderViewModel()
    
    var body: some View {
        NavigationView {
            // Sidebar - Package Types
            packageTypeSidebar
                .frame(minWidth: 220, idealWidth: 250, maxWidth: 280)
            
            // Main Content
            packageBuilderContent
        }
        .accessibilityIdentifier("offlinePackageBuilder.main")
        .navigationTitle("Offline Package Builder")
    }
    
    // MARK: - Package Type Sidebar
    
    private var packageTypeSidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Package Builder")
                    .font(.title2.bold())
                Text("Create deployment packages for offline workers")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            
            Divider()
            
            // Format List
            List(PackageFormat.allCases, selection: $viewModel.selectedFormat) { format in
                HStack(spacing: 12) {
                    Image(systemName: format.iconName)
                        .font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(format.rawValue)
                            .font(.body)
                        HStack(spacing: 4) {
                            ForEach(format.supportedPlatforms) { platform in
                                Image(systemName: platform.iconName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .tag(format)
                .padding(.vertical, 4)
            }
            .listStyle(.sidebar)
            
            Divider()
            
            // Quick Actions
            VStack(spacing: 8) {
                Button(action: viewModel.openOutputFolder) {
                    Label("Open Output Folder", systemImage: "folder")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                
                Button(action: viewModel.viewRecentBuilds) {
                    Label("Recent Builds", systemImage: "clock")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Package Builder Content
    
    private var packageBuilderContent: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text(viewModel.selectedFormat.rawValue)
                        .font(.title.bold())
                    Text(viewModel.selectedFormat.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Build Button
                Button(action: viewModel.buildPackage) {
                    HStack {
                        if viewModel.isBuilding {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "hammer.fill")
                        }
                        Text("Build Package")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.isBuilding)
            }
            .padding()
            
            Divider()
            
            // Configuration Tabs
            TabView(selection: $viewModel.selectedTab) {
                platformConfigTab
                    .tabItem { Label("Platform", systemImage: "desktopcomputer") }
                    .tag(0)
                
                artifactsTab
                    .tabItem { Label("Artifacts", systemImage: "doc.text.magnifyingglass") }
                    .tag(1)
                
                toolsTab
                    .tabItem { Label("Tools", systemImage: "wrench.and.screwdriver") }
                    .tag(2)
                
                deploymentTargetsTab
                    .tabItem { Label("Targets", systemImage: "target") }
                    .tag(3)
                
                outputTab
                    .tabItem { Label("Output", systemImage: "arrow.down.doc") }
                    .tag(4)
            }
            .padding()
            
            // Build Progress (if building)
            if viewModel.isBuilding {
                Divider()
                buildProgressView
            }
        }
    }
    
    // MARK: - Platform Configuration Tab
    
    private var platformConfigTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Target Platform") {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(viewModel.selectedFormat.supportedPlatforms) { platform in
                            Toggle(isOn: Binding(
                                get: { viewModel.selectedPlatforms.contains(platform) },
                                set: { isOn in
                                    if isOn {
                                        viewModel.selectedPlatforms.insert(platform)
                                    } else {
                                        viewModel.selectedPlatforms.remove(platform)
                                    }
                                }
                            )) {
                                HStack {
                                    Image(systemName: platform.iconName)
                                    Text(platform.rawValue)
                                }
                            }
                        }
                    }
                    .padding()
                }
                
                // Windows VM Configuration (Parallels)
                if viewModel.selectedPlatforms.contains(.windows) {
                    GroupBox("Windows VM Configuration") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Use Parallels VM for Building", isOn: $viewModel.useParallelsVM)
                                .accessibilityIdentifier("package.toggle.parallels")
                            
                            if viewModel.useParallelsVM {
                                Picker("VM Name", selection: $viewModel.selectedVMName) {
                                    Text("Select VM...").tag("")
                                    ForEach(viewModel.availableVMs, id: \.self) { vm in
                                        Text(vm).tag(vm)
                                    }
                                }
                                
                                HStack {
                                    Text("VM Status:")
                                    Spacer()
                                    Circle()
                                        .fill(viewModel.vmIsRunning ? Color.green : Color.red)
                                        .frame(width: 10, height: 10)
                                    Text(viewModel.vmIsRunning ? "Running" : "Stopped")
                                        .foregroundColor(.secondary)
                                    
                                    Button(viewModel.vmIsRunning ? "Stop" : "Start") {
                                        viewModel.toggleVM()
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // MDM Deployment Options
                GroupBox("MDM Deployment Integration") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle("Create Intune Package", isOn: $viewModel.createIntunePackage)
                            .accessibilityIdentifier("package.toggle.intune")
                        
                        if viewModel.createIntunePackage {
                            Text("Package will be formatted for Microsoft Intune deployment with detection scripts and install commands.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Toggle("Create Jamf Package", isOn: $viewModel.createJamfPackage)
                            .accessibilityIdentifier("package.toggle.jamf")
                        
                        if viewModel.createJamfPackage {
                            Text("Package will include pre/post-install scripts for Jamf Pro deployment.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Toggle("Create SCCM Package", isOn: $viewModel.createSCCMPackage)
                            .accessibilityIdentifier("package.toggle.sccm")
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Artifacts Tab
    
    private var artifactsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Select artifacts to include in the offline package:")
                    .font(.headline)
                
                GroupBox("Incident Response Kit") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.incidentKits, id: \.self) { kit in
                            Toggle(kit, isOn: .constant(true))
                        }
                    }
                    .padding()
                }
                
                GroupBox("Custom Artifacts") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.customArtifacts, id: \.self) { artifact in
                            Toggle(artifact, isOn: .constant(false))
                        }
                        
                        Button("Add Custom Artifact...") {
                            // Add artifact picker
                        }
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Tools Tab
    
    private var toolsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Select DFIR tools to bundle:")
                    .font(.headline)
                
                GroupBox("Memory Analysis") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Volatility3", isOn: $viewModel.includeVolatility)
                        Toggle("WinPmem", isOn: $viewModel.includeWinPmem)
                    }
                    .padding()
                }
                
                GroupBox("Malware Detection") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("YARA", isOn: $viewModel.includeYara)
                        Toggle("ClamAV", isOn: $viewModel.includeClamAV)
                    }
                    .padding()
                }
                
                GroupBox("Log Analysis") {
                    VStack(alignment: .leading, spacing: 8) {
                        Toggle("Chainsaw", isOn: $viewModel.includeChainsaw)
                        Toggle("Sigma Rules", isOn: $viewModel.includeSigma)
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Deployment Targets Tab
    
    private var deploymentTargetsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Configure deployment targets from integrated systems:")
                    .font(.headline)
                
                GroupBox("MDM Integration") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "rectangle.stack.person.crop")
                                .foregroundColor(.accentColor)
                            Text("Microsoft Intune")
                            Spacer()
                            Button("Connect") {}
                                .buttonStyle(.bordered)
                        }
                        
                        HStack {
                            Image(systemName: "desktopcomputer")
                                .foregroundColor(.accentColor)
                            Text("Jamf Pro")
                            Spacer()
                            Button("Connect") {}
                                .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
                
                GroupBox("CMDB Integration") {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "snow")
                                .foregroundColor(.accentColor)
                            Text("ServiceNow CMDB")
                            Spacer()
                            Text("Not Connected")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Image(systemName: "sun.max.fill")
                                .foregroundColor(.accentColor)
                            Text("SolarWinds")
                            Spacer()
                            Text("Not Connected")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                GroupBox("Manual Targets") {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Add targets manually or import from CSV:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Button("Add Target") {}
                            Button("Import CSV") {}
                        }
                        
                        // Target list would go here
                        Text("No manual targets configured")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Output Tab
    
    private var outputTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GroupBox("Output Location") {
                    HStack {
                        TextField("Output Path", text: $viewModel.outputPath)
                            .textFieldStyle(.roundedBorder)
                        Button("Browse...") {
                            viewModel.selectOutputPath()
                        }
                    }
                    .padding()
                }
                
                GroupBox("Package Options") {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Package Name", text: $viewModel.packageName)
                            .textFieldStyle(.roundedBorder)
                        
                        Toggle("Compress Package", isOn: $viewModel.compressPackage)
                        Toggle("Encrypt Package", isOn: $viewModel.encryptPackage)
                        
                        if viewModel.encryptPackage {
                            SecureField("Encryption Password", text: $viewModel.encryptionPassword)
                                .textFieldStyle(.roundedBorder)
                        }
                        
                        Toggle("Generate Checksums", isOn: $viewModel.generateChecksums)
                        Toggle("Sign Package", isOn: $viewModel.signPackage)
                    }
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Build Progress View
    
    private var buildProgressView: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Building Package...")
                    .font(.headline)
                Spacer()
                Text("\(Int(viewModel.buildProgress * 100))%")
            }
            
            ProgressView(value: viewModel.buildProgress)
            
            Text(viewModel.buildStatusMessage)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - ViewModel

@MainActor
class OfflinePackageBuilderViewModel: ObservableObject {
    @Published var selectedFormat: PackageFormat = .iso
    @Published var selectedTab = 0
    @Published var selectedPlatforms: Set<PackageTargetPlatform> = [.windows]
    
    // Windows VM
    @Published var useParallelsVM = false
    @Published var selectedVMName = ""
    @Published var vmIsRunning = false
    @Published var availableVMs: [String] = ["Windows 11", "Windows Server 2022", "Windows 10 LTSC"]
    
    // MDM
    @Published var createIntunePackage = false
    @Published var createJamfPackage = false
    @Published var createSCCMPackage = false
    
    // Artifacts
    @Published var incidentKits = ["Ransomware Response", "APT Investigation", "Insider Threat", "Malware Analysis"]
    @Published var customArtifacts = ["Windows.System.ProcessInfo", "Windows.Registry.UserAssist", "Windows.EventLogs.Security"]
    
    // Tools
    @Published var includeVolatility = true
    @Published var includeWinPmem = true
    @Published var includeYara = true
    @Published var includeClamAV = false
    @Published var includeChainsaw = true
    @Published var includeSigma = true
    
    // Output
    @Published var outputPath = "~/Downloads/VelociraptorPackages"
    @Published var packageName = "VelociraptorOffline"
    @Published var compressPackage = true
    @Published var encryptPackage = false
    @Published var encryptionPassword = ""
    @Published var generateChecksums = true
    @Published var signPackage = false
    
    // Build state
    @Published var isBuilding = false
    @Published var buildProgress: Double = 0
    @Published var buildStatusMessage = ""
    
    func openOutputFolder() {
        // Open Finder to output folder
    }
    
    func viewRecentBuilds() {
        // Show recent builds
    }
    
    func toggleVM() {
        vmIsRunning.toggle()
    }
    
    func selectOutputPath() {
        // Show folder picker
    }
    
    func buildPackage() {
        isBuilding = true
        buildProgress = 0
        buildStatusMessage = "Preparing build environment..."
        
        // Simulate build process
        Task {
            for step in 0..<10 {
                try? await Task.sleep(nanoseconds: 500_000_000)
                buildProgress = Double(step + 1) / 10.0
                switch step {
                case 0: buildStatusMessage = "Copying Velociraptor binary..."
                case 1: buildStatusMessage = "Bundling DFIR tools..."
                case 2: buildStatusMessage = "Generating configuration..."
                case 3: buildStatusMessage = "Adding artifacts..."
                case 4: buildStatusMessage = "Creating automation scripts..."
                case 5: buildStatusMessage = "Packaging for \(selectedFormat.rawValue)..."
                case 6: buildStatusMessage = "Compressing package..."
                case 7: buildStatusMessage = "Generating checksums..."
                case 8: buildStatusMessage = "Creating MDM packages..."
                case 9: buildStatusMessage = "Build complete!"
                default: break
                }
            }
            
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isBuilding = false
        }
    }
}

// MARK: - Preview

#if DEBUG
#Preview {
    OfflinePackageBuilderView()
        .frame(width: 1000, height: 700)
}
#endif
