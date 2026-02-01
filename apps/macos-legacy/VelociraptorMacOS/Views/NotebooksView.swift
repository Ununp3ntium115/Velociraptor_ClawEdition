//
//  NotebooksView.swift
//  VelociraptorMacOS
//
//  Investigation notebooks for documentation and collaboration
//  Implements Gap 0x0A: Notebooks
//

import SwiftUI

// MARK: - Notebooks View

/// Main notebooks interface with sidebar and editor
struct NotebooksView: View {
    @StateObject private var viewModel = NotebooksViewModel()
    
    var body: some View {
        HSplitView {
            // Left: Notebook list
            NotebooksSidebar(viewModel: viewModel)
                .frame(minWidth: 250, maxWidth: 300)
            
            // Right: Editor
            NotebookEditor(viewModel: viewModel)
                .frame(minWidth: 500)
        }
        .navigationTitle("Investigation Notebooks")
        .toolbar {
            NotebooksToolbar(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showNewNotebookSheet) {
            NewNotebookSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showExportSheet) {
            ExportNotebookSheet(viewModel: viewModel)
        }
        .accessibilityIdentifier("notebooks_view")
    }
}

// MARK: - Notebooks Sidebar

struct NotebooksSidebar: View {
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search notebooks...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .accessibilityIdentifier("notebooks_search")
            }
            .padding(8)
            .background(Color(NSColor.textBackgroundColor))
            .cornerRadius(6)
            .padding()
            
            Divider()
            
            // Notebook list
            List(selection: $viewModel.selectedNotebookId) {
                Section("Recent") {
                    ForEach(viewModel.recentNotebooks) { notebook in
                        NotebookRow(notebook: notebook)
                            .tag(notebook.id)
                    }
                }
                
                Section("All Notebooks") {
                    ForEach(viewModel.filteredNotebooks) { notebook in
                        NotebookRow(notebook: notebook)
                            .tag(notebook.id)
                            .contextMenu {
                                NotebookContextMenu(notebook: notebook, viewModel: viewModel)
                            }
                    }
                }
            }
            .listStyle(.sidebar)
            .accessibilityIdentifier("notebooks_list")
            
            Divider()
            
            // Quick actions
            HStack {
                Button(action: { viewModel.showNewNotebookSheet = true }) {
                    Label("New", systemImage: "plus")
                }
                .buttonStyle(.borderless)
                
                Spacer()
                
                Menu {
                    Button("Sort by Date") { viewModel.sortOrder = .date }
                    Button("Sort by Name") { viewModel.sortOrder = .name }
                    Button("Sort by Hunt") { viewModel.sortOrder = .hunt }
                } label: {
                    Image(systemName: "arrow.up.arrow.down")
                }
                .menuStyle(.borderlessButton)
            }
            .padding()
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct NotebookRow: View {
    let notebook: Notebook
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: notebook.type.icon)
                .foregroundColor(notebook.type.color)
                .frame(width: 20)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(notebook.name)
                    .lineLimit(1)
                
                HStack(spacing: 4) {
                    if let huntId = notebook.huntId {
                        Text(huntId)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(3)
                    }
                    
                    Text(notebook.modifiedFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .accessibilityIdentifier("notebook_row_\(notebook.id)")
    }
}

struct NotebookContextMenu: View {
    let notebook: Notebook
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        Button("Duplicate") {
            viewModel.duplicateNotebook(notebook)
        }
        Button("Export...") {
            viewModel.selectedNotebookId = notebook.id
            viewModel.showExportSheet = true
        }
        Divider()
        Button("Delete", role: .destructive) {
            viewModel.deleteNotebook(notebook)
        }
    }
}

// MARK: - Notebook Editor

struct NotebookEditor: View {
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            if let notebook = viewModel.selectedNotebook {
                // Header
                NotebookEditorHeader(notebook: notebook, viewModel: viewModel)
                
                Divider()
                
                // Cells
                ScrollView {
                    LazyVStack(spacing: 16) {
                        ForEach(viewModel.cells) { cell in
                            NotebookCell(cell: cell, viewModel: viewModel)
                        }
                        
                        // Add cell button
                        AddCellButton(viewModel: viewModel)
                    }
                    .padding()
                }
                
                Divider()
                
                // Status bar
                NotebookStatusBar(viewModel: viewModel)
            } else {
                NotebookEmptyState(viewModel: viewModel)
            }
        }
        .accessibilityIdentifier("notebook_editor")
    }
}

