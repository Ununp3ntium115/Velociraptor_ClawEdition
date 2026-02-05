//
//  ToolsManagerView.swift
//  VelociraptorMacOS
//
//  DFIR Tools Management interface
//  Implements Gap 0x07: Tools Integration
//

import SwiftUI

// MARK: - Tools Manager View

/// Main tools management interface
struct ToolsManagerView: View {
    @StateObject private var viewModel = ToolsManagerViewModel()
    
    var body: some View {
        HSplitView {
            // Left: Tool categories and list
            ToolsSidebar(viewModel: viewModel)
                .frame(minWidth: 250, maxWidth: 300)
            
            // Right: Tool details and execution
            ToolsDetailPane(viewModel: viewModel)
                .frame(minWidth: 500)
        }
        .navigationTitle("DFIR Tools")
        .toolbar {
            ToolsToolbar(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showInstallSheet) {
            ToolInstallSheet(viewModel: viewModel)
        }
        .accessibilityIdentifier("tools_manager_view")
    }
}

// MARK: - Tools Sidebar

struct ToolsSidebar: View {
    @ObservedObject var viewModel: ToolsManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search tools...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("tools_search")
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding()
            
            Divider()
            
            // Categories
            List(selection: $viewModel.selectedCategoryId) {
                Section("Categories") {
                    ForEach(ToolCategory.allCases) { category in
                        ToolCategoryRow(category: category, toolCount: viewModel.toolCount(for: category))
                            .tag(category.id)
                    }
                }
                
                Section("Status") {
                    StatusFilterRow(filter: .all, count: viewModel.allTools.count, viewModel: viewModel)
                    StatusFilterRow(filter: .installed, count: viewModel.installedCount, viewModel: viewModel)
                    StatusFilterRow(filter: .available, count: viewModel.availableCount, viewModel: viewModel)
                    StatusFilterRow(filter: .updateAvailable, count: viewModel.updateCount, viewModel: viewModel)
                }
            }
            .listStyle(.sidebar)
            .accessibilityIdentifier("tools_category_list")
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ToolCategoryRow: View {
    let category: ToolCategory
    let toolCount: Int
    
    var body: some View {
        HStack {
            Image(systemName: category.icon)
                .foregroundColor(category.color)
                .frame(width: 24)
            Text(category.displayName)
            Spacer()
            Text("\(toolCount)")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(4)
        }
        .accessibilityIdentifier("tools_category_\(category.rawValue)")
    }
}

struct StatusFilterRow: View {
    let filter: ToolStatusFilter
    let count: Int
    @ObservedObject var viewModel: ToolsManagerViewModel
    
    var body: some View {
        Button(action: { viewModel.statusFilter = filter }) {
            HStack {
                Circle()
                    .fill(filter.color)
                    .frame(width: 8, height: 8)
                Text(filter.displayName)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(viewModel.statusFilter == filter ? Color.accentColor.opacity(0.2) : Color.clear)
        .cornerRadius(4)
    }
}

// MARK: - Tools Detail Pane

struct ToolsDetailPane: View {
    @ObservedObject var viewModel: ToolsManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ToolsDetailHeader(viewModel: viewModel)
            
            Divider()
            
            // Tool list
            if viewModel.filteredTools.isEmpty {
                ToolsEmptyState(viewModel: viewModel)
            } else {
                ToolsGrid(viewModel: viewModel)
            }
        }
        .accessibilityIdentifier("tools_detail_pane")
    }
}

struct ToolsDetailHeader: View {
    @ObservedObject var viewModel: ToolsManagerViewModel
    
    var body: some View {
        HStack {
            Text(viewModel.selectedCategory?.displayName ?? "All Tools")
                .font(.headline)
            
            Spacer()
            
            // View mode
            Picker("View", selection: $viewModel.viewMode) {
                Image(systemName: "square.grid.2x2").tag(ToolsViewMode.grid)
                Image(systemName: "list.bullet").tag(ToolsViewMode.list)
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
            
            // Sort
            Menu {
                Button("Name") { viewModel.sortOrder = .name }
                Button("Category") { viewModel.sortOrder = .category }
                Button("Status") { viewModel.sortOrder = .status }
                Button("Recently Used") { viewModel.sortOrder = .recentlyUsed }
            } label: {
                Label("Sort", systemImage: "arrow.up.arrow.down")
            }
        }
        .padding()
    }
}

struct ToolsGrid: View {
    @ObservedObject var viewModel: ToolsManagerViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 280, maximum: 350))
            ], spacing: 16) {
                ForEach(viewModel.filteredTools) { tool in
                    ToolCard(tool: tool, viewModel: viewModel)
                }
            }
            .padding()
        }
        .accessibilityIdentifier("tools_grid")
    }
}

