//
//  VFSBrowserView.swift
//  VelociraptorMacOS
//
//  Virtual File System browser for navigating client filesystems
//  Implements Gap 0x06: VFS Browser
//

import SwiftUI

// MARK: - VFS Browser View

/// Main VFS browser interface with split view navigation
struct VFSBrowserView: View {
    @StateObject private var viewModel = VFSBrowserViewModel()
    @EnvironmentObject private var apiClient: VelociraptorAPIClient
    
    var body: some View {
        HSplitView {
            // Left: Client and path selection
            VFSNavigationPane(viewModel: viewModel)
                .frame(minWidth: 250, maxWidth: 350)
            
            // Right: File listing and details
            VFSContentPane(viewModel: viewModel)
                .frame(minWidth: 500)
        }
        .navigationTitle("VFS Browser")
        .toolbar {
            VFSToolbar(viewModel: viewModel)
        }
        .accessibilityIdentifier("vfs_browser_view")
    }
}

// MARK: - VFS Navigation Pane

struct VFSNavigationPane: View {
    @ObservedObject var viewModel: VFSBrowserViewModel
    @EnvironmentObject private var apiClient: VelociraptorAPIClient
    
    var body: some View {
        VStack(spacing: 0) {
            // Client selector
            ClientSelectorSection(viewModel: viewModel)
            
            Divider()
            
            // Quick access paths
            QuickAccessSection(viewModel: viewModel)
            
            Divider()
            
            // Path breadcrumbs
            PathBreadcrumbs(viewModel: viewModel)
        }
        .background(Color(NSColor.controlBackgroundColor))
        .accessibilityIdentifier("vfs_navigation_pane")
    }
}

// MARK: - Client Selector Section

struct ClientSelectorSection: View {
    @ObservedObject var viewModel: VFSBrowserViewModel
    @EnvironmentObject private var apiClient: VelociraptorAPIClient
    @State private var searchText = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select Client")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 12)
            
            // Search field
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search clients...", text: $searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("vfs_client_search")
                
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding(.horizontal)
            
            // Client list
            List(viewModel.filteredClients(searchText: searchText), selection: $viewModel.selectedClientId) { client in
                ClientRowView(client: client)
                    .tag(client.clientId)
            }
            .listStyle(.inset)
            .frame(height: 200)
            .accessibilityIdentifier("vfs_client_list")
        }
        .onAppear {
            Task {
                await viewModel.loadClients()
            }
        }
    }
}

struct ClientRowView: View {
    let client: VelociraptorClient
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(client.isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(client.hostname)
                    .font(.system(.body, design: .monospaced))
                Text(client.os.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .accessibilityIdentifier("vfs_client_row_\(client.clientId)")
    }
}

// MARK: - Quick Access Section

struct QuickAccessSection: View {
    @ObservedObject var viewModel: VFSBrowserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Quick Access")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            ForEach(viewModel.quickAccessPaths, id: \.path) { item in
                Button(action: { viewModel.navigateTo(path: item.path) }) {
                    HStack {
                        Image(systemName: item.icon)
                            .frame(width: 20)
                        Text(item.name)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(viewModel.currentPath == item.path ? 
                        Color.accentColor.opacity(0.2) : Color.clear)
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("vfs_quick_\(item.name.lowercased())")
            }
        }
        .padding(.bottom, 8)
    }
}

// MARK: - Path Breadcrumbs

struct PathBreadcrumbs: View {
    @ObservedObject var viewModel: VFSBrowserViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Current Path")
                .font(.headline)
                .padding(.horizontal)
                .padding(.top, 8)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(viewModel.pathComponents, id: \.self) { component in
                        Button(action: { viewModel.navigateToComponent(component) }) {
                            Text(component.isEmpty ? "/" : component)
                                .font(.system(.caption, design: .monospaced))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color(NSColor.controlBackgroundColor))
                                .cornerRadius(4)
                        }
                        .buttonStyle(.plain)
                        
