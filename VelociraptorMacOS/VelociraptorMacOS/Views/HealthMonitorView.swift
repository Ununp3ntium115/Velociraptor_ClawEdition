//
//  HealthMonitorView.swift
//  VelociraptorMacOS
//
//  Health monitoring dashboard for Velociraptor service
//

import SwiftUI
import Combine

struct HealthMonitorView: View {
    @EnvironmentObject var deploymentManager: DeploymentManager
    @StateObject private var healthMonitor = HealthMonitor()
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                HStack {
                    Image(systemName: "heart.text.square.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading) {
                        Text("Health Monitor")
                            .font(.title2.bold())
                        Text("Real-time system status and diagnostics")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button {
                        Task {
                            await healthMonitor.refreshAll()
                        }
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                    .disabled(healthMonitor.isRefreshing)
                }
                
                Divider()
                
                // Overall Status
                OverallStatusCard(status: healthMonitor.overallStatus)
                
                // Status Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    StatusCard(
                        title: "Service",
                        status: healthMonitor.serviceStatus,
                        icon: "gearshape.fill",
                        detail: healthMonitor.serviceDetail
                    )
                    
                    StatusCard(
                        title: "Network",
                        status: healthMonitor.networkStatus,
                        icon: "network",
                        detail: healthMonitor.networkDetail
                    )
                    
                    StatusCard(
                        title: "Disk Space",
                        status: healthMonitor.diskStatus,
                        icon: "internaldrive.fill",
                        detail: healthMonitor.diskDetail
                    )
                    
                    StatusCard(
                        title: "Memory",
                        status: healthMonitor.memoryStatus,
                        icon: "memorychip",
                        detail: healthMonitor.memoryDetail
                    )
                    
                    StatusCard(
                        title: "GUI Port",
                        status: healthMonitor.guiPortStatus,
                        icon: "globe",
                        detail: healthMonitor.guiPortDetail
                    )
                    
                    StatusCard(
                        title: "Frontend Port",
                        status: healthMonitor.frontendPortStatus,
                        icon: "server.rack",
                        detail: healthMonitor.frontendPortDetail
                    )
                }
                
                // System Metrics
                GroupBox("System Metrics") {
                    VStack(spacing: 16) {
                        MetricRow(
                            label: "CPU Usage",
                            value: healthMonitor.cpuUsage,
                            maxValue: 100,
                            unit: "%"
                        )
                        
                        MetricRow(
                            label: "Memory Used",
                            value: healthMonitor.memoryUsed,
                            maxValue: healthMonitor.memoryTotal,
                            unit: "GB"
                        )
                        
                        MetricRow(
                            label: "Disk Used",
                            value: healthMonitor.diskUsed,
                            maxValue: healthMonitor.diskTotal,
                            unit: "GB"
                        )
                    }
                    .padding()
                }
                
