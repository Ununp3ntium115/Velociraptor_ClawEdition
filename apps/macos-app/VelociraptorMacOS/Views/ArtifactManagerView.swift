//
//  ArtifactManagerView.swift
//  VelociraptorMacOS
//
//  Artifact Management and MCP-Powered Incident Response Assistant
//  Gap: 0x08 - Artifact Manager with AI Recommendations
//
//  DFIR Pattern: Tree-based artifact browser with MCP integration
//  Swift 6 Concurrency: Strict mode compliant
//

import SwiftUI

// MARK: - Artifact Manager View

/// Main artifact management interface with MCP-powered incident response assistant
struct ArtifactManagerView: View {
    @StateObject private var viewModel = ArtifactManagerViewModel()
    @State private var showImportSheet = false
    @State private var showIncidentAssistant = false
    
    var body: some View {
        HSplitView {
            // Left: Artifact Tree Browser
            ArtifactSidebar(viewModel: viewModel)
                .frame(minWidth: 280, idealWidth: 320, maxWidth: 400)
            
            // Center: Artifact List and Details
            ArtifactBrowserPane(viewModel: viewModel)
                .frame(minWidth: 400)
            
            // Right: Artifact Details or MCP Assistant (collapsible)
            if viewModel.showDetailPane {
                if let artifact = viewModel.selectedArtifact {
                    ArtifactDetailPane(artifact: artifact, viewModel: viewModel)
                        .frame(minWidth: 300, idealWidth: 400)
                } else if viewModel.showMCPAssistant {
                    MCPIncidentAssistantPane(viewModel: viewModel)
                        .frame(minWidth: 300, idealWidth: 400)
                }
            }
        }
        .navigationTitle("Artifact Manager")
        .toolbar {
            ArtifactManagerToolbar(viewModel: viewModel, showImportSheet: $showImportSheet, showIncidentAssistant: $showIncidentAssistant)
        }
        .sheet(isPresented: $showImportSheet) {
            ArtifactImportSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $showIncidentAssistant) {
            MCPIncidentAssistantSheet(viewModel: viewModel)
        }
        .onAppear {
            viewModel.loadArtifacts()
        }
        .accessibilityIdentifier("artifacts.manager.view")
    }
}

// MARK: - Artifact Sidebar

/// Left panel with artifact category tree
struct ArtifactSidebar: View {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search Bar
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search artifacts...", text: $viewModel.searchQuery)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("artifacts.search.field")
                