struct ToolCard: View {
    let tool: DFIRTool
    @ObservedObject var viewModel: ToolsManagerViewModel
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: tool.category.icon)
                    .font(.title2)
                    .foregroundColor(tool.category.color)
                    .frame(width: 40, height: 40)
                    .background(tool.category.color.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(tool.name)
                        .font(.headline)
                    Text(tool.version)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status indicator
                ToolStatusBadge(status: tool.status)
            }
            
            // Description
            Text(tool.description)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            // Tags
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tool.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(4)
                    }
                }
            }
            
            Divider()
            
            // Actions
            HStack {
                if tool.status == .installed {
                    Button("Run") {
                        viewModel.runTool(tool)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                    
                    Button("Configure") {
                        viewModel.configureTool(tool)
                    }
                    .controlSize(.small)
                } else {
                    Button("Install") {
                        Task { await viewModel.installTool(tool) }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.small)
                }
                
                Spacer()
                
                Menu {
                    if tool.status == .installed {
                        Button("View Documentation") {
                            viewModel.openDocumentation(tool)
                        }
                        Button("Check for Updates") {
                            Task { await viewModel.checkUpdate(tool) }
                        }
                        Divider()
                        Button("Uninstall", role: .destructive) {
                            Task { await viewModel.uninstallTool(tool) }
                        }
                    } else {
                        Button("View on GitHub") {
                            viewModel.openGitHub(tool)
                        }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .menuStyle(.borderlessButton)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isHovered ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onHover { isHovered = $0 }
        .accessibilityIdentifier("tool_card_\(tool.id)")
    }
}

struct ToolStatusBadge: View {
    let status: ToolStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(status.color)
                .frame(width: 6, height: 6)
            Text(status.displayName)
                .font(.caption2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.1))
        .cornerRadius(4)
    }
}

struct ToolsEmptyState: View {
    @ObservedObject var viewModel: ToolsManagerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "wrench.and.screwdriver")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Tools Found")
                .font(.headline)
            
            Text("No tools match your current filters")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Browse All Tools") {
                viewModel.resetFilters()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("tools_empty_state")
    }
}

// MARK: - Tools Toolbar

struct ToolsToolbar: ToolbarContent {
    @ObservedObject var viewModel: ToolsManagerViewModel
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { viewModel.showInstallSheet = true }) {
                Label("Add Tool", systemImage: "plus")
            }
            .accessibilityIdentifier("tools_add_button")
            
            Button(action: { Task { await viewModel.refreshTools() } }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .accessibilityIdentifier("tools_refresh_button")
        }
    }
}

// MARK: - Tool Install Sheet

struct ToolInstallSheet: View {
    @ObservedObject var viewModel: ToolsManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Install DFIR Tool")
                .font(.headline)
            
