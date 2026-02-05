//
//  IncidentResponseView.swift
//  VelociraptorMacOS
//
//  Incident Response Collector interface
//

import SwiftUI

struct IncidentResponseView: View {
    @EnvironmentObject var viewModel: IncidentResponseViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var showFilePicker = false
    
    var body: some View {
        HSplitView {
            // Left panel - Category and Incident Selection
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.shield.fill")
                            .font(.title2)
                            .foregroundColor(.red)
                        
                        Text("Incident Response")
                            .font(.title2.bold())
                    }
                    
                    Text("Select incident type to build a specialized collector")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                
                Divider()
                
                // Category list
                List(selection: $viewModel.selectedCategory) {
                    ForEach(IncidentResponseViewModel.IncidentCategory.allCases) { category in
                        CategoryRow(category: category)
                            .tag(category)
                    }
                }
                .listStyle(.sidebar)
                .accessibilityId(AccessibilityIdentifiers.IncidentResponse.categoryList)
                
                Divider()
                
                // Incident list (when category selected)
                if viewModel.selectedCategory != nil {
                    List(selection: $viewModel.selectedIncident) {
                        ForEach(viewModel.filteredIncidents) { incident in
                            IncidentRow(incident: incident)
                                .tag(incident)
                        }
                    }
                    .listStyle(.plain)
                    .accessibilityId(AccessibilityIdentifiers.IncidentResponse.incidentList)
                }
            }
            .frame(minWidth: 300, maxWidth: 400)
            
            // Right panel - Details and Configuration
            VStack(spacing: 0) {
                if let incident = viewModel.selectedIncident {
                    // Incident details
                    ScrollView {
                        VStack(alignment: .leading, spacing: 24) {
                            IncidentDetailsView(incident: incident)
                            
                            Divider()
                            
                            CollectorConfigView(
                                config: $viewModel.collectorConfig,
                                showFilePicker: $showFilePicker
                            )
                        }
                        .padding()
                    }
                    
                    Divider()
                    
                    // Action buttons
                    ActionButtonsView()
                        .environmentObject(viewModel)
                        .padding()
                } else {
                    // Empty state
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.shield")
                            .font(.system(size: 64))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("Select an Incident Type")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        
                        Text("Choose a category and incident from the left panel to configure a specialized offline collector.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 400)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .fileImporter(
            isPresented: $showFilePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                viewModel.collectorConfig.deploymentPath = url.path
            }
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let category: IncidentResponseViewModel.IncidentCategory
    
    var body: some View {
        HStack(spacing: 12) {
            Text(category.emoji)
                .font(.title2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(category.rawValue)
                    .font(.subheadline)
                
                Text("\(category.scenarioCount) scenarios")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Incident Row

struct IncidentRow: View {
    let incident: IncidentResponseViewModel.IncidentScenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(incident.name)
                .font(.subheadline)
            
            HStack {
                Text(incident.priority.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(incident.priority.color.opacity(0.2))
                    .foregroundColor(incident.priority.color)
                    .cornerRadius(4)
                
                Text(incident.responseTime.rawValue)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Incident Details View

struct IncidentDetailsView: View {
    let incident: IncidentResponseViewModel.IncidentScenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(incident.name)
                        .font(.title2.bold())
                    
                    Text(incident.category.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(incident.priority.rawValue)
                        .font(.caption.bold())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(incident.priority.color.opacity(0.2))
                        .foregroundColor(incident.priority.color)
                        .cornerRadius(4)
                    
                    Text(incident.responseTime.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Description
            GroupBox("Description") {
                Text(incident.description)
                    .font(.body)
                    .padding()
            }
            
            // Artifacts
            GroupBox("Recommended Artifacts") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(incident.artifacts, id: \.self) { artifact in
                        HStack {
                            Image(systemName: "doc.text.fill")
                                .foregroundColor(.accentColor)
                            Text(artifact)
                                .font(.system(.caption, design: .monospaced))
                        }
                    }
                }
                .padding()
            }
        }
    }
}

// MARK: - Collector Config View

struct CollectorConfigView: View {
    @Binding var config: IncidentResponseViewModel.CollectorConfiguration
    @Binding var showFilePicker: Bool
    
    var body: some View {
        GroupBox("Collector Configuration") {
            VStack(alignment: .leading, spacing: 16) {
                // Deployment path
                HStack {
                    Text("Output Path:")
                        .frame(width: 100, alignment: .trailing)
                    
                    TextField("Path", text: $config.deploymentPath)
                        .textFieldStyle(.roundedBorder)
                    
                    Button("Browse...") {
                        showFilePicker = true
                    }
                }
                
                Divider()
                
                // Options
                HStack(spacing: 24) {
                    Toggle("Offline Mode", isOn: $config.offlineMode)
                    Toggle("Portable Package", isOn: $config.portablePackage)
                    Toggle("Encrypt Package", isOn: $config.encryptPackage)
                }
                
                HStack(spacing: 24) {
                    Toggle("Include Tools", isOn: $config.includeTools)
                    Toggle("Compress Output", isOn: $config.compressOutput)
                }
            }
            .padding()
        }
    }
}

// MARK: - Action Buttons View

struct ActionButtonsView: View {
    @EnvironmentObject var viewModel: IncidentResponseViewModel
    
    @State private var showBuildProgress = false
    @State private var buildError: Error?
    @State private var showError = false
    
    var body: some View {
        HStack {
            // Status
            if viewModel.isBuilding {
                HStack {
                    ProgressView()
                        .controlSize(.small)
                    Text(viewModel.buildStatus)
                        .font(.caption)
                }
            }
            
            Spacer()
            
            Button {
                viewModel.reset()
            } label: {
                Label("Reset", systemImage: "arrow.counterclockwise")
            }
            
            Button {
                buildCollector()
            } label: {
                Label("Build Collector", systemImage: "hammer.fill")
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.selectedIncident == nil || viewModel.isBuilding)
        }
        .alert("Build Error", isPresented: $showError, presenting: buildError) { _ in
            Button("OK") {}
        } message: { error in
            Text(error.localizedDescription)
        }
    }
    
    /// Initiates the collector build process and updates UI state based on the outcome.
    /// - Discussion: On success delivers a macOS user notification titled "Collector Built" with an informative message. On failure stores the thrown error in `buildError` and sets `showError` to `true`.
    private func buildCollector() {
        Task {
            do {
                try await viewModel.buildCollector()
                // Show success notification
                let notification = NSUserNotification()
                notification.title = "Collector Built"
                notification.informativeText = "Collector package created successfully"
                NSUserNotificationCenter.default.deliver(notification)
            } catch {
                buildError = error
                showError = true
            }
        }
    }
}

#Preview {
    IncidentResponseView()
        .environmentObject(IncidentResponseViewModel())
        .environmentObject(AppState())
        .frame(width: 1000, height: 700)
}