                if !viewModel.searchQuery.isEmpty {
                    Button(action: { viewModel.searchQuery = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(6)
            .padding()
            
            Divider()
            
            // Quick Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ArtifactFilterPill(
                        title: "All",
                        icon: "doc.text",
                        count: viewModel.allArtifacts.count,
                        isSelected: viewModel.selectedCategory == nil,
                        action: { viewModel.selectedCategory = nil }
                    )
                    
                    ArtifactFilterPill(
                        title: "Favorites",
                        icon: "star.fill",
                        count: viewModel.favoriteArtifacts.count,
                        isSelected: viewModel.showFavoritesOnly,
                        action: { viewModel.showFavoritesOnly.toggle() }
                    )
                    
                    ArtifactFilterPill(
                        title: "Custom",
                        icon: "wrench.and.screwdriver",
                        count: viewModel.customArtifacts.count,
                        isSelected: viewModel.showCustomOnly,
                        action: { viewModel.showCustomOnly.toggle() }
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            
            Divider()
            
            // Artifact Tree
            List(selection: $viewModel.selectedCategory) {
                Section("Platforms") {
                    ForEach(ArtifactCategory.allCases) { category in
                        ArtifactCategoryRow(
                            category: category,
                            count: viewModel.artifactCount(for: category),
                            viewModel: viewModel
                        )
                        .tag(category)
                    }
                }
                
                Section("Collections") {
                    ForEach(viewModel.artifactCollections) { collection in
                        HStack {
                            Image(systemName: "folder.fill")
                                .foregroundColor(.orange)
                            Text(collection.name)
                            Spacer()
                            Text("\(collection.artifacts.count)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .accessibilityIdentifier("artifacts.collection.\(collection.id)")
                    }
                }
            }
            .listStyle(.sidebar)
            .accessibilityIdentifier("artifacts.tree.list")
            
            Divider()
            
            // Status Bar
            HStack {
                Text("\(viewModel.filteredArtifacts.count) artifacts")
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
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct ArtifactCategoryRow: View {
    let category: ArtifactCategory
    let count: Int
    @ObservedObject var viewModel: ArtifactManagerViewModel
    @State private var isExpanded = true
    
    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            ForEach(viewModel.subcategories(for: category), id: \.self) { subcategory in
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.accentColor)
                        .frame(width: 20)
                    Text(subcategory)
                        .font(.subheadline)
                    Spacer()
                    Text("\(viewModel.artifactCount(for: category, subcategory: subcategory))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.leading, 8)
                .contentShape(Rectangle())
                .onTapGesture {
                    viewModel.selectSubcategory(category, subcategory: subcategory)
                }
                .accessibilityIdentifier("artifacts.subcategory.\(subcategory)")
            }
        } label: {
            HStack {
                Image(systemName: category.icon)
                    .foregroundColor(category.color)
                    .frame(width: 24)
                Text(category.displayName)
                Spacer()
                Text("\(count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(4)
            }
        }
        .accessibilityIdentifier("artifacts.category.\(category.rawValue)")
    }
}

// MARK: - Artifact Browser Pane

/// Center panel showing filtered artifacts
struct ArtifactBrowserPane: View {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(viewModel.selectedCategoryTitle)
                    .font(.headline)
                
                Spacer()
                
                // View Mode Toggle
                Picker("View", selection: $viewModel.viewMode) {
                    Image(systemName: "list.bullet").tag(ArtifactViewMode.list)
                    Image(systemName: "square.grid.2x2").tag(ArtifactViewMode.grid)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)
                
                // Sort Menu
                Menu {
                    Button("Name") { viewModel.sortOrder = .name }
                    Button("Platform") { viewModel.sortOrder = .platform }
                    Button("Type") { viewModel.sortOrder = .type }
                    Button("Recently Used") { viewModel.sortOrder = .recentlyUsed }
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                }
                .accessibilityIdentifier("artifacts.sort.menu")
            }
            .padding()
            
            Divider()
            
            // Artifact List/Grid
            if viewModel.isLoading && viewModel.filteredArtifacts.isEmpty {
                ProgressView("Loading artifacts...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.filteredArtifacts.isEmpty {
                ArtifactEmptyState(viewModel: viewModel)
            } else {
                if viewModel.viewMode == .list {
                    ArtifactListView(viewModel: viewModel)
                } else {
                    ArtifactGridView(viewModel: viewModel)
                }
            }
        }
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct ArtifactListView: View {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    
    var body: some View {
        Table(viewModel.filteredArtifacts, selection: $viewModel.selectedArtifactId) {
            TableColumn("Name") { artifact in
                HStack(spacing: 8) {
                    if viewModel.favoriteArtifacts.contains(where: { $0.name == artifact.name }) {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    }
                    
                    Image(systemName: artifact.category.icon)
                        .foregroundColor(artifact.category.color)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(artifact.displayName)
                            .font(.body)
                        
                        if let description = artifact.description {
                            Text(description)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            .width(min: 200, ideal: 300)
            
            TableColumn("Platform") { artifact in
                HStack(spacing: 4) {
                    Image(systemName: artifact.category.icon)
                        .font(.caption)
                    Text(artifact.category.displayName)
                        .font(.caption)
                }
            }
            .width(min: 80, ideal: 100)
            
            TableColumn("Type") { artifact in
                if let type = artifact.type {
                    Text(type)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                }
            }
            .width(min: 80, ideal: 100)
            
            TableColumn("Sources") { artifact in
                Text("\(artifact.sources?.count ?? 0)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .width(min: 60, ideal: 80)
            
            TableColumn("Actions") { artifact in
                HStack(spacing: 8) {
                    Button(action: { viewModel.toggleFavorite(artifact) }) {
                        Image(systemName: viewModel.isFavorite(artifact) ? "star.fill" : "star")
                            .foregroundColor(.yellow)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("artifacts.favorite.button.\(artifact.name)")
                    
                    Button(action: { viewModel.collectArtifact(artifact) }) {
                        Image(systemName: "play.fill")
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("artifacts.collect.button.\(artifact.name)")
                }
            }
            .width(min: 80, ideal: 100)
        }
        .accessibilityIdentifier("artifacts.list.table")
    }
}

struct ArtifactGridView: View {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [
                GridItem(.adaptive(minimum: 280, maximum: 350))
            ], spacing: 16) {
                ForEach(viewModel.filteredArtifacts) { artifact in
                    ArtifactCard(artifact: artifact, viewModel: viewModel)
                }
            }
            .padding()
        }
        .accessibilityIdentifier("artifacts.grid.view")
    }
}

struct ArtifactCard: View {
    let artifact: ArtifactModel
    @ObservedObject var viewModel: ArtifactManagerViewModel
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: artifact.category.icon)
                    .font(.title2)
                    .foregroundColor(artifact.category.color)
                    .frame(width: 40, height: 40)
                    .background(artifact.category.color.opacity(0.1))
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(artifact.displayName)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(artifact.category.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { viewModel.toggleFavorite(artifact) }) {
                    Image(systemName: viewModel.isFavorite(artifact) ? "star.fill" : "star")
                        .foregroundColor(.yellow)
                }
                .buttonStyle(.plain)
            }
            
            // Description
            if let description = artifact.description {
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)
                    .frame(height: 45, alignment: .top)
            }
            
            // Metadata
            HStack(spacing: 12) {
                if let author = artifact.author {
                    Label(author, systemImage: "person")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let sourceCount = artifact.sources?.count {
                    Label("\(sourceCount) sources", systemImage: "doc.text")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Collect") {
                    viewModel.collectArtifact(artifact)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                
                Button("Details") {
                    viewModel.showArtifactDetails(artifact)
                }
                .controlSize(.small)
                
                Spacer()
                
                Menu {
                    Button("View VQL Source") {
                        viewModel.showVQLSource(artifact)
                    }
                    
                    Button("Add to Collection") {
                        viewModel.addToCollection(artifact)
                    }
                    
                    Divider()
                    
                    if !(artifact.builtIn ?? false) {
                        Button("Edit", role: .destructive) {
                            viewModel.editArtifact(artifact)
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
        .onTapGesture {
            viewModel.selectedArtifactId = artifact.id
        }
        .accessibilityIdentifier("artifacts.card.\(artifact.name)")
    }
}

struct ArtifactEmptyState: View {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Artifacts Found")
                .font(.headline)
            
            Text(viewModel.searchQuery.isEmpty ? "No artifacts match your current filters" : "No artifacts match '\(viewModel.searchQuery)'")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button("Clear Filters") {
                viewModel.resetFilters()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("artifacts.empty.state")
    }
}

// MARK: - Artifact Detail Pane

/// Right panel showing detailed artifact information
struct ArtifactDetailPane: View {
    let artifact: ArtifactModel
    @ObservedObject var viewModel: ArtifactManagerViewModel
    @State private var selectedTab: DetailTab = .overview
    
    enum DetailTab: String, CaseIterable {
        case overview = "Overview"
        case parameters = "Parameters"
        case sources = "Sources"
        case vql = "VQL"
        case dependencies = "Dependencies"
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(artifact.displayName)
                        .font(.title3.bold())
                    
                    HStack {
                        Image(systemName: artifact.category.icon)
                            .foregroundColor(artifact.category.color)
                        Text(artifact.category.displayName)
                        
                        if let type = artifact.type {
                            Text("•")
                            Text(type)
                        }
                    }
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button(action: { viewModel.closeDetailPane() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Tab Bar
            Picker("Tab", selection: $selectedTab) {
                ForEach(DetailTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding()
            
            Divider()
            
            // Tab Content
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    switch selectedTab {
                    case .overview:
                        ArtifactOverviewTab(artifact: artifact)
                    case .parameters:
                        ArtifactParametersTab(artifact: artifact)
                    case .sources:
                        ArtifactSourcesTab(artifact: artifact)
                    case .vql:
                        ArtifactVQLTab(artifact: artifact)
                    case .dependencies:
                        ArtifactDependenciesTab(artifact: artifact, viewModel: viewModel)
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Action Bar
            HStack {
                Button("Add to Favorites") {
                    viewModel.toggleFavorite(artifact)
                }
                .disabled(viewModel.isFavorite(artifact))
                
                Spacer()
                
                Button("Collect Artifact") {
                    viewModel.collectArtifact(artifact)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .accessibilityIdentifier("artifacts.detail.pane")
    }
}

struct ArtifactOverviewTab: View {
    let artifact: ArtifactModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let description = artifact.description {
                GroupBox("Description") {
                    Text(description)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            
            if let author = artifact.author {
                GroupBox("Author") {
                    HStack {
                        Image(systemName: "person.fill")
                        Text(author)
                    }
                }
            }
            
            if let permissions = artifact.requiredPermissions, !permissions.isEmpty {
                GroupBox("Required Permissions") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(permissions, id: \.self) { permission in
                            HStack {
                                Image(systemName: "checkmark.shield")
                                    .foregroundColor(.orange)
                                Text(permission)
                            }
                        }
                    }
                }
            }
            
            GroupBox("Metadata") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Built-in:")
                        Spacer()
                        Text(artifact.builtIn ?? false ? "Yes" : "No")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Sources:")
                        Spacer()
                        Text("\(artifact.sources?.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Parameters:")
                        Spacer()
                        Text("\(artifact.parameters?.count ?? 0)")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }
}

struct ArtifactParametersTab: View {
    let artifact: ArtifactModel
    
    var body: some View {
        if let parameters = artifact.parameters, !parameters.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(parameters.enumerated()), id: \.offset) { index, param in
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(param.name ?? "Parameter \(index + 1)")
                                    .font(.headline)
                                
                                if let type = param.type {
                                    Text(type)
                                        .font(.caption)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(4)
                                }
                            }
                            
                            if let description = param.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let defaultValue = param.defaultValue {
                                HStack {
                                    Text("Default:")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(defaultValue)
                                        .font(.caption.monospaced())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } else {
            Text("No parameters defined")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ArtifactSourcesTab: View {
    let artifact: ArtifactModel
    
    var body: some View {
        if let sources = artifact.sources, !sources.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(sources.enumerated()), id: \.offset) { index, source in
                    GroupBox(source.name ?? "Source \(index + 1)") {
                        VStack(alignment: .leading, spacing: 8) {
                            if let description = source.description {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            if let query = source.query {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("VQL Query:")
                                        .font(.caption.bold())
                                    
                                    Text(query)
                                        .font(.caption.monospaced())
                                        .padding(8)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(4)
                                        .textSelection(.enabled)
                                }
                            }
                            
                            if let precondition = source.precondition {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Precondition:")
                                        .font(.caption.bold())
                                    
                                    Text(precondition)
                                        .font(.caption.monospaced())
                                        .padding(8)
                                        .background(Color(NSColor.textBackgroundColor))
                                        .cornerRadius(4)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
        } else {
            Text("No sources defined")
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}

struct ArtifactVQLTab: View {
    let artifact: ArtifactModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("VQL Source Code")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { copyVQL() }) {
                    Label("Copy", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            
            if let sources = artifact.sources, let firstQuery = sources.first?.query {
                ScrollView([.horizontal, .vertical]) {
                    Text(firstQuery)
                        .font(.system(.caption, design: .monospaced))
                        .padding()
                        .background(Color(NSColor.textBackgroundColor))
                        .cornerRadius(8)
                        .textSelection(.enabled)
                }
                .frame(maxHeight: 400)
            } else {
                Text("No VQL source available")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func copyVQL() {
        if let sources = artifact.sources, let firstQuery = sources.first?.query {
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(firstQuery, forType: .string)
        }
    }
}

struct ArtifactDependenciesTab: View {
    let artifact: ArtifactModel
    @ObservedObject var viewModel: ArtifactManagerViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Artifact Dependencies")
                .font(.headline)
            
            if viewModel.dependencies(for: artifact).isEmpty {
                Text("This artifact has no dependencies")
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(viewModel.dependencies(for: artifact)) { dependency in
                    HStack {
                        Image(systemName: "link")
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading) {
                            Text(dependency.displayName)
                                .font(.body)
                            Text(dependency.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("View") {
                            viewModel.showArtifactDetails(dependency)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }
            }
        }
    }
}

// MARK: - MCP Incident Assistant Pane

/// MCP-powered incident response assistant
struct MCPIncidentAssistantPane: View {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    @State private var incidentType: IncidentType = .ransomware
    @State private var platform: ArtifactPlatform = .windows
    @State private var urgency: IncidentUrgency = .high
    @State private var scope: CollectionScope = .standard
    @State private var isGenerating = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Label("AI Incident Assistant", systemImage: "brain.head.profile")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { viewModel.closeMCPAssistant() }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Instructions
                    GroupBox {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Get AI-powered artifact recommendations", systemImage: "sparkles")
                                .font(.subheadline.bold())
                            
                            Text("Select your incident scenario below, and the AI assistant will recommend the most relevant Velociraptor artifacts for your investigation.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Incident Configuration
                    GroupBox("Incident Configuration") {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Incident Type")
                                    .font(.caption.bold())
                                
                                Picker("", selection: $incidentType) {
                                    ForEach(IncidentType.allCases) { type in
                                        Label(type.displayName, systemImage: type.icon)
                                            .tag(type)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accessibilityIdentifier("artifacts.mcp.incident_type")
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Platform")
                                    .font(.caption.bold())
                                
                                Picker("", selection: $platform) {
                                    ForEach(ArtifactPlatform.allCases) { plat in
                                        Text(plat.displayName).tag(plat)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityIdentifier("artifacts.mcp.platform")
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Urgency")
                                    .font(.caption.bold())
                                
                                Picker("", selection: $urgency) {
                                    ForEach(IncidentUrgency.allCases) { urg in
                                        Label(urg.displayName, systemImage: urg.icon)
                                            .tag(urg)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .accessibilityIdentifier("artifacts.mcp.urgency")
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Collection Scope")
                                    .font(.caption.bold())
                                
                                Picker("", selection: $scope) {
                                    ForEach(CollectionScope.allCases) { sc in
                                        Text(sc.displayName).tag(sc)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accessibilityIdentifier("artifacts.mcp.scope")
                                
                                Text(scope.description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Generate Button
                    Button(action: generateRecommendations) {
                        HStack {
                            if isGenerating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .padding(.trailing, 4)
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isGenerating ? "Generating..." : "Get Recommendations")
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating)
                    .accessibilityIdentifier("artifacts.mcp.generate.button")
                    
                    // Recommendations List
                    if !viewModel.mcpRecommendations.isEmpty {
                        GroupBox("Recommended Artifacts (\(viewModel.mcpRecommendations.count))") {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.mcpRecommendations) { rec in
                                    MCPRecommendationRow(recommendation: rec, viewModel: viewModel)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        HStack {
                            Button("Clear") {
                                viewModel.mcpRecommendations = []
                            }
                            
                            Spacer()
                            
                            Button("Add All to Collection") {
                                viewModel.addAllRecommendationsToCollection()
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }
                .padding()
            }
        }
        .accessibilityIdentifier("artifacts.mcp.assistant.pane")
    }
    
    private func generateRecommendations() {
        Task {
            isGenerating = true
            defer { isGenerating = false }
            
            await viewModel.generateMCPRecommendations(
                incidentType: incidentType,
                platform: platform,
                urgency: urgency,
                scope: scope
            )
        }
    }
}

struct MCPRecommendationRow: View {
    let recommendation: ArtifactRecommendation
    @ObservedObject var viewModel: ArtifactManagerViewModel
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Priority Badge
            Circle()
                .fill(recommendation.priority.color)
                .frame(width: 24, height: 24)
                .overlay(
                    Text("\(recommendation.priority.rawValue)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recommendation.artifact.displayName)
                    .font(.body.bold())
                
                if let rationale = recommendation.rationale {
                    Text(rationale)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    if let estimatedTime = recommendation.estimatedCollectionTime {
                        Label("\(estimatedTime)", systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                    Label(recommendation.artifact.category.displayName, systemImage: recommendation.artifact.category.icon)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("Add") {
                viewModel.addRecommendationToCollection(recommendation)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .padding(.vertical, 8)
    }
}

// MARK: - MCP Incident Assistant Sheet

struct MCPIncidentAssistantSheet: View {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack {
            MCPIncidentAssistantPane(viewModel: viewModel)
            
            HStack {
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
        }
        .frame(width: 600, height: 700)
    }
}

// MARK: - Artifact Import Sheet

struct ArtifactImportSheet: View {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var yamlContent = ""
    @State private var importError: String?
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Import Custom Artifact")
                .font(.headline)
            
            Text("Paste your artifact YAML definition below:")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $yamlContent)
                .font(.system(.body, design: .monospaced))
                .frame(height: 300)
                .border(Color.secondary.opacity(0.3))
                .accessibilityIdentifier("artifacts.import.yaml.editor")
            
            if let error = importError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                
                Spacer()
                
                Button("Import") {
                    Task {
                        do {
                            try await viewModel.importArtifact(yaml: yamlContent)
                            dismiss()
                        } catch {
                            importError = error.localizedDescription
                        }
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(yamlContent.isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
        .frame(width: 600, height: 500)
        .accessibilityIdentifier("artifacts.import.sheet")
    }
}

// MARK: - Toolbar

struct ArtifactManagerToolbar: ToolbarContent {
    @ObservedObject var viewModel: ArtifactManagerViewModel
    @Binding var showImportSheet: Bool
    @Binding var showIncidentAssistant: Bool
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { showIncidentAssistant = true }) {
                Label("AI Assistant", systemImage: "brain.head.profile")
            }
            .accessibilityIdentifier("artifacts.toolbar.assistant.button")
            
            Button(action: { showImportSheet = true }) {
                Label("Import Artifact", systemImage: "square.and.arrow.down")
            }
            .accessibilityIdentifier("artifacts.toolbar.import.button")
            
            Button(action: { Task { await viewModel.refreshArtifacts() } }) {
                Label("Refresh", systemImage: "arrow.clockwise")
            }
            .disabled(viewModel.isLoading)
            .accessibilityIdentifier("artifacts.toolbar.refresh.button")
        }
    }
}

// MARK: - Artifact Filter Pill

struct ArtifactFilterPill: View {
    let title: String
    var icon: String? = nil
    var count: Int? = nil
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.caption)
                }
                
                Text(title)
                    .font(.caption)
                
                if let count = count {
                    Text("\(count)")
                        .font(.caption)
                        .padding(.horizontal, 4)
                        .background(isSelected ? Color.white.opacity(0.3) : Color.secondary.opacity(0.2))
                        .cornerRadius(3)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            .foregroundColor(isSelected ? .white : .primary)
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    ArtifactManagerView()
        .frame(width: 1200, height: 800)
}
