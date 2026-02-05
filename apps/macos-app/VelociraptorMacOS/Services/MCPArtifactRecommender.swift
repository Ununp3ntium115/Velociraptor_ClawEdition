//
//  MCPArtifactRecommender.swift
//  VelociraptorMacOS
//
//  MCP-powered artifact recommendation service
//  Gap: 0x08 - MCP Integration for Artifact Recommendations
//  Note: MCP package temporarily disabled pending Swift 6 compatibility fixes
//

import Foundation

// MARK: - MCP Artifact Recommender

/// Service for getting AI-powered artifact recommendations via MCP
actor MCPArtifactRecommender {
    private var isConnected = false
    
    init() {
        // Uses Logger.shared singleton
    }
    
    // MARK: - Connection Management
    
    /// Connect to MCP server (stub for local MCP server connection)
    func connect() async throws {
        // In production, this would connect to the MCP server
        // For now, we'll simulate the connection
        Logger.shared.info("MCP Artifact Recommender initialized (simulation mode)", component: "MCP")
        isConnected = true
    }
    
    /// Disconnect from MCP server
    func disconnect() async {
        isConnected = false
        Logger.shared.info("MCP Artifact Recommender disconnected", component: "MCP")
    }
    
    // MARK: - Recommendation Methods
    
    /// Get artifact recommendations for an incident type
    func getRecommendations(
        incidentType: IncidentType,
        platform: ArtifactPlatform,
        urgency: IncidentUrgency,
        scope: CollectionScope,
        allArtifacts: [ArtifactModel]
    ) async throws -> [ArtifactRecommendation] {
        Logger.shared.info("Generating recommendations for \(incidentType.rawValue) on \(platform.rawValue)", component: "MCP")
        
        // Generate recommendations based on incident type and parameters
        let recommendations = generateRecommendations(
            incidentType: incidentType,
            platform: platform,
            urgency: urgency,
            scope: scope,
            allArtifacts: allArtifacts
        )
        
        return recommendations
    }
    
    // MARK: - Recommendation Logic
    
    /// Generate artifact recommendations using DFIR best practices
    private func generateRecommendations(
        incidentType: IncidentType,
        platform: ArtifactPlatform,
        urgency: IncidentUrgency,
        scope: CollectionScope,
        allArtifacts: [ArtifactModel]
    ) -> [ArtifactRecommendation] {
        var recommendations: [ArtifactRecommendation] = []
        
        // Base artifacts based on incident type
        let baseArtifactNames = getBaseArtifacts(for: incidentType, platform: platform)
        
        // Expand based on scope
        var artifactNames = baseArtifactNames
        if scope == .comprehensive || scope == .forensicFull {
            artifactNames += getExpandedArtifacts(for: incidentType, platform: platform)
        }
        if scope == .forensicFull {
            artifactNames += getForensicArtifacts(for: platform)
        }
        
        // Convert to recommendations with priorities
        for (index, name) in artifactNames.enumerated() {
            if let artifact = allArtifacts.first(where: { $0.name == name }) {
                let priority = determinePriority(
                    artifactIndex: index,
                    totalArtifacts: artifactNames.count,
                    urgency: urgency
                )
                
                let rationale = getRationale(
                    artifact: artifact,
                    incidentType: incidentType,
                    priority: priority
                )
                
                let estimatedTime = estimateCollectionTime(
                    artifact: artifact,
                    scope: scope
                )
                
                recommendations.append(
                    ArtifactRecommendation(
                        artifact: artifact,
                        priority: priority,
                        rationale: rationale,
                        estimatedCollectionTime: estimatedTime,
                        dependencies: nil
                    )
                )
            }
        }
        
        return recommendations
    }
    
    /// Get base artifacts for incident type
    private func getBaseArtifacts(for incidentType: IncidentType, platform: ArtifactPlatform) -> [String] {
        let prefix = platform == .windows ? "Windows." :
                     platform == .linux ? "Linux." :
                     platform == .macos ? "MacOS." : "Generic."
        
        switch incidentType {
        case .ransomware:
            return [
                "\(prefix)NTFS.MFT",
                "\(prefix)EventLogs.EvtxHunter",
                "\(prefix)System.ShadowCopy",
                "\(prefix)Forensics.RecycleBin",
                "\(prefix)Network.Netstat",
                "\(prefix)System.ProcessList"
            ]
            
        case .apt:
            return [
                "\(prefix)EventLogs.Security",
                "\(prefix)System.Prefetch",
                "\(prefix)NTFS.MFT",
                "\(prefix)Registry.Autoruns",
                "\(prefix)Network.ArpCache",
                "\(prefix)System.Services"
            ]
            
        case .malware:
            return [
                "\(prefix)System.ProcessList",
                "\(prefix)Network.Netstat",
                "\(prefix)Registry.Autoruns",
                "\(prefix)System.Services",
                "\(prefix)Forensics.Executables"
            ]
            
        case .insiderThreat:
            return [
                "\(prefix)EventLogs.Security",
                "\(prefix)Forensics.SRUM",
                "\(prefix)Registry.RecentDocs",
                "\(prefix)Forensics.WebBrowserHistory",
                "\(prefix)Forensics.FileAccess"
            ]
            
        case .dataExfiltration:
            return [
                "\(prefix)Network.NetstatEnriched",
                "\(prefix)System.DNSCache",
                "\(prefix)Forensics.SRUM",
                "\(prefix)Applications.CloudSync",
                "\(prefix)Forensics.WebBrowserHistory"
            ]
            
        case .lateralMovement:
            return [
                "\(prefix)EventLogs.RDPAuth",
                "\(prefix)EventLogs.PowerShellScriptBlock",
                "\(prefix)Network.NetSessions",
                "\(prefix)System.Services",
                "\(prefix)Registry.RecentDocs"
            ]
            
        case .persistence:
            return [
                "\(prefix)Registry.Autoruns",
                "\(prefix)System.ScheduledTasks",
                "\(prefix)System.Services",
                "\(prefix)Registry.RunKeys",
                "\(prefix)System.WMI"
            ]
            
        case .credentialTheft:
            return [
                "\(prefix)System.LSASSMemory",
                "\(prefix)Registry.SAM",
                "\(prefix)EventLogs.Security",
                "\(prefix)Registry.Credentials",
                "\(prefix)Forensics.BrowserPasswords"
            ]
            
        case .complianceAudit:
            return [
                "\(prefix)System.Baseline",
                "\(prefix)Registry.SecuritySettings",
                "\(prefix)System.AuditPolicy",
                "\(prefix)EventLogs.AuditConfig"
            ]
            
        case .generalTriage:
            return [
                "\(prefix)System.ProcessList",
                "\(prefix)Network.Netstat",
                "\(prefix)System.Services",
                "\(prefix)Registry.Autoruns",
                "\(prefix)EventLogs.Recent"
            ]
        }
    }
    
    /// Get expanded artifacts for comprehensive collection
    private func getExpandedArtifacts(for incidentType: IncidentType, platform: ArtifactPlatform) -> [String] {
        let prefix = platform == .windows ? "Windows." :
                     platform == .linux ? "Linux." :
                     platform == .macos ? "MacOS." : "Generic."
        
        switch incidentType {
        case .ransomware:
            return [
                "\(prefix)Forensics.Timeline",
                "\(prefix)EventLogs.PowerShell",
                "\(prefix)System.Drivers",
                "\(prefix)Forensics.FileModifications"
            ]
            
        case .apt, .malware:
            return [
                "\(prefix)Memory.Acquisition",
                "\(prefix)Forensics.Timeline",
                "\(prefix)Registry.AllKeys",
                "\(prefix)Network.DNS",
                "\(prefix)System.Drivers"
            ]
            
        case .insiderThreat, .dataExfiltration:
            return [
                "\(prefix)Forensics.USBDevices",
                "\(prefix)Forensics.EmailArtifacts",
                "\(prefix)Forensics.PrintSpooler",
                "\(prefix)Network.Shares"
            ]
            
        default:
            return [
                "\(prefix)Forensics.Timeline",
                "\(prefix)System.Baseline"
            ]
        }
    }
    
    /// Get forensic artifacts for full collection
    private func getForensicArtifacts(for platform: ArtifactPlatform) -> [String] {
        let prefix = platform == .windows ? "Windows." :
                     platform == .linux ? "Linux." :
                     platform == .macos ? "MacOS." : "Generic."
        
        return [
            "\(prefix)Memory.Acquisition",
            "\(prefix)NTFS.FullMFT",
            "\(prefix)Forensics.FullTimeline",
            "\(prefix)Registry.FullHive",
            "\(prefix)EventLogs.AllLogs"
        ]
    }
    
    /// Determine priority based on position and urgency
    private func determinePriority(artifactIndex: Int, totalArtifacts: Int, urgency: IncidentUrgency) -> RecommendationPriority {
        let position = Double(artifactIndex) / Double(totalArtifacts)
        
        // High urgency: more critical artifacts
        if urgency == .critical || urgency == .high {
            if position < 0.3 {
                return .critical
            } else if position < 0.6 {
                return .high
            } else {
                return .medium
            }
        } else {
            if position < 0.2 {
                return .high
            } else if position < 0.5 {
                return .medium
            } else {
                return .low
            }
        }
    }
    
    /// Get rationale for artifact recommendation
    private func getRationale(artifact: ArtifactModel, incidentType: IncidentType, priority: RecommendationPriority) -> String {
        let priorityText = priority == .critical ? "Essential" : "Important"
        
        switch incidentType {
        case .ransomware:
            if artifact.name.contains("MFT") {
                return "\(priorityText) for tracking file encryption timestamps and ransomware activity"
            } else if artifact.name.contains("Shadow") {
                return "\(priorityText) to identify deleted shadow copies (common ransomware tactic)"
            } else if artifact.name.contains("EventLog") {
                return "\(priorityText) for identifying ransomware execution and lateral movement"
            }
            
        case .apt:
            if artifact.name.contains("Prefetch") {
                return "\(priorityText) for identifying executed malicious binaries"
            } else if artifact.name.contains("Autoruns") {
                return "\(priorityText) for detecting persistence mechanisms"
            } else if artifact.name.contains("Memory") {
                return "\(priorityText) for capturing in-memory malware and credentials"
            }
            
        case .lateralMovement:
            if artifact.name.contains("RDP") {
                return "\(priorityText) for tracking remote desktop authentication attempts"
            } else if artifact.name.contains("PowerShell") {
                return "\(priorityText) for identifying malicious PowerShell usage"
            } else if artifact.name.contains("Security") {
                return "\(priorityText) for authentication and privilege escalation events"
            }
            
        default:
            break
        }
        
        return "\(priorityText) for \(incidentType.displayName) investigation"
    }
    
    /// Estimate collection time for artifact
    private func estimateCollectionTime(artifact: ArtifactModel, scope: CollectionScope) -> String {
        // Estimate based on artifact type and scope
        if artifact.name.contains("Memory") {
            return scope == .forensicFull ? "30-60 min" : "N/A"
        } else if artifact.name.contains("MFT") || artifact.name.contains("Timeline") {
            return "5-15 min"
        } else if artifact.name.contains("EventLog") {
            return "2-10 min"
        } else if artifact.name.contains("Registry") {
            return "1-5 min"
        } else if artifact.name.contains("Process") || artifact.name.contains("Network") {
            return "< 1 min"
        }
        
        return "1-3 min"
    }
}
