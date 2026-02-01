//
//  APIModels.swift
//  VelociraptorMacOS
//
//  Data models for Velociraptor API responses
//  Gap: 0x01 - API Client Foundation
//

import Foundation

// MARK: - Client Models

/// Represents a Velociraptor client (endpoint)
struct VelociraptorClient: Codable, Identifiable, Hashable, Sendable {
    let clientId: String
    let hostname: String
    let os: ClientOS
    let osInfo: OSInfo?
    let lastSeenAt: Date?
    let lastHuntTimestamp: Date?
    let lastInterrogateFlowId: String?
    let labels: [String]
    let agentInfo: AgentInfo?
    let firstSeenAt: Date?
    
    var id: String { clientId }
    
    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case hostname
        case os
        case osInfo = "os_info"
        case lastSeenAt = "last_seen_at"
        case lastHuntTimestamp = "last_hunt_timestamp"
        case lastInterrogateFlowId = "last_interrogate_flow_id"
        case labels
        case agentInfo = "agent_information"
        case firstSeenAt = "first_seen_at"
    }
    
    /// Whether the client is considered online (seen within last 5 minutes)
    var isOnline: Bool {
        guard let lastSeen = lastSeenAt else { return false }
        return Date().timeIntervalSince(lastSeen) < 300
    }
    
    /// Formatted last seen string
    var lastSeenFormatted: String {
        guard let lastSeen = lastSeenAt else { return "Never" }
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: lastSeen, relativeTo: Date())
    }
}

/// Operating system type
enum ClientOS: String, Codable, Sendable {
    case windows = "windows"
    case linux = "linux"
    case darwin = "darwin"
    case unknown = "unknown"
    
    var displayName: String {
        switch self {
        case .windows: return "Windows"
        case .linux: return "Linux"
        case .darwin: return "macOS"
        case .unknown: return "Unknown"
        }
    }
    
    var iconName: String {
        switch self {
        case .windows: return "pc"
        case .linux: return "terminal"
        case .darwin: return "laptopcomputer"
        case .unknown: return "questionmark.circle"
        }
    }
}

/// Operating system information
struct OSInfo: Codable, Hashable, Sendable {
    let system: String?
    let release: String?
    let version: String?
    let machine: String?
    let fqdn: String?
    let hostname: String?
}

/// Agent information
struct AgentInfo: Codable, Hashable, Sendable {
    let version: String?
    let name: String?
    let buildTime: String?
    
    enum CodingKeys: String, CodingKey {
        case version
        case name
        case buildTime = "build_time"
    }
}

// MARK: - Hunt Models

/// Represents a Velociraptor hunt
struct Hunt: Codable, Identifiable, Hashable, Sendable {
    let huntId: String
    let huntDescription: String?
    let state: HuntState
    let createTime: Date?
    let startTime: Date?
    let expires: Date?
    let creator: String?
    let artifacts: [String]
    let totalClientsScheduled: Int
    let totalClientsWithResults: Int
    let totalClientsWithErrors: Int
    let stats: HuntStats?
    
    var id: String { huntId }
    
    enum CodingKeys: String, CodingKey {
        case huntId = "hunt_id"
        case huntDescription = "hunt_description"
        case state
        case createTime = "create_time"
        case startTime = "start_time"
        case expires
        case creator
        case artifacts
        case totalClientsScheduled = "total_clients_scheduled"
        case totalClientsWithResults = "total_clients_with_results"
        case totalClientsWithErrors = "total_clients_with_errors"
        case stats
    }
    
    /// Progress percentage (0-100)
    var progressPercent: Double {
        guard totalClientsScheduled > 0 else { return 0 }
        return Double(totalClientsWithResults + totalClientsWithErrors) / Double(totalClientsScheduled) * 100
    }
}

/// Hunt state
enum HuntState: String, Codable, Sendable {
    case unspecified = "UNSPECIFIED"
    case paused = "PAUSED"
    case running = "RUNNING"
    case stopped = "STOPPED"
    case archived = "ARCHIVED"
    
    var displayName: String {
        switch self {
        case .unspecified: return "Unknown"
        case .paused: return "Paused"
        case .running: return "Running"
        case .stopped: return "Stopped"
        case .archived: return "Archived"
        }
    }
    
    var iconName: String {
        switch self {
        case .running: return "play.fill"
        case .paused: return "pause.fill"
        case .stopped: return "stop.fill"
        case .archived: return "archivebox.fill"
        case .unspecified: return "questionmark"
        }
    }
}

/// Hunt statistics
struct HuntStats: Codable, Hashable, Sendable {
    let totalClientsScheduled: Int?
    let totalClientsWithResults: Int?
    let totalClientsWithErrors: Int?
    let totalClients: Int?
    
    enum CodingKeys: String, CodingKey {
        case totalClientsScheduled = "total_clients_scheduled"
        case totalClientsWithResults = "total_clients_with_results"
        case totalClientsWithErrors = "total_clients_with_errors"
        case totalClients = "total_clients"
    }
}

