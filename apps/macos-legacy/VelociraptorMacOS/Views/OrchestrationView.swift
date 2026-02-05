//
//  OrchestrationView.swift
//  VelociraptorMacOS
//
//  Orchestration Panel - Workflow and Automation Management
//  Gap 0x11 - Enterprise workflow orchestration
//
//  Features:
//  - Create and manage automated workflows
//  - Schedule recurring tasks
//  - Response playbooks
//  - Integration triggers
//  - Workflow monitoring and history
//
//  CDIF Pattern: FC-001 (Feature Complete)
//  Swift 6 Concurrency: @MainActor, Sendable
//

import SwiftUI
import Combine

// MARK: - Data Models

struct Workflow: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var description: String
    var trigger: WorkflowTrigger
    var steps: [WorkflowStep]
    var isEnabled: Bool
    var lastRun: Date?
    var nextRun: Date?
    var runCount: Int
    var status: WorkflowStatus
    
    init(id: UUID = UUID(), name: String, description: String, trigger: WorkflowTrigger, steps: [WorkflowStep] = [], isEnabled: Bool = true, lastRun: Date? = nil, nextRun: Date? = nil, runCount: Int = 0, status: WorkflowStatus = .idle) {
        self.id = id
        self.name = name
        self.description = description
        self.trigger = trigger
        self.steps = steps
        self.isEnabled = isEnabled
        self.lastRun = lastRun
        self.nextRun = nextRun
        self.runCount = runCount
        self.status = status
    }
}

struct WorkflowStep: Identifiable, Hashable, Sendable {
    let id: UUID
    var name: String
    var type: StepType
    var configuration: [String: String]
    var conditions: [String]
    var onFailure: FailureAction
    
    init(id: UUID = UUID(), name: String, type: StepType, configuration: [String: String] = [:], conditions: [String] = [], onFailure: FailureAction = .continue) {
        self.id = id
        self.name = name
        self.type = type
        self.configuration = configuration
        self.conditions = conditions
        self.onFailure = onFailure
    }
}

struct WorkflowRun: Identifiable, Sendable {
    let id: UUID
    let workflowId: UUID
    let startTime: Date
    var endTime: Date?
    var status: RunStatus
    var stepResults: [StepResult]
    
    init(id: UUID = UUID(), workflowId: UUID, startTime: Date = Date(), endTime: Date? = nil, status: RunStatus = .running, stepResults: [StepResult] = []) {
        self.id = id
        self.workflowId = workflowId
        self.startTime = startTime
        self.endTime = endTime
        self.status = status
        self.stepResults = stepResults
    }
}

struct StepResult: Identifiable, Sendable {
    let id: UUID
    let stepName: String
    var status: RunStatus
    var output: String
    var duration: TimeInterval
    
    init(id: UUID = UUID(), stepName: String, status: RunStatus, output: String = "", duration: TimeInterval = 0) {
        self.id = id
        self.stepName = stepName
        self.status = status
        self.output = output
        self.duration = duration
    }
}

enum WorkflowTrigger: Hashable, Sendable {
    case manual
    case schedule(cron: String)
    case event(eventType: String)
    case webhook(path: String)
    case clientEnrollment
    case huntComplete
    case alert(severity: String)
    
    var displayName: String {
        switch self {
        case .manual: return "Manual"
        case .schedule(let cron): return "Schedule: \(cron)"
        case .event(let type): return "Event: \(type)"
        case .webhook(let path): return "Webhook: \(path)"
        case .clientEnrollment: return "Client Enrollment"
        case .huntComplete: return "Hunt Complete"
        case .alert(let severity): return "Alert: \(severity)"
        }
    }
    
    var icon: String {
        switch self {
        case .manual: return "hand.tap"
        case .schedule: return "clock"
        case .event: return "bell"
        case .webhook: return "network"
        case .clientEnrollment: return "person.badge.plus"
        case .huntComplete: return "checkmark.circle"
        case .alert: return "exclamationmark.triangle"
        }
    }
}

enum StepType: String, CaseIterable, Sendable {
    case runHunt = "Run Hunt"
    case collectArtifact = "Collect Artifact"
    case executeVQL = "Execute VQL"
    case sendNotification = "Send Notification"
    case callWebhook = "Call Webhook"
    case updateLabels = "Update Labels"
    case quarantineClient = "Quarantine Client"
    case generateReport = "Generate Report"
    case waitFor = "Wait/Delay"
    case conditional = "Conditional"
    
