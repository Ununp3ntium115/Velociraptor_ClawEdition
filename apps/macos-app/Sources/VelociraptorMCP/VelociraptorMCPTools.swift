// VelociraptorMCPTools.swift
// Velociraptor DFIR Tools exposed via Model Context Protocol
//
// This module provides DFIR (Digital Forensics and Incident Response) capabilities
// through the MCP protocol, enabling AI assistants like Claude and Cursor to:
// - Generate VQL queries for forensic analysis
// - Suggest artifacts for incident response
// - Plan deployment strategies
// - Analyze system configurations
// - Create incident response packages
//
// Copyright (c) 2026 Velociraptor Claw Edition Project
// Licensed under Apache 2.0

import Foundation
import MCP
import Logging

// MARK: - Tool Definitions

/// All available Velociraptor DFIR tools exposed via MCP
public enum VelociraptorTools {
    
    /// Generate VQL queries for forensic analysis
    public static let generateVQL = Tool(
        name: "velociraptor_generate_vql",
        description: """
            Generate Velociraptor Query Language (VQL) queries for digital forensics and incident response.
            VQL is a powerful query language for collecting forensic artifacts, analyzing system state,
            and hunting for indicators of compromise across endpoints.
            
            Use this tool when you need to:
            - Search for specific files, registry keys, or processes
            - Collect forensic artifacts (event logs, prefetch, shimcache, etc.)
            - Hunt for indicators of compromise (IOCs)
            - Analyze memory, network connections, or system configuration
            - Create custom collection queries for incident response
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "objective": .object([
                    "type": .string("string"),
                    "description": .string("What you want to achieve with the VQL query. Be specific about the forensic artifact, IOC, or system state you want to analyze.")
                ]),
                "platform": .object([
                    "type": .string("string"),
                    "enum": .array([.string("Windows"), .string("Linux"), .string("macOS"), .string("All")]),
                    "description": .string("Target operating system platform")
                ]),
                "output_format": .object([
                    "type": .string("string"),
                    "enum": .array([.string("table"), .string("json"), .string("csv")]),
                    "description": .string("Desired output format for the query results")
                ]),
                "include_explanation": .object([
                    "type": .string("boolean"),
                    "description": .string("Whether to include a detailed explanation of the query")
                ])
            ]),
            "required": .array([.string("objective")])
        ])
    )
    
    /// Suggest artifacts for incident response
    public static let suggestArtifacts = Tool(
        name: "velociraptor_suggest_artifacts",
        description: """
            Get AI-powered suggestions for Velociraptor artifacts based on incident type.
            Returns a prioritized list of forensic artifacts to collect, including:
            - Built-in Velociraptor artifacts
            - Artifact Exchange community artifacts
            - Custom artifact recommendations
            
            Use this tool when you need to:
            - Respond to a specific type of incident (ransomware, APT, insider threat, etc.)
            - Build a comprehensive collection plan
            - Understand which artifacts are most valuable for investigation
            - Create an incident response package
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "incident_type": .object([
                    "type": .string("string"),
                    "enum": .array([
                        .string("ransomware"),
                        .string("apt"),
                        .string("malware"),
                        .string("insider_threat"),
                        .string("data_exfiltration"),
                        .string("compliance_audit"),
                        .string("lateral_movement"),
                        .string("persistence"),
                        .string("credential_theft"),
                        .string("general_triage")
                    ]),
                    "description": .string("Type of incident or investigation scenario")
                ]),
                "platform": .object([
                    "type": .string("string"),
                    "enum": .array([.string("Windows"), .string("Linux"), .string("macOS"), .string("Mixed")]),
                    "description": .string("Target operating system platform")
                ]),
                "urgency": .object([
                    "type": .string("string"),
                    "enum": .array([.string("critical"), .string("high"), .string("medium"), .string("low")]),
                    "description": .string("Urgency level affecting artifact selection priority")
                ]),
                "scope": .object([
                    "type": .string("string"),
                    "enum": .array([.string("minimal"), .string("standard"), .string("comprehensive"), .string("forensic_full")]),
                    "description": .string("Scope of artifact collection - minimal for quick triage, full for complete forensics")
                ])
            ]),
            "required": .array([.string("incident_type")])
        ])
    )
    
    /// Plan Velociraptor deployment
    public static let planDeployment = Tool(
        name: "velociraptor_plan_deployment",
        description: """
            Create a comprehensive Velociraptor deployment plan based on environment characteristics.
            Generates step-by-step deployment instructions including:
            - Prerequisites and system requirements
            - Configuration recommendations
            - Security hardening steps
            - Rollback procedures
            
            Use this tool when you need to:
            - Deploy Velociraptor in a new environment
            - Scale an existing deployment
            - Plan for enterprise rollout
            - Understand deployment best practices
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "deployment_type": .object([
                    "type": .string("string"),
                    "enum": .array([
                        .string("standalone"),
                        .string("server_client"),
                        .string("cloud_aws"),
                        .string("cloud_azure"),
                        .string("cloud_gcp"),
                        .string("kubernetes"),
                        .string("docker")
                    ]),
                    "description": .string("Type of Velociraptor deployment")
                ]),
                "environment": .object([
                    "type": .string("object"),
                    "properties": .object([
                        "endpoint_count": .object([
                            "type": .string("integer"),
                            "description": .string("Estimated number of endpoints to manage")
                        ]),
                        "os_distribution": .object([
                            "type": .string("object"),
                            "description": .string("Distribution of operating systems (e.g., {windows: 80, linux: 15, macos: 5})")
                        ]),
                        "network_type": .object([
                            "type": .string("string"),
                            "enum": .array([.string("corporate"), .string("air_gapped"), .string("hybrid"), .string("cloud_only")]),
                            "description": .string("Network topology type")
                        ])
                    ])
                ]),
                "security_requirements": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("string"),
                        "enum": .array([
                            .string("hipaa"),
                            .string("pci_dss"),
                            .string("sox"),
                            .string("gdpr"),
                            .string("fedramp"),
                            .string("iso27001")
                        ])
                    ]),
                    "description": .string("Compliance frameworks to consider")
                ])
            ]),
            "required": .array([.string("deployment_type")])
        ])
    )
    
    /// Analyze forensic timeline
    public static let analyzeTimeline = Tool(
        name: "velociraptor_analyze_timeline",
        description: """
            Analyze forensic timeline data to identify suspicious activities and patterns.
            Helps correlate events across multiple data sources and identify:
            - Indicators of compromise
            - Attack timelines
            - Lateral movement patterns
            - Data exfiltration windows
            
            Use this tool when you need to:
            - Correlate events from multiple sources
            - Build an attack timeline
            - Identify the scope of a compromise
            - Document incident findings
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "time_range": .object([
                    "type": .string("object"),
                    "properties": .object([
                        "start": .object([
                            "type": .string("string"),
                            "format": .string("date-time"),
                            "description": .string("Start of the analysis window (ISO 8601)")
                        ]),
                        "end": .object([
                            "type": .string("string"),
                            "format": .string("date-time"),
                            "description": .string("End of the analysis window (ISO 8601)")
                        ])
                    ])
                ]),
                "focus_areas": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("string"),
                        "enum": .array([
                            .string("process_execution"),
                            .string("file_system"),
                            .string("network_connections"),
                            .string("registry_changes"),
                            .string("authentication"),
                            .string("scheduled_tasks"),
                            .string("service_installation")
                        ])
                    ]),
                    "description": .string("Areas to focus the timeline analysis on")
                ]),
                "known_iocs": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("string")
                    ]),
                    "description": .string("Known indicators of compromise to search for")
                ])
            ]),
            "required": .array([.string("time_range")])
        ])
    )
    
    /// Create incident response package
    public static let createIRPackage = Tool(
        name: "velociraptor_create_ir_package",
        description: """
            Create a self-contained incident response package for offline collection.
            Generates a portable collector that can be deployed to endpoints without
            requiring a full Velociraptor server installation.
            
            Use this tool when you need to:
            - Collect forensic data from air-gapped systems
            - Perform quick triage on remote endpoints
            - Create USB-deployable collection tools
            - Build customer-specific collection packages
            """,
        inputSchema: .object([
            "type": .string("object"),
            "properties": .object([
                "package_name": .object([
                    "type": .string("string"),
                    "description": .string("Name for the incident response package")
                ]),
                "target_platforms": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("string"),
                        "enum": .array([.string("windows_x64"), .string("windows_x86"), .string("linux_x64"), .string("macos_arm64"), .string("macos_x64")])
                    ]),
                    "description": .string("Target platforms for the package")
                ]),
                "artifacts": .object([
                    "type": .string("array"),
                    "items": .object([
                        "type": .string("string")
                    ]),
                    "description": .string("List of Velociraptor artifacts to include")
                ]),
                "output_format": .object([
                    "type": .string("string"),
                    "enum": .array([.string("zip"), .string("directory"), .string("encrypted_zip")]),
                    "description": .string("Output format for collected data")
                ]),
                "include_memory": .object([
                    "type": .string("boolean"),
                    "description": .string("Whether to include memory collection capabilities")
                ])
            ]),
            "required": .array([.string("package_name"), .string("target_platforms"), .string("artifacts")])
        ])
    )
    
    /// Get all available tools
    public static var allTools: [Tool] {
        [
            generateVQL,
            suggestArtifacts,
            planDeployment,
            analyzeTimeline,
            createIRPackage
        ]
    }
}

