//
//  ArtifactModel.swift
//  VelociraptorMacOS
//
//  Extended artifact models for Artifact Manager
//  Gap: 0x08 - Artifact Management Models
//

import Foundation
import SwiftUI

// MARK: - Artifact Model Extensions

/// Extended artifact model with UI-specific properties
struct ArtifactModel: Identifiable, Sendable {
    let id: String
    let name: String
    let description: String?
    let author: String?
    let type: String?
    let parameters: [ArtifactParameter]?
    let sources: [ArtifactSource]?
    let requiredPermissions: [String]?
    let builtIn: Bool?
    let category: ArtifactCategory
    let platform: ArtifactPlatform
    var isFavorite: Bool = false
    var lastUsed: Date?
    var collectionCount: Int = 0
}

// MARK: - ArtifactModel Hashable/Equatable Conformance

extension ArtifactModel: Hashable {
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(name)
    }
    
    static func == (lhs: ArtifactModel, rhs: ArtifactModel) -> Bool {
        lhs.id == rhs.id && lhs.name == rhs.name
    }
    
    /// Display name (derived from full name)
    var displayName: String {
        // Remove platform prefix (e.g., "Windows.System.ProcessList" -> "ProcessList")
        let components = name.components(separatedBy: ".")
        return components.count > 2 ? components[2...].joined(separator: ".") : name
    }
    
    /// Short category name (e.g., "Windows.System" -> "System")
    var subcategory: String? {
        let components = name.components(separatedBy: ".")
        return components.count > 1 ? components[1] : nil
    }
    
    /// Create from API Artifact
    init(from artifact: Artifact) {
        self.id = artifact.name
        self.name = artifact.name
        self.description = artifact.description
        self.author = artifact.author
        self.type = artifact.type
        self.parameters = artifact.parameters
        self.sources = artifact.sources
        self.requiredPermissions = nil  // Not provided by Artifact API model
        self.builtIn = nil  // Not provided by Artifact API model
        self.isFavorite = false
        self.lastUsed = nil
        self.collectionCount = 0
        
        // Determine category and platform from name
        if name.hasPrefix("Windows.") {
            self.category = .windows
            self.platform = .windows
        } else if name.hasPrefix("Linux.") {
            self.category = .linux
            self.platform = .linux
        } else if name.hasPrefix("MacOS.") || name.hasPrefix("Darwin.") {
            self.category = .macos
            self.platform = .macos
        } else if name.hasPrefix("Generic.") || name.hasPrefix("Server.") {
            self.category = .generic
            self.platform = .mixed
        } else if name.hasPrefix("Exchange.") {
            self.category = .exchange
            self.platform = .mixed
        } else {
            self.category = .custom
            self.platform = .mixed
        }
    }
}

// MARK: - Artifact Category

/// Artifact platform/category
enum ArtifactCategory: String, CaseIterable, Identifiable, Sendable {
    case windows = "Windows"
    case linux = "Linux"
    case macos = "MacOS"
    case generic = "Generic"
    case exchange = "Exchange"
    case custom = "Custom"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .windows: return "Windows"
        case .linux: return "Linux"
        case .macos: return "macOS"
        case .generic: return "Generic"
        case .exchange: return "Artifact Exchange"
        case .custom: return "Custom"
        }
    }
    
    var icon: String {
        switch self {
        case .windows: return "pc"
        case .linux: return "terminal"
        case .macos: return "laptopcomputer"
        case .generic: return "cube"
        case .exchange: return "cloud"
        case .custom: return "wrench.and.screwdriver"
        }
    }
    
    var color: Color {
        switch self {
        case .windows: return .blue
        case .linux: return .orange
        case .macos: return .purple
        case .generic: return .gray
        case .exchange: return .green
        case .custom: return .cyan
        }
    }
}

// MARK: - Artifact Platform

/// Target platform for artifacts
enum ArtifactPlatform: String, CaseIterable, Identifiable, Sendable {
    case windows = "Windows"
    case linux = "Linux"
    case macos = "macOS"
    case mixed = "Mixed"
    
