//
//  DashboardView.swift
//  VelociraptorMacOS
//
//  Main dashboard with widgets for Velociraptor monitoring
//  Gap: 0x05 - Dashboard with Widgets
//
//  CDIF Pattern: SwiftUI dashboard with real-time updates
//

import SwiftUI
import Combine

// MARK: - Dashboard View

/// Main dashboard view with statistics, activity, and quick actions
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var apiClient: VelociraptorAPIClient
    @EnvironmentObject private var webSocket: WebSocketService
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Connection Status Banner
                if !apiClient.connectionState.isConnected {
                    ConnectionBanner(state: apiClient.connectionState)
                        .accessibilityIdentifier(AccessibilityID.connectionBanner)
                }
                
                // Quick Stats Bar
                QuickStatsBar(stats: viewModel.stats)
                    .accessibilityIdentifier(AccessibilityID.quickStatsBar)
                
                // Main Content Grid
                HStack(alignment: .top, spacing: 20) {
                    // Left Column - Status Cards
                    VStack(spacing: 16) {
                        StatusCardsGrid(viewModel: viewModel)
                            .accessibilityIdentifier(AccessibilityID.statusCards)
                    }
                    .frame(minWidth: 400)
                    
                    // Right Column - Activity Timeline
                    VStack(spacing: 16) {
                        ActivityTimeline(events: viewModel.recentActivity)
                            .accessibilityIdentifier(AccessibilityID.activityTimeline)
                        
                        QuickActionsPanel(viewModel: viewModel)
                            .accessibilityIdentifier(AccessibilityID.quickActions)
                    }
                    .frame(minWidth: 300, maxWidth: 400)
                }
                
                Spacer()
            }
            .padding()
        }
        .background(Color(NSColor.windowBackgroundColor))
        .navigationTitle("Dashboard")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { viewModel.refresh() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .accessibilityIdentifier(AccessibilityID.refreshButton)
                .disabled(viewModel.isLoading)
            }
            
            ToolbarItem(placement: .automatic) {
                ConnectionIndicator(state: apiClient.connectionState)
                    .accessibilityIdentifier(AccessibilityID.connectionIndicator)
            }
        }
        .onAppear {
            viewModel.startMonitoring()
        }
        .onDisappear {
            viewModel.stopMonitoring()
        }
    }
}

// MARK: - Accessibility Identifiers

extension DashboardView {
    enum AccessibilityID {
        static let connectionBanner = "dashboard.connection.banner"
        static let quickStatsBar = "dashboard.stats.bar"
        static let statusCards = "dashboard.status.cards"
        static let activityTimeline = "dashboard.activity.timeline"
        static let quickActions = "dashboard.quick.actions"
        static let refreshButton = "dashboard.refresh.button"
        static let connectionIndicator = "dashboard.connection.indicator"
    }
}

// MARK: - Connection Banner

/// Banner shown when not connected to server
struct ConnectionBanner: View {
    let state: ConnectionState
    
    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundColor(iconColor)
            
            Text(message)
                .font(.callout)
            
            Spacer()
            
            if case .error = state {
                Button("Retry") {
                    Task {
                        try? await VelociraptorAPIClient.shared.testConnection()
                    }
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("dashboard.connection.retry.button")
            }
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(8)
    }
    
    private var iconName: String {
        switch state {
        case .disconnected: return "wifi.slash"
        case .connecting: return "wifi"
        case .connected: return "wifi"
        case .error: return "exclamationmark.triangle"
        }
    }
    
    private var iconColor: Color {
        switch state {
        case .disconnected: return .gray
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }
    
    private var message: String {
        switch state {
        case .disconnected: return "Not connected to Velociraptor server"
        case .connecting: return "Connecting to server..."
        case .connected: return "Connected"
        case .error(let msg): return "Connection error: \(msg)"
        }
    }
    
    private var backgroundColor: Color {
        switch state {
        case .error: return Color.red.opacity(0.1)
        default: return Color.orange.opacity(0.1)
        }
    }
}

// MARK: - Connection Indicator

/// Small connection status indicator for toolbar
struct ConnectionIndicator: View {
    let state: ConnectionState
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(statusColor)
                .frame(width: 8, height: 8)
            
            Text(statusText)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var statusColor: Color {
        switch state {
        case .connected: return .green
        case .connecting: return .orange
        case .disconnected, .error: return .red
        }
    }
    