struct NotebookEditorHeader: View {
    let notebook: Notebook
    @ObservedObject var viewModel: NotebooksViewModel
    @State private var isEditingTitle = false
    @State private var editedTitle = ""
    
    var body: some View {
        HStack {
            Image(systemName: notebook.type.icon)
                .font(.title2)
                .foregroundColor(notebook.type.color)
            
            if isEditingTitle {
                TextField("Notebook Name", text: $editedTitle, onCommit: {
                    viewModel.renameNotebook(notebook, to: editedTitle)
                    isEditingTitle = false
                })
                .textFieldStyle(.roundedBorder)
                .frame(maxWidth: 300)
            } else {
                Text(notebook.name)
                    .font(.headline)
                    .onTapGesture(count: 2) {
                        editedTitle = notebook.name
                        isEditingTitle = true
                    }
            }
            
            if let huntId = notebook.huntId {
                Text("Hunt: \(huntId)")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Spacer()
            
            // Collaborators
            HStack(spacing: -8) {
                ForEach(notebook.collaborators.prefix(3), id: \.self) { collaborator in
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text(String(collaborator.prefix(1)))
                                .font(.caption)
                                .foregroundColor(.white)
                        )
                }
                
                if notebook.collaborators.count > 3 {
                    Circle()
                        .fill(Color.gray)
                        .frame(width: 28, height: 28)
                        .overlay(
                            Text("+\(notebook.collaborators.count - 3)")
                                .font(.caption2)
                                .foregroundColor(.white)
                        )
                }
            }
            
            Button(action: { viewModel.shareNotebook() }) {
                Image(systemName: "person.badge.plus")
            }
            .accessibilityIdentifier("notebook_share_button")
        }
        .padding()
    }
}

// MARK: - Notebook Cell

struct NotebookCell: View {
    let cell: NotebookCell_
    @ObservedObject var viewModel: NotebooksViewModel
    @State private var isEditing = false
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Cell header
            HStack {
                Image(systemName: cell.type.icon)
                    .foregroundColor(cell.type.color)
                
                Text(cell.type.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if isHovered {
                    CellActions(cell: cell, viewModel: viewModel)
                }
            }
            
            // Cell content
            switch cell.type {
            case .markdown:
                MarkdownCellContent(cell: cell, isEditing: $isEditing, viewModel: viewModel)
            case .vql:
                VQLCellContent(cell: cell, viewModel: viewModel)
            case .artifact:
                ArtifactCellContent(cell: cell, viewModel: viewModel)
            case .timeline:
                TimelineCellContent(cell: cell, viewModel: viewModel)
            case .evidence:
                EvidenceCellContent(cell: cell, viewModel: viewModel)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isHovered ? Color.accentColor.opacity(0.5) : Color.clear, lineWidth: 1)
        )
        .onHover { isHovered = $0 }
        .accessibilityIdentifier("notebook_cell_\(cell.id)")
    }
}

struct CellActions: View {
    let cell: NotebookCell_
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        HStack(spacing: 4) {
            Button(action: { viewModel.moveCell(cell, direction: .up) }) {
                Image(systemName: "chevron.up")
            }
            .buttonStyle(.borderless)
            
            Button(action: { viewModel.moveCell(cell, direction: .down) }) {
                Image(systemName: "chevron.down")
            }
            .buttonStyle(.borderless)
            
            if cell.type == .vql {
                Button(action: { Task { await viewModel.executeCell(cell) } }) {
                    Image(systemName: "play.fill")
                }
                .buttonStyle(.borderless)
            }
            
            Menu {
                Button("Duplicate") { viewModel.duplicateCell(cell) }
                Button("Copy") { viewModel.copyCell(cell) }
                Divider()
                Button("Delete", role: .destructive) { viewModel.deleteCell(cell) }
            } label: {
                Image(systemName: "ellipsis")
            }
            .menuStyle(.borderlessButton)
        }
    }
}

// MARK: - Cell Content Views

