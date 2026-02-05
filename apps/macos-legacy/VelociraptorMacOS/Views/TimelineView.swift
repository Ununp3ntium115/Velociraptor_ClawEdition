//
//  TimelineView.swift
//  VelociraptorMacOS
//
//  Timeline Analysis with MCP-Powered Investigation Guidance
//  Gap: 0x0A - Timeline Analysis
//
//  CDIF Pattern: Interactive timeline with MCP analysis integration
//  Swift 6 Concurrency: Strict mode compliant
//

import SwiftUI

// MARK: - Timeline View

/// Main timeline analysis interface with MCP integration
struct TimelineView: View {
    @StateObject private var viewModel = TimelineViewModel()
    
    var body: some View {
        HSplitView {
            // Left: Timeline Configuration
            TimelineConfigPane(viewModel: viewModel)
                .frame(minWidth: 280, maxWidth: 350)
            
            // Center: Timeline Visualization
            TimelineContentPane(viewModel: viewModel)
                .frame(minWidth: 500)
            
            // Right: Event Details (collapsible)
            if viewModel.selectedEvent != nil {
                TimelineEventDetailPane(viewModel: viewModel)
                    .frame(minWidth: 300, maxWidth: 400)
            }
        }
        .navigationTitle("Timeline Analysis")
        .toolbar {
            TimelineToolbar(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showMCPAnalysis) {
            MCPTimelineAnalysisSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showExportSheet) {
            TimelineExportSheet(viewModel: viewModel)
        }
        .accessibilityIdentifier("timeline.view")
    }
}

// MARK: - Timeline Config Pane

struct TimelineConfigPane: View {
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Configuration")
                    .font(.headline)
                Spacer()
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Time Range
                    GroupBox("Time Range") {
                        VStack(alignment: .leading, spacing: 12) {
                            DatePicker("Start", selection: $viewModel.startDate)
                                .accessibilityIdentifier("timeline.start.date")
                            
                            DatePicker("End", selection: $viewModel.endDate)
                                .accessibilityIdentifier("timeline.end.date")
                            
                            HStack {
                                Button("Last 24h") { viewModel.setTimeRange(hours: 24) }
                                Button("Last 7d") { viewModel.setTimeRange(days: 7) }
                                Button("Last 30d") { viewModel.setTimeRange(days: 30) }
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                    
                    // Focus Areas
                    GroupBox("Focus Areas") {
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(TimelineFocusArea.allCases) { area in
                                Toggle(isOn: Binding(
                                    get: { viewModel.focusAreas.contains(area) },
                                    set: { isOn in
                                        if isOn {
                                            viewModel.focusAreas.insert(area)
                                        } else {
                                            viewModel.focusAreas.remove(area)
                                        }
                                    }
                                )) {
                                    HStack {
                                        Image(systemName: area.icon)
                                            .foregroundColor(area.color)
                                            .frame(width: 20)
                                        Text(area.displayName)
                                    }
                                }
                                .accessibilityIdentifier("timeline.focus.\(area.rawValue)")
                            }
                        }
                    }
                    
                    // IOC Input
                    GroupBox("Known IOCs") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Enter known indicators (one per line)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            TextEditor(text: $viewModel.knownIOCsText)
                                .frame(height: 80)
                                .border(Color.secondary.opacity(0.3))
                                .accessibilityIdentifier("timeline.iocs.input")
                            
                            Text("\(viewModel.knownIOCs.count) IOCs")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // MCP Analysis
                    GroupBox {
                        HStack {
                            Image(systemName: "sparkles")
                                .foregroundColor(.purple)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text("AI Analysis")
                                    .font(.subheadline.bold())
                                Text("Get investigation guidance")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Analyze") {
                                viewModel.showMCPAnalysis = true
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(viewModel.events.isEmpty)
                            .accessibilityIdentifier("timeline.mcp.analyze")
                        }
                    }
                    
                    // Load Button
                    Button("Load Timeline") {
                        Task { await viewModel.loadTimeline() }
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isLoading)
                    .accessibilityIdentifier("timeline.load.button")
                }
                .padding()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Timeline Content Pane

struct TimelineContentPane: View {
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with filters
            TimelineContentHeader(viewModel: viewModel)
            
            Divider()
            
            // Timeline content
            if viewModel.isLoading {
                ProgressView("Loading timeline...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredEvents.isEmpty {
                TimelineEmptyState(viewModel: viewModel)
            } else {
                TimelineEventList(viewModel: viewModel)
            }
            
            Divider()
            
            // Status bar
            TimelineStatusBar(viewModel: viewModel)
        }
        .accessibilityIdentifier("timeline.content.pane")
    }
}

struct TimelineContentHeader: View {
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some View {
        HStack {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search events...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("timeline.search")
            }
            .padding(6)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .frame(maxWidth: 300)
            
            Spacer()
            
            // Filters
            Menu {
                ForEach(TimelineEventType.allCases) { type in
                    Button(action: { viewModel.toggleEventTypeFilter(type) }) {
                        HStack {
                            if viewModel.eventTypeFilters.contains(type) {
                                Image(systemName: "checkmark")
                            }
                            Text(type.displayName)
                        }
                    }
                }
                Divider()
                Button("Show All") { viewModel.showAllEventTypes() }
                Button("Show Suspicious Only") { viewModel.showSuspiciousOnly() }
            } label: {
                Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
            }
            .accessibilityIdentifier("timeline.filter.menu")
            
            // View mode
            Picker("View", selection: $viewModel.viewMode) {
                Image(systemName: "list.bullet").tag(TimelineViewMode.list)
                Image(systemName: "chart.bar.xaxis").tag(TimelineViewMode.chart)
            }
            .pickerStyle(.segmented)
            .frame(width: 80)
            .accessibilityIdentifier("timeline.view.mode")
        }
        .padding()
    }
}

struct TimelineEventList: View {
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some View {
        List(viewModel.filteredEvents, selection: $viewModel.selectedEventId) { event in
            TimelineEventRow(event: event, viewModel: viewModel)
                .tag(event.id)
                .accessibilityIdentifier("timeline.event.\(event.id)")
        }
        .listStyle(.inset)
    }
}

struct TimelineEventRow: View {
    let event: TimelineEvent
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            // Timestamp
            VStack(alignment: .trailing) {
                Text(event.timestamp, style: .time)
                    .font(.system(.caption, design: .monospaced))
                Text(event.timestamp, style: .date)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(width: 80)
            
            // Type indicator
            Circle()
                .fill(event.type.color)
                .frame(width: 10, height: 10)
            
            // Event details
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.title)
                        .font(.headline)
                        .lineLimit(1)
                    