            Text("Select a tool to install from the available tools list, or provide a custom tool URL.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Available tools list
            List(viewModel.availableTools, selection: $viewModel.toolToInstall) { tool in
                HStack {
                    Image(systemName: tool.category.icon)
                        .foregroundColor(tool.category.color)
                    VStack(alignment: .leading) {
                        Text(tool.name)
                        Text(tool.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .tag(tool)
            }
            .frame(height: 200)
            
            Divider()
            
            // Custom URL
            VStack(alignment: .leading, spacing: 4) {
                Text("Or enter custom tool URL:")
                    .font(.caption)
                TextField("https://github.com/...", text: $viewModel.customToolURL)
                    .textFieldStyle(.roundedBorder)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                
                Spacer()
                
                Button("Install") {
                    Task {
                        if let tool = viewModel.toolToInstall {
                            await viewModel.installTool(tool)
                        }
                        dismiss()
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(viewModel.toolToInstall == nil && viewModel.customToolURL.isEmpty)
            }
        }
        .padding()
        .frame(width: 500, height: 400)
        .accessibilityIdentifier("tool_install_sheet")
    }
}

// MARK: - Models

enum ToolCategory: String, CaseIterable, Identifiable {
    case memory = "memory"
    case filesystem = "filesystem"
    case network = "network"
    case malware = "malware"
    case logs = "logs"
    case registry = "registry"
    case timeline = "timeline"
    case triage = "triage"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .memory: return "Memory Analysis"
        case .filesystem: return "Filesystem"
        case .network: return "Network"
        case .malware: return "Malware Detection"
        case .logs: return "Log Analysis"
        case .registry: return "Registry"
        case .timeline: return "Timeline"
        case .triage: return "Triage"
        }
    }
    
    var icon: String {
        switch self {
        case .memory: return "memorychip"
        case .filesystem: return "folder"
        case .network: return "network"
        case .malware: return "ladybug"
        case .logs: return "doc.text.magnifyingglass"
        case .registry: return "gearshape.2"
        case .timeline: return "clock"
        case .triage: return "exclamationmark.triangle"
        }
    }
    
    var color: Color {
        switch self {
        case .memory: return .purple
        case .filesystem: return .blue
        case .network: return .green
        case .malware: return .red
        case .logs: return .orange
        case .registry: return .cyan
        case .timeline: return .indigo
        case .triage: return .yellow
        }
    }
}

enum ToolStatus: String {
    case installed, available, updateAvailable, installing, error
    
    var displayName: String {
        switch self {
        case .installed: return "Installed"
        case .available: return "Available"
        case .updateAvailable: return "Update"
        case .installing: return "Installing"
        case .error: return "Error"
        }
    }
    
    var color: Color {
        switch self {
        case .installed: return .green
        case .available: return .blue
        case .updateAvailable: return .orange
        case .installing: return .purple
        case .error: return .red
        }
    }
}

enum ToolStatusFilter: String, CaseIterable {
    case all, installed, available, updateAvailable
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .installed: return "Installed"
        case .available: return "Available"
        case .updateAvailable: return "Updates"
        }
    }
    
    var color: Color {
        switch self {
        case .all: return .gray
        case .installed: return .green
        case .available: return .blue
        case .updateAvailable: return .orange
        }
    }
}

enum ToolsViewMode: String {
    case grid, list
}

enum ToolsSortOrder: String {
    case name, category, status, recentlyUsed
}

struct DFIRTool: Identifiable, Hashable {
    let id: String
    let name: String
    let description: String
    let version: String
    let category: ToolCategory
    var status: ToolStatus
    let tags: [String]
    let githubURL: String?
    let documentationURL: String?
    let lastUsed: Date?
    
    static func == (lhs: DFIRTool, rhs: DFIRTool) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

// MARK: - View Model

@MainActor
class ToolsManagerViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var searchText: String = ""
    @Published var selectedCategoryId: String?
    @Published var statusFilter: ToolStatusFilter = .all
    @Published var viewMode: ToolsViewMode = .grid
    @Published var sortOrder: ToolsSortOrder = .name
    
    @Published var showInstallSheet: Bool = false
    @Published var toolToInstall: DFIRTool?
    @Published var customToolURL: String = ""
    
    @Published var isLoading: Bool = false
    
    // MARK: - Tools Data
    
    @Published var allTools: [DFIRTool] = DFIRTool.defaultTools
    
    // MARK: - Computed Properties
    
    var selectedCategory: ToolCategory? {
        guard let id = selectedCategoryId else { return nil }
        return ToolCategory(rawValue: id)
    }
    
    var filteredTools: [DFIRTool] {
        var tools = allTools
        
        // Category filter
        if let category = selectedCategory {
            tools = tools.filter { $0.category == category }
        }
        
        // Status filter
        switch statusFilter {
        case .installed:
            tools = tools.filter { $0.status == .installed }
        case .available:
            tools = tools.filter { $0.status == .available }
        case .updateAvailable:
            tools = tools.filter { $0.status == .updateAvailable }
        case .all:
            break
        }
        
        // Search filter
        if !searchText.isEmpty {
            tools = tools.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.description.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sort
        switch sortOrder {
        case .name:
            tools.sort { $0.name < $1.name }
        case .category:
            tools.sort { $0.category.displayName < $1.category.displayName }
        case .status:
            tools.sort { $0.status.rawValue < $1.status.rawValue }
        case .recentlyUsed:
            tools.sort { ($0.lastUsed ?? .distantPast) > ($1.lastUsed ?? .distantPast) }
        }
        
        return tools
    }
    
    var availableTools: [DFIRTool] {
        allTools.filter { $0.status == .available }
    }
    
    var installedCount: Int {
        allTools.filter { $0.status == .installed }.count
    }
    
    var availableCount: Int {
        allTools.filter { $0.status == .available }.count
    }
    
    var updateCount: Int {
        allTools.filter { $0.status == .updateAvailable }.count
    }
    
    // MARK: - Methods
    
    func toolCount(for category: ToolCategory) -> Int {
        allTools.filter { $0.category == category }.count
    }
    
    func resetFilters() {
        selectedCategoryId = nil
        statusFilter = .all
        searchText = ""
    }
    
    func refreshTools() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Fetch tools from server
        try? await Task.sleep(nanoseconds: 500_000_000)
    }
    
