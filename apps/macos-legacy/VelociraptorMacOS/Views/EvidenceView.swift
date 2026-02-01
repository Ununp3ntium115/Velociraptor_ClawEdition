//
//  EvidenceView.swift
//  VelociraptorMacOS
//
//  Evidence management and chain of custody interface
//  Implements Gap 0x0C: Evidence Management
//

import SwiftUI

// MARK: - Evidence View

/// Main evidence management interface
struct EvidenceView: View {
    @StateObject private var viewModel = EvidenceViewModel()
    
    var body: some View {
        HSplitView {
            // Left: Evidence list
            EvidenceSidebar(viewModel: viewModel)
                .frame(minWidth: 300, maxWidth: 400)
            
            // Right: Evidence details
            EvidenceDetailPane(viewModel: viewModel)
                .frame(minWidth: 500)
        }
        .navigationTitle("Evidence Management")
        .toolbar {
            EvidenceToolbar(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddEvidenceSheet(viewModel: viewModel)
        }
        .sheet(isPresented: $viewModel.showChainOfCustodySheet) {
            ChainOfCustodySheet(viewModel: viewModel)
        }
        .accessibilityIdentifier("evidence_view")
    }
}

// MARK: - Evidence Sidebar

struct EvidenceSidebar: View {
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some View {
        VStack(spacing: 0) {
            // Search and filter
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search evidence...", text: $viewModel.searchText)
                        .textFieldStyle(.plain)
                }
                .padding(8)
                .background(Color(NSColor.textBackgroundColor))
                .cornerRadius(6)
                
                // Filter chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        FilterChip(title: "All", isSelected: viewModel.typeFilter == nil) {
                            viewModel.typeFilter = nil
                        }
                        ForEach(EvidenceType.allCases) { type in
                            FilterChip(title: type.displayName, isSelected: viewModel.typeFilter == type) {
                                viewModel.typeFilter = type
                            }
                        }
                    }
                }
            }
            .padding()
            
            Divider()
            
            // Evidence list
            List(selection: $viewModel.selectedEvidenceId) {
                ForEach(viewModel.filteredEvidence) { evidence in
                    EvidenceRow(evidence: evidence)
                        .tag(evidence.id)
                }
            }
            .listStyle(.inset)
            .accessibilityIdentifier("evidence_list")
            
            Divider()
            
            // Stats
            EvidenceStats(viewModel: viewModel)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(isSelected ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct EvidenceRow: View {
    let evidence: EvidenceItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Type icon
            Image(systemName: evidence.type.icon)
                .font(.title2)
                .foregroundColor(evidence.type.color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(evidence.name)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    Label(evidence.caseId, systemImage: "folder")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(evidence.collectedFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tags
                HStack(spacing: 4) {
                    ForEach(evidence.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption2)
                            .padding(.horizontal, 4)
                            .padding(.vertical, 1)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(3)
                    }
                }
            }
            
            Spacer()
            
            // Status
            EvidenceStatusBadge(status: evidence.status)
        }
        .padding(.vertical, 4)
        .accessibilityIdentifier("evidence_row_\(evidence.id)")
    }
}

struct EvidenceStatusBadge: View {
    let status: EvidenceStatus
    
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
        .cornerRadius(8)
    }
}

struct EvidenceStats: View {
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("\(viewModel.evidence.count)")
                    .font(.headline)
                Text("Items")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .center) {
                Text(viewModel.totalSizeFormatted)
                    .font(.headline)
                Text("Total Size")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing) {
                Text("\(viewModel.evidence.filter { $0.status == .verified }.count)")
                    .font(.headline)
                Text("Verified")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
    }
}

// MARK: - Evidence Detail Pane

struct EvidenceDetailPane: View {
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some View {
        if let evidence = viewModel.selectedEvidence {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    EvidenceDetailHeader(evidence: evidence, viewModel: viewModel)
                    
                    Divider()
                    
                    // Hash verification
                    HashVerificationSection(evidence: evidence, viewModel: viewModel)
                    
                    Divider()
                    
                    // Metadata
                    EvidenceMetadataSection(evidence: evidence)
                    
                    Divider()
                    
                    // Chain of custody
                    ChainOfCustodySection(evidence: evidence, viewModel: viewModel)
                    
                    Divider()
                    
                    // Related items
                    RelatedEvidenceSection(evidence: evidence, viewModel: viewModel)
                }
                .padding()
            }
            .accessibilityIdentifier("evidence_detail")
        } else {
            EvidenceEmptyState(viewModel: viewModel)
        }
    }
}

