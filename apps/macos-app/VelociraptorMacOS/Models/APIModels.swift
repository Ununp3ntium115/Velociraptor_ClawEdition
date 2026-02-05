//
//  APIModels.swift
//  VelociraptorMacOS
//
//  Velociraptor API Request/Response Models
//  Gap: 0x01 - API Client Foundation
//
//  CDIF Pattern: Codable models with Swift 6 Sendable compliance
//  Swift 6 Concurrency: All models are Sendable and thread-safe
//

import Foundation

// MARK: - Server Info Models

/// Server information and health
struct ServerInfo: Codable, Sendable {
    let version: String?
    let name: String?
    let buildTime: String?
    let installTime: String?
    let serverUptime: Double?
    let frontendUptime: Double?
    let clientCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case version
        case name
        case buildTime = "build_time"
        case installTime = "install_time"
        case serverUptime = "server_uptime"
        case frontendUptime = "frontend_uptime"
        case clientCount = "client_count"
    }
}

/// Health check response
struct HealthResponse: Codable, Sendable {
    let status: String
    let version: String?
    let uptime: Double?
    let cpuPercent: Double?
    let memoryPercent: Double?
    
    enum CodingKeys: String, CodingKey {
        case status
        case version
        case uptime
        case cpuPercent = "cpu_percent"
        case memoryPercent = "memory_percent"
    }
    
    /// Computed property for health check
    var isHealthy: Bool {
        status.lowercased() == "ok" || status.lowercased() == "healthy"
    }
}

// MARK: - Client Models

/// Velociraptor client (endpoint/agent)
struct VelociraptorClient: Codable, Sendable, Identifiable, Hashable {
    let clientId: String
    let agentInformation: AgentInformation?
    let osInfo: OSInfo?
    let firstSeenAt: Date?
    let lastSeenAt: Date?
    let lastIp: String?
    let labels: [String]?
    
    var id: String { clientId }
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case agentInformation = "agent_information"
        case osInfo = "os_info"
        case firstSeenAt = "first_seen_at"
        case lastSeenAt = "last_seen_at"
        case lastIp = "last_ip"
        case labels
    }
    
    // Manual Hashable conformance using clientId only
    func hash(into hasher: inout Hasher) {
        hasher.combine(clientId)
    }
    
    static func == (lhs: VelociraptorClient, rhs: VelociraptorClient) -> Bool {
        lhs.clientId == rhs.clientId
    }
}

/// Agent information
struct AgentInformation: Codable, Sendable {
    let version: String?
    let name: String?
    let buildTime: String?
    let installTime: String?
    
    enum CodingKeys: String, CodingKey {
        case version
        case name
        case buildTime = "build_time"
        case installTime = "install_time"
    }
}

/// Operating system information
struct OSInfo: Codable, Sendable {
    let system: String?
    let hostname: String?
    let release: String?
    let machine: String?
    let fqdn: String?
    let kernel: String?
    
    enum CodingKeys: String, CodingKey {
        case system
        case hostname
        case release
        case machine
        case fqdn
        case kernel
    }
}

// MARK: - VelociraptorClient OS Extension

/// Extension to provide convenience properties
extension VelociraptorClient {
    /// Hostname from osInfo
    var hostname: String {
        osInfo?.hostname ?? "Unknown Host"
    }
    /// Computed OS type based on osInfo.system
    var os: ClientOSType {
        guard let system = osInfo?.system?.lowercased() else {
            return .unknown
        }
        
        if system.contains("windows") {
            return .windows
        } else if system.contains("linux") {
            return .linux
        } else if system.contains("darwin") || system.contains("macos") {
            return .darwin
        } else {
            return .unknown
        }
    }
    
    enum ClientOSType: String {
        case windows = "Windows"
        case linux = "Linux"
        case darwin = "macOS"
        case unknown = "Unknown"
        
        var displayName: String { rawValue }
        
        var iconName: String {
            switch self {
            case .windows: return "pc"
            case .linux: return "terminal"
            case .darwin: return "laptopcomputer"
            case .unknown: return "questionmark.circle"
            }
        }
    }
}

// MARK: - Hunt Models

