//
//  HuntManagerView.swift
//  VelociraptorMacOS
//
//  Hunt management interface for creating and monitoring hunts
//  Gap: 0x03 - Hunt Management Interface
//
//  CDIF Pattern: SwiftUI list with creation wizard
//

import SwiftUI
import Combine

// MARK: - Hunt Manager View

/// Main hunt management view with list and detail panels
struct HuntManagerView: View {
    @StateObject private var viewModel = HuntManagerViewModel()
    @State private var selectedHunt: Hunt?
    @State private var showingCreateHunt = false
    
    var body: some View {
        HSplitView {
            // Left: Hunt List
            HuntListView(
                viewModel: viewModel,
                selectedHunt: $selectedHunt
            )
            .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            
            // Right: Hunt Detail or Empty State
            if let hunt = selectedHunt {
                HuntDetailView(hunt: hunt, viewModel: viewModel)
            } else {
                EmptyHuntSelection(onCreateHunt: { showingCreateHunt = true })
            }
        }
        .navigationTitle("Hunts")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { showingCreateHunt = true }) {
                    Label("New Hunt", systemImage: "plus")
                }
                .accessibilityIdentifier("hunts.create.button")
            }
            
            ToolbarItem(placement: .automatic) {
                Button(action: { viewModel.refresh() }) {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .accessibilityIdentifier("hunts.refresh.button")
                .disabled(viewModel.isLoading)
            }
        }
        .sheet(isPresented: $showingCreateHunt) {
            HuntCreationWizard(onComplete: { hunt in
                showingCreateHunt = false
                selectedHunt = hunt
            })
        }
        .onAppear {
            viewModel.loadHunts()
        }
    }
}

// MARK: - Hunt List View

/// Left panel showing hunt list with filters
struct HuntListView: View {
    @ObservedObject var viewModel: HuntManagerViewModel
    @Binding var selectedHunt: Hunt?
    
