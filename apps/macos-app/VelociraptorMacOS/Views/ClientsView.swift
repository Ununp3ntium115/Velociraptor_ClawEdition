//
//  ClientsView.swift
//  VelociraptorMacOS
//
//  Client management interface for Velociraptor endpoints
//  Gap: 0x02 - Client Management Interface
//
//  CDIF Pattern: SwiftUI list with detail split view
//

import SwiftUI
import Combine

// MARK: - ClientOS Type

/// Client operating system type for filtering
enum ClientOS: String, CaseIterable {
    case windows = "Windows"
    case linux = "Linux"
    case darwin = "macOS"
    case unknown = "Unknown"
    
    var displayName: String { rawValue }
    
    var iconName: String {
        switch self {
        case .windows: return "pc"
        case .linux: return "terminal"
        case .darwin: return "laptopcomputer"
        case .unknown: return "questionmark.circle"
        }
    }
}

// MARK: - Clients View

/// Main clients management view with list and detail panels
struct ClientsView: View {
    @StateObject private var viewModel = ClientsViewModel()
    @State private var selectedClient: VelociraptorClient?
    @State private var showingDeleteConfirmation = false
    @State private var clientToDelete: VelociraptorClient?
    
    var body: some View {
        HSplitView {
            // Left: Client List
            ClientListView(
                viewModel: viewModel,
                selectedClient: $selectedClient
            )
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            
            // Right: Client Detail or Empty State
            if let client = selectedClient {
                ClientDetailView(
                    client: client,
                    viewModel: viewModel,
                    onDelete: { clientToDelete = client; showingDeleteConfirmation = true }
                )
            } else {
                EmptyClientSelection()
            }
        }
        .navigationTitle("Clients")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { viewModel.refresh() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .accessibilityIdentifier("clients.refresh.button")
                .disabled(viewModel.isLoading)
            }
        }
        .alert("Delete Client", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                if let client = clientToDelete {
                    Task { await viewModel.deleteClient(client) }
                    if selectedClient?.clientId == client.clientId {
                        selectedClient = nil
                    }
                }
            }
        } message: {
            Text("Are you sure you want to delete this client? This action cannot be undone.")
        }
        .onAppear {
            viewModel.loadClients()
        }
    }
}

// MARK: - Client List View

/// Left panel showing filterable client list
struct ClientListView: View {
    @ObservedObject var viewModel: ClientsViewModel
    @Binding var selectedClient: VelociraptorClient?
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and Filter Bar
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    
                    TextField("Search clients...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                        .accessibilityIdentifier("clients.search.field")
                    
                    if !viewModel.searchText.isEmpty {
                        Button(action: { viewModel.searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityIdentifier("clients.search.clear.button")
                    }
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Filter Pills
                HStack(spacing: 8) {
                    FilterPill(
                        title: "All",
                        isSelected: viewModel.statusFilter == nil,
                        action: { viewModel.statusFilter = nil }
                    )
                    .accessibilityIdentifier("clients.filter.all")
                    
                    FilterPill(
                        title: "Online",
                        isSelected: viewModel.statusFilter == .online,
                        action: { viewModel.statusFilter = .online }
                    )
                    .accessibilityIdentifier("clients.filter.online")
                    
                    FilterPill(
                        title: "Offline",
                        isSelected: viewModel.statusFilter == .offline,
                        action: { viewModel.statusFilter = .offline }
                    )
                    .accessibilityIdentifier("clients.filter.offline")
                    
                    Spacer()
                    
                    Menu {
                        ForEach(ClientOS.allCases, id: \.self) { os in
                            Button(os.displayName) {
                                viewModel.osFilter = os
                            }
                        }
                        Divider()
                        Button("All OS") {
                            viewModel.osFilter = nil
                        }
                    } label: {
                        Label(viewModel.osFilter?.displayName ?? "All OS", systemImage: "desktopcomputer")
                            .font(.caption)
                    }
                    .accessibilityIdentifier("clients.filter.os.menu")
                }
            }
            .padding()
            
            Divider()
            
            // Client List
            if viewModel.isLoading && viewModel.clients.isEmpty {
                ProgressView("Loading clients...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredClients.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "desktopcomputer.trianglebadge.exclamationmark")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.clients.isEmpty ? "No clients connected" : "No clients match filters")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filteredClients, selection: $selectedClient) { client in
                    ClientRow(client: client)
                        .tag(client)
                        .accessibilityIdentifier("clients.row.\(client.clientId)")
                }
                .listStyle(.sidebar)
            }
            
            // Status Bar
            HStack {
                Text("\(viewModel.filteredClients.count) of \(viewModel.clients.count) clients")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.6)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
        }
    }
}

