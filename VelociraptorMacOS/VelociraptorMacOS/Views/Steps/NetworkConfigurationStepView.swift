//
//  NetworkConfigurationStepView.swift
//  VelociraptorMacOS
//
//  Network configuration step
//

import SwiftUI

struct NetworkConfigurationStepView: View {
    @EnvironmentObject var configViewModel: ConfigurationViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var portConflictWarning: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Configure network bindings and ports:")
                .font(.body)
            
            // Only show full network config for Server/Standalone
            if appState.deploymentType != .client {
                // Frontend Configuration
                GroupBox("Frontend (Client Communication)") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("The frontend handles communication with Velociraptor clients.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Bind Address:")
                                .frame(width: 120, alignment: .trailing)
                            
                            TextField("0.0.0.0", text: $configViewModel.data.bindAddress)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                            
                            Text("Port:")
                                .frame(width: 40, alignment: .trailing)
                            
                            TextField("8000", value: $configViewModel.data.bindPort, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            
                            PortStatusView(port: configViewModel.data.bindPort)
                        }
                        
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.blue)
                            Text("Use 0.0.0.0 to listen on all interfaces, or 127.0.0.1 for localhost only.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                // GUI Configuration
                GroupBox("Web GUI") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("The web-based graphical user interface for administration.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Bind Address:")
                                .frame(width: 120, alignment: .trailing)
                            
                            TextField("127.0.0.1", text: $configViewModel.data.guiBindAddress)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                            
                            Text("Port:")
                                .frame(width: 40, alignment: .trailing)
                            
                            TextField("8889", value: $configViewModel.data.guiBindPort, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            
                            PortStatusView(port: configViewModel.data.guiBindPort)
                        }
                        
                        HStack {
                            Image(systemName: "exclamationmark.shield.fill")
                                .foregroundColor(.orange)
                            Text("For security, consider binding GUI to localhost (127.0.0.1) only.")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                // API Configuration
                GroupBox("API Server") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("The gRPC API for programmatic access.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Bind Address:")
                                .frame(width: 120, alignment: .trailing)
                            
                            TextField("127.0.0.1", text: $configViewModel.data.apiBindAddress)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 150)
                            
                            Text("Port:")
                                .frame(width: 40, alignment: .trailing)
                            
                            TextField("8001", value: $configViewModel.data.apiBindPort, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                            
                            PortStatusView(port: configViewModel.data.apiBindPort)
                        }
                    }
                    .padding()
                }
            } else {
                // Client-only configuration
                GroupBox("Server Connection") {
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Configure the connection to your Velociraptor server.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            Text("Server Address:")
                                .frame(width: 120, alignment: .trailing)
                            
                            TextField("server.example.com", text: $configViewModel.data.bindAddress)
                                .textFieldStyle(.roundedBorder)
                            
                            Text("Port:")
                                .frame(width: 40, alignment: .trailing)
                            
                            TextField("8000", value: $configViewModel.data.bindPort, format: .number)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 80)
                        }
                    }
                    .padding()
                }
            }
            
            // Port conflict check
            if let warning = portConflictWarning {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                    Text(warning)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Quick port presets
            GroupBox("Quick Presets") {
                HStack(spacing: 16) {
                    Button("Standard") {
                        applyPreset(.standard)
                    }
                    
                    Button("Development") {
                        applyPreset(.development)
                    }
                    
                    Button("Custom Ports") {
                        applyPreset(.custom)
                    }
                }
                .padding()
            }
        }
        .onChange(of: configViewModel.data.bindPort) { _, _ in checkPortConflicts() }
        .onChange(of: configViewModel.data.guiBindPort) { _, _ in checkPortConflicts() }
        .onChange(of: configViewModel.data.apiBindPort) { _, _ in checkPortConflicts() }
    }
    
    private func checkPortConflicts() {
        let ports = [configViewModel.data.bindPort, configViewModel.data.guiBindPort, configViewModel.data.apiBindPort]
        let uniquePorts = Set(ports)
        
        if uniquePorts.count != ports.count {
            portConflictWarning = "Port conflict detected! All ports must be different."
        } else {
            portConflictWarning = nil
        }
    }
    
    enum PortPreset {
        case standard
        case development
        case custom
    }
    
    private func applyPreset(_ preset: PortPreset) {
        switch preset {
        case .standard:
            configViewModel.data.bindPort = 8000
            configViewModel.data.guiBindPort = 8889
            configViewModel.data.apiBindPort = 8001
            configViewModel.data.bindAddress = "0.0.0.0"
            configViewModel.data.guiBindAddress = "127.0.0.1"
            configViewModel.data.apiBindAddress = "127.0.0.1"
            
        case .development:
            configViewModel.data.bindPort = 8000
            configViewModel.data.guiBindPort = 8889
            configViewModel.data.apiBindPort = 8001
            configViewModel.data.bindAddress = "127.0.0.1"
            configViewModel.data.guiBindAddress = "127.0.0.1"
            configViewModel.data.apiBindAddress = "127.0.0.1"
            
        case .custom:
            configViewModel.data.bindPort = 9000
            configViewModel.data.guiBindPort = 9889
            configViewModel.data.apiBindPort = 9001
        }
    }
}

// MARK: - Port Status View

struct PortStatusView: View {
    let port: Int
    
    @State private var isAvailable: Bool?
    
    var body: some View {
        Group {
            if let available = isAvailable {
                if available {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                        .help("Port is available")
                } else {
                    Image(systemName: "exclamationmark.circle.fill")
                        .foregroundColor(.orange)
                        .help("Port may be in use")
                }
            } else {
                ProgressView()
                    .controlSize(.small)
            }
        }
        .onAppear { checkPort() }
        .onChange(of: port) { _, _ in checkPort() }
    }
    
    private func checkPort() {
        isAvailable = nil
        
        Task {
            // Simple port check using socket
            isAvailable = await checkPortAvailable(port)
        }
    }
    
    private func checkPortAvailable(_ port: Int) async -> Bool {
        // Try to create a socket on the port
        let socket = socket(AF_INET, SOCK_STREAM, 0)
        guard socket >= 0 else { return true }
        defer { close(socket) }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(port).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        
        var optval: Int32 = 1
        setsockopt(socket, SOL_SOCKET, SO_REUSEADDR, &optval, socklen_t(MemoryLayout<Int32>.size))
        
        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(socket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        return result == 0
    }
}

#Preview {
    NetworkConfigurationStepView()
        .environmentObject(ConfigurationViewModel())
        .environmentObject(AppState())
        .padding()
        .frame(width: 700)
}