struct MarkdownCellContent: View {
    let cell: NotebookCell_
    @Binding var isEditing: Bool
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        if isEditing {
            TextEditor(text: Binding(
                get: { cell.content },
                set: { viewModel.updateCellContent(cell, content: $0) }
            ))
            .font(.system(.body, design: .monospaced))
            .frame(minHeight: 100)
            .onSubmit { isEditing = false }
        } else {
            Text(cell.content.isEmpty ? "Click to edit..." : cell.content)
                .frame(maxWidth: .infinity, alignment: .leading)
                .foregroundColor(cell.content.isEmpty ? .secondary : .primary)
                .onTapGesture { isEditing = true }
        }
    }
}

struct VQLCellContent: View {
    let cell: NotebookCell_
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Query
            Text(cell.content)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(4)
            
            // Results
            if let results = cell.results {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Results (\(results.count) rows)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ScrollView(.horizontal, showsIndicators: true) {
                        NotebookVQLResultsTable(results: results)
                    }
                    .frame(maxHeight: 200)
                }
            }
            
            // Execution info
            if let executionTime = cell.executionTime {
                Text("Executed in \(String(format: "%.2f", executionTime))s")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct NotebookVQLResultsTable: View {
    let results: [[String: String]]
    
    var body: some View {
        if let first = results.first {
            let columns = Array(first.keys)
            
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack(spacing: 0) {
                    ForEach(columns, id: \.self) { column in
                        Text(column)
                            .font(.caption.bold())
                            .frame(width: 150, alignment: .leading)
                            .padding(4)
                            .background(Color(NSColor.controlBackgroundColor))
                    }
                }
                
                Divider()
                
                // Rows
                ForEach(Array(results.prefix(50).enumerated()), id: \.offset) { _, row in
                    HStack(spacing: 0) {
                        ForEach(columns, id: \.self) { column in
                            Text(row[column] ?? "-")
                                .font(.caption)
                                .frame(width: 150, alignment: .leading)
                                .padding(4)
                        }
                    }
                }
            }
        }
    }
}

struct ArtifactCellContent: View {
    let cell: NotebookCell_
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(cell.content)
                .font(.headline)
            
            if let metadata = cell.metadata {
                HStack {
                    Label(metadata["source"] ?? "Unknown", systemImage: "desktopcomputer")
                    Label(metadata["collected"] ?? "-", systemImage: "clock")
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
    }
}

struct TimelineCellContent: View {
    let cell: NotebookCell_
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Timeline Events")
                .font(.headline)
            
            // Placeholder timeline visualization
            Rectangle()
                .fill(Color.blue.opacity(0.1))
                .frame(height: 100)
                .overlay(
                    Text("Timeline visualization")
                        .foregroundColor(.secondary)
                )
                .cornerRadius(4)
        }
    }
}

struct EvidenceCellContent: View {
    let cell: NotebookCell_
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        HStack {
            Image(systemName: "doc.fill")
                .font(.title)
                .foregroundColor(.orange)
            
            VStack(alignment: .leading) {
                Text(cell.content)
                    .font(.body)
                
                if let metadata = cell.metadata {
                    Text("Hash: \(metadata["hash"] ?? "N/A")")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            Button("View") {
                viewModel.viewEvidence(cell)
            }
        }
    }
}

// MARK: - Add Cell Button

struct AddCellButton: View {
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        Menu {
            Button(action: { viewModel.addCell(type: .markdown) }) {
                Label("Markdown", systemImage: "text.alignleft")
            }
            Button(action: { viewModel.addCell(type: .vql) }) {
                Label("VQL Query", systemImage: "terminal")
            }
            Button(action: { viewModel.addCell(type: .artifact) }) {
                Label("Artifact Reference", systemImage: "doc.on.doc")
            }
            Button(action: { viewModel.addCell(type: .timeline) }) {
                Label("Timeline", systemImage: "clock")
            }
            Button(action: { viewModel.addCell(type: .evidence) }) {
                Label("Evidence", systemImage: "tray.full")
            }
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Add Cell")
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5]))
                    .foregroundColor(.secondary.opacity(0.5))
            )
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("add_cell_button")
    }
}

// MARK: - Empty State