                // Recent Logs
                GroupBox("Recent Log Entries") {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(healthMonitor.recentLogs, id: \.self) { log in
                            HStack(alignment: .top) {
                                Text(log.prefix(19))
                                    .font(.caption.monospaced())
                                    .foregroundColor(.secondary)
                                
                                Text(String(log.dropFirst(20)))
                                    .font(.caption.monospaced())
                                    .lineLimit(2)
                            }
                        }
                        
                        if healthMonitor.recentLogs.isEmpty {
                            Text("No recent log entries")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
                
                // Actions
                HStack {
                    Button {
                        openLogsFolder()
                    } label: {
                        Label("View All Logs", systemImage: "doc.text.magnifyingglass")
                    }
                    
                    Button {
                        exportDiagnostics()
                    } label: {
                        Label("Export Diagnostics", systemImage: "square.and.arrow.up")
                    }
                    
                    Spacer()
                    
                    if deploymentManager.isRunning {
                        Button(role: .destructive) {
                            Task {
                                try? await deploymentManager.stopService()
                                await healthMonitor.refreshAll()
                            }
                        } label: {
                            Label("Stop Service", systemImage: "stop.fill")
                        }
                    } else {
                        Button {
                            Task {
                                try? await deploymentManager.restartService()
                                await healthMonitor.refreshAll()
                            }
                        } label: {
                            Label("Start Service", systemImage: "play.fill")
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .padding()
        }
        .onAppear {
            Task {
                await healthMonitor.refreshAll()
            }
        }
    }
    
    /// Opens the current user's Velociraptor logs directory in Finder.
    /// 
    /// Locates the "Velociraptor" folder inside `~/Library/Logs` and opens it so the user can view log files.
    private func openLogsFolder() {
        let logsPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Velociraptor")
        NSWorkspace.shared.open(logsPath)
    }
    
    /// Presents a save panel for the user to export the diagnostics report and writes the report to the chosen file.
    /// 
    /// The panel is preconfigured to save plain-text files with a default filename of the form `velociraptor-diagnostics-<ISO8601 date>.txt`. If the user confirms the save, the function obtains the diagnostics text from `healthMonitor.generateDiagnosticsReport()` and attempts to write it to the selected URL; write failures are ignored (no error is propagated).
    private func exportDiagnostics() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.plainText]
        panel.nameFieldStringValue = "velociraptor-diagnostics-\(Date().ISO8601Format()).txt"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let content = healthMonitor.generateDiagnosticsReport()
                try? content.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - Health Monitor

@MainActor
class HealthMonitor: ObservableObject {
    @Published var isRefreshing = false
    
    @Published var overallStatus: HealthStatus = .unknown
    
    @Published var serviceStatus: HealthStatus = .unknown
    @Published var serviceDetail: String = "Checking..."
    
    @Published var networkStatus: HealthStatus = .unknown
    @Published var networkDetail: String = "Checking..."
    
    @Published var diskStatus: HealthStatus = .unknown
    @Published var diskDetail: String = "Checking..."
    
    @Published var memoryStatus: HealthStatus = .unknown
    @Published var memoryDetail: String = "Checking..."
    
    @Published var guiPortStatus: HealthStatus = .unknown
    @Published var guiPortDetail: String = "Port 8889"
    
    @Published var frontendPortStatus: HealthStatus = .unknown
    @Published var frontendPortDetail: String = "Port 8000"
    
    @Published var cpuUsage: Double = 0
    @Published var memoryUsed: Double = 0
    @Published var memoryTotal: Double = 0
    @Published var diskUsed: Double = 0
    @Published var diskTotal: Double = 0
    
    @Published var recentLogs: [String] = []
    
    enum HealthStatus {
        case healthy
        case warning
        case critical
        case unknown
        
        var color: Color {
            switch self {
            case .healthy: return .green
            case .warning: return .orange
            case .critical: return .red
            case .unknown: return .gray
            }
        }
        
        var icon: String {
            switch self {
            case .healthy: return "checkmark.circle.fill"
            case .warning: return "exclamationmark.triangle.fill"
            case .critical: return "xmark.circle.fill"
            case .unknown: return "questionmark.circle.fill"
            }
        }
        
        var description: String {
            switch self {
            case .healthy: return "Healthy"
            case .warning: return "Warning"
            case .critical: return "Critical"
            case .unknown: return "Unknown"
            }
        }
    }
    
    /// Triggers a full refresh of all health checks and updates the aggregated overall status.
    /// 
    /// While running, the monitor's `isRefreshing` flag is set to `true`. Performs checks for service, network, disk, memory, ports, and recent logs concurrently, then recalculates `overallStatus`.
    func refreshAll() async {
        isRefreshing = true
        defer { isRefreshing = false }
        
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.checkService() }
            group.addTask { await self.checkNetwork() }
            group.addTask { await self.checkDisk() }
            group.addTask { await self.checkMemory() }
            group.addTask { await self.checkPorts() }
            group.addTask { await self.loadRecentLogs() }
        }
        
        updateOverallStatus()
    }
    
    /// Determines whether the Velociraptor service process is running and updates the published `serviceStatus` and `serviceDetail`.
    /// 
    /// - Behaviour:
    ///   - Sets `serviceStatus` to `.healthy` and `serviceDetail` to `"Velociraptor is running"` when the service process is present.
    ///   - Sets `serviceStatus` to `.critical` and `serviceDetail` to `"Velociraptor is not running"` when the process is not found.
    ///   - Sets `serviceStatus` to `.unknown` and `serviceDetail` to `"Could not check status"` if an error occurs while checking.
    private func checkService() async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        process.arguments = ["-x", "velociraptor"]
        
        do {
            try process.run()
            process.waitUntilExit()
            
            if process.terminationStatus == 0 {
                serviceStatus = .healthy
                serviceDetail = "Velociraptor is running"
            } else {
                serviceStatus = .critical
                serviceDetail = "Velociraptor is not running"
            }
        } catch {
            serviceStatus = .unknown
            serviceDetail = "Could not check status"
        }
    }
    