    private var statusText: String {
        switch state {
        case .connected: return "Connected"
        case .connecting: return "Connecting"
        case .disconnected: return "Disconnected"
        case .error: return "Error"
        }
    }
}

// MARK: - Quick Stats Bar

/// Horizontal bar showing key statistics
struct QuickStatsBar: View {
    let stats: DashboardStats
    
    var body: some View {
        HStack(spacing: 0) {
            StatItem(
                title: "Total Clients",
                value: "\(stats.totalClients)",
                icon: "desktopcomputer",
                color: .blue,
                accessibilityId: "dashboard.stat.clients"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "Online",
                value: "\(stats.onlineClients)",
                subtitle: String(format: "%.0f%%", stats.onlinePercentage),
                icon: "network",
                color: .green,
                accessibilityId: "dashboard.stat.online"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "Active Hunts",
                value: "\(stats.activeHunts)",
                icon: "scope",
                color: .orange,
                accessibilityId: "dashboard.stat.hunts"
            )
            
            Divider()
                .frame(height: 40)
            
            StatItem(
                title: "Artifacts",
                value: "\(stats.totalArtifacts)",
                icon: "doc.text",
                color: .purple,
                accessibilityId: "dashboard.stat.artifacts"
            )
            
            if stats.alertCount > 0 {
                Divider()
                    .frame(height: 40)
                
                StatItem(
                    title: "Alerts",
                    value: "\(stats.alertCount)",
                    icon: "exclamationmark.triangle.fill",
                    color: .red,
                    accessibilityId: "dashboard.stat.alerts"
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

/// Individual stat item
struct StatItem: View {
    let title: String
    let value: String
    var subtitle: String? = nil
    let icon: String
    let color: Color
    let accessibilityId: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2.bold())
                
                HStack(spacing: 4) {
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(color)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityIdentifier(accessibilityId)
    }
}

// MARK: - Status Cards Grid

/// Grid of status cards
struct StatusCardsGrid: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            DashboardStatusCard(
                title: "Velociraptor Server",
                status: viewModel.serverStatus,
                icon: "server.rack",
                details: viewModel.serverDetails,
                accessibilityId: "dashboard.card.server"
            )
            
            DashboardStatusCard(
                title: "DFIR Tools",
                status: viewModel.toolsStatus,
                icon: "wrench.and.screwdriver",
                details: viewModel.toolsDetails,
                accessibilityId: "dashboard.card.tools"
            )
            
            DashboardStatusCard(
                title: "Recent Collections",
                status: .normal,
                icon: "doc.on.doc",
                details: viewModel.collectionsDetails,
                accessibilityId: "dashboard.card.collections"
            )
            
            DashboardStatusCard(
                title: "System Health",
                status: viewModel.healthStatus,
                icon: "heart.fill",
                details: viewModel.healthDetails,
                accessibilityId: "dashboard.card.health"
            )
        }
    }
}

/// Individual status card for dashboard
struct DashboardStatusCard: View {
    let title: String
    let status: StatusLevel
    let icon: String
    let details: [StatusDetail]
    let accessibilityId: String
    
    enum StatusLevel {
        case normal
        case warning
        case error
        case unknown
        
        var color: Color {
            switch self {
            case .normal: return .green
            case .warning: return .orange
            case .error: return .red
            case .unknown: return .gray
            }
        }
        
        var iconName: String {
            switch self {
            case .normal: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .error: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
    }
    
    struct StatusDetail: Identifiable {
        let id = UUID()
        let label: String
        let value: String
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text(title)
                    .font(.headline)
                
                Spacer()
                
                Image(systemName: status.iconName)
                    .foregroundColor(status.color)
            }
            
            Divider()
            
            // Details
            ForEach(details) { detail in
                HStack {
                    Text(detail.label)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Text(detail.value)
                        .font(.caption.bold())
                }
            }
            
            if details.isEmpty {
                Text("No data available")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .italic()
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .accessibilityIdentifier(accessibilityId)
    }
}

// MARK: - Activity Timeline

/// Timeline of recent activity events
struct ActivityTimeline: View {
    let events: [ActivityEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Recent Activity")
                    .font(.headline)
                
                Spacer()
                
                Text("\(events.count) events")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Divider()
            
            if events.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text("No recent activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(events.prefix(50)) { event in
                            ActivityRow(event: event)
                                .accessibilityIdentifier("dashboard.activity.row.\(event.id)")
                        }
                    }
                }
                .frame(maxHeight: 300)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

/// Single activity row
struct ActivityRow: View {
    let event: ActivityEvent
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: event.type.iconName)
                .foregroundColor(iconColor)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(event.message)
                    .font(.callout)
                    .lineLimit(2)
                