                        if component != viewModel.pathComponents.last {
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .frame(height: 30)
            
            // Full path display
            Text(viewModel.currentPath)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .accessibilityIdentifier("vfs_current_path")
        }
    }
}

// MARK: - VFS Content Pane

struct VFSContentPane: View {
    @ObservedObject var viewModel: VFSBrowserViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with path and actions
            VFSContentHeader(viewModel: viewModel)
            
            Divider()
            
            // Content area
            if viewModel.isLoading {
                ProgressView("Loading...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.selectedClientId == nil {
                VFSEmptyState(
                    icon: "desktopcomputer",
                    title: "Select a Client",
                    message: "Choose a client from the left panel to browse its filesystem"
                )
            } else if viewModel.entries.isEmpty {
                VFSEmptyState(
                    icon: "folder",
                    title: "Empty Directory",
                    message: "This directory contains no files or folders"
                )
            } else {
                // File listing
                VFSFileList(viewModel: viewModel)
            }
            
            Divider()
            
            // Status bar
            VFSStatusBar(viewModel: viewModel)
        }
        .accessibilityIdentifier("vfs_content_pane")
    }
}

// MARK: - VFS Content Header

struct VFSContentHeader: View {
    @ObservedObject var viewModel: VFSBrowserViewModel
    