    /// Performs a simple internet connectivity check and updates `networkStatus` and `networkDetail`.
    /// - Details: Sets `networkStatus` to `.healthy` with `networkDetail` "Internet connected" when an HTTP 200 response is received; sets `.warning` with `networkDetail` "Limited connectivity" for non-200 responses; sets `.critical` with `networkDetail` "No internet connection" on request errors.
    private func checkNetwork() async {
        let url = URL(string: "https://api.github.com")!
        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                networkStatus = .healthy
                networkDetail = "Internet connected"
            } else {
                networkStatus = .warning
                networkDetail = "Limited connectivity"
            }
        } catch {
            networkStatus = .critical
            networkDetail = "No internet connection"
        }
    }
    
    /// Checks disk usage for the Velociraptor application data directory and updates the monitor's disk metrics and status.
    /// 
    /// Reads available and total capacity for ~/Library/Application Support/Velociraptor, computes used and total space in gigabytes, and updates `diskUsed` and `diskTotal`. Sets `diskStatus` and `diskDetail` according to the percent used: healthy when below 80%, warning when below 95%, and critical otherwise. On failure, sets `diskStatus` to `.unknown` and `diskDetail` to "Could not check disk".
    private func checkDisk() async {
        let dataPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Application Support/Velociraptor")
        
        do {
            let values = try dataPath.resourceValues(forKeys: [
                .volumeAvailableCapacityForImportantUsageKey,
                .volumeTotalCapacityKey
            ])
            
            let available = Double(values.volumeAvailableCapacityForImportantUsage ?? 0) / 1_000_000_000
            let total = Double(values.volumeTotalCapacity ?? 0) / 1_000_000_000
            
            diskUsed = total - available
            diskTotal = total
            
            let percentUsed = (total - available) / total * 100
            
            if percentUsed < 80 {
                diskStatus = .healthy
                diskDetail = String(format: "%.0f GB available", available)
            } else if percentUsed < 95 {
                diskStatus = .warning
                diskDetail = String(format: "Low space: %.0f GB", available)
            } else {
                diskStatus = .critical
                diskDetail = String(format: "Critical: %.0f GB", available)
            }
        } catch {
            diskStatus = .unknown
            diskDetail = "Could not check disk"
        }
    }
    
    /// Estimates current system memory usage and updates the monitor's memory metrics and status.
    /// 
    /// Updates the following published properties based on the estimate:
    /// - `memoryUsed`: estimated used memory in GB.
    /// - `memoryTotal`: total physical memory in GB.
    /// - `memoryStatus`: `.healthy` when usage < 80%, `.warning` when usage >= 80% and < 95%, `.critical` when usage >= 95%, or `.unknown` if the measurement fails.
    /// - `memoryDetail`: a formatted string describing used and total memory or total only when unknown.
    private func checkMemory() async {
        let info = ProcessInfo.processInfo
        let total = Double(info.physicalMemory) / 1_000_000_000
        
        // Estimate used memory (simplified)
        var pageSize: vm_size_t = 0
        host_page_size(mach_host_self(), &pageSize)
        
        var vmStats = vm_statistics64()
        var count = mach_msg_type_number_t(MemoryLayout<vm_statistics64>.size / MemoryLayout<integer_t>.size)
        
        let result = withUnsafeMutablePointer(to: &vmStats) {
            $0.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                host_statistics64(mach_host_self(), HOST_VM_INFO64, $0, &count)
            }
        }
        
        if result == KERN_SUCCESS {
            let free = Double(vmStats.free_count) * Double(pageSize) / 1_000_000_000
            let used = total - free
            
            memoryUsed = used
            memoryTotal = total
            
            let percentUsed = used / total * 100
            
            if percentUsed < 80 {
                memoryStatus = .healthy
                memoryDetail = String(format: "%.1f / %.1f GB", used, total)
            } else if percentUsed < 95 {
                memoryStatus = .warning
                memoryDetail = String(format: "High: %.1f / %.1f GB", used, total)
            } else {
                memoryStatus = .critical
                memoryDetail = String(format: "Critical: %.1f / %.1f GB", used, total)
            }
        } else {
            memoryTotal = total
            memoryStatus = .unknown
            memoryDetail = String(format: "%.0f GB total", total)
        }
    }
    
    /// Checks whether the local GUI and frontend ports are accepting connections and updates the corresponding status and detail properties.
    /// 
    /// The method updates `guiPortStatus` and `guiPortDetail` based on port 8889, and `frontendPortStatus` and `frontendPortDetail` based on port 8000. Each status is set to `.healthy` when the port is reachable and `.warning` when it is not; detail strings reflect whether the port is "Listening" or "Not listening".
    private func checkPorts() async {
        guiPortStatus = await checkPort(8889) ? .healthy : .warning
        guiPortDetail = guiPortStatus == .healthy ? "Listening on 8889" : "Not listening"
        
        frontendPortStatus = await checkPort(8000) ? .healthy : .warning
        frontendPortDetail = frontendPortStatus == .healthy ? "Listening on 8000" : "Not listening"
    }
    
    /// Checks whether a TCP listener is accepting connections on the localhost loopback for the specified port.
    /// - Parameter port: The TCP port number on localhost to test.
    /// - Returns: `true` if a connection to the specified localhost port succeeded, `false` otherwise.
    private func checkPort(_ port: Int) async -> Bool {
        let socket = socket(AF_INET, SOCK_STREAM, 0)
        guard socket >= 0 else { return false }
        defer { close(socket) }
        
        var addr = sockaddr_in()
        addr.sin_family = sa_family_t(AF_INET)
        addr.sin_port = UInt16(port).bigEndian
        addr.sin_addr.s_addr = inet_addr("127.0.0.1")
        
        let result = withUnsafePointer(to: &addr) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                connect(socket, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        
        return result == 0
    }
    
    /// Loads the most recent Velociraptor log and updates `recentLogs` with its last 10 non-empty lines.
    /// 
    /// Attempts to read log files from `~/Library/Logs/Velociraptor`, selects the most recently modified `.log` file,
    /// and sets `recentLogs` to the final 10 non-empty lines of that file. If no log is found or an error occurs,
    /// `recentLogs` is set to an empty array.
    private func loadRecentLogs() async {
        let logPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Logs/Velociraptor")
        
        do {
            let files = try FileManager.default.contentsOfDirectory(at: logPath, includingPropertiesForKeys: [.modificationDateKey])
                .filter { $0.pathExtension == "log" }
                .sorted { url1, url2 in
                    let date1 = (try? url1.resourceValues(forKeys: [.modificationDateKey]).modificationDate) ?? Date.distantPast
                    let date2 = (try? url2.resourceValues(forKeys: [.modificationDateKey]).modificationDate) ?? Date.distantPast
                    return date1 > date2
                }
            
            if let latestLog = files.first {
                let content = try String(contentsOf: latestLog, encoding: .utf8)
                let lines = content.components(separatedBy: .newlines)
                recentLogs = Array(lines.suffix(10).filter { !$0.isEmpty })
            }
        } catch {
            recentLogs = []
        }
    }
    
    /// Update the aggregated overallStatus based on individual component statuses.
    /// 
    /// Sets `overallStatus` to `.critical` if any component is `.critical`, to `.warning` if none are critical but at least one is `.warning`, to `.healthy` if all components are `.healthy`, and to `.unknown` otherwise.
    private func updateOverallStatus() {
        let statuses = [serviceStatus, networkStatus, diskStatus, memoryStatus]
        
        if statuses.contains(.critical) {
            overallStatus = .critical
        } else if statuses.contains(.warning) {
            overallStatus = .warning
        } else if statuses.allSatisfy({ $0 == .healthy }) {
            overallStatus = .healthy
        } else {
            overallStatus = .unknown
        }
    }
    
    /// Creates a multi-section diagnostics report for Velociraptor on macOS containing system information, current health statuses, system metrics, and recent logs.
    /// - Returns: A formatted string that includes a generation timestamp, system information (macOS version, host, processors, memory), per-component health statuses with details, CPU/memory/disk metrics, and the most recent log lines.
    func generateDiagnosticsReport() -> String {
        let sysinfo = ProcessInfo.processInfo
        
        return """
        Velociraptor macOS Diagnostics Report
        =====================================
        Generated: \(Date())
        
        System Information:
        - macOS: \(sysinfo.operatingSystemVersionString)
        - Host: \(sysinfo.hostName)
        - Processors: \(sysinfo.processorCount)
        - Memory: \(String(format: "%.1f", memoryTotal)) GB
        
        Health Status:
        - Overall: \(overallStatus.description)
        - Service: \(serviceStatus.description) - \(serviceDetail)
        - Network: \(networkStatus.description) - \(networkDetail)
        - Disk: \(diskStatus.description) - \(diskDetail)
        - Memory: \(memoryStatus.description) - \(memoryDetail)
        - GUI Port: \(guiPortStatus.description) - \(guiPortDetail)
        - Frontend Port: \(frontendPortStatus.description) - \(frontendPortDetail)
        
        System Metrics:
        - CPU Usage: \(String(format: "%.1f", cpuUsage))%
        - Memory Used: \(String(format: "%.1f", memoryUsed)) / \(String(format: "%.1f", memoryTotal)) GB
        - Disk Used: \(String(format: "%.1f", diskUsed)) / \(String(format: "%.1f", diskTotal)) GB
        
        Recent Logs:
        \(recentLogs.joined(separator: "\n"))
        
        End of Report
        """
    }
}