    func installTool(_ tool: DFIRTool) async {
        guard let index = allTools.firstIndex(where: { $0.id == tool.id }) else { return }
        
        allTools[index].status = .installing
        
        // Simulate installation
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        allTools[index].status = .installed
    }
    
    func uninstallTool(_ tool: DFIRTool) async {
        guard let index = allTools.firstIndex(where: { $0.id == tool.id }) else { return }
        
        // Simulate uninstallation
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        allTools[index].status = .available
    }
    
    func checkUpdate(_ tool: DFIRTool) async {
        // TODO: Check for updates
    }
    
    func runTool(_ tool: DFIRTool) {
        // TODO: Launch tool execution interface
        print("Run: \(tool.name)")
    }
    
    func configureTool(_ tool: DFIRTool) {
        // TODO: Open tool configuration
        print("Configure: \(tool.name)")
    }
    
    func openDocumentation(_ tool: DFIRTool) {
        guard let urlString = tool.documentationURL,
              let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
    
    func openGitHub(_ tool: DFIRTool) {
        guard let urlString = tool.githubURL,
              let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }
}

// MARK: - Default Tools

extension DFIRTool {
    static let defaultTools: [DFIRTool] = [
        // Memory Analysis
        DFIRTool(
            id: "volatility3",
            name: "Volatility 3",
            description: "Advanced memory forensics framework for analyzing RAM dumps",
            version: "2.5.0",
            category: .memory,
            status: .available,
            tags: ["memory", "forensics", "malware", "windows", "linux"],
            githubURL: "https://github.com/volatilityfoundation/volatility3",
            documentationURL: "https://volatility3.readthedocs.io/",
            lastUsed: nil
        ),
        DFIRTool(
            id: "rekall",
            name: "Rekall",
            description: "Memory analysis framework with live memory analysis support",
            version: "1.7.2",
            category: .memory,
            status: .available,
            tags: ["memory", "live-analysis", "forensics"],
            githubURL: "https://github.com/google/rekall",
            documentationURL: nil,
            lastUsed: nil
        ),
        
        // Malware Detection
        DFIRTool(
            id: "yara",
            name: "YARA",
            description: "Pattern matching tool for malware research and detection",
            version: "4.3.2",
            category: .malware,
            status: .installed,
            tags: ["malware", "detection", "signatures", "hunting"],
            githubURL: "https://github.com/VirusTotal/yara",
            documentationURL: "https://yara.readthedocs.io/",
            lastUsed: Date()
        ),
        DFIRTool(
            id: "clamav",
            name: "ClamAV",
            description: "Open-source antivirus engine for detecting trojans and malware",
            version: "1.2.1",
            category: .malware,
            status: .available,
            tags: ["antivirus", "scanning", "detection"],
            githubURL: "https://github.com/Cisco-Talos/clamav",
            documentationURL: "https://docs.clamav.net/",
            lastUsed: nil
        ),
        
        // Log Analysis
        DFIRTool(
            id: "chainsaw",
            name: "Chainsaw",
            description: "Rapidly search and hunt through Windows forensic artifacts",
            version: "2.8.0",
            category: .logs,
            status: .installed,
            tags: ["windows", "evtx", "hunting", "sigma"],
            githubURL: "https://github.com/WithSecureLabs/chainsaw",
            documentationURL: nil,
            lastUsed: Date().addingTimeInterval(-86400)
        ),
        DFIRTool(
            id: "hayabusa",
            name: "Hayabusa",
            description: "Windows event log fast forensics timeline generator",
            version: "2.10.0",
            category: .logs,
            status: .available,
            tags: ["windows", "evtx", "timeline", "sigma"],
            githubURL: "https://github.com/Yamato-Security/hayabusa",
            documentationURL: nil,
            lastUsed: nil
        ),
        DFIRTool(
            id: "evtx-dump",
            name: "EVTX Dump",
            description: "Fast EVTX parser with JSON output",
            version: "0.8.0",
            category: .logs,
            status: .available,
            tags: ["windows", "evtx", "parser"],
            githubURL: "https://github.com/omerbenamram/evtx",
            documentationURL: nil,
            lastUsed: nil
        ),
        
        // Timeline
        DFIRTool(
            id: "plaso",
            name: "Plaso (log2timeline)",
            description: "Super timeline generation tool for digital forensics",
            version: "20231002",
            category: .timeline,
            status: .available,
            tags: ["timeline", "forensics", "artifact-collection"],
            githubURL: "https://github.com/log2timeline/plaso",
            documentationURL: "https://plaso.readthedocs.io/",
            lastUsed: nil
        ),
        DFIRTool(
            id: "timesketch",
            name: "Timesketch",
            description: "Collaborative forensic timeline analysis",
            version: "2023.10",
            category: .timeline,
            status: .available,
            tags: ["timeline", "collaboration", "analysis"],
            githubURL: "https://github.com/google/timesketch",
            documentationURL: "https://timesketch.org/",
            lastUsed: nil
        ),
        
        // Filesystem
        DFIRTool(
            id: "sleuthkit",
            name: "The Sleuth Kit",
            description: "File system and media management forensic tools",
            version: "4.12.0",
            category: .filesystem,
            status: .installed,
            tags: ["filesystem", "disk", "forensics", "autopsy"],
            githubURL: "https://github.com/sleuthkit/sleuthkit",
            documentationURL: "https://wiki.sleuthkit.org/",
            lastUsed: Date().addingTimeInterval(-172800)
        ),
        DFIRTool(
            id: "mft-parser",
            name: "MFT Parser",
            description: "Parse and analyze NTFS Master File Table",
            version: "1.0.0",
            category: .filesystem,
            status: .available,
            tags: ["ntfs", "mft", "windows", "forensics"],
            githubURL: nil,
            documentationURL: nil,
            lastUsed: nil
        ),
        
        // Network
        DFIRTool(
            id: "zeek",
            name: "Zeek (Bro)",
            description: "Network security monitoring and analysis framework",
            version: "6.0.1",
            category: .network,
            status: .available,
            tags: ["network", "pcap", "monitoring", "ids"],
            githubURL: "https://github.com/zeek/zeek",
            documentationURL: "https://docs.zeek.org/",
            lastUsed: nil
        ),
        DFIRTool(
            id: "networkminer",
            name: "NetworkMiner",
            description: "Network forensic analyzer for extracting artifacts",
            version: "2.8.1",
            category: .network,
            status: .available,
            tags: ["network", "pcap", "extraction"],
            githubURL: nil,
            documentationURL: nil,
            lastUsed: nil
        ),
        
        // Registry
        DFIRTool(
            id: "regripper",
            name: "RegRipper",
            description: "Windows Registry data extraction and analysis",
            version: "3.0",
            category: .registry,
            status: .installed,
            tags: ["windows", "registry", "forensics"],
            githubURL: "https://github.com/keydet89/RegRipper3.0",
            documentationURL: nil,
            lastUsed: Date().addingTimeInterval(-259200)
        ),
        
        // Triage
        DFIRTool(
            id: "kape",
            name: "KAPE",
            description: "Kroll Artifact Parser and Extractor",
            version: "1.3.0.2",
            category: .triage,
            status: .available,
            tags: ["triage", "collection", "windows", "artifacts"],
            githubURL: nil,
            documentationURL: "https://www.kroll.com/en/insights/publications/cyber/kroll-artifact-parser-extractor-kape",
            lastUsed: nil
        ),
        DFIRTool(
            id: "velociraptor-tools",
            name: "Velociraptor Tools Pack",
            description: "Collection of Velociraptor-compatible analysis tools",
            version: "0.7.0",
            category: .triage,
            status: .installed,
            tags: ["velociraptor", "artifacts", "collection"],
            githubURL: nil,
            documentationURL: nil,
            lastUsed: Date()
        ),
    ]
}

// MARK: - Preview

#Preview {
    ToolsManagerView()
        .frame(width: 1000, height: 700)
}