                Text(event.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var iconColor: Color {
        switch event.type {
        case .huntCreated, .huntCompleted: return .orange
        case .clientConnected: return .green
        case .clientDisconnected: return .red
        case .collectionCompleted: return .blue
        case .alertTriggered: return .red
        case .userLogin: return .purple
        case .systemEvent: return .gray
        }
    }
}

// MARK: - Quick Actions Panel

/// Panel with quick action buttons
struct QuickActionsPanel: View {
    @ObservedObject var viewModel: DashboardViewModel
    
    let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Actions")
                .font(.headline)
            
            Divider()
            
            LazyVGrid(columns: columns, spacing: 12) {
                DashboardActionButton(
                    title: "New Hunt",
                    icon: "scope",
                    color: .orange,
                    action: viewModel.createNewHunt,
                    accessibilityId: "dashboard.action.newhunt"
                )
                
                DashboardActionButton(
                    title: "Add Client",
                    icon: "plus.circle",
                    color: .blue,
                    action: viewModel.addClient,
                    accessibilityId: "dashboard.action.addclient"
                )
                
                DashboardActionButton(
                    title: "Run VQL",
                    icon: "terminal",
                    color: .green,
                    action: viewModel.openVQLTerminal,
                    accessibilityId: "dashboard.action.vql"
                )
                
                DashboardActionButton(
                    title: "View Logs",
                    icon: "doc.text.magnifyingglass",
                    color: .purple,
                    action: viewModel.viewLogs,
                    accessibilityId: "dashboard.action.logs"
                )
                
                DashboardActionButton(
                    title: "Export Report",
                    icon: "square.and.arrow.up",
                    color: .indigo,
                    action: viewModel.exportReport,
                    accessibilityId: "dashboard.action.export"
                )
                
                DashboardActionButton(
                    title: "Settings",
                    icon: "gear",
                    color: .gray,
                    action: viewModel.openSettings,
                    accessibilityId: "dashboard.action.settings"
                )
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
    }
}

/// Quick action button for dashboard
struct DashboardActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    let accessibilityId: String
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(color.opacity(0.1))
            .cornerRadius(8)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityId)
    }
}

// MARK: - Dashboard ViewModel

/// ViewModel for dashboard data and actions
@MainActor
class DashboardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var stats = DashboardStats(
        totalClients: 0,
        onlineClients: 0,
        activeHunts: 0,
        completedHunts: 0,
        totalArtifacts: 0,
        alertCount: 0
    )
    
    @Published var isLoading = false
    @Published var recentActivity: [ActivityEvent] = []
    
    // Status card data
    @Published var serverStatus: DashboardStatusCard.StatusLevel = .unknown
    @Published var serverDetails: [DashboardStatusCard.StatusDetail] = []
    
    @Published var toolsStatus: DashboardStatusCard.StatusLevel = .unknown
    @Published var toolsDetails: [DashboardStatusCard.StatusDetail] = []
    
    @Published var collectionsDetails: [DashboardStatusCard.StatusDetail] = []
    
    @Published var healthStatus: DashboardStatusCard.StatusLevel = .unknown
    @Published var healthDetails: [DashboardStatusCard.StatusDetail] = []
    
    // MARK: - Private Properties
    
    private var refreshTask: Task<Void, Never>?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init() {
        setupWebSocketSubscriptions()
    }
    
    // MARK: - Lifecycle
    