struct NotebookEmptyState: View {
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "book.closed")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Notebook Selected")
                .font(.headline)
            
            Text("Select a notebook from the sidebar or create a new one")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { viewModel.showNewNotebookSheet = true }) {
                Label("New Notebook", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("notebook_empty_state")
    }
}

// MARK: - Status Bar

struct NotebookStatusBar: View {
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some View {
        HStack {
            Text("\(viewModel.cells.count) cells")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            if viewModel.isSaving {
                ProgressView()
                    .scaleEffect(0.5)
                Text("Saving...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if let lastSaved = viewModel.lastSaved {
                Text("Saved \(lastSaved, style: .relative) ago")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 6)
    }
}

// MARK: - Toolbar

struct NotebooksToolbar: ToolbarContent {
    @ObservedObject var viewModel: NotebooksViewModel
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { viewModel.showNewNotebookSheet = true }) {
                Label("New", systemImage: "plus")
            }
            .accessibilityIdentifier("new_notebook_button")
            
            Button(action: { viewModel.showExportSheet = true }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.selectedNotebook == nil)
            .accessibilityIdentifier("export_notebook_button")
        }
    }
}

// MARK: - Sheets

struct NewNotebookSheet: View {
    @ObservedObject var viewModel: NotebooksViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var type: NotebookType = .investigation
    @State private var huntId = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("New Notebook")
                .font(.headline)
            
            Form {
                TextField("Name", text: $name)
                
                Picker("Type", selection: $type) {
                    ForEach(NotebookType.allCases) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                
                TextField("Hunt ID (optional)", text: $huntId)
            }
            .frame(width: 300)
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Create") {
                    viewModel.createNotebook(name: name, type: type, huntId: huntId.isEmpty ? nil : huntId)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
        .accessibilityIdentifier("new_notebook_sheet")
    }
}

struct ExportNotebookSheet: View {
    @ObservedObject var viewModel: NotebooksViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var format: ExportFormat = .markdown
    @State private var includeResults = true
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Export Notebook")
                .font(.headline)
            
            Form {
                Picker("Format", selection: $format) {
                    Text("Markdown").tag(ExportFormat.markdown)
                    Text("HTML").tag(ExportFormat.html)
                    Text("PDF").tag(ExportFormat.pdf)
                    Text("JSON").tag(ExportFormat.json)
                }
                
                Toggle("Include VQL Results", isOn: $includeResults)
            }
            .frame(width: 300)
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Export") {
                    viewModel.exportNotebook(format: format, includeResults: includeResults)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(width: 400)
        .accessibilityIdentifier("export_notebook_sheet")
    }
}

// MARK: - Models

enum NotebookType: String, CaseIterable, Identifiable {
    case investigation, hunt, incident, template
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .investigation: return "Investigation"
        case .hunt: return "Hunt Analysis"
        case .incident: return "Incident Response"
        case .template: return "Template"
        }
    }
    
    var icon: String {
        switch self {
        case .investigation: return "magnifyingglass"
        case .hunt: return "binoculars"
        case .incident: return "exclamationmark.triangle"
        case .template: return "doc.on.doc"
        }
    }
    
    var color: Color {
        switch self {
        case .investigation: return .blue
        case .hunt: return .green
        case .incident: return .red
        case .template: return .gray
        }
    }
}

enum CellType: String, CaseIterable {
    case markdown, vql, artifact, timeline, evidence
    
    var displayName: String {
        switch self {
        case .markdown: return "Markdown"
        case .vql: return "VQL Query"
        case .artifact: return "Artifact"
        case .timeline: return "Timeline"
        case .evidence: return "Evidence"
        }
    }
    
    var icon: String {
        switch self {
        case .markdown: return "text.alignleft"
        case .vql: return "terminal"
        case .artifact: return "doc.on.doc"
        case .timeline: return "clock"
        case .evidence: return "tray.full"
        }
    }
    
    var color: Color {
        switch self {
        case .markdown: return .primary
        case .vql: return .green
        case .artifact: return .blue
        case .timeline: return .purple
        case .evidence: return .orange
        }
    }
}

enum ExportFormat: String {
    case markdown, html, pdf, json
}

enum NotebookSortOrder: String {
    case date, name, hunt
}