    var id: String { rawValue }
    
    var displayName: String { rawValue }
}

// MARK: - Artifact Collection

/// Named collection of artifacts for specific scenarios
struct ArtifactCollection: Identifiable, Codable, Sendable {
    let id: String
    let name: String
    let description: String?
    var artifacts: [String]  // Artifact names
    let createdAt: Date
    var updatedAt: Date
    
    init(id: String = UUID().uuidString, name: String, description: String? = nil, artifacts: [String] = [], createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.name = name
        self.description = description
        self.artifacts = artifacts
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - MCP Integration Models

/// Incident type for MCP recommendations
enum IncidentType: String, CaseIterable, Identifiable, Sendable {
    case ransomware = "ransomware"
    case apt = "apt"
    case malware = "malware"
    case insiderThreat = "insider_threat"
    case dataExfiltration = "data_exfiltration"
    case complianceAudit = "compliance_audit"
    case lateralMovement = "lateral_movement"
    case persistence = "persistence"
    case credentialTheft = "credential_theft"
    case generalTriage = "general_triage"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .ransomware: return "Ransomware"
        case .apt: return "APT/Advanced Threat"
        case .malware: return "Malware Infection"
        case .insiderThreat: return "Insider Threat"
        case .dataExfiltration: return "Data Exfiltration"
        case .complianceAudit: return "Compliance Audit"
        case .lateralMovement: return "Lateral Movement"
        case .persistence: return "Persistence Mechanisms"
        case .credentialTheft: return "Credential Theft"
        case .generalTriage: return "General Triage"
        }
    }
    
    var icon: String {
        switch self {
        case .ransomware: return "lock.fill"
        case .apt: return "shield.lefthalf.filled"
        case .malware: return "ladybug.fill"
        case .insiderThreat: return "person.fill.xmark"
        case .dataExfiltration: return "arrow.up.doc.fill"
        case .complianceAudit: return "checkmark.seal.fill"
        case .lateralMovement: return "arrow.left.arrow.right"
        case .persistence: return "arrow.clockwise.circle.fill"
        case .credentialTheft: return "key.fill"
        case .generalTriage: return "stethoscope"
        }
    }
    
    var description: String {
        switch self {
        case .ransomware:
            return "Ransomware attack response - collect encryption evidence, shadow copies, and ransom notes"
        case .apt:
            return "Advanced Persistent Threat investigation - comprehensive forensic collection"
        case .malware:
            return "Malware infection analysis - executables, persistence, and network connections"
        case .insiderThreat:
            return "Insider threat investigation - user activity, file access, and data movement"
        case .dataExfiltration:
            return "Data exfiltration investigation - network traffic, file transfers, cloud uploads"
        case .complianceAudit:
            return "Compliance audit collection - system configurations and security settings"
        case .lateralMovement:
            return "Lateral movement detection - authentication logs, remote connections, privilege escalation"
        case .persistence:
            return "Persistence mechanism analysis - autoruns, scheduled tasks, services"
        case .credentialTheft:
            return "Credential theft investigation - credential dumping, pass-the-hash, Kerberos attacks"
        case .generalTriage:
            return "General system triage - quick overview of system state and suspicious activity"
        }
    }
}

/// Incident urgency level
enum IncidentUrgency: String, CaseIterable, Identifiable, Sendable {
    case critical = "critical"
    case high = "high"
    case medium = "medium"
    case low = "low"
    
    var id: String { rawValue }
    
    var displayName: String {
        rawValue.capitalized
    }
    