    var body: some View {
        VStack(spacing: 0) {
            // Filter Bar
            HStack(spacing: 8) {
                ForEach([nil] + HuntState.allCases, id: \.self) { state in
                    FilterPill(
                        title: state?.displayName ?? "All",
                        isSelected: viewModel.stateFilter == state,
                        action: { viewModel.stateFilter = state }
                    )
                    .accessibilityIdentifier("hunts.filter.\(state?.rawValue ?? "all")")
                }
            }
            .padding()
            
            Divider()
            
            // Hunt List
            if viewModel.isLoading && viewModel.hunts.isEmpty {
                ProgressView("Loading hunts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredHunts.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "scope")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    
                    Text(viewModel.hunts.isEmpty ? "No hunts created" : "No hunts match filter")
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.filteredHunts, selection: $selectedHunt) { hunt in
                    HuntRow(hunt: hunt, progress: viewModel.huntProgress[hunt.huntId])
                        .tag(hunt)
                        .accessibilityIdentifier("hunts.row.\(hunt.huntId)")
                }
                .listStyle(.sidebar)
            }
            
            // Status Bar
            HStack {
                Text("\(viewModel.filteredHunts.count) hunts")
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

// MARK: - Hunt Row

/// Single row in hunt list
struct HuntRow: View {
    let hunt: Hunt
    let progress: Double?
    
    var body: some View {
        HStack(spacing: 12) {
            // Status Icon
            Image(systemName: (hunt.state ?? .unset).iconName)
                .font(.title2)
                .foregroundColor(stateColor)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                // Description
                Text(hunt.huntDescription ?? hunt.huntId)
                    .font(.headline)
                    .lineLimit(1)
                
                // Artifacts
                Text(hunt.artifacts.joined(separator: ", "))
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                // Progress (if running)
                if hunt.state == .running {
                    ProgressView(value: progress ?? hunt.progressPercent / 100)
                        .progressViewStyle(.linear)
                }
            }
            
            Spacer()
            
            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(hunt.totalClientsWithResults)")
                    .font(.headline)
                
                Text("results")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private var stateColor: Color {
        switch hunt.state ?? .unset {
        case .running: return .orange
        case .stopped, .paused: return .yellow
        case .archived: return .gray
        case .unspecified, .unset: return .secondary
        }
    }
}

// MARK: - Empty Hunt Selection

/// Shown when no hunt is selected
struct EmptyHuntSelection: View {
    let onCreateHunt: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scope")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("Select a hunt")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Text("Choose a hunt from the list or create a new one")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
            
            Button("Create New Hunt", action: onCreateHunt)
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("hunts.empty.create.button")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Hunt Detail View

/// Right panel showing hunt details
struct HuntDetailView: View {
    let hunt: Hunt
    @ObservedObject var viewModel: HuntManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HuntDetailHeader(hunt: hunt, viewModel: viewModel)
            
            Divider()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Progress Section
                    HuntProgressSection(hunt: hunt, progress: viewModel.huntProgress[hunt.huntId])
                    
                    // Artifacts Section
                    HuntArtifactsSection(hunt: hunt)
                    
                    // Results Section
                    HuntResultsSection(hunt: hunt, viewModel: viewModel)
                    
                    Spacer()
                }
                .padding()
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

// MARK: - Hunt Detail Header

struct HuntDetailHeader: View {
    let hunt: Hunt
    @ObservedObject var viewModel: HuntManagerViewModel
    
    var body: some View {
        HStack(spacing: 16) {
            // Status Icon
            Image(systemName: (hunt.state ?? .unset).iconName)
                .font(.largeTitle)
                .foregroundColor(stateColor)
            
            // Hunt Info
            VStack(alignment: .leading, spacing: 4) {
                Text(hunt.huntDescription ?? "Unnamed Hunt")
                    .font(.title2.bold())
                
                HStack {
                    Text(hunt.huntId)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                    
                    Text("•")
                        .foregroundColor(.secondary)
                    
                    Text((hunt.state ?? .unset).displayName)
                        .font(.caption)
                        .foregroundColor(stateColor)
                }
            }
            
            Spacer()
            
            // Action Buttons
            HStack(spacing: 12) {
                if hunt.state == .paused || hunt.state == .unspecified {
                    Button(action: { Task { await viewModel.startHunt(hunt) } }) {
                        Label("Start", systemImage: "play.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .accessibilityIdentifier("hunts.detail.start.button")
                }
                
                if hunt.state == .running {
                    Button(action: { Task { await viewModel.stopHunt(hunt) } }) {
                        Label("Stop", systemImage: "stop.fill")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("hunts.detail.stop.button")
                }
                
                if hunt.state == .stopped {
                    Button(action: { Task { await viewModel.archiveHunt(hunt) } }) {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .buttonStyle(.bordered)
                    .accessibilityIdentifier("hunts.detail.archive.button")
                }
                
                Menu {
                    Button(action: { viewModel.duplicateHunt(hunt) }) {
                        Label("Duplicate", systemImage: "doc.on.doc")
                    }
                    
                    Button(action: { viewModel.exportResults(hunt) }) {
                        Label("Export Results", systemImage: "square.and.arrow.up")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive, action: { Task { await viewModel.deleteHunt(hunt) } }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .accessibilityIdentifier("hunts.detail.more.menu")
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    private var stateColor: Color {
        switch hunt.state ?? .unset {
        case .running: return .orange
        case .stopped, .paused: return .yellow
        case .archived: return .gray
        case .unspecified, .unset: return .secondary
        }
    }
}

// MARK: - Hunt Progress Section

struct HuntProgressSection: View {
    let hunt: Hunt
    let progress: Double?
    
    var body: some View {
        GroupBox("Progress") {
            VStack(spacing: 12) {
                // Progress Bar
                ProgressView(value: progress ?? hunt.progressPercent / 100)
                    .progressViewStyle(.linear)
                
                // Stats Grid
                HStack(spacing: 40) {
                    StatBox(title: "Scheduled", value: "\(hunt.totalClientsScheduled)", color: .blue)
                    StatBox(title: "Completed", value: "\(hunt.totalClientsWithResults)", color: .green)
                    StatBox(title: "Errors", value: "\(hunt.totalClientsWithErrors)", color: .red)
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("hunts.detail.progress")
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title.bold())
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Hunt Artifacts Section

struct HuntArtifactsSection: View {
    let hunt: Hunt
    
    var body: some View {
        GroupBox("Artifacts") {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(hunt.artifacts, id: \.self) { artifact in
                    HStack {
                        Image(systemName: "doc.text")
                            .foregroundColor(.accentColor)
                        
                        Text(artifact)
                            .font(.body)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .accessibilityIdentifier("hunts.detail.artifact.\(artifact)")
                }
            }
            .padding(.vertical, 4)
        }
        .accessibilityIdentifier("hunts.detail.artifacts")
    }
}

// MARK: - Hunt Results Section

struct HuntResultsSection: View {
    let hunt: Hunt
    @ObservedObject var viewModel: HuntManagerViewModel
    
    var body: some View {
        GroupBox("Results") {
            if viewModel.huntResults.isEmpty {
                VStack(spacing: 8) {
                    Text("No results yet")
                        .foregroundColor(.secondary)
                    
                    if hunt.state == .running {
                        Text("Results will appear as clients report back")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("\(viewModel.huntResults.count) rows")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    // Simple table view of results
                    // TODO: Full results table with export
                }
            }
        }
        .accessibilityIdentifier("hunts.detail.results")
        .onAppear {
            Task { await viewModel.loadResults(for: hunt) }
        }
    }
}

// MARK: - Hunt Creation Wizard

/// Wizard for creating new hunts
struct HuntCreationWizard: View {
    let onComplete: (Hunt) -> Void
    @Environment(\.dismiss) private var dismiss
    
    @State private var currentStep = 0
    @State private var description = ""
    @State private var selectedArtifacts: Set<String> = []
    @State private var searchQuery = ""
    @State private var availableArtifacts: [Artifact] = []
    @State private var isLoading = false
    @State private var error: Error?
    
    private let steps = ["Artifacts", "Configure", "Review"]
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Create New Hunt")
                    .font(.title2.bold())
                
                Spacer()
                
                Button("Cancel") { dismiss() }
                    .accessibilityIdentifier("hunts.wizard.cancel.button")
            }
            .padding()
            
            Divider()
            
            // Step Indicator
            HStack(spacing: 0) {
                ForEach(0..<steps.count, id: \.self) { index in
                    HStack {
                        Circle()
                            .fill(index <= currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Text("\(index + 1)")
                                    .font(.caption.bold())
                                    .foregroundColor(.white)
                            )
                        
                        Text(steps[index])
                            .font(.caption)
                            .foregroundColor(index <= currentStep ? .primary : .secondary)
                        
                        if index < steps.count - 1 {
                            Rectangle()
                                .fill(index < currentStep ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(height: 2)
                                .padding(.horizontal, 8)
                        }
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Step Content
            Group {
                switch currentStep {
                case 0:
                    HuntArtifactSelectionStep(
                        artifacts: availableArtifacts,
                        selectedArtifacts: $selectedArtifacts,
                        searchQuery: $searchQuery
                    )
                case 1:
                    HuntConfigurationStep(description: $description)
                case 2:
                    HuntReviewStep(
                        description: description,
                        selectedArtifacts: selectedArtifacts
                    )
                default:
                    EmptyView()
                }
            }
            .frame(maxHeight: .infinity)
            
            Divider()
            
            // Footer
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        currentStep -= 1
                    }
                    .accessibilityIdentifier("hunts.wizard.back.button")
                }
                
                Spacer()
                
                if currentStep < steps.count - 1 {
                    Button("Next") {
                        currentStep += 1
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canProceed)
                    .accessibilityIdentifier("hunts.wizard.next.button")
                } else {
                    Button("Create Hunt") {
                        createHunt()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!canCreate)
                    .accessibilityIdentifier("hunts.wizard.create.button")
                }
            }
            .padding()
        }
        .frame(width: 600, height: 500)
        .onAppear {
            loadArtifacts()
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case 0: return !selectedArtifacts.isEmpty
        case 1: return !description.isEmpty
        default: return true
        }
    }
    
    private var canCreate: Bool {
        !selectedArtifacts.isEmpty && !description.isEmpty
    }
    
    private func loadArtifacts() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                availableArtifacts = try await VelociraptorAPIClient.shared.listArtifacts()
            } catch {
                self.error = error
            }
        }
    }
    
    private func createHunt() {
        Task {
            isLoading = true
            defer { isLoading = false }
            
            do {
                let hunt = try await VelociraptorAPIClient.shared.createHunt(
                    description: description,
                    artifacts: Array(selectedArtifacts)
                )
                onComplete(hunt)
            } catch {
                self.error = error
            }
        }
    }
}

// MARK: - Wizard Steps

struct HuntArtifactSelectionStep: View {
    let artifacts: [Artifact]
    @Binding var selectedArtifacts: Set<String>
    @Binding var searchQuery: String
    
    var filteredArtifacts: [Artifact] {
        if searchQuery.isEmpty {
            return artifacts
        }
        return artifacts.filter { artifact in
            artifact.name.localizedCaseInsensitiveContains(searchQuery) ||
            (artifact.description?.localizedCaseInsensitiveContains(searchQuery) ?? false)
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                
                TextField("Search artifacts...", text: $searchQuery)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("hunts.wizard.artifacts.search")
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .padding(.horizontal)
            
            // Selected count
            HStack {
                Text("\(selectedArtifacts.count) artifacts selected")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .padding(.horizontal)
            
            // Artifact List
            List(filteredArtifacts) { artifact in
                HStack {
                    Toggle(isOn: Binding(
                        get: { selectedArtifacts.contains(artifact.name) },
                        set: { isSelected in
                            if isSelected {
                                selectedArtifacts.insert(artifact.name)
                            } else {
                                selectedArtifacts.remove(artifact.name)
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
                    .accessibilityIdentifier("hunts.wizard.artifact.\(artifact.name)")
                }
            }
        }
    }
}

struct HuntConfigurationStep: View {
    @Binding var description: String
    
    var body: some View {
        Form {
            Section("Hunt Details") {
                TextField("Description", text: $description, axis: .vertical)
                    .lineLimit(3...5)
                    .accessibilityIdentifier("hunts.wizard.description.field")
            }
            
            Section("Options") {
                Text("Additional hunt configuration options will be added here")
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

struct HuntReviewStep: View {
    let description: String
    let selectedArtifacts: Set<String>
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Description") {
                Text(description)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            GroupBox("Artifacts (\(selectedArtifacts.count))") {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(Array(selectedArtifacts).sorted(), id: \.self) { artifact in
                        HStack {
                            Image(systemName: "doc.text")
                                .foregroundColor(.accentColor)
                            Text(artifact)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            Spacer()
        }
        .padding()
    }
}

// MARK: - Hunt Manager ViewModel

@MainActor
class HuntManagerViewModel: ObservableObject {
    @Published var hunts: [Hunt] = []
    @Published var filteredHunts: [Hunt] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    @Published var stateFilter: HuntState? = nil {
        didSet { applyFilters() }
    }
    
    @Published var huntProgress: [String: Double] = [:]
    @Published var huntResults: [VQLResult] = []
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupWebSocketSubscriptions()
    }
    
    // MARK: - Data Loading
    
    func loadHunts() {
        Task { await fetchHunts() }
    }
    
    func refresh() {
        loadHunts()
    }
    
    private func fetchHunts() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            hunts = try await VelociraptorAPIClient.shared.listHunts()
            applyFilters()
        } catch {
            self.error = error
        }
    }
    
    private func applyFilters() {
        if let filter = stateFilter {
            filteredHunts = hunts.filter { $0.state == filter }
        } else {
            filteredHunts = hunts
        }
    }
    
    // MARK: - WebSocket
    
    private func setupWebSocketSubscriptions() {
        WebSocketService.shared.huntProgressPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] huntId, progress in
                self?.huntProgress[huntId] = progress
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Hunt Operations
    
    func startHunt(_ hunt: Hunt) async {
        do {
            _ = try await VelociraptorAPIClient.shared.startHunt(id: hunt.huntId)
            await fetchHunts()
        } catch {
            self.error = error
        }
    }
    
    func stopHunt(_ hunt: Hunt) async {
        do {
            _ = try await VelociraptorAPIClient.shared.stopHunt(id: hunt.huntId)
            await fetchHunts()
        } catch {
            self.error = error
        }
    }
    
    func archiveHunt(_ hunt: Hunt) async {
        do {
            _ = try await VelociraptorAPIClient.shared.archiveHunt(id: hunt.huntId)
            await fetchHunts()
        } catch {
            self.error = error
        }
    }
    
    func deleteHunt(_ hunt: Hunt) async {
        do {
            try await VelociraptorAPIClient.shared.deleteHunt(id: hunt.huntId)
            hunts.removeAll { $0.huntId == hunt.huntId }
            applyFilters()
        } catch {
            self.error = error
        }
    }
    
    func duplicateHunt(_ hunt: Hunt) {
        // TODO: Implement
    }
    
    func exportResults(_ hunt: Hunt) {
        // TODO: Implement
    }
    
    // MARK: - Results
    
    func loadResults(for hunt: Hunt) async {
        guard let artifact = hunt.artifacts.first else { return }
        
        do {
            let result = try await VelociraptorAPIClient.shared.getHuntResults(
                huntId: hunt.huntId,
                artifact: artifact
            )
            huntResults = [result]
        } catch {
            Logger.shared.error("Failed to load hunt results: \(error)", component: "Hunts")
        }
    }
}

// MARK: - Preview

#Preview {
    HuntManagerView()
        .frame(width: 1000, height: 700)
}