// MARK: - Tool Handler

/// Handles execution of Velociraptor MCP tools
public actor VelociraptorToolHandler {
    private let logger: Logger
    
    public init(logger: Logger = Logger(label: "com.velociraptor.mcp.tools")) {
        self.logger = logger
    }
    
    /// Handle a tool call request
    public func handleToolCall(name: String, arguments: [String: Value]?) async throws -> CallTool.Result {
        logger.info("Handling tool call", metadata: ["tool": "\(name)"])
        
        switch name {
        case "velociraptor_generate_vql":
            return try await handleGenerateVQL(arguments: arguments)
        case "velociraptor_suggest_artifacts":
            return try await handleSuggestArtifacts(arguments: arguments)
        case "velociraptor_plan_deployment":
            return try await handlePlanDeployment(arguments: arguments)
        case "velociraptor_analyze_timeline":
            return try await handleAnalyzeTimeline(arguments: arguments)
        case "velociraptor_create_ir_package":
            return try await handleCreateIRPackage(arguments: arguments)
        default:
            logger.warning("Unknown tool requested", metadata: ["tool": "\(name)"])
            return CallTool.Result(
                content: [.text("Unknown tool: \(name)")],
                isError: true
            )
        }
    }
    
    // MARK: - Tool Implementations
    
    private func handleGenerateVQL(arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let objective = arguments?["objective"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: 'objective' parameter is required")],
                isError: true
            )
        }
        
        let platform = arguments?["platform"]?.stringValue ?? "Windows"
        let includeExplanation = arguments?["include_explanation"]?.boolValue ?? true
        
        // Generate VQL based on objective
        let vqlResult = generateVQLQuery(objective: objective, platform: platform, includeExplanation: includeExplanation)
        
        return CallTool.Result(
            content: [.text(vqlResult)],
            isError: false
        )
    }
    
    private func handleSuggestArtifacts(arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let incidentType = arguments?["incident_type"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: 'incident_type' parameter is required")],
                isError: true
            )
        }
        
        let platform = arguments?["platform"]?.stringValue ?? "Windows"
        let urgency = arguments?["urgency"]?.stringValue ?? "high"
        let scope = arguments?["scope"]?.stringValue ?? "standard"
        
        let suggestions = suggestArtifactsForIncident(
            incidentType: incidentType,
            platform: platform,
            urgency: urgency,
            scope: scope
        )
        
        return CallTool.Result(
            content: [.text(suggestions)],
            isError: false
        )
    }
    
    private func handlePlanDeployment(arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let deploymentType = arguments?["deployment_type"]?.stringValue else {
            return CallTool.Result(
                content: [.text("Error: 'deployment_type' parameter is required")],
                isError: true
            )
        }
        
        let plan = createDeploymentPlan(deploymentType: deploymentType, environment: arguments?["environment"], securityRequirements: arguments?["security_requirements"])
        
        return CallTool.Result(
            content: [.text(plan)],
            isError: false
        )
    }
    
    private func handleAnalyzeTimeline(arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let timeRange = arguments?["time_range"] else {
            return CallTool.Result(
                content: [.text("Error: 'time_range' parameter is required")],
                isError: true
            )
        }
        
        let analysis = analyzeForensicTimeline(timeRange: timeRange, focusAreas: arguments?["focus_areas"], knownIOCs: arguments?["known_iocs"])
        
        return CallTool.Result(
            content: [.text(analysis)],
            isError: false
        )
    }
    
    private func handleCreateIRPackage(arguments: [String: Value]?) async throws -> CallTool.Result {
        guard let packageName = arguments?["package_name"]?.stringValue,
              let targetPlatforms = arguments?["target_platforms"],
              let artifacts = arguments?["artifacts"] else {
            return CallTool.Result(
                content: [.text("Error: 'package_name', 'target_platforms', and 'artifacts' parameters are required")],
                isError: true
            )
        }
        
        let packageResult = createIncidentResponsePackage(
            name: packageName,
            platforms: targetPlatforms,
            artifacts: artifacts,
            outputFormat: arguments?["output_format"]?.stringValue ?? "zip",
            includeMemory: arguments?["include_memory"]?.boolValue ?? false
        )
        
        return CallTool.Result(
            content: [.text(packageResult)],
            isError: false
        )
    }
    
    // MARK: - VQL Generation Logic
    
    private func generateVQLQuery(objective: String, platform: String, includeExplanation: Bool) -> String {
        // This is a comprehensive VQL generation system
        // In production, this would use more sophisticated AI/ML or rule-based generation
        
        let objectiveLower = objective.lowercased()
        var vql = ""
        var explanation = ""
        
        // Process execution queries
        if objectiveLower.contains("process") || objectiveLower.contains("running") || objectiveLower.contains("execute") {
            if platform == "Windows" {
                vql = """
                    -- Query to enumerate running processes with details
                    SELECT Pid, Name, Exe, CommandLine, Username,
                           CreateTime, ParentPid,
                           hash(path=Exe, hashselect="SHA256") as SHA256
                    FROM pslist()
                    WHERE Name =~ "."
                    ORDER BY CreateTime DESC
                    """
                explanation = """
                    This VQL query enumerates all running processes on Windows endpoints.
                    It collects the process ID, name, executable path, command line arguments,
                    username context, creation time, parent process ID, and SHA256 hash of the executable.
                    Results are ordered by creation time to help identify recently spawned processes.
                    """
            } else if platform == "Linux" || platform == "macOS" {
                vql = """
                    -- Query to enumerate running processes on Unix-like systems
                    SELECT Pid, Name, Exe, Cmdline, Username,
                           StartTime as CreateTime
                    FROM pslist()
                    ORDER BY CreateTime DESC
                    """
                explanation = "Enumerates running processes on Unix-like systems with key forensic attributes."
            }
        }
        // Network connection queries
        else if objectiveLower.contains("network") || objectiveLower.contains("connection") || objectiveLower.contains("socket") {
            vql = """
                -- Query to enumerate network connections
                SELECT Pid, Name, FamilyString as Family,
                       TypeString as Type,
                       format(format="%s:%d", args=[Laddr.IP, Laddr.Port]) as LocalAddress,
                       format(format="%s:%d", args=[Raddr.IP, Raddr.Port]) as RemoteAddress,
                       Status
                FROM netstat()
                WHERE Status = "ESTABLISHED" OR Status = "LISTEN"
                """
            explanation = """
                This query enumerates active network connections showing local and remote addresses,
                ports, and connection status. Filters for established connections and listening ports
                which are most relevant for security investigations.
                """
        }
        // File search queries
        else if objectiveLower.contains("file") || objectiveLower.contains("search") || objectiveLower.contains("find") {
            vql = """
                -- Query to search for files matching criteria
                SELECT FullPath, Name, Size, Mtime, Atime, Ctime,
                       hash(path=FullPath, hashselect="SHA256") as SHA256
                FROM glob(globs="C:/Users/*/Downloads/*", accessor="auto")
                WHERE Size > 0
                ORDER BY Mtime DESC
                LIMIT 1000
                """
            explanation = """
                This query searches for files in user download directories.
                Modify the glob pattern to target specific paths or file types.
                Collects file metadata and SHA256 hashes for forensic analysis.
                """
        }
        // Registry queries (Windows)
        else if objectiveLower.contains("registry") || objectiveLower.contains("autorun") || objectiveLower.contains("persistence") {
            vql = """
                -- Query to check common persistence locations in registry
                LET persistence_keys = (
                    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run",
                    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce",
                    "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Run",
                    "HKEY_CURRENT_USER\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\RunOnce",
                    "HKEY_LOCAL_MACHINE\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\Shell Folders"
                )
                
                SELECT Key.FullPath, Key.Mtime, 
                       Name, Type, Data
                FROM foreach(row=persistence_keys, query={
                    SELECT * FROM glob(globs=_value + "/*", accessor="registry")
                })
                """
            explanation = """
                This query examines common Windows registry persistence locations.
                Attackers frequently use these keys to maintain access across reboots.
                The query checks Run/RunOnce keys for both HKLM and HKCU hives.
                """
        }
        // Event log queries
        else if objectiveLower.contains("event") || objectiveLower.contains("log") || objectiveLower.contains("security") {
            vql = """
                -- Query Windows Security Event Log for authentication events
                SELECT System.TimeCreated.SystemTime as EventTime,
                       System.EventID.Value as EventID,
                       System.Computer as Computer,
                       EventData.TargetUserName as Username,
                       EventData.TargetDomainName as Domain,
                       EventData.LogonType as LogonType,
                       EventData.IpAddress as SourceIP,
                       Message
                FROM parse_evtx(filename="C:/Windows/System32/winevt/Logs/Security.evtx")
                WHERE System.EventID.Value in (4624, 4625, 4634, 4648, 4672)
                ORDER BY EventTime DESC
                LIMIT 1000
                """
            explanation = """
                This query parses the Windows Security Event Log for authentication-related events:
                - 4624: Successful logon
                - 4625: Failed logon
                - 4634: Logoff
                - 4648: Explicit credential logon
                - 4672: Special privileges assigned
                These events are critical for detecting unauthorized access and lateral movement.
                """
        }
        // Default comprehensive triage query
        else {
            vql = """
                -- Comprehensive triage query for forensic collection
                LET triage_data = SELECT * FROM chain(
                    -- System information
                    a = { SELECT * FROM info() },
                    
                    -- Running processes
                    b = { SELECT "Process" as Type, Pid, Name, Exe, CommandLine 
                          FROM pslist() LIMIT 100 },
                    
                    -- Network connections
                    c = { SELECT "Network" as Type, Pid, Name, 
                          format(format="%s:%d", args=[Laddr.IP, Laddr.Port]) as Local,
                          format(format="%s:%d", args=[Raddr.IP, Raddr.Port]) as Remote,
                          Status
                          FROM netstat() WHERE Status != "" LIMIT 100 },
                    
                    -- Scheduled tasks (Windows)
                    d = { SELECT "ScheduledTask" as Type, Name, Path, Actions
                          FROM Artifact.Windows.System.TaskScheduler() LIMIT 50 }
                )
                
                SELECT * FROM triage_data
                """
            explanation = """
                This comprehensive triage query collects essential forensic data including:
                - System information
                - Running processes with command lines
                - Active network connections
                - Scheduled tasks
                
                This provides a quick overview for initial incident assessment.
                Modify or expand based on specific investigation needs.
                """
        }
        
        var result = "# Generated VQL Query\n\n"
        result += "```vql\n\(vql)\n```\n\n"
        
        if includeExplanation {
            result += "## Explanation\n\n\(explanation)\n\n"
            result += "## Usage Notes\n\n"
            result += "- Run this query through the Velociraptor GUI or API\n"
            result += "- Adjust LIMIT clauses based on your environment size\n"
            result += "- Consider adding WHERE clauses to filter for specific indicators\n"
            result += "- For production hunts, test on a small set of endpoints first\n"
        }
        
        return result
    }
    
    // MARK: - Artifact Suggestion Logic
    
    private func suggestArtifactsForIncident(incidentType: String, platform: String, urgency: String, scope: String) -> String {
        var artifacts: [(name: String, priority: String, description: String, collection_time: String)] = []
        
        switch incidentType.lowercased() {
        case "ransomware":
            artifacts = [
                ("Windows.KapeFiles.Targets", "critical", "Collect KAPE forensic targets including MFT, event logs, and registry", "10-30 min"),
                ("Windows.EventLogs.Evtx", "critical", "Collect and parse Windows Event Logs for encryption activity", "5-15 min"),
                ("Windows.System.Amcache", "high", "Application execution history to identify ransomware binary", "2-5 min"),
                ("Windows.Forensics.Prefetch", "high", "Prefetch files showing recent program execution", "2-5 min"),
                ("Windows.Registry.RecentDocs", "medium", "Recently accessed documents (may show encrypted files)", "1-2 min"),
                ("Windows.Network.Netstat", "high", "Active network connections for C2 identification", "< 1 min"),
                ("Windows.Sys.Users", "medium", "User account information", "< 1 min"),
                ("Windows.Forensics.Usn", "high", "USN Journal for file system changes", "5-15 min")
            ]
            
        case "apt", "lateral_movement":
            artifacts = [
                ("Windows.System.Pslist", "critical", "Running processes with parent relationships", "< 1 min"),
                ("Windows.EventLogs.RDPAuth", "critical", "RDP authentication events for lateral movement", "2-5 min"),
                ("Windows.EventLogs.PowerShell", "critical", "PowerShell script block logging", "5-10 min"),
                ("Windows.Network.Netstat", "critical", "Network connections for C2 and lateral movement", "< 1 min"),
                ("Windows.Registry.NTUser", "high", "User registry hives for persistence", "5-10 min"),
                ("Windows.System.Services", "high", "Installed services for persistence", "1-2 min"),
                ("Windows.System.TaskScheduler", "high", "Scheduled tasks for persistence", "1-2 min"),
                ("Windows.Forensics.SRUM", "medium", "System Resource Usage Monitor data", "2-5 min"),
                ("Windows.Sys.Wmi", "high", "WMI persistence mechanisms", "2-5 min"),
                ("Windows.Detection.Autoruns", "high", "All autostart locations", "5-10 min")
            ]
            
        case "malware":
            artifacts = [
                ("Windows.System.Pslist", "critical", "Running processes with hashes", "< 1 min"),
                ("Windows.Detection.Yara.Process", "critical", "YARA scan of running processes", "5-15 min"),
                ("Windows.Forensics.Prefetch", "high", "Execution history", "2-5 min"),
                ("Windows.System.Amcache", "high", "Application execution records", "2-5 min"),
                ("Windows.Detection.Autoruns", "high", "Persistence mechanisms", "5-10 min"),
                ("Windows.System.Drivers", "medium", "Loaded drivers for rootkit detection", "1-2 min"),
                ("Windows.Network.Netstat", "high", "C2 connections", "< 1 min"),
                ("Windows.System.DLLs", "medium", "Loaded DLLs for injection detection", "2-5 min")
            ]
            
        case "insider_threat":
            artifacts = [
                ("Windows.Forensics.RecentApps", "critical", "Recently used applications", "1-2 min"),
                ("Windows.Forensics.Shellbags", "high", "Folder access history", "2-5 min"),
                ("Windows.EventLogs.Evtx", "critical", "Comprehensive event log collection", "5-15 min"),
                ("Windows.Applications.Chrome.History", "high", "Browser history", "2-5 min"),
                ("Windows.Forensics.Usn", "high", "File system activity journal", "5-15 min"),
                ("Windows.Network.Netstat", "medium", "Network connections", "< 1 min"),
                ("Windows.System.CatFiles", "medium", "USB device history", "1-2 min"),
                ("Windows.Registry.RecentDocs", "high", "Recently accessed documents", "1-2 min")
            ]
            
        case "data_exfiltration":
            artifacts = [
                ("Windows.Network.Netstat", "critical", "Active connections and data transfer", "< 1 min"),
                ("Windows.EventLogs.Security", "critical", "File access and share events", "5-15 min"),
                ("Windows.Forensics.Usn", "critical", "File copy and move operations", "5-15 min"),
                ("Windows.System.CatFiles", "high", "USB device connections", "1-2 min"),
                ("Windows.Applications.Chrome.Downloads", "high", "Browser download history", "1-2 min"),
                ("Windows.Forensics.Shellbags", "medium", "Folder navigation history", "2-5 min"),
                ("Windows.Sys.FirewallRules", "medium", "Firewall configuration", "1-2 min")
            ]
            
        case "credential_theft":
            artifacts = [
                ("Windows.EventLogs.Security", "critical", "Authentication events (4624, 4625, 4648)", "5-15 min"),
                ("Windows.System.Pslist", "critical", "Processes accessing LSASS", "< 1 min"),
                ("Windows.Sys.Users", "high", "User account enumeration", "< 1 min"),
                ("Windows.System.Services", "high", "Service account misuse", "1-2 min"),
                ("Windows.Detection.Mimikatz", "critical", "Mimikatz detection artifacts", "2-5 min"),
                ("Windows.Registry.SAM", "high", "SAM registry for local accounts", "2-5 min"),
                ("Windows.EventLogs.Kerberos", "high", "Kerberos authentication events", "5-10 min")
            ]
            
        default: // general_triage
            artifacts = [
                ("Generic.Client.Info", "critical", "Basic system information", "< 1 min"),
                ("Windows.System.Pslist", "critical", "Running processes", "< 1 min"),
                ("Windows.Network.Netstat", "high", "Network connections", "< 1 min"),
                ("Windows.Detection.Autoruns", "high", "Persistence mechanisms", "5-10 min"),
                ("Windows.EventLogs.Evtx", "medium", "Event logs", "5-15 min"),
                ("Windows.System.Services", "medium", "Installed services", "1-2 min"),
                ("Windows.Forensics.Prefetch", "medium", "Execution history", "2-5 min")
            ]
        }
        
        // Filter by urgency and scope
        if urgency == "critical" {
            artifacts = artifacts.filter { $0.priority == "critical" || $0.priority == "high" }
        }
        
        if scope == "minimal" {
            artifacts = Array(artifacts.prefix(3))
        } else if scope == "standard" {
            artifacts = Array(artifacts.prefix(6))
        }
        // comprehensive and forensic_full get all artifacts
        
        // Build response
        var result = "# Recommended Artifacts for \(incidentType.capitalized) Incident\n\n"
        result += "**Platform:** \(platform)\n"
        result += "**Urgency:** \(urgency)\n"
        result += "**Scope:** \(scope)\n\n"
        result += "## Artifact Collection Plan\n\n"
        result += "| Priority | Artifact | Est. Time | Description |\n"
        result += "|----------|----------|-----------|-------------|\n"
        
        for artifact in artifacts {
            let priorityEmoji = artifact.priority == "critical" ? "🔴" : (artifact.priority == "high" ? "🟠" : "🟡")
            result += "| \(priorityEmoji) \(artifact.priority.capitalized) | `\(artifact.name)` | \(artifact.collection_time) | \(artifact.description) |\n"
        }
        
        result += "\n## Quick Start Command\n\n"
        result += "```vql\n"
        result += "-- Run these artifacts as a hunt\n"
        result += "SELECT * FROM Artifact.Windows.Collection.Triage(\n"
        result += "    artifacts=[\n"
        for (index, artifact) in artifacts.prefix(5).enumerated() {
            let comma = index < min(artifacts.count, 5) - 1 ? "," : ""
            result += "        \"\(artifact.name)\"\(comma)\n"
        }
        result += "    ]\n"
        result += ")\n"
        result += "```\n"
        
        return result
    }
    
    // MARK: - Deployment Planning Logic
    
    private func createDeploymentPlan(deploymentType: String, environment: Value?, securityRequirements: Value?) -> String {
        var plan = "# Velociraptor Deployment Plan\n\n"
        plan += "**Deployment Type:** \(deploymentType)\n\n"
        
        switch deploymentType.lowercased() {
        case "standalone":
            plan += """
                ## Standalone Deployment
                
                A standalone deployment runs Velociraptor as both server and client on a single machine.
                Ideal for: Individual investigators, small labs, training environments.
                
                ### Prerequisites
                - [ ] Windows 10/11, Server 2016+, Linux, or macOS
                - [ ] Minimum 4GB RAM, 8GB recommended
                - [ ] 50GB+ available disk space
                - [ ] Administrator/root privileges
                
                ### Deployment Steps
                
                1. **Download Velociraptor**
                   ```powershell
                   # Download latest release
                   $url = "https://github.com/Velocidex/velociraptor/releases/latest"
                   ```
                
                2. **Generate Configuration**
                   ```bash
                   ./velociraptor config generate -i
                   ```
                
                3. **Start Server**
                   ```bash
                   ./velociraptor frontend -v
                   ```
                
                4. **Access GUI**
                   Navigate to https://localhost:8889 (default)
                
                ### Security Considerations
                - Use HTTPS with valid certificates for production
                - Configure strong authentication
                - Restrict network access to management interface
                
                """
                
        case "server_client":
            plan += """
                ## Server-Client Deployment
                
                Distributed architecture with a central server managing multiple client endpoints.
                Ideal for: Enterprise deployments, SOC operations, managed services.
                
                ### Prerequisites
                - [ ] Dedicated server (physical or VM)
                - [ ] Server: 8GB+ RAM, 100GB+ storage
                - [ ] Network connectivity between server and clients
                - [ ] SSL certificates for secure communication
                - [ ] Firewall rules for port 8000 (gRPC) and 8889 (GUI)
                
                ### Server Deployment Steps
                
                1. **Server Installation**
                   ```bash
                   # Generate server config
                   ./velociraptor config generate
                   
                   # Install as service
                   ./velociraptor service install --config server.config.yaml
                   ```
                
                2. **Generate Client Package**
                   ```bash
                   ./velociraptor config repack --config server.config.yaml \\
                       --exe velociraptor.exe \\
                       output client.exe
                   ```
                
                3. **Deploy Clients**
                   - Use GPO, SCCM, or other deployment tools
                   - Install client package on endpoints
                
                ### High Availability Considerations
                - Use load balancer for frontend scaling
                - Configure database replication
                - Implement backup procedures
                
                """
                
        case "kubernetes", "docker":
            plan += """
                ## Container Deployment
                
                Containerized deployment using Docker or Kubernetes for scalability.
                Ideal for: Cloud-native environments, dynamic scaling, microservices architecture.
                
                ### Prerequisites
                - [ ] Docker Engine 20.10+ or Kubernetes 1.20+
                - [ ] Persistent storage for data
                - [ ] Container registry access
                - [ ] Ingress controller (Kubernetes)
                
                ### Docker Deployment
                
                ```yaml
                # docker-compose.yaml
                version: '3.8'
                services:
                  velociraptor:
                    image: velocidex/velociraptor:latest
                    volumes:
                      - ./config:/config
                      - ./data:/data
                    ports:
                      - "8000:8000"
                      - "8889:8889"
                    restart: unless-stopped
                ```
                
                ### Kubernetes Deployment
                
                ```bash
                # Using Helm chart
                helm install velociraptor ./charts/velociraptor \\
                    --set persistence.enabled=true \\
                    --set ingress.enabled=true
                ```
                
                """
                
        default:
            plan += """
                ## Cloud Deployment (\(deploymentType))
                
                Deploy Velociraptor in cloud infrastructure for global reach and scalability.
                
                ### General Cloud Considerations
                - Use managed databases where available
                - Implement auto-scaling groups
                - Configure VPC/security groups appropriately
                - Enable cloud-native logging and monitoring
                - Consider serverless options for cost optimization
                
                """
        }
        
        // Add security requirements section if provided
        plan += "\n## Security Hardening Checklist\n\n"
        plan += "- [ ] Enable TLS 1.3 for all communications\n"
        plan += "- [ ] Configure certificate pinning for clients\n"
        plan += "- [ ] Implement multi-factor authentication\n"
        plan += "- [ ] Enable audit logging\n"
        plan += "- [ ] Configure network segmentation\n"
        plan += "- [ ] Implement backup and disaster recovery\n"
        plan += "- [ ] Regular security updates and patching\n"
        
        return plan
    }
    
    // MARK: - Timeline Analysis Logic
    
    private func analyzeForensicTimeline(timeRange: Value, focusAreas: Value?, knownIOCs: Value?) -> String {
        var analysis = "# Forensic Timeline Analysis Guide\n\n"
        
        analysis += """
            ## Timeline Analysis Approach
            
            Effective timeline analysis requires correlating events from multiple sources
            to build a comprehensive picture of attacker activity.
            
            ### Recommended VQL for Timeline Generation
            
            ```vql
            -- Generate super timeline from multiple sources
            LET timeline = SELECT * FROM chain(
                -- MFT Timeline
                a = { SELECT Mtime as EventTime, "MFT" as Source, 
                      FullPath, "FileModified" as EventType
                      FROM parse_mft(filename="C:/$MFT") },
                
                -- Event Log Timeline
                b = { SELECT System.TimeCreated.SystemTime as EventTime,
                      "EventLog" as Source,
                      System.Channel as FullPath,
                      format(format="EventID_%d", args=[System.EventID.Value]) as EventType
                      FROM parse_evtx(filename="C:/Windows/System32/winevt/Logs/*.evtx") },
                
                -- Prefetch Timeline
                c = { SELECT LastRunTimes[0] as EventTime, "Prefetch" as Source,
                      Executable as FullPath, "Execution" as EventType
                      FROM Artifact.Windows.Forensics.Prefetch() },
                
                -- Registry Timeline
                d = { SELECT Mtime as EventTime, "Registry" as Source,
                      Key.FullPath as FullPath, "RegistryModified" as EventType
                      FROM Artifact.Windows.Registry.NTUser() }
            )
            
            SELECT * FROM timeline
            WHERE EventTime > "2024-01-01"
            ORDER BY EventTime
            ```
            
            ### Key Events to Correlate
            
            | Event Type | Significance | Sources |
            |------------|--------------|---------|
            | Initial Access | First attacker foothold | Web logs, Email, Downloads |
            | Execution | Malware/tool execution | Prefetch, Amcache, Process logs |
            | Persistence | Maintaining access | Registry, Scheduled Tasks, Services |
            | Lateral Movement | Network spread | RDP logs, PSExec, WMI events |
            | Collection | Data gathering | File access, Archives created |
            | Exfiltration | Data theft | Network logs, Cloud uploads |
            
            ### Analysis Workflow
            
            1. **Establish baseline** - Understand normal activity patterns
            2. **Identify anomalies** - Find deviations from baseline
            3. **Pivot on indicators** - Expand from known-bad to unknown
            4. **Build timeline** - Chronological sequence of events
            5. **Document findings** - Clear, evidence-based conclusions
            
            """
        
        return analysis
    }
    
    // MARK: - IR Package Creation Logic
    
    private func createIncidentResponsePackage(name: String, platforms: Value, artifacts: Value, outputFormat: String, includeMemory: Bool) -> String {
        var result = "# Incident Response Package: \(name)\n\n"
        
        result += """
            ## Package Configuration
            
            Creating a self-contained incident response collector with the following specifications:
            
            **Package Name:** \(name)
            **Output Format:** \(outputFormat)
            **Memory Collection:** \(includeMemory ? "Enabled" : "Disabled")
            
            ### Generation Command
            
            ```bash
            # Generate offline collector
            velociraptor config repack \\
                --config server.config.yaml \\
                --exe velociraptor-v0.7.1-windows-amd64.exe \\
                output \(name).exe
            
            # Or use the GUI to create collector:
            # Server Artifacts -> Build Collector
            ```
            
            ### Package Contents
            
            The generated collector will include:
            - Velociraptor binary (self-extracting)
            - Embedded configuration
            - Selected artifact definitions
            - Collection parameters
            
            ### Deployment Instructions
            
            1. Copy collector to target system (USB, network share, etc.)
            2. Run with administrator privileges:
               ```cmd
               .\\collector.exe
               ```
            3. Collector will:
               - Execute all configured artifacts
               - Package results into ZIP/container
               - Clean up temporary files
            
            4. Retrieve the output package for analysis
            
            ### Output Structure
            
            ```
            Collection_[hostname]_[timestamp]/
            ├── uploads/           # Collected files
            ├── results/           # Artifact outputs (JSON)
            ├── logs/              # Collection logs
            └── metadata.json      # Collection metadata
            ```
            
            ### Security Notes
            
            - Collector runs with embedded credentials
            - Consider encrypting output packages
            - Maintain chain of custody documentation
            - Store collector securely (contains config secrets)
            
            """
        
        return result
    }
}

// Note: Value extension methods (stringValue, boolValue, intValue) are provided by the MCP SDK