/// Hunt state enum
enum HuntState: String, Codable, Sendable, CaseIterable {
    case running = "RUNNING"
    case stopped = "STOPPED"
    case paused = "PAUSED"
    case archived = "ARCHIVED"
    case unset = "UNSET"
    case unspecified = "UNSPECIFIED"
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .paused: return "Paused"
        case .archived: return "Archived"
        case .unset, .unspecified: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .running: return "play.circle.fill"
        case .stopped: return "stop.circle.fill"
        case .paused: return "pause.circle.fill"
        case .archived: return "archivebox.fill"
        case .unset, .unspecified: return "questionmark.circle"
        }
    }
}

/// Hunt object
struct Hunt: Codable, Sendable, Identifiable, Hashable {
    let huntId: String
    let huntDescription: String?
    let state: HuntState?
    let startRequest: StartRequest?
    let stats: HuntStats?
    let createTime: Date?
    let startTime: Date?
    let expires: Date?
    let creator: String?
    let condition: Condition?
    
    var id: String { huntId }
    
    // Hashable conformance based on huntId
    func hash(into hasher: inout Hasher) {
        hasher.combine(huntId)
    }
    
    static func == (lhs: Hunt, rhs: Hunt) -> Bool {
        lhs.huntId == rhs.huntId
    }
    
    enum CodingKeys: String, CodingKey {
        case huntId = "hunt_id"
        case huntDescription = "hunt_description"
        case state
        case startRequest = "start_request"
        case stats
        case createTime = "create_time"
        case startTime = "start_time"
        case expires
        case creator
        case condition
    }
}

/// Hunt extension for convenience properties
extension Hunt {
    /// Artifacts from startRequest
    var artifacts: [String] {
        startRequest?.artifacts ?? []
    }
    
    /// Total clients with results
    var totalClientsWithResults: Int {
        stats?.totalClientsWithResults ?? 0
    }
    
    /// Total clients scheduled
    var totalClientsScheduled: Int {
        stats?.totalClientsScheduled ?? 0
    }
    
    /// Total clients with errors
    var totalClientsWithErrors: Int {
        stats?.totalClientsWithErrors ?? 0
    }
    
    /// Progress as percentage (0-100)
    var progressPercent: Double {
        guard let stats = stats,
              let scheduled = stats.totalClientsScheduled,
              scheduled > 0,
              let withResults = stats.totalClientsWithResults else {
            return 0
        }
        return Double(withResults) / Double(scheduled) * 100
    }
}

/// Hunt start request
struct StartRequest: Codable, Sendable {
    let artifacts: [String]?
    let specs: [ArtifactSpec]?
    
    enum CodingKeys: String, CodingKey {
        case artifacts
        case specs
    }
}

/// Hunt statistics
struct HuntStats: Codable, Sendable {
    let totalClientsScheduled: Int?
    let totalClientsWithResults: Int?
    let totalClientsWithErrors: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalClientsScheduled = "total_clients_scheduled"
        case totalClientsWithResults = "total_clients_with_results"
        case totalClientsWithErrors = "total_clients_with_errors"
    }
}

/// Hunt condition (when to run)
struct Condition: Codable, Sendable {
    let excludedLabels: [String]?
    let labels: [String]?
    let os: OSCondition?
    
    enum CodingKeys: String, CodingKey {
        case excludedLabels = "excluded_labels"
        case labels
        case os
    }
}

/// OS condition for hunts
struct OSCondition: Codable, Sendable {
    let os: String?
    
    enum CodingKeys: String, CodingKey {
        case os
    }
}

// MARK: - Flow Models

/// Flow (artifact collection job)
struct Flow: Codable, Sendable, Identifiable {
    let sessionId: String
    let clientId: String?
    let flowId: String?
    let artifacts: [String]?
    let state: FlowState?
    let createTime: Date?
    let startTime: Date?
    let activeTime: Date?
    let totalUploadedFiles: Int?
    let totalExpectedUploadedBytes: Int?
    let totalUploadedBytes: Int?
    let totalCollectedRows: Int?
    let outstandingRequests: Int?
    let nextResponseId: Int?
    let executionDuration: Double?
    let totalLoads: Int?
    let userCpuTimeUsed: Double?
    let systemCpuTimeUsed: Double?
    