// MARK: - Filter Pill

/// Small filter button
struct FilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.2))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Client Row

/// Single row in client list
struct ClientRow: View {
    let client: VelociraptorClient
    
    var body: some View {
        HStack(spacing: 12) {
            // OS Icon
            Image(systemName: client.os.iconName)
                .font(.title2)
                .foregroundColor(.accentColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                // Hostname
                Text(client.hostname)
                    .font(.headline)
                    .lineLimit(1)
                
                // OS and Last Seen
                HStack(spacing: 8) {
                    Text(client.os.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text(client.lastSeenFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Online Status
            Circle()
                .fill(client.isOnline ? Color.green : Color.red)
                .frame(width: 8, height: 8)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty Client Selection

/// Shown when no client is selected
struct EmptyClientSelection: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "desktopcomputer")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Select a client")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Choose a client from the list to view details and perform actions")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Client Detail View

/// Right panel showing client details and actions
struct ClientDetailView: View {
    let client: VelociraptorClient
    @ObservedObject var viewModel: ClientsViewModel
    let onDelete: () -> Void
    
    @State private var selectedTab: ClientTab = .overview
    
    enum ClientTab: String, CaseIterable, Identifiable {
        case overview = "Overview"
        case collections = "Collections"
        case activity = "Activity"
        case labels = "Labels"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .overview: return "info.circle"
            case .collections: return "doc.on.doc"
            case .activity: return "clock"
            case .labels: return "tag"
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ClientDetailHeader(
                client: client,
                viewModel: viewModel,
                onDelete: onDelete
            )
            
            Divider()
            
            // Tab Bar
            HStack(spacing: 0) {
                ForEach(ClientTab.allCases) { tab in
                    Button(action: { selectedTab = tab }) {
                        Label(tab.rawValue, systemImage: tab.icon)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                    .accessibilityIdentifier("clients.detail.tab.\(tab.rawValue.lowercased())")
                }
                
                Spacer()
            }
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Tab Content
            ScrollView {
                switch selectedTab {
                case .overview:
                    ClientOverviewTab(client: client)
                case .collections:
                    ClientCollectionsTab(client: client, viewModel: viewModel)
                case .activity:
                    ClientActivityTab(client: client)
                case .labels:
                    ClientLabelsTab(client: client, viewModel: viewModel)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Client Detail Header

/// Header with client info and action buttons
struct ClientDetailHeader: View {
    let client: VelociraptorClient
    @ObservedObject var viewModel: ClientsViewModel
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            // Client Icon
            Image(systemName: client.os.iconName)
                .font(.largeTitle)
                .foregroundColor(.accentColor)
            
            // Client Info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(client.hostname)
                        .font(.title2.bold())
                    
                    Circle()
                        .fill(client.isOnline ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(client.isOnline ? "Online" : "Offline")
                        .font(.caption)
                        .foregroundColor(client.isOnline ? .green : .red)
                }
                
                Text(client.clientId)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .textSelection(.enabled)
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                Button(action: { Task { await viewModel.interrogateClient(client) } }) {
                    Label("Interrogate", systemImage: "magnifyingglass.circle")
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("clients.detail.interrogate.button")
                
                Button(action: { viewModel.showCollectionSheet(for: client) }) {
                    Label("Collect", systemImage: "square.and.arrow.down")
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("clients.detail.collect.button")
                
                Menu {
                    Button(action: { viewModel.showShell(for: client) }) {
                        Label("Open Shell", systemImage: "terminal")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: onDelete) {
                        Label("Delete Client", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityIdentifier("clients.detail.more.menu")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
}

// MARK: - Tab Views

/// Overview tab content
struct ClientOverviewTab: View {
    let client: VelociraptorClient
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // System Information
            GroupBox("System Information") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    GridRow {
                        Text("Operating System")
                            .foregroundColor(.secondary)
                        Text(client.os.displayName)
                    }
                    
                    if let osInfo = client.osInfo {
                        GridRow {
                            Text("Release")
                                .foregroundColor(.secondary)
                            Text(osInfo.release ?? "Unknown")
                        }
                        
                        GridRow {
                            Text("Architecture")
                                .foregroundColor(.secondary)
                            Text(osInfo.machine ?? "Unknown")
                        }
                        
                        if let fqdn = osInfo.fqdn {
                            GridRow {
                                Text("FQDN")
                                    .foregroundColor(.secondary)
                                Text(fqdn)
                                    .textSelection(.enabled)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            
            // Agent Information
            if let agentInfo = client.agentInformation {
                GroupBox("Agent Information") {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                        GridRow {
                            Text("Agent Version")
                                .foregroundColor(.secondary)
                            Text(agentInfo.version ?? "Unknown")
                        }
                        
                        if let buildTime = agentInfo.buildTime {
                            GridRow {
                                Text("Build Time")
                                    .foregroundColor(.secondary)
                                Text(buildTime)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)
                }
            }
            
            // Timestamps
            GroupBox("Timeline") {
                Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                    if let firstSeen = client.firstSeenAt {
                        GridRow {
                            Text("First Seen")
                                .foregroundColor(.secondary)
                            Text(firstSeen, style: .date)
                        }
                    }
                    
                    if let lastSeen = client.lastSeenAt {
                        GridRow {
                            Text("Last Seen")
                                .foregroundColor(.secondary)
                            Text(lastSeen, style: .relative)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }
            
            Spacer()
        }
        .padding()
        .accessibilityIdentifier("clients.detail.overview")
    }
}

/// Collections tab content
struct ClientCollectionsTab: View {
    let client: VelociraptorClient
    @ObservedObject var viewModel: ClientsViewModel
    
    var body: some View {
        VStack {
            if viewModel.clientFlows.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "doc.on.doc")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No collections")
                        .foregroundColor(.secondary)
                    
                    Button("Start Collection") {
                        viewModel.showCollectionSheet(for: client)
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("clients.collections.start.button")
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.clientFlows) { flow in
                    FlowRow(flow: flow)
                        .accessibilityIdentifier("clients.collections.flow.\(flow.flowId)")
                }
            }
        }
        .accessibilityIdentifier("clients.detail.collections")
        .onAppear {
            Task { await viewModel.loadFlows(for: client) }
        }
    }
}

/// Flow row
struct FlowRow: View {
    let flow: Flow
    
    var body: some View {
        HStack {
            Image(systemName: flow.state == .running ? "arrow.triangle.2.circlepath" : "checkmark.circle")
                .foregroundColor(flow.state == .running ? .orange : .green)
            
            VStack(alignment: .leading) {
                Text(flow.artifacts?.joined(separator: ", ") ?? "No artifacts")
                    .font(.headline)
                    .lineLimit(1)
                
                if let createTime = flow.createTime {
                    Text(createTime, style: .relative)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Text((flow.state ?? .unset).displayName)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(4)
        }
    }
}

/// Activity tab content
struct ClientActivityTab: View {
    let client: VelociraptorClient
    
    var body: some View {
        VStack {
            Text("Client activity will be shown here")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("clients.detail.activity")
    }
}

/// Labels tab content
struct ClientLabelsTab: View {
    let client: VelociraptorClient
    @ObservedObject var viewModel: ClientsViewModel
    @State private var newLabel = ""
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Add Label
            HStack {
                TextField("Add label...", text: $newLabel)
                    .textFieldStyle(.roundedBorder)
                    .accessibilityIdentifier("clients.labels.input")
                
                Button("Add") {
                    guard !newLabel.isEmpty else { return }
                    Task {
                        await viewModel.addLabel(to: client, label: newLabel)
                        newLabel = ""
                    }
                }
                .disabled(newLabel.isEmpty)
                .accessibilityIdentifier("clients.labels.add.button")
            }
            
            // Current Labels
            if client.labels?.isEmpty ?? true {
                Text("No labels")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                FlowLayout(spacing: 8) {
                    ForEach(client.labels ?? [], id: \.self) { label in
                        LabelPill(
                            label: label,
                            onRemove: {
                                Task { await viewModel.removeLabel(from: client, label: label) }
                            }
                        )
                        .accessibilityIdentifier("clients.labels.pill.\(label)")
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .accessibilityIdentifier("clients.detail.labels")
    }
}

/// Label pill with remove button
struct LabelPill: View {
    let label: String
    let onRemove: () -> Void
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.callout)
            
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(Color.accentColor.opacity(0.2))
        .cornerRadius(12)
    }
}

/// Simple flow layout for labels
struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = layout(proposal: proposal, subviews: subviews)
        return result.size
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = layout(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }
    
    private func layout(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, positions: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var lineHeight: CGFloat = 0
        var totalHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > maxWidth && currentX > 0 {
                currentX = 0
                currentY += lineHeight + spacing
                lineHeight = 0
            }
            
            positions.append(CGPoint(x: currentX, y: currentY))
            lineHeight = max(lineHeight, size.height)
            currentX += size.width + spacing
            totalHeight = currentY + lineHeight
        }
        
        return (CGSize(width: maxWidth, height: totalHeight), positions)
    }
}

// MARK: - Clients ViewModel

/// ViewModel for clients management
@MainActor
class ClientsViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var clients: [VelociraptorClient] = []
    @Published var filteredClients: [VelociraptorClient] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    @Published var searchText = "" {
        didSet { applyFilters() }
    }
    
    @Published var statusFilter: StatusFilter? = nil {
        didSet { applyFilters() }
    }
    
    @Published var osFilter: ClientOS? = nil {
        didSet { applyFilters() }
    }
    
    @Published var clientFlows: [Flow] = []
    
    // MARK: - Types
    
    enum StatusFilter {
        case online
        case offline
    }
    
    // MARK: - Data Loading
    
    func loadClients() {
        Task {
            await fetchClients()
        }
    }
    
    func refresh() {
        loadClients()
    }
    
    private func fetchClients() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            clients = try await VelociraptorAPIClient.shared.listClients(limit: 1000)
            applyFilters()
            Logger.shared.info("Loaded \(clients.count) clients", component: "Clients")
        } catch {
            self.error = error
            Logger.shared.error("Failed to load clients: \(error)", component: "Clients")
        }
    }
    
    // MARK: - Filtering
    
    private func applyFilters() {
        var result = clients
        
        // Search filter
        if !searchText.isEmpty {
            let query = searchText.lowercased()
            result = result.filter { client in
                client.hostname.lowercased().contains(query) ||
                client.clientId.lowercased().contains(query) ||
                (client.labels ?? []).contains { $0.lowercased().contains(query) }
            }
        }
        
        // Status filter
        if let statusFilter = statusFilter {
            switch statusFilter {
            case .online:
                result = result.filter { $0.isOnline }
            case .offline:
                result = result.filter { !$0.isOnline }
            }
        }
        
        // OS filter
        if let osFilter = osFilter {
            // Compare rawValue of client OS type with filter
            result = result.filter { $0.os.rawValue == osFilter.rawValue }
        }
        
        filteredClients = result
    }
    
    // MARK: - Client Operations
    
    func interrogateClient(_ client: VelociraptorClient) async {
        do {
            let flow = try await VelociraptorAPIClient.shared.interrogateClient(id: client.clientId)
            Logger.shared.success("Interrogation started: \(flow.flowId)", component: "Clients")
        } catch {
            Logger.shared.error("Interrogation failed: \(error)", component: "Clients")
        }
    }
    
    func deleteClient(_ client: VelociraptorClient) async {
        do {
            try await VelociraptorAPIClient.shared.deleteClient(id: client.clientId)
            clients.removeAll { $0.clientId == client.clientId }
            applyFilters()
            Logger.shared.success("Client deleted: \(client.clientId)", component: "Clients")
        } catch {
            Logger.shared.error("Delete failed: \(error)", component: "Clients")
        }
    }
    
    func showCollectionSheet(for client: VelociraptorClient) {
        // TODO: Present collection sheet
        Logger.shared.info("Show collection sheet for: \(client.clientId)", component: "Clients")
    }
    
    func showShell(for client: VelociraptorClient) {
        // TODO: Open VQL shell for client
        Logger.shared.info("Open shell for: \(client.clientId)", component: "Clients")
    }
    
    // MARK: - Flows
    
    func loadFlows(for client: VelociraptorClient) async {
        do {
            clientFlows = try await VelociraptorAPIClient.shared.getClientFlows(clientId: client.clientId)
        } catch {
            Logger.shared.error("Failed to load flows: \(error)", component: "Clients")
        }
    }
    
    // MARK: - Labels
    
    func addLabel(to client: VelociraptorClient, label: String) async {
        do {
            try await VelociraptorAPIClient.shared.addLabel(clientId: client.clientId, label: label)
            await fetchClients()
            Logger.shared.success("Label added: \(label)", component: "Clients")
        } catch {
            Logger.shared.error("Failed to add label: \(error)", component: "Clients")
        }
    }
    
    func removeLabel(from client: VelociraptorClient, label: String) async {
        do {
            try await VelociraptorAPIClient.shared.removeLabel(clientId: client.clientId, label: label)
            await fetchClients()
            Logger.shared.success("Label removed: \(label)", component: "Clients")
        } catch {
            Logger.shared.error("Failed to remove label: \(error)", component: "Clients")
        }
    }
}

// MARK: - Preview

#Preview {
    ClientsView()
        .frame(width: 1000, height: 700)
}
