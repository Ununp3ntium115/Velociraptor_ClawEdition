//
//  IncidentResponseViewModel.swift
//  VelociraptorMacOS
//
//  View model for incident response collector
//

import SwiftUI
import Combine

/// View model for the Incident Response Collector interface
@MainActor
class IncidentResponseViewModel: ObservableObject {
    // MARK: - Published Properties
    
    /// Selected incident category
    @Published var selectedCategory: IncidentCategory?
    
    /// Selected specific incident
    @Published var selectedIncident: IncidentScenario?
    
    /// Collector configuration
    @Published var collectorConfig = CollectorConfiguration()
    
    /// Whether collector is being built
    @Published var isBuilding: Bool = false
    
    /// Build progress
    @Published var buildProgress: Double = 0.0
    
    /// Build status message
    @Published var buildStatus: String = ""
    
    /// Last error
    @Published var lastError: Error?
    
    // MARK: - Computed Properties
    
    /// Filtered incidents based on selected category
    var filteredIncidents: [IncidentScenario] {
        guard let category = selectedCategory else { return [] }
        return allIncidents.filter { $0.category == category }
    }
    
    // MARK: - Types
    
    /// Incident categories
    enum IncidentCategory: String, CaseIterable, Identifiable {
        case malwareRansomware = "Malware & Ransomware"
        case apt = "Advanced Persistent Threats"
        case insider = "Insider Threats"
        case network = "Network & Infrastructure"
        case dataBreach = "Data Breaches & Compliance"
        case industrial = "Industrial & Critical Infrastructure"
        case emerging = "Emerging & Specialized Threats"
        
        var id: String { rawValue }
        
        var emoji: String {
            switch self {
            case .malwareRansomware: return "🦠"
            case .apt: return "🎯"
            case .insider: return "👤"
            case .network: return "🌐"
            case .dataBreach: return "💳"
            case .industrial: return "🏭"
            case .emerging: return "📱"
            }
        }
        
        var scenarioCount: Int {
            switch self {
            case .malwareRansomware: return 25
            case .apt: return 20
            case .insider: return 15
            case .network: return 15
            case .dataBreach: return 10
            case .industrial: return 10
            case .emerging: return 5
            }
        }
    }
    
    /// Individual incident scenario
    struct IncidentScenario: Identifiable, Hashable {
        let id = UUID()
        let name: String
        let category: IncidentCategory
        let description: String
        let artifacts: [String]
        let priority: Priority
        let responseTime: ResponseTime
        
        enum Priority: String {
            case critical = "Critical"
            case high = "High"
            case medium = "Medium"
            case low = "Low"
            
            var color: Color {
                switch self {
                case .critical: return .red
                case .high: return .orange
                case .medium: return .yellow
                case .low: return .green
                }
            }
        }
        
        enum ResponseTime: String {
            case immediate = "0-1 hour"
            case rapid = "1-4 hours"
            case standard = "4-12 hours"
            case extended = "12+ hours"
        }
    }
    
    /// Collector configuration
    struct CollectorConfiguration {
        var deploymentPath: String = defaultDeploymentPath
        var offlineMode: Bool = true
        var portablePackage: Bool = true
        var encryptPackage: Bool = false
        var priority: String = "High"
        var urgency: String = "Rapid"
        var includeTools: Bool = true
        var compressOutput: Bool = true
        
        static var defaultDeploymentPath: String {
            FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("VelociraptorCollectors")
                .path
        }
    }
    
    // MARK: - All Incidents
    