    var id: String { sessionId }
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case clientId = "client_id"
        case flowId = "flow_id"
        case artifacts
        case state
        case createTime = "create_time"
        case startTime = "start_time"
        case activeTime = "active_time"
        case totalUploadedFiles = "total_uploaded_files"
        case totalExpectedUploadedBytes = "total_expected_uploaded_bytes"
        case totalUploadedBytes = "total_uploaded_bytes"
        case totalCollectedRows = "total_collected_rows"
        case outstandingRequests = "outstanding_requests"
        case nextResponseId = "next_response_id"
        case executionDuration = "execution_duration"
        case totalLoads = "total_loads"
        case userCpuTimeUsed = "user_cpu_time_used"
        case systemCpuTimeUsed = "system_cpu_time_used"
    }
}

/// Flow state
enum FlowState: String, Codable, Sendable {
    case running = "RUNNING"
    case terminated = "TERMINATED"
    case error = "ERROR"
    case finished = "FINISHED"
    case unset = "UNSET"
    
    var displayName: String {
        switch self {
        case .running: return "Running"
        case .terminated: return "Terminated"
        case .error: return "Error"
        case .finished: return "Finished"
        case .unset: return "Unknown"
        }
    }
}

// MARK: - VQL Models

/// VQL query result
struct VQLResult: Sendable {
    let columns: [String]?
    let rows: [[VQLValue]]?
    let totalRows: Int?
    
    init(columns: [String]?, rows: [[VQLValue]]?, totalRows: Int? = nil) {
        self.columns = columns
        self.rows = rows
        self.totalRows = totalRows
    }
}

// MARK: - VQLResult Decodable

extension VQLResult: Decodable {
    enum CodingKeys: String, CodingKey {
        case columns
        case rows
        case totalRows = "total_rows"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        columns = try container.decodeIfPresent([String].self, forKey: .columns)
        totalRows = try container.decodeIfPresent(Int.self, forKey: .totalRows)
        
        // VQL rows can be complex nested structures
        if let rowsData = try container.decodeIfPresent([[String: AnyCodable]].self, forKey: .rows) {
            rows = rowsData.map { row in
                row.values.map { VQLValue.object($0.value) }
            }
        } else {
            rows = nil
        }
    }
}

/// VQL value (can be string, number, bool, object, array)
/// Note: Uses @unchecked Sendable because VQL results may contain dynamic types
enum VQLValue: @unchecked Sendable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case object(Any)
    case array([Any])
    case null
    
    /// Convert VQL value to a display string
    var stringValue: String {
        switch self {
        case .string(let s):
            return s
        case .number(let n):
            if n.truncatingRemainder(dividingBy: 1) == 0 {
                return String(format: "%.0f", n)
            }
            return String(n)
        case .bool(let b):
            return b ? "true" : "false"
        case .object(let obj):
            if let data = try? JSONSerialization.data(withJSONObject: obj, options: .fragmentsAllowed),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return String(describing: obj)
        case .array(let arr):
            if let data = try? JSONSerialization.data(withJSONObject: arr, options: .fragmentsAllowed),
               let str = String(data: data, encoding: .utf8) {
                return str
            }
            return String(describing: arr)
        case .null:
            return "null"
        }
    }
}

/// Helper for decoding any JSON value
/// Note: Uses @unchecked Sendable for flexibility with dynamic JSON structures
struct AnyCodable: Codable, @unchecked Sendable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if let intValue = try? container.decode(Int.self) {
            value = intValue
        } else if let doubleValue = try? container.decode(Double.self) {
            value = doubleValue
        } else if let boolValue = try? container.decode(Bool.self) {
            value = boolValue
        } else if let stringValue = try? container.decode(String.self) {
            value = stringValue
        } else if let arrayValue = try? container.decode([AnyCodable].self) {
            value = arrayValue.map { $0.value }
        } else if let dictValue = try? container.decode([String: AnyCodable].self) {
            value = dictValue.mapValues { $0.value }
        } else {
            value = NSNull()
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch value {
        case let intValue as Int:
            try container.encode(intValue)
        case let doubleValue as Double:
            try container.encode(doubleValue)
        case let boolValue as Bool:
            try container.encode(boolValue)
        case let stringValue as String:
            try container.encode(stringValue)
        case let arrayValue as [Any]:
            try container.encode(arrayValue.map { AnyCodable($0) })
        case let dictValue as [String: Any]:
            try container.encode(dictValue.mapValues { AnyCodable($0) })
        default:
            try container.encodeNil()
        }
    }
}

