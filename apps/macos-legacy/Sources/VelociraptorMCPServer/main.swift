// main.swift
// VelociraptorMCPServer - Model Context Protocol Server for Velociraptor DFIR
//
// This server exposes Velociraptor DFIR capabilities through the Model Context Protocol,
// enabling AI assistants like Claude, Cursor, and other MCP hosts to interact with
// Velociraptor tools for digital forensics and incident response.
//
// Usage:
//   ./VelociraptorMCPServer          # Start with stdio transport (default)
//   ./VelociraptorMCPServer --http   # Start with HTTP transport
//   ./VelociraptorMCPServer --help   # Show usage information
//
// Copyright (c) 2026 Velociraptor Claw Edition Project
// Licensed under Apache 2.0

import Foundation
import MCP
import ServiceLifecycle
import Logging
import ArgumentParser
import VelociraptorMCP

// MARK: - CLI Arguments

@main
struct VelociraptorMCPServerCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "VelociraptorMCPServer",
        abstract: "Model Context Protocol server for Velociraptor DFIR tools",
        discussion: """
            This MCP server exposes Velociraptor digital forensics and incident response
            capabilities to AI assistants. It can be used with:
            
            - Claude Desktop (add to claude_desktop_config.json)
            - Cursor IDE (add to .cursor/mcp.json)
            - Any other MCP-compatible host
            
            The server provides tools for:
            - VQL query generation
            - Artifact recommendations
            - Deployment planning
            - Timeline analysis
            - Incident response package creation
            """,
        version: "1.0.0"
    )
    
    @Option(name: .shortAndLong, help: "Transport type: stdio (default) or http")
    var transport: TransportType = .stdio
    
    @Option(name: .shortAndLong, help: "Port for HTTP transport (default: 3000)")
    var port: Int = 3000
    
    @Option(name: .shortAndLong, help: "Log level: debug, info, warning, error")
    var logLevel: String = "info"
    
    @Flag(name: .long, help: "Enable verbose logging")
    var verbose: Bool = false
    
    func run() async throws {
        // Configure logging
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = verbose ? .debug : parseLogLevel(logLevel)
            return handler
        }
        
        let logger = Logger(label: "com.velociraptor.mcp.server")
        logger.info("Starting Velociraptor MCP Server", metadata: [
            "transport": "\(transport)",
            "version": "1.0.0"
        ])
        
        // Create the MCP server
        let server = VelociraptorMCPServerImpl(logger: logger)
        
        // Start with appropriate transport
        switch transport {
        case .stdio:
            try await server.runWithStdio()
        case .http:
            try await server.runWithHTTP(port: port)
        }
    }
    
    private func parseLogLevel(_ level: String) -> Logger.Level {
        switch level.lowercased() {
        case "debug", "trace": return .debug
        case "info": return .info
        case "warning", "warn": return .warning
        case "error": return .error
        default: return .info
        }
    }
}

// MARK: - Transport Type

enum TransportType: String, ExpressibleByArgument {
    case stdio
    case http
}

// MARK: - MCP Server Implementation