/// Hunt creation request
struct HuntCreateRequest: Codable, Sendable {
    let huntDescription: String
    let artifacts: [String]
    let specs: [ArtifactSpec]?
    let condition: String?
    let expires: Int?  // Unix timestamp
    let timeout: Int?
    let opsPerSecond: Int?
    
    enum CodingKeys: String, CodingKey {
        case huntDescription = "hunt_description"
        case artifacts
        case specs
        case condition
        case expires
        case timeout
        case opsPerSecond = "ops_per_second"
    }
}

/// Artifact specification for hunt
struct ArtifactSpec: Codable, Hashable, Sendable {
    let artifact: String
    let parameters: [String: String]?
}

// MARK: - VQL Models

/// VQL query request
struct VQLRequest: Codable, Sendable {
    let query: String
    let env: [String: String]?
    let timeout: Int?
    let maxRows: Int?
    let orgId: String?
    
    enum CodingKeys: String, CodingKey {
        case query
        case env
        case timeout
        case maxRows = "max_rows"
        case orgId = "org_id"
    }
}

/// VQL query result
struct VQLResult: Codable, Sendable, Identifiable {
    let id = UUID()
    let columns: [String]
    let rows: [[VQLValue]]
    let types: [String]?
    let part: Int?
    
    enum CodingKeys: String, CodingKey {
        case columns
        case rows
        case types
        case part
    }
    
    /// Get value at row and column
    func value(row: Int, column: String) -> VQLValue? {
        guard let colIndex = columns.firstIndex(of: column),
              row < rows.count else { return nil }
        return rows[row][colIndex]
    }
}

/// VQL value (can be various types)
enum VQLValue: Codable, Sendable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case null
    case array([VQLValue])
    case object([String: VQLValue])
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        if container.decodeNil() {
            self = .null
            return
        }
        
        if let string = try? container.decode(String.self) {
            self = .string(string)
            return
        }
        
        if let int = try? container.decode(Int.self) {
            self = .int(int)
            return
        }
        
        if let double = try? container.decode(Double.self) {
            self = .double(double)
            return
        }
        
        if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
            return
        }
        
        if let array = try? container.decode([VQLValue].self) {
            self = .array(array)
            return
        }
        
        if let object = try? container.decode([String: VQLValue].self) {
            self = .object(object)
            return
        }
        
        self = .null
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value): try container.encode(value)
        case .int(let value): try container.encode(value)
        case .double(let value): try container.encode(value)
        case .bool(let value): try container.encode(value)
        case .null: try container.encodeNil()
        case .array(let value): try container.encode(value)
        case .object(let value): try container.encode(value)
        }
    }
    
    /// String representation
    var stringValue: String {
        switch self {
        case .string(let value): return value
        case .int(let value): return String(value)
        case .double(let value): return String(value)
        case .bool(let value): return String(value)
        case .null: return "null"
        case .array(let value): return "[\(value.map { $0.stringValue }.joined(separator: ", "))]"
        case .object: return "[Object]"
        }
    }
}

// MARK: - Artifact Models

/// Velociraptor artifact definition
struct Artifact: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let description: String?
    let author: String?
    let type: String?
    let parameters: [ArtifactParameter]?
    let sources: [ArtifactSource]?
    let requiredPermissions: [String]?
    let builtIn: Bool?
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case description
        case author
        case type
        case parameters
        case sources
        case requiredPermissions = "required_permissions"
        case builtIn = "built_in"
    }
}

/// Artifact parameter
struct ArtifactParameter: Codable, Hashable, Sendable {
    let name: String
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
struct ArtifactSource: Codable, Hashable, Sendable {
    let name: String?
    let description: String?
    let query: String?
    let precondition: String?
}

// MARK: - VFS Models

/// Virtual File System entry
struct VFSEntry: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let path: String
    let mode: String?
    let size: Int64?
    let mtime: Date?
    let atime: Date?
    let ctime: Date?
    let isDir: Bool
    let downloadInfo: DownloadInfo?
    