// MARK: - VFS Models

/// VFS (Virtual File System) entry
struct VFSEntry: Codable, Sendable, Identifiable {
    let name: String
    let size: Int64?
    let mode: String?
    let mtime: Date?
    let atime: Date?
    let ctime: Date?
    let btime: Date?
    let isDir: Bool?
    let data: VFSData?
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case size = "Size"
        case mode = "Mode"
        case mtime = "mtime"
        case atime = "atime"
        case ctime = "ctime"
        case btime = "btime"
        case isDir = "IsDir"
        case data = "Data"
    }
}

/// VFS entry data
struct VFSData: Codable, Sendable {
    let pathspec: VFSPathspec?
    
    enum CodingKeys: String, CodingKey {
        case pathspec = "Pathspec"
    }
}

/// VFS path specification
struct VFSPathspec: Codable, Sendable {
    let path: String?
    let pathType: String?
    
    enum CodingKeys: String, CodingKey {
        case path = "Path"
        case pathType = "PathType"
    }
}

// MARK: - Artifact Models

/// Artifact definition
struct Artifact: Codable, Sendable, Identifiable {
    let name: String
    let description: String?
    let type: String?
    let author: String?
    let precondition: String?
    let parameters: [ArtifactParameter]?
    let sources: [ArtifactSource]?
    let reports: [ArtifactReport]?
    let tools: [ArtifactTool]?
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case type
        case author
        case precondition
        case parameters
        case sources
        case reports
        case tools
    }
}

/// Artifact parameter
struct ArtifactParameter: Codable, Sendable {
    let name: String?
    let description: String?
    let type: String?
    let defaultValue: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case type
        case defaultValue = "default"
    }
}

/// Artifact source
struct ArtifactSource: Codable, Sendable {
    let name: String?
    let description: String?
    let query: String?
    let precondition: String?
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case query
        case precondition
    }
}

/// Artifact report
struct ArtifactReport: Codable, Sendable {
    let type: String?
    let template: String?
    
    enum CodingKeys: String, CodingKey {
        case type
        case template
    }
}

/// Artifact tool
struct ArtifactTool: Codable, Sendable {
    let name: String?
    let url: String?
    let serveLocally: Bool?
    
    enum CodingKeys: String, CodingKey {
        case name
        case url
        case serveLocally = "serve_locally"
    }
}

/// Artifact specification for collection
struct ArtifactSpec: Codable, Sendable {
    let artifact: String
    let parameters: [String: String]?
    
    enum CodingKeys: String, CodingKey {
        case artifact
        case parameters
    }
}

// MARK: - User Models

/// Velociraptor user
struct VelociraptorUser: Codable, Sendable, Identifiable {
    let name: String
    let roles: [String]?
    let locked: Bool?
    let picture: String?
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case roles
        case locked
        case picture
    }
}

// MARK: - Label Models

/// Client label
struct ClientLabel: Codable, Sendable, Identifiable {
    let label: String
    let count: Int?
    
    var id: String { label }
    
    enum CodingKeys: String, CodingKey {
        case label
        case count
    }
}

// MARK: - Notification Models

/// Server event/notification
struct ServerEvent: Codable, Sendable, Identifiable {
    let id: String
    let timestamp: Date
    let eventType: String
    let clientId: String?
    let flowId: String?
    let huntId: String?
    let artifactName: String?
    let message: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case eventType = "event_type"
        case clientId = "client_id"
        case flowId = "flow_id"
        case huntId = "hunt_id"
        case artifactName = "artifact_name"
        case message
    }
}

// MARK: - Error Models

/// API error response
struct APIErrorResponse: Codable, Sendable {
    let error: String?
    let message: String?
    let code: Int?
    