enum CellMoveDirection {
    case up, down
}

struct Notebook: Identifiable {
    var id: String
    var name: String
    var type: NotebookType
    var huntId: String?
    var collaborators: [String]
    var created: Date
    var modified: Date
    
    var modifiedFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: modified, relativeTo: Date())
    }
}

struct NotebookCell_: Identifiable {
    var id: String
    var type: CellType
    var content: String
    var results: [[String: String]]?
    var executionTime: Double?
    var metadata: [String: String]?
}

// MARK: - View Model

@MainActor
class NotebooksViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published var notebooks: [Notebook] = Notebook.sampleNotebooks
    @Published var selectedNotebookId: String?
    @Published var cells: [NotebookCell_] = []
    
    @Published var searchText = ""
    @Published var sortOrder: NotebookSortOrder = .date
    
    @Published var showNewNotebookSheet = false
    @Published var showExportSheet = false
    
    @Published var isSaving = false
    @Published var lastSaved: Date?
    
    // MARK: - Computed Properties
    
    var selectedNotebook: Notebook? {
        notebooks.first { $0.id == selectedNotebookId }
    }
    
    var recentNotebooks: [Notebook] {
        Array(notebooks.sorted { $0.modified > $1.modified }.prefix(3))
    }
    
    var filteredNotebooks: [Notebook] {
        var result = notebooks
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                ($0.huntId?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        switch sortOrder {
        case .date:
            result.sort { $0.modified > $1.modified }
        case .name:
            result.sort { $0.name < $1.name }
        case .hunt:
            result.sort { ($0.huntId ?? "") < ($1.huntId ?? "") }
        }
        
        return result
    }
    
    // MARK: - Initialization
    
    init() {
        // Load sample cells for first notebook
        if let first = notebooks.first {
            selectedNotebookId = first.id
            cells = NotebookCell_.sampleCells
        }
    }
    
    // MARK: - Notebook Operations
    
    func createNotebook(name: String, type: NotebookType, huntId: String?) {
        let notebook = Notebook(
            id: UUID().uuidString,
            name: name,
            type: type,
            huntId: huntId,
            collaborators: [],
            created: Date(),
            modified: Date()
        )
        notebooks.insert(notebook, at: 0)
        selectedNotebookId = notebook.id
        cells = []
    }
    
    func renameNotebook(_ notebook: Notebook, to name: String) {
        guard let index = notebooks.firstIndex(where: { $0.id == notebook.id }) else { return }
        notebooks[index].name = name
        notebooks[index].modified = Date()
    }
    
    func duplicateNotebook(_ notebook: Notebook) {
        var duplicate = notebook
        duplicate.id = UUID().uuidString
        duplicate.name = "\(notebook.name) (Copy)"
        duplicate.created = Date()
        duplicate.modified = Date()
        notebooks.insert(duplicate, at: 0)
    }
    
    func deleteNotebook(_ notebook: Notebook) {
        notebooks.removeAll { $0.id == notebook.id }
        if selectedNotebookId == notebook.id {
            selectedNotebookId = notebooks.first?.id
        }
    }
    
    func shareNotebook() {
        // TODO: Implement sharing
    }
    
    func exportNotebook(format: ExportFormat, includeResults: Bool) {
        // TODO: Implement export
    }
    
    // MARK: - Cell Operations
    
    func addCell(type: CellType) {
        let cell = NotebookCell_(
            id: UUID().uuidString,
            type: type,
            content: "",
            results: nil,
            executionTime: nil,
            metadata: nil
        )
        cells.append(cell)
        autoSave()
    }
    
    func updateCellContent(_ cell: NotebookCell_, content: String) {
        guard let index = cells.firstIndex(where: { $0.id == cell.id }) else { return }
        cells[index].content = content
        autoSave()
    }
    
    func moveCell(_ cell: NotebookCell_, direction: CellMoveDirection) {
        guard let index = cells.firstIndex(where: { $0.id == cell.id }) else { return }
        
        switch direction {
        case .up:
            guard index > 0 else { return }
            cells.swapAt(index, index - 1)
        case .down:
            guard index < cells.count - 1 else { return }
            cells.swapAt(index, index + 1)
        }
        autoSave()
    }
    
    func duplicateCell(_ cell: NotebookCell_) {
        guard let index = cells.firstIndex(where: { $0.id == cell.id }) else { return }
        var duplicate = cell
        duplicate.id = UUID().uuidString
        cells.insert(duplicate, at: index + 1)
        autoSave()
    }
    
    func copyCell(_ cell: NotebookCell_) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(cell.content, forType: .string)
    }
    
    func deleteCell(_ cell: NotebookCell_) {
        cells.removeAll { $0.id == cell.id }
        autoSave()
    }
    
    func executeCell(_ cell: NotebookCell_) async {
        guard let index = cells.firstIndex(where: { $0.id == cell.id }) else { return }
        
        // Simulate VQL execution
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        cells[index].results = [
            ["Timestamp": "2026-01-31 21:00:00", "Process": "notepad.exe", "PID": "1234"],
            ["Timestamp": "2026-01-31 21:01:00", "Process": "cmd.exe", "PID": "5678"],
        ]
        cells[index].executionTime = 1.25
        autoSave()
    }
    
    func viewEvidence(_ cell: NotebookCell_) {
        // TODO: Open evidence viewer
    }
    
    // MARK: - Auto-save
    
    private func autoSave() {
        isSaving = true
        
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000)
            isSaving = false
            lastSaved = Date()
            
            // Update notebook modified date
            if let id = selectedNotebookId,
               let index = notebooks.firstIndex(where: { $0.id == id }) {
                notebooks[index].modified = Date()
            }
        }
    }
}