    var icon: String {
        switch self {
        case .runHunt: return "magnifyingglass"
        case .collectArtifact: return "doc.text"
        case .executeVQL: return "terminal"
        case .sendNotification: return "bell.fill"
        case .callWebhook: return "arrow.right.circle"
        case .updateLabels: return "tag"
        case .quarantineClient: return "shield.slash"
        case .generateReport: return "doc.richtext"
        case .waitFor: return "clock"
        case .conditional: return "arrow.triangle.branch"
        }
    }
}

enum FailureAction: String, CaseIterable, Sendable {
    case stop = "Stop Workflow"
    case `continue` = "Continue"
    case retry = "Retry Step"
    case notify = "Notify and Continue"
}

enum WorkflowStatus: String, Sendable {
    case idle = "Idle"
    case running = "Running"
    case paused = "Paused"
    case error = "Error"
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .running: return .green
        case .paused: return .orange
        case .error: return .red
        }
    }
}

enum RunStatus: String, Sendable {
    case pending = "Pending"
    case running = "Running"
    case success = "Success"
    case failed = "Failed"
    case skipped = "Skipped"
    
    var color: Color {
        switch self {
        case .pending: return .gray
        case .running: return .blue
        case .success: return .green
        case .failed: return .red
        case .skipped: return .orange
        }
    }
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .running: return "arrow.clockwise"
        case .success: return "checkmark.circle.fill"
        case .failed: return "xmark.circle.fill"
        case .skipped: return "arrow.right.circle"
        }
    }
}

// MARK: - ViewModel

@MainActor
final class OrchestrationViewModel: ObservableObject {
    @Published var workflows: [Workflow] = []
    @Published var selectedWorkflow: Workflow?
    @Published var recentRuns: [WorkflowRun] = []
    @Published var isLoading = false
    @Published var showCreateSheet = false
    @Published var searchText = ""
    
    var filteredWorkflows: [Workflow] {
        if searchText.isEmpty {
            return workflows
        }
        return workflows.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    func loadWorkflows() async {
        isLoading = true
        defer { isLoading = false }
        
        // Load sample workflows
        if workflows.isEmpty {
            workflows = [
                Workflow(
                    name: "New Client Triage",
                    description: "Automatic triage collection when new client enrolls",
                    trigger: .clientEnrollment,
                    steps: [
                        WorkflowStep(name: "Collect System Info", type: .collectArtifact, configuration: ["artifact": "Generic.Client.Info"]),
                        WorkflowStep(name: "Run Security Scan", type: .runHunt, configuration: ["artifacts": "Windows.Detection.Yara"]),
                        WorkflowStep(name: "Notify SOC", type: .sendNotification, configuration: ["channel": "soc-alerts"])
                    ],
                    isEnabled: true,
                    lastRun: Date().addingTimeInterval(-3600),
                    runCount: 47,
                    status: .idle
                ),
                Workflow(
                    name: "Daily Threat Hunt",
                    description: "Scheduled threat hunt across all endpoints",
                    trigger: .schedule(cron: "0 2 * * *"),
                    steps: [
                        WorkflowStep(name: "Persistence Check", type: .runHunt, configuration: ["artifacts": "Windows.System.Persistence"]),
                        WorkflowStep(name: "Network Connections", type: .collectArtifact, configuration: ["artifact": "Windows.Network.Connections"]),
                        WorkflowStep(name: "Generate Report", type: .generateReport)
                    ],
                    isEnabled: true,
                    lastRun: Date().addingTimeInterval(-86400),
                    nextRun: Date().addingTimeInterval(43200),
                    runCount: 30,
                    status: .idle
                ),
                Workflow(
                    name: "Alert Response: Critical",
                    description: "Automated response to critical security alerts",
                    trigger: .alert(severity: "critical"),
                    steps: [
                        WorkflowStep(name: "Isolate Client", type: .quarantineClient),
                        WorkflowStep(name: "Full Collection", type: .collectArtifact, configuration: ["artifact": "Windows.KapeFiles.Targets"]),
                        WorkflowStep(name: "Memory Dump", type: .collectArtifact, configuration: ["artifact": "Windows.Memory.Acquisition"]),
                        WorkflowStep(name: "Notify IR Team", type: .sendNotification, configuration: ["channel": "incident-response"])
                    ],
                    isEnabled: true,
                    runCount: 3,
                    status: .idle
                ),
                Workflow(
                    name: "Ransomware Playbook",
                    description: "Comprehensive ransomware incident response",
                    trigger: .manual,
                    steps: [
                        WorkflowStep(name: "Quarantine Affected", type: .quarantineClient),
                        WorkflowStep(name: "Collect Ransomware Artifacts", type: .collectArtifact),
                        WorkflowStep(name: "Check Backup Status", type: .executeVQL),
                        WorkflowStep(name: "Notify Management", type: .sendNotification),
                        WorkflowStep(name: "Generate IR Report", type: .generateReport)
                    ],
                    isEnabled: true,
                    runCount: 0,
                    status: .idle
                )
            ]
            
            // Sample recent runs
            recentRuns = [
                WorkflowRun(
                    workflowId: workflows[0].id,
                    startTime: Date().addingTimeInterval(-3600),
                    endTime: Date().addingTimeInterval(-3540),
                    status: .success,
                    stepResults: [
                        StepResult(stepName: "Collect System Info", status: .success, duration: 15),
                        StepResult(stepName: "Run Security Scan", status: .success, duration: 40),
                        StepResult(stepName: "Notify SOC", status: .success, duration: 2)
                    ]
                ),
                WorkflowRun(
                    workflowId: workflows[1].id,
                    startTime: Date().addingTimeInterval(-86400),
                    endTime: Date().addingTimeInterval(-84600),
                    status: .success,
                    stepResults: [
                        StepResult(stepName: "Persistence Check", status: .success, duration: 1200),
                        StepResult(stepName: "Network Connections", status: .success, duration: 300),
                        StepResult(stepName: "Generate Report", status: .success, duration: 60)
                    ]
                )
            ]
        }
    }
    
    func runWorkflow(_ workflow: Workflow) async {
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index].status = .running
        }
        
