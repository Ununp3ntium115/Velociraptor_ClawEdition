//
//  LabelsView.swift
//  VelociraptorMacOS
//
//  Client labeling and tagging management view
//  Feature parity with Electron app's Labels tab
//

import SwiftUI

/// Label model for client tagging - local view model
struct LabelItem: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var color: Color
    var description: String
    var clientCount: Int
    var createdAt: Date
    var isSystem: Bool
    
    static let systemLabels: [LabelItem] = [
        LabelItem(name: "Windows", color: .blue, description: "Windows clients", clientCount: 0, createdAt: Date(), isSystem: true),
        LabelItem(name: "macOS", color: .purple, description: "macOS clients", clientCount: 0, createdAt: Date(), isSystem: true),
        LabelItem(name: "Linux", color: .orange, description: "Linux clients", clientCount: 0, createdAt: Date(), isSystem: true),
        LabelItem(name: "Server", color: .green, description: "Server endpoints", clientCount: 0, createdAt: Date(), isSystem: true),
        LabelItem(name: "Workstation", color: .cyan, description: "Workstation endpoints", clientCount: 0, createdAt: Date(), isSystem: true),
        LabelItem(name: "Critical", color: .red, description: "Critical infrastructure", clientCount: 0, createdAt: Date(), isSystem: true),
        LabelItem(name: "Quarantine", color: .yellow, description: "Quarantined clients", clientCount: 0, createdAt: Date(), isSystem: true)
    ]
}

/// Labels management view for client tagging
struct LabelsView: View {
    @State private var labels: [LabelItem] = LabelItem.systemLabels
    @State private var searchText = ""
    @State private var showingCreateSheet = false
    @State private var selectedLabel: LabelItem?
    @State private var showingDeleteConfirmation = false
    @State private var labelToDelete: LabelItem?
    
    // New label form
    @State private var newLabelName = ""
    @State private var newLabelDescription = ""
    @State private var newLabelColor: Color = .blue
    