    var icon: String {
        switch self {
        case .critical: return "exclamationmark.triangle.fill"
        case .high: return "exclamationmark.circle.fill"
        case .medium: return "exclamationmark.circle"
        case .low: return "info.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

/// Collection scope
enum CollectionScope: String, CaseIterable, Identifiable, Sendable {
    case minimal = "minimal"
    case standard = "standard"
    case comprehensive = "comprehensive"
    case forensicFull = "forensic_full"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .minimal: return "Minimal (Fast Triage)"
        case .standard: return "Standard"
        case .comprehensive: return "Comprehensive"
        case .forensicFull: return "Full Forensic"
        }
    }
    
    var description: String {
        switch self {
        case .minimal:
            return "Quick triage artifacts only (~5-10 min collection time)"
        case .standard:
            return "Standard investigation artifacts (~15-30 min collection time)"
        case .comprehensive:
            return "Deep investigation with extensive artifacts (~1-2 hour collection time)"
        case .forensicFull:
            return "Complete forensic collection including memory dumps (2+ hours)"
        }
    }
}

/// MCP Artifact Recommendation
struct ArtifactRecommendation: Identifiable, Sendable {
    let id: String
    let artifact: ArtifactModel
    let priority: RecommendationPriority
    let rationale: String?
    let estimatedCollectionTime: String?
    let dependencies: [String]?
    
    init(
        id: String = UUID().uuidString,
        artifact: ArtifactModel,
        priority: RecommendationPriority,
        rationale: String? = nil,
        estimatedCollectionTime: String? = nil,
        dependencies: [String]? = nil
    ) {
        self.id = id
        self.artifact = artifact
        self.priority = priority
        self.rationale = rationale
        self.estimatedCollectionTime = estimatedCollectionTime
        self.dependencies = dependencies
    }
}

/// Recommendation priority
enum RecommendationPriority: Int, Codable, Sendable {
    case critical = 1
    case high = 2
    case medium = 3
    case low = 4
    
    var displayName: String {
        switch self {
        case .critical: return "Critical"
        case .high: return "High"
        case .medium: return "Medium"
        case .low: return "Low"
        }
    }
    
    var color: Color {
        switch self {
        case .critical: return .red
        case .high: return .orange
        case .medium: return .yellow
        case .low: return .blue
        }
    }
}

// MARK: - View Models

/// View mode for artifact display
enum ArtifactViewMode: String, Sendable {
    case list = "list"
    case grid = "grid"
}

/// Sort order for artifacts
enum ArtifactSortOrder: String, Sendable {
    case name = "name"
    case platform = "platform"
    case type = "type"
    case recentlyUsed = "recently_used"
}

// MARK: - DFIR Best Practices

/// Common artifact groupings for DFIR scenarios
struct DFIRArtifactSets {
    /// Quick triage artifacts
    static let quickTriage = [
        "Windows.System.ProcessList",
        "Windows.Network.Netstat",
        "Windows.System.Services",
        "Windows.Registry.Autoruns"
    ]
    
    /// Ransomware investigation
    static let ransomware = [
        "Windows.NTFS.MFT",
        "Windows.EventLogs.EvtxHunter",
        "Windows.System.ShadowCopy",
        "Windows.Forensics.RecycleBin",
        "Windows.Network.Netstat",
        "Windows.System.ProcessList"
    ]
    
    /// APT investigation
    static let aptInvestigation = [
        "Windows.EventLogs.Security",
        "Windows.System.Prefetch",
        "Windows.NTFS.MFT",
        "Windows.Registry.Autoruns",
        "Windows.Network.ArpCache",
        "Windows.Memory.Acquisition",
        "Windows.Forensics.Timeline"
    ]
    
    /// Lateral movement detection
    static let lateralMovement = [
        "Windows.EventLogs.RDPAuth",
        "Windows.EventLogs.PowerShellScriptBlock",
        "Windows.Network.NetSessions",
        "Windows.System.Services",
        "Windows.Registry.RecentDocs"
    ]
    
    /// Data exfiltration
    static let dataExfiltration = [
        "Windows.Network.NetstatEnriched",
        "Windows.System.DNSCache",
        "Windows.Forensics.SRUM",
        "Windows.Applications.CloudSync",
        "Windows.Forensics.WebBrowserHistory"
    ]
}