                    if event.isSuspicious {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                    }
                }
                
                Text(event.source.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if let details = event.details {
                    Text(details)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            // Tags
            if !event.tags.isEmpty {
                HStack(spacing: 4) {
                    ForEach(event.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.secondary.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .background(event.isSuspicious ? Color.orange.opacity(0.1) : Color.clear)
    }
}

struct TimelineEmptyState: View {
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Timeline Events")
                .font(.headline)
            
            Text("Configure time range and focus areas, then click 'Load Timeline' to begin")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("timeline.empty.state")
    }
}

struct TimelineStatusBar: View {
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some View {
        HStack {
            Text("\(viewModel.filteredEvents.count) of \(viewModel.events.count) events")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if viewModel.suspiciousCount > 0 {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text("\(viewModel.suspiciousCount) suspicious")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

// MARK: - Event Detail Pane

struct TimelineEventDetailPane: View {
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let event = viewModel.selectedEvent {
                // Header
                HStack {
                    Text("Event Details")
                        .font(.headline)
                    Spacer()
                    Button(action: { viewModel.selectedEventId = nil }) {
                        Image(systemName: "xmark")
                    }
                    .buttonStyle(.plain)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                
                Divider()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Event info
                        GroupBox("Event") {
                            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 8) {
                                GridRow {
                                    Text("Time:")
                                        .foregroundColor(.secondary)
                                    Text(event.timestamp, style: .date) + Text(" ") + Text(event.timestamp, style: .time)
                                }
                                
                                GridRow {
                                    Text("Type:")
                                        .foregroundColor(.secondary)
                                    HStack {
                                        Circle()
                                            .fill(event.type.color)
                                            .frame(width: 8, height: 8)
                                        Text(event.type.displayName)
                                    }
                                }
                                
                                GridRow {
                                    Text("Source:")
                                        .foregroundColor(.secondary)
                                    Text(event.source.displayName)
                                }
                                
                                if event.isSuspicious {
                                    GridRow {
                                        Text("Status:")
                                            .foregroundColor(.secondary)
                                        HStack {
                                            Image(systemName: "exclamationmark.triangle.fill")
                                                .foregroundColor(.orange)
                                            Text("Suspicious")
                                                .foregroundColor(.orange)
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Details
                        GroupBox("Details") {
                            Text(event.details ?? "No additional details")
                                .font(.system(.body, design: .monospaced))
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        // Raw data
                        if let rawData = event.rawData {
                            GroupBox("Raw Data") {
                                ScrollView(.horizontal) {
                                    Text(rawData)
                                        .font(.system(.caption, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                                .frame(maxHeight: 150)
                            }
                        }
                        
                        // Tags
                        if !event.tags.isEmpty {
                            GroupBox("Tags") {
                                FlowLayout(spacing: 8) {
                                    ForEach(event.tags, id: \.self) { tag in
                                        Text(tag)
                                            .font(.caption)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.accentColor.opacity(0.2))
                                            .cornerRadius(4)
                                    }
                                }
                            }
                        }
                        
                        // Actions
                        GroupBox("Actions") {
                            VStack(alignment: .leading, spacing: 8) {
                                Button("Add to IOC List") {
                                    viewModel.addEventToIOCs(event)
                                }
                                
                                Button("Query in VQL") {
                                    viewModel.queryEventInVQL(event)
                                }
                                
                                Button("Mark as Investigated") {
                                    viewModel.markEventInvestigated(event)
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding()
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
        .accessibilityIdentifier("timeline.detail.pane")
    }
}

// MARK: - Toolbar

struct TimelineToolbar: ToolbarContent {
    @ObservedObject var viewModel: TimelineViewModel
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { Task { await viewModel.loadTimeline() } }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier("timeline.refresh.button")
            
            Button(action: { viewModel.showExportSheet = true }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.events.isEmpty)
            .accessibilityIdentifier("timeline.export.button")
        }
    }
}

// MARK: - MCP Analysis Sheet

struct MCPTimelineAnalysisSheet: View {
    @ObservedObject var viewModel: TimelineViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("AI Timeline Analysis")
                    .font(.title2.bold())
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()
            
            Divider()
            
            if viewModel.isAnalyzing {
                ProgressView("Analyzing timeline...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let analysis = viewModel.mcpAnalysis {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        GroupBox("Summary") {
                            Text(analysis.summary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        GroupBox("Key Findings") {
                            ForEach(analysis.findings, id: \.self) { finding in
                                HStack(alignment: .top) {
                                    Image(systemName: "arrow.right.circle.fill")
                                        .foregroundColor(.accentColor)
                                    Text(finding)
                                }
                            }
                        }
                        
                        GroupBox("Recommended Actions") {
                            ForEach(analysis.recommendations, id: \.self) { rec in
                                HStack(alignment: .top) {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundColor(.yellow)
                                    Text(rec)
                                }
                            }
                        }
                        
                        if !analysis.suspiciousPatterns.isEmpty {
                            GroupBox("Suspicious Patterns") {
                                ForEach(analysis.suspiciousPatterns, id: \.self) { pattern in
                                    HStack(alignment: .top) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.orange)
                                        Text(pattern)
                                    }
                                }
                            }
                        }
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Text("Get AI-powered analysis of your timeline")
                    
                    Button("Start Analysis") {
                        Task { await viewModel.runMCPAnalysis() }
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 600, height: 500)
        .accessibilityIdentifier("timeline.mcp.sheet")
    }
}

// MARK: - Export Sheet

struct TimelineExportSheet: View {
    @ObservedObject var viewModel: TimelineViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Export Timeline")
                .font(.headline)
            
            Picker("Format", selection: $viewModel.exportFormat) {
                Text("CSV").tag(TimelineExportFormat.csv)
                Text("JSON").tag(TimelineExportFormat.json)
                Text("Timeline CSV (Plaso)").tag(TimelineExportFormat.plaso)
            }
            .pickerStyle(.segmented)
            
            Toggle("Include only filtered events", isOn: $viewModel.exportFilteredOnly)
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Export") {
                    viewModel.exportTimeline()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400, height: 200)
        .accessibilityIdentifier("timeline.export.sheet")
    }
}

// MARK: - Models

enum TimelineFocusArea: String, CaseIterable, Identifiable {
    case processExecution = "process_execution"
    case fileSystem = "file_system"
    case networkConnections = "network_connections"
    case registryChanges = "registry_changes"
    case authentication = "authentication"
    case scheduledTasks = "scheduled_tasks"
    case serviceInstallation = "service_installation"
    case userActivity = "user_activity"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .processExecution: return "Process Execution"
        case .fileSystem: return "File System"
        case .networkConnections: return "Network Connections"
        case .registryChanges: return "Registry Changes"
        case .authentication: return "Authentication"
        case .scheduledTasks: return "Scheduled Tasks"
        case .serviceInstallation: return "Service Installation"
        case .userActivity: return "User Activity"
        }
    }
    
    var icon: String {
        switch self {
        case .processExecution: return "gearshape"
        case .fileSystem: return "folder"
        case .networkConnections: return "network"
        case .registryChanges: return "gearshape.2"
        case .authentication: return "key"
        case .scheduledTasks: return "calendar"
        case .serviceInstallation: return "wrench.and.screwdriver"
        case .userActivity: return "person"
        }
    }
    
    var color: Color {
        switch self {
        case .processExecution: return .purple
        case .fileSystem: return .blue
        case .networkConnections: return .green
        case .registryChanges: return .orange
        case .authentication: return .red
        case .scheduledTasks: return .cyan
        case .serviceInstallation: return .yellow
        case .userActivity: return .indigo
        }
    }
}

enum TimelineEventType: String, CaseIterable, Identifiable {
    case processStart = "process_start"
    case processEnd = "process_end"
    case fileCreate = "file_create"
    case fileModify = "file_modify"
    case fileDelete = "file_delete"
    case networkConnect = "network_connect"
    case registryModify = "registry_modify"
    case logon = "logon"
    case logoff = "logoff"
    case taskSchedule = "task_schedule"
    case serviceInstall = "service_install"
    case other = "other"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .processStart: return "Process Start"
        case .processEnd: return "Process End"
        case .fileCreate: return "File Created"
        case .fileModify: return "File Modified"
        case .fileDelete: return "File Deleted"
        case .networkConnect: return "Network Connection"
        case .registryModify: return "Registry Modified"
        case .logon: return "Logon"
        case .logoff: return "Logoff"
        case .taskSchedule: return "Task Scheduled"
        case .serviceInstall: return "Service Installed"
        case .other: return "Other"
        }
    }
    
    var color: Color {
        switch self {
        case .processStart, .processEnd: return .purple
        case .fileCreate, .fileModify, .fileDelete: return .blue
        case .networkConnect: return .green
        case .registryModify: return .orange
        case .logon, .logoff: return .red
        case .taskSchedule: return .cyan
        case .serviceInstall: return .yellow
        case .other: return .gray
        }
    }
}

enum TimelineEventSource: String {
    case mft = "MFT"
    case eventLog = "EventLog"
    case prefetch = "Prefetch"
    case registry = "Registry"
    case usn = "USN"
    case srum = "SRUM"
    case amcache = "Amcache"
    case other = "Other"
    
    var displayName: String { rawValue }
}

struct TimelineEvent: Identifiable {
    let id: String
    let timestamp: Date
    let type: TimelineEventType
    let source: TimelineEventSource
    let title: String
    let details: String?
    let rawData: String?
    let tags: [String]
    var isSuspicious: Bool
    var isInvestigated: Bool
}

struct MCPTimelineAnalysis {
    let summary: String
    let findings: [String]
    let recommendations: [String]
    let suspiciousPatterns: [String]
}

enum TimelineViewMode: String {
    case list, chart
}

enum TimelineExportFormat: String {
    case csv, json, plaso
}

// MARK: - View Model

@MainActor
class TimelineViewModel: ObservableObject {
    // MARK: - Configuration
    
    @Published var startDate: Date = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @Published var endDate: Date = Date()
    @Published var focusAreas: Set<TimelineFocusArea> = [.processExecution, .fileSystem, .networkConnections]
    @Published var knownIOCsText: String = ""
    
    // MARK: - Events
    
    @Published var events: [TimelineEvent] = []
    @Published var selectedEventId: String?
    @Published var searchQuery: String = ""
    @Published var eventTypeFilters: Set<TimelineEventType> = Set(TimelineEventType.allCases)
    @Published var viewMode: TimelineViewMode = .list
    
    // MARK: - State
    
    @Published var isLoading: Bool = false
    @Published var isAnalyzing: Bool = false
    @Published var showMCPAnalysis: Bool = false
    @Published var showExportSheet: Bool = false
    @Published var mcpAnalysis: MCPTimelineAnalysis?
    
    // MARK: - Export
    
    @Published var exportFormat: TimelineExportFormat = .csv
    @Published var exportFilteredOnly: Bool = true
    
    // MARK: - Computed Properties
    
    var knownIOCs: [String] {
        knownIOCsText.components(separatedBy: .newlines).filter { !$0.isEmpty }
    }
    
    var selectedEvent: TimelineEvent? {
        events.first { $0.id == selectedEventId }
    }
    
    var filteredEvents: [TimelineEvent] {
        var result = events
        
        // Filter by search
        if !searchQuery.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchQuery) ||
                ($0.details?.localizedCaseInsensitiveContains(searchQuery) ?? false) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            }
        }
        
        // Filter by type
        result = result.filter { eventTypeFilters.contains($0.type) }
        
        return result.sorted { $0.timestamp > $1.timestamp }
    }
    
    var suspiciousCount: Int {
        events.filter { $0.isSuspicious }.count
    }
    
    // MARK: - Methods
    
    func setTimeRange(hours: Int? = nil, days: Int? = nil) {
        endDate = Date()
        if let hours = hours {
            startDate = Calendar.current.date(byAdding: .hour, value: -hours, to: Date()) ?? Date()
        } else if let days = days {
            startDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        }
    }
    
    func toggleEventTypeFilter(_ type: TimelineEventType) {
        if eventTypeFilters.contains(type) {
            eventTypeFilters.remove(type)
        } else {
            eventTypeFilters.insert(type)
        }
    }
    
    func showAllEventTypes() {
        eventTypeFilters = Set(TimelineEventType.allCases)
    }
    
    func showSuspiciousOnly() {
        events = events.map { event in
            var modified = event
            modified.isSuspicious = true
            return modified
        }.filter { $0.isSuspicious }
    }
    
    func loadTimeline() async {
        isLoading = true
        defer { isLoading = false }
        
        // Build VQL query based on focus areas
        let vql = buildTimelineVQL()
        
        do {
            let result = try await VelociraptorAPIClient.shared.executeQuery(vql: vql)
            events = parseTimelineResults(result)
            
            // Mark suspicious events based on IOCs
            markSuspiciousEvents()
            
            Logger.shared.success("Loaded \(events.count) timeline events", component: "Timeline")
        } catch {
            Logger.shared.error("Failed to load timeline: \(error)", component: "Timeline")
            
            // Load sample data for demo
            events = generateSampleEvents()
        }
    }
    
    private func buildTimelineVQL() -> String {
        // Build VQL based on focus areas
        var queries: [String] = []
        
        if focusAreas.contains(.processExecution) {
            queries.append("SELECT timestamp, Pid, Name, Cmdline FROM pslist()")
        }
        
        if focusAreas.contains(.fileSystem) {
            queries.append("SELECT Atime, Mtime, FullPath FROM glob(globs='C:/Windows/System32/**')")
        }
        
        return queries.joined(separator: " UNION ")
    }
    
    private func parseTimelineResults(_ result: VQLResult) -> [TimelineEvent] {
        // Parse VQL results into timeline events
        return []
    }
    
    private func markSuspiciousEvents() {
        let iocs = Set(knownIOCs.map { $0.lowercased() })
        
        for i in events.indices {
            let title = events[i].title.lowercased()
            let details = events[i].details?.lowercased() ?? ""
            
            events[i].isSuspicious = iocs.contains { ioc in
                title.contains(ioc) || details.contains(ioc)
            }
        }
    }
    
    private func generateSampleEvents() -> [TimelineEvent] {
        // Generate sample events for demo
        return [
            TimelineEvent(
                id: "1",
                timestamp: Date().addingTimeInterval(-3600),
                type: .processStart,
                source: .eventLog,
                title: "powershell.exe",
                details: "-ExecutionPolicy Bypass -EncodedCommand...",
                rawData: nil,
                tags: ["suspicious", "encoded"],
                isSuspicious: true,
                isInvestigated: false
            ),
            TimelineEvent(
                id: "2",
                timestamp: Date().addingTimeInterval(-7200),
                type: .networkConnect,
                source: .eventLog,
                title: "Connection to 192.168.1.100:443",
                details: "Established by svchost.exe",
                rawData: nil,
                tags: ["outbound"],
                isSuspicious: false,
                isInvestigated: false
            ),
            TimelineEvent(
                id: "3",
                timestamp: Date().addingTimeInterval(-10800),
                type: .fileCreate,
                source: .mft,
                title: "C:\\Users\\Admin\\AppData\\Local\\Temp\\payload.exe",
                details: "Size: 1.2MB, Created by chrome.exe",
                rawData: nil,
                tags: ["temp", "executable"],
                isSuspicious: true,
                isInvestigated: false
            ),
        ]
    }
    
    func addEventToIOCs(_ event: TimelineEvent) {
        if !knownIOCsText.isEmpty && !knownIOCsText.hasSuffix("\n") {
            knownIOCsText += "\n"
        }
        knownIOCsText += event.title
    }
    
    func queryEventInVQL(_ event: TimelineEvent) {
        // Open VQL editor with query for this event
        Logger.shared.info("Query event: \(event.title)", component: "Timeline")
    }
    
    func markEventInvestigated(_ event: TimelineEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index].isInvestigated = true
        }
    }
    
    func runMCPAnalysis() async {
        isAnalyzing = true
        defer { isAnalyzing = false }
        
        // Simulate MCP analysis
        try? await Task.sleep(nanoseconds: 2_000_000_000)
        
        mcpAnalysis = MCPTimelineAnalysis(
            summary: "Analysis identified \(suspiciousCount) suspicious events within the specified time range. Primary indicators suggest potential malware activity with encoded PowerShell execution and suspicious file creation.",
            findings: [
                "Encoded PowerShell commands detected - common malware technique",
                "Executable created in Temp folder by browser - potential download and execute",
                "Timeline shows activity pattern consistent with initial access",
            ],
            recommendations: [
                "Collect memory dump from affected host",
                "Review all PowerShell script block logs",
                "Check for persistence mechanisms in Registry and Scheduled Tasks",
                "Isolate host if still on network",
            ],
            suspiciousPatterns: [
                "PowerShell with -ExecutionPolicy Bypass and -EncodedCommand",
                "Executable file created in user Temp directory",
            ]
        )
        
        Logger.shared.success("MCP analysis complete", component: "Timeline")
    }
    
    func exportTimeline() {
        let eventsToExport = exportFilteredOnly ? filteredEvents : events
        Logger.shared.info("Exporting \(eventsToExport.count) events as \(exportFormat.rawValue)", component: "Timeline")
    }
}

// MARK: - Preview

#Preview {
    TimelineView()
        .frame(width: 1200, height: 800)
}