    var body: some View {
        HStack {
            // Navigation buttons
            Button(action: { viewModel.goBack() }) {
                Image(systemName: "chevron.left")
            }
            .disabled(!viewModel.canGoBack)
            .accessibilityIdentifier("vfs_back_button")
            
            Button(action: { viewModel.goForward() }) {
                Image(systemName: "chevron.right")
            }
            .disabled(!viewModel.canGoForward)
            .accessibilityIdentifier("vfs_forward_button")
            
            Button(action: { viewModel.goUp() }) {
                Image(systemName: "chevron.up")
            }
            .disabled(!viewModel.canGoUp)
            .accessibilityIdentifier("vfs_up_button")
            
            Button(action: { Task { await viewModel.refresh() } }) {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityIdentifier("vfs_refresh_button")
            
            Spacer()
            
            // View mode toggle
            Picker("View", selection: $viewModel.viewMode) {
                Image(systemName: "list.bullet").tag(VFSViewMode.list)
                Image(systemName: "square.grid.2x2").tag(VFSViewMode.grid)
                Image(systemName: "tablecells").tag(VFSViewMode.columns)
            }
            .pickerStyle(.segmented)
            .frame(width: 100)
            .accessibilityIdentifier("vfs_view_mode_picker")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

// MARK: - VFS File List

struct VFSFileList: View {
    @ObservedObject var viewModel: VFSBrowserViewModel
    
    var body: some View {
        List(viewModel.entries, selection: $viewModel.selectedEntryId) { entry in
            VFSEntryRow(entry: entry, viewModel: viewModel)
                .tag(entry.id)
                .onTapGesture(count: 2) {
                    viewModel.openEntry(entry)
                }
        }
        .listStyle(.inset)
        .accessibilityIdentifier("vfs_file_list")
    }
}

struct VFSEntryRow: View {
    let entry: VFSEntry
    @ObservedObject var viewModel: VFSBrowserViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: entry.icon)
                .font(.title2)
                .foregroundColor(entry.iconColor)
                .frame(width: 24)
            
            // Name and details
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.name)
                    .font(.system(.body, design: .default))
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let size = entry.formattedSize {
                        Text(size)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let modified = entry.formattedModified {
                        Text(modified)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Permissions
            if let mode = entry.mode {
                Text(mode)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            // Actions
            Menu {
                Button("Download") {
                    Task { await viewModel.downloadEntry(entry) }
                }
                Button("Copy Path") {
                    viewModel.copyPath(entry)
                }
                Divider()
                Button("Collect as Evidence") {
                    viewModel.collectAsEvidence(entry)
                }
                Button("Run VQL Query") {
                    viewModel.queryEntry(entry)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
            }
            .menuStyle(.borderlessButton)
            .frame(width: 30)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("vfs_entry_\(entry.name)")
    }
}

// MARK: - VFS Empty State

struct VFSEmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text(title)
                .font(.headline)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("vfs_empty_state")
    }
}

// MARK: - VFS Status Bar

struct VFSStatusBar: View {
    @ObservedObject var viewModel: VFSBrowserViewModel
    
    var body: some View {
        HStack {
            Text("\(viewModel.entries.count) items")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if let selected = viewModel.selectedEntry {
                Text(selected.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
        .accessibilityIdentifier("vfs_status_bar")
    }
}

// MARK: - VFS Toolbar

struct VFSToolbar: ToolbarContent {
    @ObservedObject var viewModel: VFSBrowserViewModel
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { viewModel.showDownloadSheet = true }) {
                Label("Download", systemImage: "arrow.down.circle")
            }
            .disabled(viewModel.selectedEntry == nil)
            .accessibilityIdentifier("vfs_download_button")
            
            Button(action: { viewModel.showCollectSheet = true }) {
                Label("Collect", systemImage: "tray.and.arrow.down")
            }
            .disabled(viewModel.selectedEntry == nil)
            .accessibilityIdentifier("vfs_collect_button")
        }
    }
}

// MARK: - View Model

enum VFSViewMode: String, CaseIterable {
    case list, grid, columns
}

struct QuickAccessItem {
    let name: String
    let path: String
    let icon: String
}

@MainActor
class VFSBrowserViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var clients: [VelociraptorClient] = []
    @Published var selectedClientId: String? {
        didSet {
            if selectedClientId != nil {
                Task { await loadDirectory() }
            }
        }
    }
    
    @Published var currentPath: String = "/"
    @Published var entries: [VFSEntry] = []
    @Published var selectedEntryId: String?
    
    @Published var isLoading: Bool = false
    @Published var viewMode: VFSViewMode = .list
    
    @Published var showDownloadSheet: Bool = false
    @Published var showCollectSheet: Bool = false
    
    // Navigation history
    private var historyBack: [String] = []
    private var historyForward: [String] = []
    
    // MARK: - Computed Properties
    
    var selectedEntry: VFSEntry? {
        entries.first { $0.id == selectedEntryId }
    }
    
    var canGoBack: Bool { !historyBack.isEmpty }
    var canGoForward: Bool { !historyForward.isEmpty }
    var canGoUp: Bool { currentPath != "/" }
    
    var pathComponents: [String] {
        let components = currentPath.split(separator: "/").map(String.init)
        return [""] + components
    }
    
    var quickAccessPaths: [QuickAccessItem] {
        [
            QuickAccessItem(name: "Root", path: "/", icon: "folder"),
            QuickAccessItem(name: "Windows", path: "/file/C:", icon: "desktopcomputer"),
            QuickAccessItem(name: "Users", path: "/file/C:/Users", icon: "person.2"),
            QuickAccessItem(name: "Program Files", path: "/file/C:/Program Files", icon: "app"),
            QuickAccessItem(name: "Registry", path: "/registry", icon: "gearshape.2"),
            QuickAccessItem(name: "NTFS", path: "/ntfs", icon: "internaldrive"),
        ]
    }
    
    // MARK: - Methods
    
    func filteredClients(searchText: String) -> [VelociraptorClient] {
        guard !searchText.isEmpty else { return clients }
        return clients.filter { 
            $0.hostname.localizedCaseInsensitiveContains(searchText) ||
            $0.clientId.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func loadClients() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            clients = try await VelociraptorAPIClient.shared.listClients()
        } catch {
            print("Failed to load clients: \(error)")
        }
    }
    
    func loadDirectory() async {
        guard let clientId = selectedClientId else { return }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            entries = try await VelociraptorAPIClient.shared.listVFSDirectory(
                clientId: clientId,
                path: currentPath
            )
        } catch {
            print("Failed to load VFS: \(error)")
            entries = []
        }
    }
    
    func navigateTo(path: String) {
        historyBack.append(currentPath)
        historyForward.removeAll()
        currentPath = path
        Task { await loadDirectory() }
    }
    
    func navigateToComponent(_ component: String) {
        let index = pathComponents.firstIndex(of: component) ?? 0
        let newPath = "/" + pathComponents[1...index].joined(separator: "/")
        navigateTo(path: newPath.isEmpty ? "/" : newPath)
    }
    
    func goBack() {
        guard canGoBack else { return }
        historyForward.append(currentPath)
        currentPath = historyBack.removeLast()
        Task { await loadDirectory() }
    }
    
    func goForward() {
        guard canGoForward else { return }
        historyBack.append(currentPath)
        currentPath = historyForward.removeLast()
        Task { await loadDirectory() }
    }
    
    func goUp() {
        guard canGoUp else { return }
        let parentPath = (currentPath as NSString).deletingLastPathComponent
        navigateTo(path: parentPath.isEmpty ? "/" : parentPath)
    }
    
    func refresh() async {
        await loadDirectory()
    }
    
    func openEntry(_ entry: VFSEntry) {
        if entry.isDirectory {
            let newPath = currentPath.hasSuffix("/") ? 
                currentPath + entry.name : 
                currentPath + "/" + entry.name
            navigateTo(path: newPath)
        } else {
            // Open file preview or download
            Task { await downloadEntry(entry) }
        }
    }
    
    func downloadEntry(_ entry: VFSEntry) async {
        guard let clientId = selectedClientId else { return }
        
        // TODO: Implement file download
        print("Download: \(entry.name) from \(clientId)")
    }
    
    func copyPath(_ entry: VFSEntry) {
        let fullPath = currentPath.hasSuffix("/") ? 
            currentPath + entry.name : 
            currentPath + "/" + entry.name
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(fullPath, forType: .string)
    }
    
    func collectAsEvidence(_ entry: VFSEntry) {
        // TODO: Implement evidence collection
        print("Collect: \(entry.name)")
    }
    
    func queryEntry(_ entry: VFSEntry) {
        // TODO: Open VQL editor with query for this entry
        print("Query: \(entry.name)")
    }
}

// MARK: - VFS Entry Extensions

extension VFSEntry {
    var icon: String {
        if isDir == true {
            return "folder.fill"
        }
        
        // Determine icon based on extension
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "exe", "dll", "sys":
            return "gearshape.fill"
        case "txt", "log", "md":
            return "doc.text.fill"
        case "pdf":
            return "doc.fill"
        case "jpg", "jpeg", "png", "gif", "bmp":
            return "photo.fill"
        case "zip", "rar", "7z", "tar", "gz":
            return "doc.zipper"
        case "ps1", "py", "sh", "bat", "cmd":
            return "terminal.fill"
        case "evtx", "evt":
            return "list.bullet.rectangle.fill"
        case "reg":
            return "gearshape.2.fill"
        default:
            return "doc.fill"
        }
    }
    
    var iconColor: Color {
        if isDir == true {
            return .blue
        }
        
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "exe", "dll", "sys":
            return .orange
        case "ps1", "py", "sh", "bat", "cmd":
            return .green
        case "evtx", "evt", "log":
            return .purple
        default:
            return .gray
        }
    }
    
    var isDirectory: Bool { isDir ?? false }
    
    var formattedSize: String? {
        guard let size = size, isDir != true else { return nil }
        return ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var formattedModified: String? {
        guard let modified = mtime else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: modified)
    }
}

// MARK: - Preview

#Preview {
    VFSBrowserView()
        .environmentObject(VelociraptorAPIClient.shared)
        .frame(width: 1000, height: 700)
}