    var filteredLabels: [LabelItem] {
        if searchText.isEmpty {
            return labels
        }
        return labels.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerSection
            
            Divider()
            
            // Content
            HSplitView {
                // Label list
                labelListSection
                    .frame(minWidth: 300)
                
                // Label details
                labelDetailsSection
                    .frame(minWidth: 400)
            }
        }
        .sheet(isPresented: $showingCreateSheet) {
            createLabelSheet
        }
        .alert("Delete Label", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let label = labelToDelete {
                    deleteLabel(label)
                }
            }
        } message: {
            Text("Are you sure you want to delete the label '\(labelToDelete?.name ?? "")'? This action cannot be undone.")
        }
    }
    
    // MARK: - Header
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Client Labels")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("Organize and tag clients for easier management")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            HStack(spacing: 12) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search labels...", text: $searchText)
                        .textFieldStyle(.plain)
                        .frame(width: 200)
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                
                // Create button
                Button(action: { showingCreateSheet = true }) {
                    Label("Create Label", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
    
    // MARK: - Label List
    
    private var labelListSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            // List header
            HStack {
                Text("Labels (\(filteredLabels.count))")
                    .font(.headline)
                Spacer()
                Menu {
                    Button("Name") {}
                    Button("Client Count") {}
                    Button("Created Date") {}
                } label: {
                    Label("Sort", systemImage: "arrow.up.arrow.down")
                        .font(.caption)
                }
                .menuStyle(.borderlessButton)
            }
            .padding()
            
            Divider()
            
            // Label list
            List(selection: $selectedLabel) {
                ForEach(filteredLabels) { label in
                    LabelRowView(label: label, isSelected: selectedLabel?.id == label.id)
                        .tag(label)
                        .contextMenu {
                            Button("Edit") {
                                selectedLabel = label
                            }
                            Divider()
                            Button("Duplicate") {
                                duplicateLabel(label)
                            }
                            if !label.isSystem {
                                Button("Delete", role: .destructive) {
                                    labelToDelete = label
                                    showingDeleteConfirmation = true
                                }
                            }
                        }
                }
            }
            .listStyle(.sidebar)
        }
        .background(Color(NSColor.controlBackgroundColor))
    }
    
    // MARK: - Label Details
    
    private var labelDetailsSection: some View {
        Group {
            if let label = selectedLabel {
                VStack(alignment: .leading, spacing: 20) {
                    // Label header
                    HStack(spacing: 16) {
                        Circle()
                            .fill(label.color)
                            .frame(width: 48, height: 48)
                            .overlay(
                                Image(systemName: "tag.fill")
                                    .foregroundColor(.white)
                                    .font(.title2)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(label.name)
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                if label.isSystem {
                                    Text("SYSTEM")
                                        .font(.caption2)
                                        .fontWeight(.medium)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.secondary.opacity(0.2))
                                        .cornerRadius(4)
                                }
                            }
                            Text(label.description)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if !label.isSystem {
                            Button(action: {}) {
                                Label("Edit", systemImage: "pencil")
                            }
                        }
                    }
                    .padding()
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    // Statistics
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "Clients", value: "\(label.clientCount)", icon: "desktopcomputer", color: .blue)
                        StatCard(title: "Created", value: formatDate(label.createdAt), icon: "calendar", color: .green)
                        StatCard(title: "Last Modified", value: "Never", icon: "clock", color: .orange)
                    }
                    
                    // Assigned clients section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Assigned Clients")
                                .font(.headline)
                            Spacer()
                            Button("Manage Assignments") {
                                // TODO: Open client assignment sheet
                            }
                            .buttonStyle(.link)
                        }
                        
                        if label.clientCount == 0 {
                            VStack(spacing: 12) {
                                Image(systemName: "desktopcomputer.trianglebadge.exclamationmark")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("No clients assigned to this label")
                                    .foregroundColor(.secondary)
                                Button("Assign Clients") {
                                    // TODO: Open client assignment
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(40)
                            .background(Color(NSColor.controlBackgroundColor))
                            .cornerRadius(12)
                        } else {
                            // Would show list of assigned clients
                            Text("Client list would appear here")
                                .foregroundColor(.secondary)
                                .padding()
                        }
                    }
                    
                    Spacer()
                }
                .padding()
            } else {
                // Empty state
                VStack(spacing: 16) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 64))
                        .foregroundColor(.secondary)
                    Text("Select a Label")
                        .font(.title2)
                        .fontWeight(.medium)
                    Text("Choose a label from the list to view its details and assigned clients")
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Create Label Sheet
    
    private var createLabelSheet: some View {
        VStack(spacing: 20) {
            Text("Create New Label")
                .font(.title2)
                .fontWeight(.semibold)
            
            Form {
                TextField("Label Name", text: $newLabelName)
                TextField("Description", text: $newLabelDescription)
                ColorPicker("Color", selection: $newLabelColor)
            }
            .formStyle(.grouped)
            
            HStack {
                Button("Cancel") {
                    showingCreateSheet = false
                    resetNewLabelForm()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Create Label") {
                    createLabel()
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.return)
                .disabled(newLabelName.isEmpty)
            }
        }
        .padding()
        .frame(width: 400, height: 300)
    }
    
    // MARK: - Helper Methods
    
    private func createLabel() {
        let label = LabelItem(
            name: newLabelName,
            color: newLabelColor,
            description: newLabelDescription,
            clientCount: 0,
            createdAt: Date(),
            isSystem: false
        )
        labels.append(label)
        showingCreateSheet = false
        resetNewLabelForm()
        selectedLabel = label
    }
    
    private func duplicateLabel(_ label: LabelItem) {
        let copy = LabelItem(
            name: "\(label.name) Copy",
            color: label.color,
            description: label.description,
            clientCount: 0,
            createdAt: Date(),
            isSystem: false
        )
        labels.append(copy)
        selectedLabel = copy
    }
    
    private func deleteLabel(_ label: LabelItem) {
        labels.removeAll { $0.id == label.id }
        if selectedLabel?.id == label.id {
            selectedLabel = nil
        }
    }
    
    private func resetNewLabelForm() {
        newLabelName = ""
        newLabelDescription = ""
        newLabelColor = .blue
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views

struct LabelRowView: View {
    let label: LabelItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(label.color)
                .frame(width: 24, height: 24)
                .overlay(
                    Image(systemName: "tag.fill")
                        .foregroundColor(.white)
                        .font(.caption)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text(label.name)
                        .fontWeight(.medium)
                    if label.isSystem {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                Text("\(label.clientCount) clients")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    LabelsView()
}