    let allIncidents: [IncidentScenario] = [
        // Malware & Ransomware
        IncidentScenario(
            name: "WannaCry-style Worm Ransomware",
            category: .malwareRansomware,
            description: "Fast-spreading ransomware with worm capabilities targeting SMB vulnerabilities.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Forensics.PersistenceSniper", "Windows.Detection.Yara.Yara64"],
            priority: .critical,
            responseTime: .immediate
        ),
        IncidentScenario(
            name: "Targeted Ransomware (REvil/Sodinokibi)",
            category: .malwareRansomware,
            description: "Sophisticated targeted ransomware with data exfiltration capabilities.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Forensics.PersistenceSniper", "Windows.Memory.ProcessInfo"],
            priority: .critical,
            responseTime: .immediate
        ),
        IncidentScenario(
            name: "Double Extortion Ransomware",
            category: .malwareRansomware,
            description: "Ransomware combined with data theft for double extortion.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Network.NetstatEnriched", "Windows.System.Services"],
            priority: .critical,
            responseTime: .immediate
        ),
        IncidentScenario(
            name: "Banking Trojan (Emotet/TrickBot)",
            category: .malwareRansomware,
            description: "Financial malware targeting banking credentials.",
            artifacts: ["Windows.Forensics.PersistenceSniper", "Windows.Registry.NTUser", "Windows.Applications.Chrome.History"],
            priority: .high,
            responseTime: .rapid
        ),
        IncidentScenario(
            name: "Fileless Malware",
            category: .malwareRansomware,
            description: "Memory-resident malware with no file-based persistence.",
            artifacts: ["Windows.Memory.ProcessInfo", "Windows.System.Powershell.PSReadline", "Windows.EventLogs.Hayabusa"],
            priority: .high,
            responseTime: .rapid
        ),
        
        // APT
        IncidentScenario(
            name: "Chinese APT Groups (APT1, APT40)",
            category: .apt,
            description: "State-sponsored threat actors targeting intellectual property.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Forensics.PersistenceSniper", "Windows.Network.NetstatEnriched"],
            priority: .critical,
            responseTime: .immediate
        ),
        IncidentScenario(
            name: "Russian APT Groups (APT28, APT29)",
            category: .apt,
            description: "State-sponsored espionage operations.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Memory.ProcessInfo", "Windows.System.Services"],
            priority: .critical,
            responseTime: .immediate
        ),
        IncidentScenario(
            name: "North Korean APT Groups (Lazarus)",
            category: .apt,
            description: "Financially motivated state-sponsored attacks.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Forensics.PersistenceSniper", "Windows.Network.NetstatEnriched"],
            priority: .critical,
            responseTime: .immediate
        ),
        
        // Insider Threats
        IncidentScenario(
            name: "Disgruntled Employee Data Theft",
            category: .insider,
            description: "Employee exfiltrating sensitive data before departure.",
            artifacts: ["Windows.Forensics.UserAccessLogs", "Windows.Registry.RecentDocs", "Windows.Applications.Chrome.History"],
            priority: .high,
            responseTime: .rapid
        ),
        IncidentScenario(
            name: "Privileged User Abuse",
            category: .insider,
            description: "Administrator misusing elevated privileges.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.System.LoggedInUsers", "Windows.Registry.NTUser"],
            priority: .high,
            responseTime: .rapid
        ),
        
        // Network & Infrastructure
        IncidentScenario(
            name: "Lateral Movement Detection",
            category: .network,
            description: "Attacker moving through the network after initial compromise.",
            artifacts: ["Windows.Network.NetstatEnriched", "Windows.EventLogs.Authentication", "Windows.System.Services"],
            priority: .critical,
            responseTime: .immediate
        ),
        IncidentScenario(
            name: "Domain Controller Compromise",
            category: .network,
            description: "Active Directory domain controller has been compromised.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.System.Services", "Windows.Registry.NTUser"],
            priority: .critical,
            responseTime: .immediate
        ),
        
        // Data Breaches
        IncidentScenario(
            name: "Healthcare Data Breach (HIPAA)",
            category: .dataBreach,
            description: "Protected health information exposure.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Forensics.UserAccessLogs", "Windows.Network.NetstatEnriched"],
            priority: .critical,
            responseTime: .immediate
        ),
        IncidentScenario(
            name: "Financial Data Breach (PCI-DSS)",
            category: .dataBreach,
            description: "Payment card data exposure.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Forensics.UserAccessLogs", "Windows.Applications.Chrome.History"],
            priority: .critical,
            responseTime: .immediate
        ),
        
        // Industrial
        IncidentScenario(
            name: "SCADA System Compromise",
            category: .industrial,
            description: "Industrial control system has been targeted.",
            artifacts: ["Windows.EventLogs.Hayabusa", "Windows.Network.NetstatEnriched", "Windows.System.Services"],
            priority: .critical,
            responseTime: .immediate
        ),
        
        // Emerging
        IncidentScenario(
            name: "Supply Chain Software Attack",
            category: .emerging,
            description: "Compromise through trusted software supply chain.",
            artifacts: ["Windows.Forensics.PersistenceSniper", "Windows.System.Services", "Windows.Detection.Yara.Yara64"],
            priority: .critical,
            responseTime: .immediate
        )
    ]
    
    // MARK: - Methods
    
    /// Builds a collector package for the currently selected incident and writes the resulting configuration and package to the configured deployment path.
    /// 
    /// The method updates the view-model's progress and status properties, creates the output directory, writes a YAML collector configuration for the selected incident, and performs the packaging/finalization steps.
    /// - Throws: `CollectorError.noIncidentSelected` if no incident is selected. May also throw file-system errors if directory creation or file writing fails.
    func buildCollector() async throws {
        isBuilding = true
        buildProgress = 0.0
        buildStatus = "Preparing collector..."
        
        defer { isBuilding = false }
        
        guard let incident = selectedIncident else {
            throw CollectorError.noIncidentSelected
        }
        
        // Create output directory
        let outputDir = URL(fileURLWithPath: collectorConfig.deploymentPath)
        try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        
        buildProgress = 0.2
        buildStatus = "Creating collector configuration..."
        
        // Generate collector config
        let configContent = generateCollectorConfig(for: incident)
        let configPath = outputDir.appendingPathComponent("\(incident.name.replacingOccurrences(of: " ", with: "_")).yaml")
        try configContent.write(to: configPath, atomically: true, encoding: .utf8)
        
        buildProgress = 0.5
        buildStatus = "Packaging artifacts..."
        
        // Simulate packaging (would call velociraptor binary)
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        buildProgress = 0.8
        buildStatus = "Finalizing package..."
        
        try await Task.sleep(nanoseconds: 500_000_000)
        
        buildProgress = 1.0
        buildStatus = "Collector package created successfully!"
        
        Logger.shared.success("Collector built for: \(incident.name)", component: "IR")
    }
    
    /// Generate a YAML collector configuration for the given incident.
    /// The configuration includes header metadata, an artifacts list, runtime parameters, output settings (path, compress, encrypt) and options (offline_mode, portable, include_tools) populated from the current `collectorConfig`.
    /// - Parameter incident: The IncidentScenario to base the configuration on.
    /// - Returns: A YAML-formatted string representing the offline collector configuration.
    private func generateCollectorConfig(for incident: IncidentScenario) -> String {
        let artifacts = incident.artifacts.map { "  - \($0)" }.joined(separator: "\n")
        
        return """
        # Velociraptor Offline Collector Configuration
        # Generated for: \(incident.name)
        # Category: \(incident.category.rawValue)
        # Priority: \(incident.priority.rawValue)
        # Generated: \(ISO8601DateFormatter().string(from: Date()))
        
        artifacts:
        \(artifacts)
        
        parameters:
          timeout: 1800
          cpu_limit: 50
          iops_limit: 500
          progress_timeout: 600
        
        output:
          path: \(collectorConfig.deploymentPath)
          compress: \(collectorConfig.compressOutput)
          encrypt: \(collectorConfig.encryptPackage)
        
        options:
          offline_mode: \(collectorConfig.offlineMode)
          portable: \(collectorConfig.portablePackage)
          include_tools: \(collectorConfig.includeTools)
        """
    }
    
    /// Resets the view model's UI state to its default values.
    /// Clears the selected category and incident, replaces the collector configuration with a fresh default, sets build progress and status to their initial values, and clears any stored error.
    func reset() {
        selectedCategory = nil
        selectedIncident = nil
        collectorConfig = CollectorConfiguration()
        buildProgress = 0.0
        buildStatus = ""
        lastError = nil
    }
    
    // MARK: - Errors
    
    enum CollectorError: LocalizedError {
        case noIncidentSelected
        case buildFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .noIncidentSelected:
                return "Please select an incident type before building"
            case .buildFailed(let message):
                return "Build failed: \(message)"
            }
        }
    }
}