actor VelociraptorMCPServerImpl {
    private let logger: Logger
    private let toolHandler: VelociraptorToolHandler
    private var mcpServer: Server?
    
    init(logger: Logger) {
        self.logger = logger
        self.toolHandler = VelociraptorToolHandler(logger: logger)
    }
    
    func runWithStdio() async throws {
        logger.info("Starting MCP server with stdio transport")
        
        // Create MCP server with capabilities
        let server = Server(
            name: "velociraptor-mcp",
            version: "1.0.0",
            capabilities: .init(
                prompts: .init(listChanged: true),
                resources: .init(subscribe: false, listChanged: true),
                tools: .init(listChanged: true)
            )
        )
        
        self.mcpServer = server
        
        // Register handlers
        await registerHandlers(server: server)
        
        // Create stdio transport and start
        let transport = StdioTransport(logger: logger)
        
        // Start the server
        try await server.start(transport: transport) { clientInfo, capabilities in
            self.logger.info("Client connected", metadata: [
                "client": "\(clientInfo.name)",
                "version": "\(clientInfo.version)"
            ])
        }
        
        // Keep running until interrupted
        logger.info("MCP server running on stdio. Press Ctrl+C to stop.")
        
        // Use service lifecycle for graceful shutdown
        let service = MCPService(server: server, transport: transport)
        let serviceGroup = ServiceGroup(
            services: [service],
            configuration: .init(
                gracefulShutdownSignals: [.sigterm, .sigint]
            ),
            logger: logger
        )
        
        try await serviceGroup.run()
    }
    
    func runWithHTTP(port: Int) async throws {
        logger.info("Starting MCP server with HTTP transport", metadata: ["port": "\(port)"])
        
        // Create MCP server
        let server = Server(
            name: "velociraptor-mcp",
            version: "1.0.0",
            capabilities: .init(
                prompts: .init(listChanged: true),
                resources: .init(subscribe: false, listChanged: true),
                tools: .init(listChanged: true)
            )
        )
        
        self.mcpServer = server
        
        // Register handlers
        await registerHandlers(server: server)
        
        logger.info("HTTP transport not yet implemented. Use stdio transport.")
        logger.info("For HTTP, consider running behind a reverse proxy that bridges to stdio.")
        
        // For now, fall back to stdio
        try await runWithStdio()
    }
    
    private func registerHandlers(server: Server) async {
        // Register tool list handler
        await server.withMethodHandler(ListTools.self) { [self] _ in
            self.logger.debug("Listing available tools")
            return ListTools.Result(tools: VelociraptorTools.allTools)
        }
        
        // Register tool call handler
        await server.withMethodHandler(CallTool.self) { [self] params in
            self.logger.info("Tool call received", metadata: ["tool": "\(params.name)"])
            return try await self.toolHandler.handleToolCall(
                name: params.name,
                arguments: params.arguments
            )
        }
        
        // Register prompt list handler
        await server.withMethodHandler(ListPrompts.self) { [self] _ in
            self.logger.debug("Listing available prompts")
            return ListPrompts.Result(prompts: VelociraptorPrompts.allPrompts)
        }
        
        // Register prompt get handler
        await server.withMethodHandler(GetPrompt.self) { [self] params in
            self.logger.info("Prompt requested", metadata: ["prompt": "\(params.name)"])
            return try VelociraptorPrompts.getPrompt(name: params.name, arguments: params.arguments)
        }
        
        // Register resource list handler
        await server.withMethodHandler(ListResources.self) { [self] _ in
            self.logger.debug("Listing available resources")
            return ListResources.Result(resources: VelociraptorResources.allResources)
        }
        
        // Register resource read handler
        await server.withMethodHandler(ReadResource.self) { [self] params in
            self.logger.info("Resource requested", metadata: ["uri": "\(params.uri)"])
            return try VelociraptorResources.readResource(uri: params.uri)
        }
        
        logger.info("All MCP handlers registered successfully")
    }
}

// MARK: - MCP Service for Lifecycle Management

struct MCPService: Service {
    let server: Server
    let transport: StdioTransport
    
    func run() async throws {
        // Server is already started, just wait
        try await Task.sleep(for: .seconds(365 * 24 * 60 * 60)) // Effectively forever
    }
}

// MARK: - Prompts

enum VelociraptorPrompts {
    static let incidentResponse = Prompt(
        name: "incident_response",
        description: "Start an incident response workflow with AI guidance",
        arguments: [
            .init(name: "incident_type", description: "Type of incident (ransomware, apt, malware, etc.)", required: true),
            .init(name: "urgency", description: "Urgency level (critical, high, medium, low)", required: false),
            .init(name: "platform", description: "Target platform (Windows, Linux, macOS)", required: false)
        ]
    )
    
    static let forensicAnalysis = Prompt(
        name: "forensic_analysis",
        description: "Begin a forensic analysis session with step-by-step guidance",
        arguments: [
            .init(name: "artifact_type", description: "Type of artifact to analyze", required: true),
            .init(name: "context", description: "Additional context about the investigation", required: false)
        ]
    )
    