    enum CodingKeys: String, CodingKey {
        case error
        case message
        case code
    }
}

// MARK: - Request Models

/// Generic search request
struct SearchRequest: Codable, Sendable {
    let query: String?
    let limit: Int?
    let offset: Int?
    let sort: String?
    
    enum CodingKeys: String, CodingKey {
        case query
        case limit
        case offset
        case sort
    }
}

/// Collection request
struct CollectionRequest: Codable, Sendable {
    let clientId: String
    let artifacts: [String]
    let specs: [ArtifactSpec]?
    let urgent: Bool?
    let allowCustomOverrides: Bool?
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case artifacts
        case specs
        case urgent
        case allowCustomOverrides = "allow_custom_overrides"
    }
}

/// Hunt create request
struct HuntCreateRequest: Codable, Sendable {
    let huntDescription: String
    let artifacts: [String]
    let specs: [ArtifactSpec]?
    let expires: Int?
    let includeLabels: [String]?
    let excludeLabels: [String]?
    let condition: Condition?
    
    enum CodingKeys: String, CodingKey {
        case huntDescription = "hunt_description"
        case artifacts
        case specs
        case expires
        case includeLabels = "include_labels"
        case excludeLabels = "exclude_labels"
        case condition
    }
}

/// Hunt modify request
struct HuntModifyRequest: Codable, Sendable {
    let huntId: String
    let state: HuntState
    
    enum CodingKeys: String, CodingKey {
        case huntId = "hunt_id"
        case state
    }
}

/// VQL query request
struct VQLQueryRequest: Codable, Sendable {
    let query: String
    let env: [VQLEnvironmentVar]?
    let timeout: Int?
    let maxRow: Int?
    let maxWait: Int?
    
    enum CodingKeys: String, CodingKey {
        case query
        case env
        case timeout
        case maxRow = "max_row"
        case maxWait = "max_wait"
    }
}

/// VQL environment variable
struct VQLEnvironmentVar: Codable, Sendable {
    let key: String
    let value: String
    
    enum CodingKeys: String, CodingKey {
        case key
        case value
    }
}

// MARK: - Response Wrapper Models

/// Generic list response
struct ListResponse<T: Codable>: Codable where T: Sendable {
    let items: [T]?
    let totalCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case items
        case totalCount = "total_count"
    }
}

/// Generic pagination metadata
struct PaginationMetadata: Codable, Sendable {
    let limit: Int
    let offset: Int
    let totalCount: Int?
    let hasMore: Bool?
    
    enum CodingKeys: String, CodingKey {
        case limit
        case offset
        case totalCount = "total_count"
        case hasMore = "has_more"
    }
}

// MARK: - Helper Extensions

extension VelociraptorClient {
    /// Human-readable last seen time
    var lastSeenFormatted: String {
        guard let lastSeen = lastSeenAt else { return "Never" }
        
        let interval = Date().timeIntervalSince(lastSeen)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    /// Whether client is online (seen in last 5 minutes)
    var isOnline: Bool {
        guard let lastSeen = lastSeenAt else { return false }
        return Date().timeIntervalSince(lastSeen) < 300
    }
}

extension Hunt {
    /// Human-readable state
    var stateDescription: String {
        switch state {
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .paused: return "Paused"
        case .archived: return "Archived"
        case .unset, .unspecified, .none: return "Not Started"
        }
    }
    
    /// Progress percentage
    var progressPercentage: Double {
        guard let scheduled = stats?.totalClientsScheduled,
              let results = stats?.totalClientsWithResults,
              scheduled > 0 else {
            return 0.0
        }
        return Double(results) / Double(scheduled) * 100.0
    }
}

extension Flow {
    /// Human-readable state
    var stateDescription: String {
        switch state {
        case .running: return "Running"
        case .terminated: return "Terminated"
        case .error: return "Error"
        case .finished: return "Finished"
        case .unset, .none: return "Unknown"
        }
    }
    
    /// Upload progress percentage
    var uploadProgress: Double {
        guard let expected = totalExpectedUploadedBytes,
              let uploaded = totalUploadedBytes,
              expected > 0 else {
            return 0.0
        }
        return Double(uploaded) / Double(expected) * 100.0
    }
}