struct EvidenceDetailHeader: View {
    let evidence: EvidenceItem
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: evidence.type.icon)
                .font(.system(size: 48))
                .foregroundColor(evidence.type.color)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(evidence.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                HStack {
                    EvidenceStatusBadge(status: evidence.status)
                    
                    Label(evidence.type.displayName, systemImage: evidence.type.icon)
                        .font(.caption)
                    
                    Text("•")
                    
                    Text(evidence.sizeFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Tags
                HStack {
                    ForEach(evidence.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                    
                    Button(action: { viewModel.addTag() }) {
                        Image(systemName: "plus")
                            .font(.caption)
                    }
                    .buttonStyle(.borderless)
                }
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Button("Download") {
                    viewModel.downloadEvidence(evidence)
                }
                .buttonStyle(.borderedProminent)
                
                Button("Verify Hash") {
                    Task { await viewModel.verifyHash(evidence) }
                }
            }
        }
    }
}

struct HashVerificationSection: View {
    let evidence: EvidenceItem
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hash Verification")
                .font(.headline)
            
            VStack(spacing: 8) {
                HashRow(algorithm: "MD5", hash: evidence.md5Hash, verified: evidence.hashVerified)
                HashRow(algorithm: "SHA1", hash: evidence.sha1Hash, verified: evidence.hashVerified)
                HashRow(algorithm: "SHA256", hash: evidence.sha256Hash, verified: evidence.hashVerified)
            }
            
            if evidence.hashVerified {
                HStack {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("Hash verified on \(evidence.verifiedAtFormatted ?? "N/A")")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct HashRow: View {
    let algorithm: String
    let hash: String?
    let verified: Bool
    
    var body: some View {
        HStack {
            Text(algorithm)
                .font(.caption)
                .frame(width: 60, alignment: .leading)
            
            Text(hash ?? "Not calculated")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(hash != nil ? .primary : .secondary)
                .lineLimit(1)
                .truncationMode(.middle)
            
            Spacer()
            
            if verified {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
            
            Button(action: {
                if let hash = hash {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(hash, forType: .string)
                }
            }) {
                Image(systemName: "doc.on.doc")
            }
            .buttonStyle(.borderless)
            .disabled(hash == nil)
        }
    }
}

struct EvidenceMetadataSection: View {
    let evidence: EvidenceItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Metadata")
                .font(.headline)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                MetadataItem(label: "Case ID", value: evidence.caseId)
                MetadataItem(label: "Source", value: evidence.source)
                MetadataItem(label: "Collected", value: evidence.collectedFormatted)
                MetadataItem(label: "Collected By", value: evidence.collectedBy)
                MetadataItem(label: "Client", value: evidence.clientId ?? "N/A")
                MetadataItem(label: "Hunt", value: evidence.huntId ?? "N/A")
                MetadataItem(label: "Original Path", value: evidence.originalPath ?? "N/A")
                MetadataItem(label: "Storage Location", value: evidence.storagePath)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct MetadataItem: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.body)
                .lineLimit(1)
                .truncationMode(.middle)
        }
    }
}

struct ChainOfCustodySection: View {
    let evidence: EvidenceItem
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Chain of Custody")
                    .font(.headline)
                
                Spacer()
                
                Button("Add Entry") {
                    viewModel.showChainOfCustodySheet = true
                }
            }
            