    static let vqlHelper = Prompt(
        name: "vql_helper",
        description: "Get interactive help writing VQL queries",
        arguments: [
            .init(name: "objective", description: "What you want to achieve with VQL", required: true)
        ]
    )
    
    static let deploymentWizard = Prompt(
        name: "deployment_wizard",
        description: "Interactive Velociraptor deployment planning wizard",
        arguments: [
            .init(name: "environment", description: "Target environment description", required: false)
        ]
    )
    
    static var allPrompts: [Prompt] {
        [incidentResponse, forensicAnalysis, vqlHelper, deploymentWizard]
    }
    
    static func getPrompt(name: String, arguments: [String: Value]?) throws -> GetPrompt.Result {
        switch name {
        case "incident_response":
            let incidentType = arguments?["incident_type"]?.stringValue ?? "general"
            let urgency = arguments?["urgency"]?.stringValue ?? "high"
            let platform = arguments?["platform"]?.stringValue ?? "Windows"
            
            return GetPrompt.Result(
                description: "Incident Response Workflow for \(incidentType)",
                messages: [
                    .user("""
                        I'm responding to a \(incidentType) incident with \(urgency) urgency on \(platform) systems.
                        
                        Please help me with:
                        1. Initial triage steps
                        2. Evidence collection priorities
                        3. Recommended Velociraptor artifacts to deploy
                        4. VQL queries for hunting related indicators
                        5. Containment recommendations
                        
                        Start by asking me clarifying questions about the incident scope and current status.
                        """),
                    .assistant("""
                        I'll help you respond to this \(incidentType) incident. Let me start by gathering some critical information:
                        
                        **Initial Assessment Questions:**
                        
                        1. **Scope**: How many endpoints are potentially affected?
                        2. **Timeline**: When was the incident first detected?
                        3. **Indicators**: Do you have any IOCs (hashes, IPs, domains) identified?
                        4. **Current Status**: Are affected systems still online/accessible?
                        5. **Prior Actions**: What containment steps have already been taken?
                        
                        Once I understand the scope, I'll provide:
                        - Prioritized artifact collection plan
                        - Custom VQL queries for your specific indicators
                        - Timeline analysis guidance
                        - Evidence preservation checklist
                        
                        Let's start - can you describe the initial detection event?
                        """)
                ]
            )
            
        case "forensic_analysis":
            let artifactType = arguments?["artifact_type"]?.stringValue ?? "general"
            let context = arguments?["context"]?.stringValue ?? ""
            
            return GetPrompt.Result(
                description: "Forensic Analysis Session for \(artifactType)",
                messages: [
                    .user("""
                        I need help analyzing \(artifactType) forensic artifacts.
                        \(context.isEmpty ? "" : "Context: \(context)")
                        
                        Please guide me through:
                        1. What to look for in this artifact type
                        2. Common indicators of compromise
                        3. VQL queries for extraction and analysis
                        4. How to interpret the results
                        """),
                    .assistant("""
                        I'll guide you through analyzing \(artifactType) artifacts. Let's approach this systematically.
                        
                        **Analysis Framework:**
                        
                        1. **Collection**: Ensure proper evidence handling
                        2. **Processing**: Parse and normalize the data
                        3. **Analysis**: Look for anomalies and indicators
                        4. **Correlation**: Connect findings to other evidence
                        5. **Documentation**: Record findings with timestamps
                        
                        Let me know what specific data you have collected, and I'll provide targeted VQL queries and interpretation guidance.
                        """)
                ]
            )
            
        case "vql_helper":
            let objective = arguments?["objective"]?.stringValue ?? "query data"
            
            return GetPrompt.Result(
                description: "VQL Query Development Assistant",
                messages: [
                    .user("""
                        I need help writing a VQL query to: \(objective)
                        
                        Please help me:
                        1. Understand the relevant VQL plugins and functions
                        2. Build the query step by step
                        3. Optimize for performance
                        4. Handle edge cases
                        """),
                    .assistant("""
                        I'll help you build a VQL query for: **\(objective)**
                        
                        Let's develop this step by step. First, some questions:
                        
                        1. **Target Platform**: Windows, Linux, or macOS?
                        2. **Data Source**: What artifact or data do you need to query?
                        3. **Output**: What fields/columns do you need in the results?
                        4. **Filters**: Any specific conditions to apply?
                        5. **Scale**: Single endpoint or hunt across many?
                        
                        As we build the query, I'll explain:
                        - The VQL plugins being used
                        - Why certain patterns are preferred
                        - Performance optimization tips
                        - Common pitfalls to avoid
                        
                        What's your target platform?
                        """)
                ]
            )
            
        case "deployment_wizard":
            let environment = arguments?["environment"]?.stringValue ?? "not specified"
            
            return GetPrompt.Result(
                description: "Velociraptor Deployment Planning Wizard",
                messages: [
                    .user("""
                        I want to deploy Velociraptor in my environment.
                        \(environment == "not specified" ? "" : "Environment: \(environment)")
                        
                        Please help me plan:
                        1. Deployment architecture
                        2. Infrastructure requirements
                        3. Security configuration
                        4. Rollout strategy
                        """),
                    .assistant("""
                        I'll help you plan your Velociraptor deployment! Let's gather the key requirements:
                        
                        **Environment Assessment:**
                        
                        1. **Scale**: How many endpoints will you manage?
                           - Small (< 100)
                           - Medium (100-1000)
                           - Large (1000-10000)
                           - Enterprise (10000+)
                        
                        2. **Infrastructure**:
                           - On-premises / Cloud / Hybrid?
                           - Preferred cloud provider (if applicable)?
                        
                        3. **OS Distribution**:
                           - Percentage Windows/Linux/macOS?
                        
                        4. **Use Cases**:
                           - Continuous monitoring?
                           - Incident response only?
                           - Compliance auditing?
                        
                        5. **Security Requirements**:
                           - Any compliance frameworks (HIPAA, PCI-DSS, etc.)?
                           - Network restrictions?
                        
                        Based on your answers, I'll recommend the optimal deployment architecture and provide step-by-step guidance.
                        """)
                ]
            )
            
        default:
            throw MCPError.invalidParams("Unknown prompt: \(name)")
        }
    }
}