// MARK: - Sample Data

extension Notebook {
    static let sampleNotebooks: [Notebook] = [
        Notebook(
            id: "nb-1",
            name: "Ransomware Investigation - ACME Corp",
            type: .investigation,
            huntId: "H.ABC123",
            collaborators: ["Alice", "Bob"],
            created: Date().addingTimeInterval(-86400 * 5),
            modified: Date().addingTimeInterval(-3600)
        ),
        Notebook(
            id: "nb-2",
            name: "Lateral Movement Hunt",
            type: .hunt,
            huntId: "H.DEF456",
            collaborators: ["Charlie"],
            created: Date().addingTimeInterval(-86400 * 3),
            modified: Date().addingTimeInterval(-7200)
        ),
        Notebook(
            id: "nb-3",
            name: "IR Playbook - Phishing",
            type: .incident,
            huntId: nil,
            collaborators: [],
            created: Date().addingTimeInterval(-86400 * 10),
            modified: Date().addingTimeInterval(-86400)
        ),
        Notebook(
            id: "nb-4",
            name: "Triage Template",
            type: .template,
            huntId: nil,
            collaborators: [],
            created: Date().addingTimeInterval(-86400 * 30),
            modified: Date().addingTimeInterval(-86400 * 7)
        ),
    ]
}

extension NotebookCell_ {
    static let sampleCells: [NotebookCell_] = [
        NotebookCell_(
            id: "cell-1",
            type: .markdown,
            content: "# Investigation Summary\n\nThis notebook documents the ransomware investigation for ACME Corp.\n\n## Key Findings\n- Initial access via phishing email\n- Lateral movement using PsExec\n- Data exfiltration before encryption",
            results: nil,
            executionTime: nil,
            metadata: nil
        ),
        NotebookCell_(
            id: "cell-2",
            type: .vql,
            content: "SELECT Timestamp, EventID, Message FROM Artifact.Windows.EventLogs.Evtx() WHERE EventID IN (4624, 4625) LIMIT 100",
            results: [
                ["Timestamp": "2026-01-30 14:23:45", "EventID": "4624", "Message": "Successful logon"],
                ["Timestamp": "2026-01-30 14:24:12", "EventID": "4625", "Message": "Failed logon attempt"],
            ],
            executionTime: 2.34,
            metadata: nil
        ),
        NotebookCell_(
            id: "cell-3",
            type: .artifact,
            content: "Windows.System.Pslist",
            results: nil,
            executionTime: nil,
            metadata: ["source": "WKS-001", "collected": "2026-01-30 15:00:00"]
        ),
    ]
}

// MARK: - Preview

#Preview {
    NotebooksView()
        .frame(width: 1000, height: 700)
}