            ForEach(evidence.chainOfCustody) { entry in
                ChainOfCustodyRow(entry: entry)
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ChainOfCustodyRow: View {
    let entry: ChainOfCustodyEntry
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Timeline indicator
            VStack {
                Circle()
                    .fill(entry.action.color)
                    .frame(width: 12, height: 12)
                Rectangle()
                    .fill(Color.secondary.opacity(0.3))
                    .frame(width: 2)
            }
            .frame(width: 12)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(entry.action.displayName)
                        .font(.headline)
                    Spacer()
                    Text(entry.timestampFormatted)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Text(entry.description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                HStack {
                    Label(entry.performedBy, systemImage: "person")
                    if let location = entry.location {
                        Label(location, systemImage: "location")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct RelatedEvidenceSection: View {
    let evidence: EvidenceItem
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Related Evidence")
                .font(.headline)
            
            let related = viewModel.evidence.filter { 
                $0.caseId == evidence.caseId && $0.id != evidence.id 
            }
            
            if related.isEmpty {
                Text("No related evidence found")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(related.prefix(5)) { item in
                    HStack {
                        Image(systemName: item.type.icon)
                            .foregroundColor(item.type.color)
                        Text(item.name)
                        Spacer()
                        Button("View") {
                            viewModel.selectedEvidenceId = item.id
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

// MARK: - Empty State

struct EvidenceEmptyState: View {
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.full")
                .font(.system(size: 48))
                .foregroundColor(.secondary)
            
            Text("No Evidence Selected")
                .font(.headline)
            
            Text("Select an evidence item from the sidebar or add new evidence")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button(action: { viewModel.showAddSheet = true }) {
                Label("Add Evidence", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityIdentifier("evidence_empty_state")
    }
}

// MARK: - Toolbar

struct EvidenceToolbar: ToolbarContent {
    @ObservedObject var viewModel: EvidenceViewModel
    
    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button(action: { viewModel.showAddSheet = true }) {
                Label("Add", systemImage: "plus")
            }
            .accessibilityIdentifier("add_evidence_button")
            
            Button(action: { viewModel.exportEvidence() }) {
                Label("Export", systemImage: "square.and.arrow.up")
            }
            .disabled(viewModel.selectedEvidence == nil)
        }
    }
}

// MARK: - Add Evidence Sheet

struct AddEvidenceSheet: View {
    @ObservedObject var viewModel: EvidenceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var type: EvidenceType = .file
    @State private var caseId = ""
    @State private var source = ""
    @State private var tags = ""
    @State private var notes = ""
    @State private var filePath = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Evidence")
                .font(.headline)
            
            Form {
                TextField("Name", text: $name)
                
                Picker("Type", selection: $type) {
                    ForEach(EvidenceType.allCases) { type in
                        Label(type.displayName, systemImage: type.icon)
                            .tag(type)
                    }
                }
                
                TextField("Case ID", text: $caseId)
                TextField("Source", text: $source)
                TextField("Tags (comma separated)", text: $tags)
                
                Section("File") {
                    HStack {
                        TextField("File Path", text: $filePath)
                        Button("Browse...") {
                            viewModel.browseForFile { path in
                                filePath = path
                                if name.isEmpty {
                                    name = (path as NSString).lastPathComponent
                                }
                            }
                        }
                    }
                }
                
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(height: 80)
                }
            }
            .frame(height: 400)
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add Evidence") {
                    viewModel.addEvidence(
                        name: name,
                        type: type,
                        caseId: caseId,
                        source: source,
                        tags: tags.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) },
                        filePath: filePath
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(name.isEmpty || caseId.isEmpty || filePath.isEmpty)
            }
        }
        .padding()
        .frame(width: 500)
        .accessibilityIdentifier("add_evidence_sheet")
    }
}

// MARK: - Chain of Custody Sheet

struct ChainOfCustodySheet: View {
    @ObservedObject var viewModel: EvidenceViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var action: CustodyAction = .accessed
    @State private var description = ""
    @State private var location = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Add Chain of Custody Entry")
                .font(.headline)
            
            Form {
                Picker("Action", selection: $action) {
                    ForEach(CustodyAction.allCases) { action in
                        Text(action.displayName).tag(action)
                    }
                }
                
                TextField("Description", text: $description)
                TextField("Location (optional)", text: $location)
            }
            
            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Add Entry") {
                    viewModel.addChainOfCustodyEntry(
                        action: action,
                        description: description,
                        location: location.isEmpty ? nil : location
                    )
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(description.isEmpty)
            }
        }
        .padding()
        .frame(width: 400)
        .accessibilityIdentifier("chain_of_custody_sheet")
    }
}

// MARK: - Models

enum EvidenceType: String, CaseIterable, Identifiable {
    case file, memoryDump, diskImage, networkCapture, artifact, log
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .file: return "File"
        case .memoryDump: return "Memory Dump"
        case .diskImage: return "Disk Image"
        case .networkCapture: return "Network Capture"
        case .artifact: return "Artifact"
        case .log: return "Log"
        }
    }
    
    var icon: String {
        switch self {
        case .file: return "doc.fill"
        case .memoryDump: return "memorychip"
        case .diskImage: return "internaldrive"
        case .networkCapture: return "network"
        case .artifact: return "archivebox"
        case .log: return "doc.text"
        }
    }
    
    var color: Color {
        switch self {
        case .file: return .blue
        case .memoryDump: return .purple
        case .diskImage: return .orange
        case .networkCapture: return .green
        case .artifact: return .cyan
        case .log: return .yellow
        }
    }
}