    var id: String { path }
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case path = "FullPath"
        case mode = "Mode"
        case size = "Size"
        case mtime = "Mtime"
        case atime = "Atime"
        case ctime = "Ctime"
        case isDir = "IsDir"
        case downloadInfo = "Download"
    }
    
    /// Icon name based on type
    var iconName: String {
        if isDir {
            return "folder.fill"
        }
        let ext = (name as NSString).pathExtension.lowercased()
        switch ext {
        case "txt", "log", "md": return "doc.text.fill"
        case "pdf": return "doc.fill"
        case "jpg", "jpeg", "png", "gif": return "photo.fill"
        case "exe", "dll": return "app.fill"
        case "zip", "tar", "gz": return "archivebox.fill"
        default: return "doc.fill"
        }
    }
    
    /// Formatted size string
    var sizeFormatted: String {
        guard let size = size else { return "-" }
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

/// VFS download info
struct DownloadInfo: Codable, Hashable, Sendable {
    let vfsPath: String?
    let sha256: String?
    let size: Int64?
    
    enum CodingKeys: String, CodingKey {
        case vfsPath = "vfs_path"
        case sha256
        case size
    }
}

// MARK: - Server Info Models

/// Server information
struct ServerInfo: Codable, Sendable {
    let name: String?
    let version: String?
    let buildTime: String?
    let installTime: Date?
    let clientCount: Int?
    
    enum CodingKeys: String, CodingKey {
        case name
        case version
        case buildTime = "build_time"
        case installTime = "install_time"
        case clientCount = "client_count"
    }
}

/// Server health response
struct HealthResponse: Codable, Sendable {
    let status: String?
    let version: String?
    let uptime: Int?
    let cpuPercent: Double?
    let memoryPercent: Double?
    let diskPercent: Double?
    
    enum CodingKeys: String, CodingKey {
        case status
        case version
        case uptime
        case cpuPercent = "cpu_percent"
        case memoryPercent = "memory_percent"
        case diskPercent = "disk_percent"
    }
    
    var isHealthy: Bool {
        status?.lowercased() == "ok" || status?.lowercased() == "healthy"
    }
}

// MARK: - User Models

/// Velociraptor user
struct VelociraptorUser: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let roles: [String]
    let type: String?
    let createdTime: Date?
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name
        case roles
        case type
        case createdTime = "created_time"
    }
}

// MARK: - Flow Models

/// Collection flow
struct Flow: Codable, Identifiable, Hashable, Sendable {
    let flowId: String
    let clientId: String
    let state: FlowState
    let createTime: Date?
    let startTime: Date?
    let activeTime: Date?
    let artifacts: [String]
    let totalUploadedFiles: Int?
    let totalUploadedBytes: Int64?
    let totalExpectedUploadedBytes: Int64?
    let totalCollectedRows: Int?
    
    var id: String { flowId }
    
    enum CodingKeys: String, CodingKey {
        case flowId = "session_id"
        case clientId = "client_id"
        case state
        case createTime = "create_time"
        case startTime = "start_time"
        case activeTime = "active_time"
        case artifacts = "artifacts_with_results"
        case totalUploadedFiles = "total_uploaded_files"
        case totalUploadedBytes = "total_uploaded_bytes"
        case totalExpectedUploadedBytes = "total_expected_uploaded_bytes"
        case totalCollectedRows = "total_collected_rows"
    }
}

/// Flow state
enum FlowState: String, Codable, Sendable {
    case unspecified = "UNSPECIFIED"
    case running = "RUNNING"
    case finished = "FINISHED"
    case error = "ERROR"
    case archived = "ARCHIVED"
    
    var displayName: String {
        switch self {
        case .unspecified: return "Unknown"
        case .running: return "Running"
        case .finished: return "Completed"
        case .error: return "Error"
        case .archived: return "Archived"
        }
    }
}

// MARK: - API Response Wrappers

/// Generic paginated response
struct PaginatedResponse<T: Codable>: Codable where T: Sendable {
    let items: [T]
    let total: Int?
    let offset: Int?
    let limit: Int?
}

/// API error response
struct APIErrorResponse: Codable, Sendable {
    let error: String?
    let message: String?
    let code: Int?
}

// MARK: - Activity Models (for Dashboard)

/// Activity event for dashboard timeline
struct ActivityEvent: Codable, Identifiable, Sendable {
    let id: String
    let type: ActivityType
    let timestamp: Date
    let message: String
    let clientId: String?
    let huntId: String?
    let user: String?
    
    enum ActivityType: String, Codable, Sendable {
        case huntCreated = "hunt_created"
        case huntCompleted = "hunt_completed"
        case clientConnected = "client_connected"
        case clientDisconnected = "client_disconnected"
        case collectionCompleted = "collection_completed"
        case alertTriggered = "alert_triggered"
        case userLogin = "user_login"
        case systemEvent = "system_event"
        
        var iconName: String {
            switch self {
            case .huntCreated: return "scope"
            case .huntCompleted: return "checkmark.circle.fill"
            case .clientConnected: return "network"
            case .clientDisconnected: return "network.slash"
            case .collectionCompleted: return "doc.on.doc.fill"
            case .alertTriggered: return "exclamationmark.triangle.fill"
            case .userLogin: return "person.fill"
            case .systemEvent: return "gear"
            }
        }
    }
}

// MARK: - Dashboard Statistics

/// Quick stats for dashboard
struct DashboardStats: Codable, Sendable {
    let totalClients: Int
    let onlineClients: Int
    let activeHunts: Int
    let completedHunts: Int
    let totalArtifacts: Int
    let alertCount: Int
    
    var onlinePercentage: Double {
        guard totalClients > 0 else { return 0 }
        return Double(onlineClients) / Double(totalClients) * 100
    }
}

// MARK: - Label Models

/// Client label
struct ClientLabel: Codable, Identifiable, Hashable, Sendable {
    let name: String
    let clientCount: Int?
    
    var id: String { name }
    
    enum CodingKeys: String, CodingKey {
        case name = "label"
        case clientCount = "client_count"
    }
}