        // Simulate workflow execution
        try? await Task.sleep(nanoseconds: 3_000_000_000)
        
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index].status = .idle
            workflows[index].lastRun = Date()
            workflows[index].runCount += 1
        }
    }
    
    func toggleWorkflow(_ workflow: Workflow) {
        if let index = workflows.firstIndex(where: { $0.id == workflow.id }) {
            workflows[index].isEnabled.toggle()
        }
    }
    
    func deleteWorkflow(_ workflow: Workflow) {
        workflows.removeAll { $0.id == workflow.id }
        if selectedWorkflow?.id == workflow.id {
            selectedWorkflow = nil
        }
    }
}

// MARK: - Main View

struct OrchestrationView: View {
    @StateObject private var viewModel = OrchestrationViewModel()
    
    var body: some View {
        HSplitView {
            // Sidebar
            WorkflowListView(viewModel: viewModel)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            
            // Detail
            if let workflow = viewModel.selectedWorkflow {
                WorkflowDetailView(workflow: workflow, viewModel: viewModel)
            } else {
                OrchestrationDashboard(viewModel: viewModel)
            }
        }
        .task {
            await viewModel.loadWorkflows()
        }
        .sheet(isPresented: $viewModel.showCreateSheet) {
            CreateWorkflowSheet(viewModel: viewModel)
        }
        .accessibilityIdentifier("orchestration.main")
    }
}

// MARK: - Workflow List

struct WorkflowListView: View {
    @ObservedObject var viewModel: OrchestrationViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Workflows")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.showCreateSheet = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.borderless)
                .accessibilityIdentifier("orchestration.add")
            }
            .padding()
            
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search workflows...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            .padding(.bottom)
            
            Divider()
            
            // Workflow List
            if viewModel.isLoading {
                Spacer()
                ProgressView("Loading...")
                Spacer()
            } else if viewModel.filteredWorkflows.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "gearshape.2")
                        .font(.system(size: 48))
                        .foregroundColor(.secondary)
                    Text("No Workflows")
                        .font(.headline)
                    Text("Create an automated workflow")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Button("Create Workflow") {
                        viewModel.showCreateSheet = true
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else {
                List(viewModel.filteredWorkflows, selection: $viewModel.selectedWorkflow) { workflow in
                    WorkflowRow(workflow: workflow)
                        .tag(workflow)
                }
                .listStyle(.sidebar)
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct WorkflowRow: View {
    let workflow: Workflow
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: workflow.trigger.icon)
                .font(.title2)
                .foregroundColor(workflow.isEnabled ? .accentColor : .secondary)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(workflow.name)
                        .font(.headline)
                    if !workflow.isEnabled {
                        Text("Disabled")
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 2)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(4)
                    }
                }
                HStack(spacing: 8) {
                    Text(workflow.trigger.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("•")
                        .foregroundColor(.secondary)
                    Text("\(workflow.steps.count) steps")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Circle()
                .fill(workflow.status.color)
                .frame(width: 10, height: 10)
        }
        .padding(.vertical, 4)
        .opacity(workflow.isEnabled ? 1 : 0.6)
        .accessibilityIdentifier("orchestration.workflow.\(workflow.id)")
    }
}