// MARK: - Supporting Views

struct OverallStatusCard: View {
    let status: HealthMonitor.HealthStatus
    
    var body: some View {
        HStack {
            Image(systemName: status.icon)
                .font(.largeTitle)
                .foregroundColor(status.color)
            
            VStack(alignment: .leading) {
                Text("Overall Status")
                    .font(.headline)
                Text(status.description)
                    .font(.title2.bold())
                    .foregroundColor(status.color)
            }
            
            Spacer()
            
            Text(Date(), style: .time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(status.color.opacity(0.1))
        .cornerRadius(12)
    }
}

struct StatusCard: View {
    let title: String
    let status: HealthMonitor.HealthStatus
    let icon: String
    let detail: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.subheadline.bold())
                Spacer()
                Image(systemName: status.icon)
                    .foregroundColor(status.color)
            }
            
            Text(detail)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct MetricRow: View {
    let label: String
    let value: Double
    let maxValue: Double
    let unit: String
    
    var percentage: Double {
        guard maxValue > 0 else { return 0 }
        return value / maxValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.subheadline)
                Spacer()
                Text(String(format: "%.1f / %.1f %@", value, maxValue, unit))
                    .font(.caption.monospaced())
                    .foregroundColor(.secondary)
            }
            
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                    
                    Rectangle()
                        .fill(percentage < 0.8 ? Color.green : (percentage < 0.95 ? Color.orange : Color.red))
                        .frame(width: geometry.size.width * CGFloat(percentage))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
        }
    }
}

#Preview {
    HealthMonitorView()
        .environmentObject(DeploymentManager())
        .frame(width: 700, height: 800)
}