enum EvidenceStatus: String {
    case collected, verified, analyzing, archived, compromised
    
    var displayName: String {
        switch self {
        case .collected: return "Collected"
        case .verified: return "Verified"
        case .analyzing: return "Analyzing"
        case .archived: return "Archived"
        case .compromised: return "Compromised"
        }
    }
    
    var color: Color {
        switch self {
        case .collected: return .blue
        case .verified: return .green
        case .analyzing: return .orange
        case .archived: return .gray
        case .compromised: return .red
        }
    }
}

enum CustodyAction: String, CaseIterable, Identifiable {
    case collected, transferred, accessed, analyzed, exported, archived
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .collected: return "Collected"
        case .transferred: return "Transferred"
        case .accessed: return "Accessed"
        case .analyzed: return "Analyzed"
        case .exported: return "Exported"
        case .archived: return "Archived"
        }
    }
    
    var color: Color {
        switch self {
        case .collected: return .green
        case .transferred: return .blue
        case .accessed: return .orange
        case .analyzed: return .purple
        case .exported: return .cyan
        case .archived: return .gray
        }
    }
}

struct ChainOfCustodyEntry: Identifiable {
    let id: String
    let action: CustodyAction
    let description: String
    let performedBy: String
    let timestamp: Date
    let location: String?
    
    var timestampFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
}

struct EvidenceItem: Identifiable {
    let id: String
    var name: String
    let type: EvidenceType
    var status: EvidenceStatus
    let caseId: String
    let source: String
    let size: Int64
    let collected: Date
    let collectedBy: String
    var tags: [String]
    let md5Hash: String?
    let sha1Hash: String?
    let sha256Hash: String?
    var hashVerified: Bool
    var verifiedAt: Date?
    let clientId: String?
    let huntId: String?
    let originalPath: String?
    let storagePath: String
    var chainOfCustody: [ChainOfCustodyEntry]
    