// MARK: - Resources

enum VelociraptorResources {
    static let vqlReference = Resource(
        name: "VQL Quick Reference",
        uri: "velociraptor://docs/vql-reference",
        description: "Quick reference guide for Velociraptor Query Language",
        mimeType: "text/markdown"
    )
    
    static let artifactCatalog = Resource(
        name: "Artifact Catalog",
        uri: "velociraptor://docs/artifacts",
        description: "Catalog of available Velociraptor artifacts",
        mimeType: "text/markdown"
    )
    
    static let incidentPlaybooks = Resource(
        name: "Incident Response Playbooks",
        uri: "velociraptor://docs/playbooks",
        description: "Collection of incident response playbooks",
        mimeType: "text/markdown"
    )
    
    static var allResources: [Resource] {
        [vqlReference, artifactCatalog, incidentPlaybooks]
    }
    
    static func readResource(uri: String) throws -> ReadResource.Result {
        switch uri {
        case "velociraptor://docs/vql-reference":
            return ReadResource.Result(contents: [
                .text(vqlReferenceContent, uri: uri, mimeType: "text/markdown")
            ])
            
        case "velociraptor://docs/artifacts":
            return ReadResource.Result(contents: [
                .text(artifactCatalogContent, uri: uri, mimeType: "text/markdown")
            ])
            
        case "velociraptor://docs/playbooks":
            return ReadResource.Result(contents: [
                .text(playbooksContent, uri: uri, mimeType: "text/markdown")
            ])
            
        default:
            throw MCPError.invalidParams("Unknown resource: \(uri)")
        }
    }
    
