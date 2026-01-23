//
//  StorageConfigurationStepView.swift
//  VelociraptorMacOS
//
//  Storage configuration step
//

import SwiftUI

struct StorageConfigurationStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    
    @State private var showDatastorePicker = false
    @State private var showLogsPicker = false
    @State private var showCachePicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Configure data storage locations:")
                .font(.body)
            
            // Datastore Directory
            GroupBox("Datastore Directory") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Primary location for Velociraptor data, including collected artifacts and database files.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Datastore path", text: $configViewModel.data.datastoreDirectory)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Browse...") {
                            showDatastorePicker = true
                        }
                        
                        Button {
                            configViewModel.data.datastoreDirectory = ConfigurationData.defaultDatastorePath
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .help("Reset to default")
                    }
                    
                    DirectoryStatusView(path: configViewModel.data.datastoreDirectory)
                }
                .padding()
            }
            
            // Logs Directory
            GroupBox("Logs Directory") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Location for log files. Following macOS conventions, logs go to ~/Library/Logs.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Logs path", text: $configViewModel.data.logsDirectory)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Browse...") {
                            showLogsPicker = true
                        }
                        
                        Button {
                            configViewModel.data.logsDirectory = ConfigurationData.defaultLogsPath
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .help("Reset to default")
                    }
                    
                    DirectoryStatusView(path: configViewModel.data.logsDirectory)
                }
                .padding()
            }
            
            // Cache Directory
            GroupBox("Cache Directory") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Temporary cache for downloaded tools and temporary files.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack {
                        TextField("Cache path", text: $configViewModel.data.cacheDirectory)
                            .textFieldStyle(.roundedBorder)
                        
                        Button("Browse...") {
                            showCachePicker = true
                        }
                        
                        Button {
                            configViewModel.data.cacheDirectory = ConfigurationData.defaultCachePath
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .help("Reset to default")
                    }
                    
                    DirectoryStatusView(path: configViewModel.data.cacheDirectory)
                }
                .padding()
            }
            
            // Datastore Size
            GroupBox("Datastore Size Preset") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Expected scale:", selection: $configViewModel.data.datastoreSize) {
                        ForEach(ConfigurationData.DatastoreSize.allCases) { size in
                            Text("\(size.rawValue) - \(size.description)").tag(size)
                        }
                    }
                    
                    HStack {
                        Image(systemName: "externaldrive.fill")
                            .foregroundColor(.secondary)
                        Text("Recommended disk space: \(configViewModel.data.datastoreSize.recommendedDiskSpace)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
            
            // Disk space info
            DiskSpaceInfoView(path: configViewModel.data.datastoreDirectory)
        }
        .fileImporter(
            isPresented: $showDatastorePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                configViewModel.data.datastoreDirectory = url.path
            }
        }
        .fileImporter(
            isPresented: $showLogsPicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                configViewModel.data.logsDirectory = url.path
            }
        }
        .fileImporter(
            isPresented: $showCachePicker,
            allowedContentTypes: [.folder],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                configViewModel.data.cacheDirectory = url.path
            }
        }
    }
}

// MARK: - Directory Status View

struct DirectoryStatusView: View {
    let path: String
    
    var exists: Bool {
        FileManager.default.fileExists(atPath: path)
    }
    
    var isWritable: Bool {
        FileManager.default.isWritableFile(atPath: path)
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if path.isEmpty {
                Label("Path required", systemImage: "exclamationmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            } else if exists {
                if isWritable {
                    Label("Directory exists and is writable", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                } else {
                    Label("Directory exists but is not writable", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            } else {
                Label("Directory will be created", systemImage: "folder.badge.plus")
                    .font(.caption)
                    .foregroundColor(.blue)
            }
        }
    }
}

// MARK: - Disk Space Info View

struct DiskSpaceInfoView: View {
    let path: String
    
    var availableSpace: String {
        let url = URL(fileURLWithPath: path.isEmpty ? NSHomeDirectory() : path)
        do {
            let values = try url.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return ByteCountFormatter.string(fromByteCount: capacity, countStyle: .file)
            }
        } catch {}
        return "Unknown"
    }
    
    var totalSpace: String {
        let url = URL(fileURLWithPath: path.isEmpty ? NSHomeDirectory() : path)
        do {
            let values = try url.resourceValues(forKeys: [.volumeTotalCapacityKey])
            if let capacity = values.volumeTotalCapacity {
                return ByteCountFormatter.string(fromByteCount: Int64(capacity), countStyle: .file)
            }
        } catch {}
        return "Unknown"
    }
    
    var body: some View {
        HStack {
            Image(systemName: "internaldrive.fill")
                .foregroundColor(.secondary)
            
            Text("Available: \(availableSpace) / \(totalSpace) total")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    StorageConfigurationStepView()
        .environmentObject(ConfigurationViewModel())
        .padding()
        .frame(width: 700)
}