    var collectedFormatted: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: collected, relativeTo: Date())
    }
    
    var sizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: size, countStyle: .file)
    }
    
    var verifiedAtFormatted: String? {
        guard let date = verifiedAt else { return nil }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - View Model

@MainActor
class EvidenceViewModel: ObservableObject {
    @Published var evidence: [EvidenceItem] = EvidenceItem.sampleEvidence
    @Published var selectedEvidenceId: String?
    
    @Published var searchText = ""
    @Published var typeFilter: EvidenceType?
    
    @Published var showAddSheet = false
    @Published var showChainOfCustodySheet = false
    
    var selectedEvidence: EvidenceItem? {
        evidence.first { $0.id == selectedEvidenceId }
    }
    
    var filteredEvidence: [EvidenceItem] {
        var result = evidence
        
        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.caseId.localizedCaseInsensitiveContains(searchText) ||
                $0.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        if let type = typeFilter {
            result = result.filter { $0.type == type }
        }
        
        return result.sorted { $0.collected > $1.collected }
    }
    
    var totalSizeFormatted: String {
        let total = evidence.reduce(0) { $0 + $1.size }
        return ByteCountFormatter.string(fromByteCount: total, countStyle: .file)
    }
    
    func addEvidence(name: String, type: EvidenceType, caseId: String, source: String, tags: [String], filePath: String) {
        let item = EvidenceItem(
            id: UUID().uuidString,
            name: name,
            type: type,
            status: .collected,
            caseId: caseId,
            source: source,
            size: Int64.random(in: 1000000...100000000),
            collected: Date(),
            collectedBy: "Current User",
            tags: tags,
            md5Hash: nil,
            sha1Hash: nil,
            sha256Hash: nil,
            hashVerified: false,
            verifiedAt: nil,
            clientId: nil,
            huntId: nil,
            originalPath: filePath,
            storagePath: "/evidence/\(caseId)/\(name)",
            chainOfCustody: [
                ChainOfCustodyEntry(
                    id: UUID().uuidString,
                    action: .collected,
                    description: "Evidence collected from \(source)",
                    performedBy: "Current User",
                    timestamp: Date(),
                    location: nil
                )
            ]
        )
        evidence.insert(item, at: 0)
        selectedEvidenceId = item.id
    }
    
    func addChainOfCustodyEntry(action: CustodyAction, description: String, location: String?) {
        guard let id = selectedEvidenceId,
              let index = evidence.firstIndex(where: { $0.id == id }) else { return }
        
        let entry = ChainOfCustodyEntry(
            id: UUID().uuidString,
            action: action,
            description: description,
            performedBy: "Current User",
            timestamp: Date(),
            location: location
        )
        evidence[index].chainOfCustody.append(entry)
    }
    
    func verifyHash(_ evidence: EvidenceItem) async {
        guard let index = self.evidence.firstIndex(where: { $0.id == evidence.id }) else { return }
        
        // Simulate hash verification
        try? await Task.sleep(nanoseconds: 1_500_000_000)
        
        self.evidence[index].hashVerified = true
        self.evidence[index].verifiedAt = Date()
        self.evidence[index].status = .verified
    }
    
    func downloadEvidence(_ evidence: EvidenceItem) {
        print("Download: \(evidence.name)")
    }
    
    func exportEvidence() {
        print("Export evidence")
    }
    
    func addTag() {
        // TODO: Add tag dialog
    }
    
    func browseForFile(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }
}

// MARK: - Sample Data

extension EvidenceItem {
    static let sampleEvidence: [EvidenceItem] = [
        EvidenceItem(
            id: "ev-1",
            name: "memory_dump_wks001.raw",
            type: .memoryDump,
            status: .verified,
            caseId: "CASE-2026-001",
            source: "WKS-001",
            size: 8589934592,
            collected: Date().addingTimeInterval(-3600),
            collectedBy: "Alice",
            tags: ["ransomware", "memory", "critical"],
            md5Hash: "d41d8cd98f00b204e9800998ecf8427e",
            sha1Hash: "da39a3ee5e6b4b0d3255bfef95601890afd80709",
            sha256Hash: "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
            hashVerified: true,
            verifiedAt: Date().addingTimeInterval(-1800),
            clientId: "C.abc123",
            huntId: "H.DEF456",
            originalPath: "/memory/WKS-001/dump.raw",
            storagePath: "/evidence/CASE-2026-001/memory_dump_wks001.raw",
            chainOfCustody: [
                ChainOfCustodyEntry(id: "coc-1", action: .collected, description: "Memory acquired using winpmem", performedBy: "Alice", timestamp: Date().addingTimeInterval(-3600), location: "On-site"),
                ChainOfCustodyEntry(id: "coc-2", action: .transferred, description: "Transferred to evidence server", performedBy: "Alice", timestamp: Date().addingTimeInterval(-3000), location: nil),
                ChainOfCustodyEntry(id: "coc-3", action: .analyzed, description: "Volatility 3 analysis completed", performedBy: "Bob", timestamp: Date().addingTimeInterval(-1800), location: nil),
            ]
        ),
        EvidenceItem(
            id: "ev-2",
            name: "c_drive_image.E01",
            type: .diskImage,
            status: .analyzing,
            caseId: "CASE-2026-001",
            source: "WKS-001",
            size: 107374182400,
            collected: Date().addingTimeInterval(-7200),
            collectedBy: "Alice",
            tags: ["ransomware", "disk", "forensic-image"],
            md5Hash: nil,
            sha1Hash: nil,
            sha256Hash: nil,
            hashVerified: false,
            verifiedAt: nil,
            clientId: "C.abc123",
            huntId: nil,
            originalPath: nil,
            storagePath: "/evidence/CASE-2026-001/c_drive_image.E01",
            chainOfCustody: [
                ChainOfCustodyEntry(id: "coc-4", action: .collected, description: "Disk image acquired using FTK Imager", performedBy: "Alice", timestamp: Date().addingTimeInterval(-7200), location: "On-site"),
            ]
        ),
        EvidenceItem(
            id: "ev-3",
            name: "network_capture.pcap",
            type: .networkCapture,
            status: .collected,
            caseId: "CASE-2026-002",
            source: "Firewall-01",
            size: 52428800,
            collected: Date().addingTimeInterval(-86400),
            collectedBy: "Charlie",
            tags: ["c2", "network", "exfiltration"],
            md5Hash: "098f6bcd4621d373cade4e832627b4f6",
            sha1Hash: nil,
            sha256Hash: nil,
            hashVerified: false,
            verifiedAt: nil,
            clientId: nil,
            huntId: nil,
            originalPath: "/var/log/captures/20260131.pcap",
            storagePath: "/evidence/CASE-2026-002/network_capture.pcap",
            chainOfCustody: []
        ),
    ]
}

// MARK: - Preview

#Preview {
    EvidenceView()
        .frame(width: 1000, height: 700)
}