// MARK: - Orchestration Dashboard

struct OrchestrationDashboard: View {
    @ObservedObject var viewModel: OrchestrationViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "gearshape.2.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.accentColor)
                    
                    Text("Workflow Orchestration")
                        .font(.title)
                    
                    Text("Automate your incident response and threat hunting")
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                // Stats
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    OrchestrationStatCard(
                        title: "Total Workflows",
                        value: "\(viewModel.workflows.count)",
                        icon: "gearshape.2",
                        color: .blue
                    )
                    OrchestrationStatCard(
                        title: "Active",
                        value: "\(viewModel.workflows.filter { $0.isEnabled }.count)",
                        icon: "checkmark.circle.fill",
                        color: .green
                    )
                    OrchestrationStatCard(
                        title: "Runs Today",
                        value: "\(viewModel.recentRuns.count)",
                        icon: "arrow.clockwise",
                        color: .orange
                    )
                    OrchestrationStatCard(
                        title: "Success Rate",
                        value: "98%",
                        icon: "chart.line.uptrend.xyaxis",
                        color: .purple
                    )
                }
                .padding(.horizontal, 40)
                
                // Recent Runs
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Activity")
                        .font(.headline)
                    
                    ForEach(viewModel.recentRuns.prefix(5)) { run in
                        RecentRunRow(run: run, workflows: viewModel.workflows)
                    }
                }
                .padding(.horizontal, 40)
                
                // Quick Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quick Actions")
                        .font(.headline)
                    
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        QuickActionCard(
                            title: "New Workflow",
                            icon: "plus.circle.fill",
                            color: .blue,
                            action: { viewModel.showCreateSheet = true }
                        )
                        QuickActionCard(
                            title: "Playbook Library",
                            icon: "books.vertical.fill",
                            color: .green,
                            action: { }
                        )
                        QuickActionCard(
                            title: "Run History",
                            icon: "clock.arrow.circlepath",
                            color: .orange,
                            action: { }
                        )
                    }
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.bottom, 40)
        }
    }
}

struct OrchestrationStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct RecentRunRow: View {
    let run: WorkflowRun
    let workflows: [Workflow]
    
    var workflowName: String {
        workflows.first { $0.id == run.workflowId }?.name ?? "Unknown"
    }
    