    func startMonitoring() {
        refresh()
        
        // Refresh every 30 seconds
        refreshTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 30_000_000_000)
                if !Task.isCancelled {
                    refresh()
                }
            }
        }
    }
    
    func stopMonitoring() {
        refreshTask?.cancel()
    }
    
    // MARK: - Data Loading
    
    func refresh() {
        Task {
            await loadDashboardData()
        }
    }
    
    private func loadDashboardData() async {
        isLoading = true
        defer { isLoading = false }
        
        let api = VelociraptorAPIClient.shared
        
        // Load clients
        do {
            let clients = try await api.listClients(limit: 1000)
            let online = clients.filter { $0.isOnline }.count
            
            stats = DashboardStats(
                totalClients: clients.count,
                onlineClients: online,
                activeHunts: stats.activeHunts,
                completedHunts: stats.completedHunts,
                totalArtifacts: stats.totalArtifacts,
                alertCount: stats.alertCount
            )
        } catch {
            Logger.shared.error("Failed to load clients: \(error)", component: "Dashboard")
        }
        
        // Load hunts
        do {
            let hunts = try await api.listHunts()
            let activeCount = hunts.filter { $0.state == .running }.count
            let completedCount = hunts.filter { $0.state == .stopped || $0.state == .archived }.count
            
            stats = DashboardStats(
                totalClients: stats.totalClients,
                onlineClients: stats.onlineClients,
                activeHunts: activeCount,
                completedHunts: completedCount,
                totalArtifacts: stats.totalArtifacts,
                alertCount: stats.alertCount
            )
        } catch {
            Logger.shared.error("Failed to load hunts: \(error)", component: "Dashboard")
        }
        
        // Load artifacts
        do {
            let artifacts = try await api.listArtifacts()
            stats = DashboardStats(
                totalClients: stats.totalClients,
                onlineClients: stats.onlineClients,
                activeHunts: stats.activeHunts,
                completedHunts: stats.completedHunts,
                totalArtifacts: artifacts.count,
                alertCount: stats.alertCount
            )
        } catch {
            Logger.shared.error("Failed to load artifacts: \(error)", component: "Dashboard")
        }
        
        // Load server info
        do {
            let info = try await api.getServerInfo()
            serverStatus = .normal
            serverDetails = [
                DashboardStatusCard.StatusDetail(label: "Version", value: info.version ?? "Unknown"),
                DashboardStatusCard.StatusDetail(label: "Build", value: info.buildTime ?? "Unknown"),
                DashboardStatusCard.StatusDetail(label: "Clients", value: "\(info.clientCount ?? 0)")
            ]
        } catch {
            serverStatus = .error
            serverDetails = [
                DashboardStatusCard.StatusDetail(label: "Error", value: "Failed to connect")
            ]
        }
        
        // Update tools status (placeholder)
        toolsStatus = .normal
        toolsDetails = [
            DashboardStatusCard.StatusDetail(label: "Available", value: "25+"),
            DashboardStatusCard.StatusDetail(label: "Installed", value: "0")
        ]
        
        // Update collections
        collectionsDetails = [
            DashboardStatusCard.StatusDetail(label: "Active Hunts", value: "\(stats.activeHunts)"),
            DashboardStatusCard.StatusDetail(label: "Completed", value: "\(stats.completedHunts)")
        ]
        
        // Update health status
        do {
            let health = try await api.getHealth()
            healthStatus = health.isHealthy ? .normal : .warning
            healthDetails = [
                DashboardStatusCard.StatusDetail(label: "Status", value: health.status ?? "Unknown"),
                DashboardStatusCard.StatusDetail(label: "CPU", value: String(format: "%.1f%%", health.cpuPercent ?? 0)),
                DashboardStatusCard.StatusDetail(label: "Memory", value: String(format: "%.1f%%", health.memoryPercent ?? 0))
            ]
        } catch {
            healthStatus = .unknown
            healthDetails = []
        }
        
        // Load recent activity from WebSocket
        recentActivity = WebSocketService.shared.recentEvents
    }
    
    // MARK: - WebSocket Subscriptions
    
    private func setupWebSocketSubscriptions() {
        let ws = WebSocketService.shared
        
        // Subscribe to activity events
        ws.$recentEvents
            .receive(on: DispatchQueue.main)
            .assign(to: &$recentActivity)
        
        // Hunt progress updates
        ws.huntProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
        
        // Client status updates
        ws.clientStatusPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.refresh()
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Quick Actions
    
    func createNewHunt() {
        Logger.shared.info("Create new hunt action triggered", component: "Dashboard")
        // TODO: Navigate to hunt creation
    }
    
    func addClient() {
        Logger.shared.info("Add client action triggered", component: "Dashboard")
        // TODO: Navigate to client addition
    }
    
    func openVQLTerminal() {
        Logger.shared.info("Open VQL terminal action triggered", component: "Dashboard")
        // TODO: Navigate to VQL terminal
    }
    
    func viewLogs() {
        Logger.shared.info("View logs action triggered", component: "Dashboard")
        // TODO: Navigate to logs view
    }
    
    func exportReport() {
        Logger.shared.info("Export report action triggered", component: "Dashboard")
        // TODO: Implement export
    }
    
    func openSettings() {
        Logger.shared.info("Open settings action triggered", component: "Dashboard")
        // TODO: Navigate to settings
    }
}

// MARK: - Preview

#Preview {
    DashboardView()
        .environmentObject(VelociraptorAPIClient.shared)
        .environmentObject(WebSocketService.shared)
        .frame(width: 900, height: 700)
}