    private static let vqlReferenceContent = """
        # VQL Quick Reference
        
        ## Basic Query Structure
        
        ```vql
        SELECT column1, column2
        FROM plugin()
        WHERE condition
        ORDER BY column
        LIMIT n
        ```
        
        ## Common Plugins
        
        | Plugin | Description |
        |--------|-------------|
        | `pslist()` | List running processes |
        | `netstat()` | Network connections |
        | `glob()` | File system search |
        | `parse_evtx()` | Parse Windows Event Logs |
        | `info()` | System information |
        | `hash()` | Calculate file hashes |
        
        ## Useful Functions
        
        - `format()` - String formatting
        - `timestamp()` - Time parsing
        - `regex()` - Regular expression matching
        - `if()` - Conditional logic
        - `dict()` - Create dictionaries
        - `array()` - Create arrays
        
        ## Examples
        
        ### Find processes by name
        ```vql
        SELECT * FROM pslist() WHERE Name =~ "chrome"
        ```
        
        ### Search for files
        ```vql
        SELECT * FROM glob(globs="C:/Users/*/Downloads/*.exe")
        ```
        
        ### Parse event logs
        ```vql
        SELECT * FROM parse_evtx(filename="Security.evtx")
        WHERE System.EventID.Value = 4624
        ```
        """
    
    private static let artifactCatalogContent = """
        # Velociraptor Artifact Catalog
        
        ## Windows Artifacts
        
        ### System Information
        - `Generic.Client.Info` - Basic client information
        - `Windows.Sys.Users` - User accounts
        - `Windows.System.Services` - Windows services
        - `Windows.System.Drivers` - Loaded drivers
        
        ### Process & Execution
        - `Windows.System.Pslist` - Running processes
        - `Windows.Forensics.Prefetch` - Prefetch files
        - `Windows.System.Amcache` - Amcache entries
        - `Windows.Forensics.Shimcache` - Shimcache entries
        
        ### File System
        - `Windows.NTFS.MFT` - Master File Table
        - `Windows.Forensics.Usn` - USN Journal
        - `Windows.Search.FileFinder` - Search for files
        
        ### Registry
        - `Windows.Registry.NTUser` - User registry hives
        - `Windows.Registry.Autoruns` - Autorun locations
        
        ### Event Logs
        - `Windows.EventLogs.Evtx` - Event log collection
        - `Windows.EventLogs.PowerShell` - PowerShell logs
        - `Windows.EventLogs.RDPAuth` - RDP authentication
        
        ### Network
        - `Windows.Network.Netstat` - Network connections
        - `Windows.Network.ArpCache` - ARP cache
        
        ## Linux Artifacts
        
        - `Linux.Sys.Users` - User accounts
        - `Linux.Proc.Pslist` - Process list
        - `Linux.Forensics.Bash.History` - Bash history
        - `Linux.Sys.Crontab` - Scheduled tasks
        
        ## macOS Artifacts
        
        - `MacOS.Sys.Users` - User accounts
        - `MacOS.Proc.Pslist` - Process list
        - `MacOS.Applications.Chrome.History` - Chrome history
        """
    
    private static let playbooksContent = """
        # Incident Response Playbooks
        
        ## Ransomware Response
        
        ### Phase 1: Detection & Scoping
        1. Identify affected systems
        2. Determine ransomware variant
        3. Find initial access vector
        
        ### Phase 2: Containment
        1. Isolate affected systems
        2. Block C2 communications
        3. Disable compromised accounts
        
        ### Phase 3: Evidence Collection
        1. Memory acquisition
        2. Disk imaging
        3. Log collection
        
        ### Key Artifacts
        - Encrypted file samples
        - Ransom notes
        - Prefetch entries
        - Event logs (especially Security and PowerShell)
        
        ---
        
        ## APT/Advanced Threat Response
        
        ### Phase 1: Initial Assessment
        1. Identify IOCs from detection
        2. Hunt for related indicators
        3. Establish timeline
        
        ### Phase 2: Deep Dive
        1. Analyze persistence mechanisms
        2. Map lateral movement
        3. Identify data access
        
        ### Key Artifacts
        - Scheduled tasks
        - Services
        - Registry autoruns
        - WMI subscriptions
        - Authentication logs
        
        ---
        
        ## Insider Threat Investigation
        
        ### Focus Areas
        1. Data access patterns
        2. Unusual working hours
        3. Large file transfers
        4. USB device usage
        5. Cloud storage access
        
        ### Key Artifacts
        - Shellbags
        - Recent documents
        - USB device history
        - Browser history
        - Email metadata
        """
}