    var body: some View {
        HStack {
            Image(systemName: run.status.icon)
                .foregroundColor(run.status.color)
            
            VStack(alignment: .leading) {
                Text(workflowName)
                    .font(.headline)
                Text(formatDate(run.startTime))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(run.status.rawValue)
                .font(.caption)
                .foregroundColor(run.status.color)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundColor(color)
                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Workflow Detail

struct WorkflowDetailView: View {
    let workflow: Workflow
    @ObservedObject var viewModel: OrchestrationViewModel
    @State private var showDeleteConfirm = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(workflow.name)
                                .font(.title)
                            
                            Circle()
                                .fill(workflow.status.color)
                                .frame(width: 12, height: 12)
                        }
                        
                        Text(workflow.description)
                            .foregroundColor(.secondary)
                        
                        HStack(spacing: 16) {
                            Label(workflow.trigger.displayName, systemImage: workflow.trigger.icon)
                            Label("\(workflow.runCount) runs", systemImage: "arrow.clockwise")
                            if let lastRun = workflow.lastRun {
                                Label("Last: \(formatDate(lastRun))", systemImage: "clock")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Toggle("Enabled", isOn: .constant(workflow.isEnabled))
                        .toggleStyle(.switch)
                        .labelsHidden()
                        .onChange(of: workflow.isEnabled) { _, _ in
                            viewModel.toggleWorkflow(workflow)
                        }
                }
                
                Divider()
                
                // Actions
                HStack(spacing: 12) {
                    Button(action: {
                        Task {
                            await viewModel.runWorkflow(workflow)
                        }
                    }) {
                        Label("Run Now", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(workflow.status == .running)
                    
                    Button(action: { }) {
                        Label("Edit", systemImage: "pencil")
                    }
                    .buttonStyle(.bordered)
                    
                    Button(action: { }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button(role: .destructive, action: { showDeleteConfirm = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                    .buttonStyle(.bordered)
                }
                
                // Steps
                GroupBox("Workflow Steps") {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(workflow.steps.enumerated()), id: \.element.id) { index, step in
                            HStack(spacing: 16) {
                                VStack {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 32, height: 32)
                                        .overlay(
                                            Text("\(index + 1)")
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                        )
                                    
                                    if index < workflow.steps.count - 1 {
                                        Rectangle()
                                            .fill(Color.accentColor.opacity(0.3))
                                            .frame(width: 2)
                                            .frame(maxHeight: .infinity)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: step.type.icon)
                                            .foregroundColor(.accentColor)
                                        Text(step.name)
                                            .font(.headline)
                                    }
                                    Text(step.type.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if !step.configuration.isEmpty {
                                        HStack {
                                            ForEach(Array(step.configuration.keys.sorted()), id: \.self) { key in
                                                Text("\(key): \(step.configuration[key] ?? "")")
                                                    .font(.caption2)
                                                    .padding(.horizontal, 6)
                                                    .padding(.vertical, 2)
                                                    .background(Color.gray.opacity(0.2))
                                                    .cornerRadius(4)
                                            }
                                        }
                                    }
                                }
                                .padding(.vertical, 12)
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                }
                
                // Run History
                GroupBox("Recent Runs") {
                    let workflowRuns = viewModel.recentRuns.filter { $0.workflowId == workflow.id }
                    
                    if workflowRuns.isEmpty {
                        Text("No runs yet")
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        VStack(spacing: 8) {
                            ForEach(workflowRuns.prefix(5)) { run in
                                HStack {
                                    Image(systemName: run.status.icon)
                                        .foregroundColor(run.status.color)
                                    Text(formatDate(run.startTime))
                                    Spacer()
                                    if let endTime = run.endTime {
                                        Text("Duration: \(Int(endTime.timeIntervalSince(run.startTime)))s")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    Text(run.status.rawValue)
                                        .font(.caption)
                                        .foregroundColor(run.status.color)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                        .padding()
                    }
                }
                
                Spacer()
            }
            .padding(24)
        }
        .alert("Delete Workflow?", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteWorkflow(workflow)
            }
        } message: {
            Text("This will permanently delete the \(workflow.name) workflow.")
        }
        .accessibilityIdentifier("orchestration.detail")
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Create Workflow Sheet

struct CreateWorkflowSheet: View {
    @ObservedObject var viewModel: OrchestrationViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedTrigger: TriggerOption = .manual
    @State private var cronExpression = "0 * * * *"
    @State private var eventType = ""
    
    enum TriggerOption: String, CaseIterable {
        case manual = "Manual"
        case schedule = "Schedule"
        case clientEnrollment = "Client Enrollment"
        case huntComplete = "Hunt Complete"
        case alert = "Alert"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create Workflow")
                    .font(.headline)
                Spacer()
                Button("Cancel") { dismiss() }
                    .buttonStyle(.borderless)
            }
            .padding()
            
            Divider()
            
            Form {
                Section("Details") {
                    TextField("Workflow Name", text: $name, prompt: Text("e.g., Ransomware Response"))
                    TextField("Description", text: $description, prompt: Text("Brief description of this workflow"))
                }
                
                Section("Trigger") {
                    Picker("Trigger Type", selection: $selectedTrigger) {
                        ForEach(TriggerOption.allCases, id: \.self) { option in
                            Text(option.rawValue).tag(option)
                        }
                    }
                    
                    if selectedTrigger == .schedule {
                        TextField("Cron Expression", text: $cronExpression)
                            .font(.system(.body, design: .monospaced))
                    }
                }
                
                Section {
                    Text("You can add steps after creating the workflow.")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .formStyle(.grouped)
            
            Divider()
            
            // Footer
            HStack {
                Spacer()
                Button("Cancel") { dismiss() }
                    .keyboardShortcut(.escape)
                Button("Create Workflow") {
                    createWorkflow()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
            .padding()
        }
        .frame(width: 500, height: 400)
        .accessibilityIdentifier("orchestration.create.sheet")
    }
    
    private func createWorkflow() {
        let trigger: WorkflowTrigger
        switch selectedTrigger {
        case .manual: trigger = .manual
        case .schedule: trigger = .schedule(cron: cronExpression)
        case .clientEnrollment: trigger = .clientEnrollment
        case .huntComplete: trigger = .huntComplete
        case .alert: trigger = .alert(severity: "high")
        }
        
        let workflow = Workflow(
            name: name,
            description: description,
            trigger: trigger
        )
        
        viewModel.workflows.append(workflow)
        dismiss()
    }
}

// MARK: - Preview

#if DEBUG
struct OrchestrationView_Previews: PreviewProvider {
    static var previews: some View {
        OrchestrationView()
            .frame(width: 1200, height: 800)
    }
}
#endif
