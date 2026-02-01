//
//  VelociraptorAPIClient.swift
//  VelociraptorMacOS
//
//  Velociraptor REST API Client
//  Gap: 0x01 - API Client Foundation
//
//  CDIF Pattern: Actor-isolated API client with async/await
//  Swift 6 Concurrency: Strict mode compliant
//

import Foundation
import Combine

// MARK: - API Endpoint Definitions

/// All Velociraptor API endpoints
enum APIEndpoint: Sendable {
    // Health & Info
    case health
    case version
    case serverInfo
    
    // Clients
    case listClients(limit: Int, offset: Int, query: String?)
    case getClient(id: String)
    case interrogateClient(id: String)
    case collectArtifacts(clientId: String)
    case deleteClient(id: String)
    case getClientFlows(clientId: String)
    
    // Hunts
    case listHunts(state: HuntState?)
    case getHunt(id: String)
    case createHunt
    case startHunt(id: String)
    case stopHunt(id: String)
    case archiveHunt(id: String)
    case deleteHunt(id: String)
    case getHuntResults(huntId: String, artifact: String?)
    
    // VQL
    case executeQuery
    
    // VFS
    case listVFSDirectory(clientId: String, path: String)
    case downloadVFSFile(clientId: String, path: String)
    case getVFSMetadata(clientId: String, path: String)
    case refreshVFSDirectory(clientId: String, path: String)
    
    // Artifacts
    case listArtifacts
    case getArtifact(name: String)
    case uploadArtifact
    
    // Users
    case listUsers
    case createUser
    case deleteUser(username: String)
    
    // Labels
    case listLabels
    case addLabel(clientId: String)
    case removeLabel(clientId: String)
    
    // Flows
    case getFlow(clientId: String, flowId: String)
    case cancelFlow(clientId: String, flowId: String)
    case getFlowResults(clientId: String, flowId: String, artifact: String)
    
    var path: String {
        switch self {
        case .health: return "/api/v1/GetServerInfo"
        case .version: return "/api/v1/GetServerInfo"
        case .serverInfo: return "/api/v1/GetServerInfo"
        case .listClients: return "/api/v1/SearchClients"
        case .getClient(let id): return "/api/v1/GetClient/\(id)"
        case .interrogateClient: return "/api/v1/CollectArtifact"
        case .collectArtifacts: return "/api/v1/CollectArtifact"
        case .deleteClient(let id): return "/api/v1/DeleteClient/\(id)"
        case .getClientFlows(let clientId): return "/api/v1/GetClientFlows/\(clientId)"
        case .listHunts: return "/api/v1/ListHunts"
        case .getHunt(let id): return "/api/v1/GetHunt/\(id)"
        case .createHunt: return "/api/v1/CreateHunt"
        case .startHunt(let id): return "/api/v1/ModifyHunt/\(id)"
        case .stopHunt(let id): return "/api/v1/ModifyHunt/\(id)"
        case .archiveHunt(let id): return "/api/v1/ModifyHunt/\(id)"
        case .deleteHunt(let id): return "/api/v1/DeleteHunt/\(id)"
        case .getHuntResults(let huntId, _): return "/api/v1/GetHuntResults/\(huntId)"
        case .executeQuery: return "/api/v1/Query"
        case .listVFSDirectory(let clientId, _): return "/api/v1/VFSListDirectory/\(clientId)"
        case .downloadVFSFile(let clientId, _): return "/api/v1/VFSDownloadFile/\(clientId)"
        case .getVFSMetadata(let clientId, _): return "/api/v1/VFSGetBuffer/\(clientId)"
        case .refreshVFSDirectory(let clientId, _): return "/api/v1/VFSRefreshDirectory/\(clientId)"
        case .listArtifacts: return "/api/v1/GetArtifacts"
        case .getArtifact(let name): return "/api/v1/GetArtifact/\(name)"
        case .uploadArtifact: return "/api/v1/SetArtifactFile"
        case .listUsers: return "/api/v1/GetUsers"
        case .createUser: return "/api/v1/CreateUser"
        case .deleteUser(let username): return "/api/v1/DeleteUser/\(username)"
        case .listLabels: return "/api/v1/GetClientLabels"
        case .addLabel(let clientId): return "/api/v1/LabelClients/\(clientId)"
        case .removeLabel(let clientId): return "/api/v1/LabelClients/\(clientId)"
        case .getFlow(let clientId, let flowId): return "/api/v1/GetFlowDetails/\(clientId)/\(flowId)"
        case .cancelFlow(let clientId, let flowId): return "/api/v1/CancelFlow/\(clientId)/\(flowId)"
        case .getFlowResults(let clientId, let flowId, _): return "/api/v1/GetFlowResults/\(clientId)/\(flowId)"
        }
    }
    
    var method: String {
        switch self {
        case .health, .version, .serverInfo, .listClients, .getClient, .getClientFlows,
             .listHunts, .getHunt, .getHuntResults, .listVFSDirectory, .getVFSMetadata,
             .listArtifacts, .getArtifact, .listUsers, .listLabels, .getFlow, .getFlowResults:
            return "GET"
        case .interrogateClient, .collectArtifacts, .createHunt, .startHunt, .stopHunt,
             .archiveHunt, .executeQuery, .downloadVFSFile, .refreshVFSDirectory,
             .uploadArtifact, .createUser, .addLabel, .removeLabel, .cancelFlow:
            return "POST"
        case .deleteClient, .deleteHunt, .deleteUser:
            return "DELETE"
        }
    }
}

// MARK: - Connection State

/// API connection state
enum ConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case error(String)
    
    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }
}

// MARK: - API Errors

/// API client errors
enum APIError: LocalizedError, Sendable {
    case notConfigured
    case connectionFailed(String)
    case authenticationFailed
    case unauthorized
    case notFound(String)
    case serverError(Int, String)
    case invalidResponse
    case decodingError(String)
    case networkError(String)
    case timeout
    case cancelled
    case rateLimited
    case invalidURL
    
    var errorDescription: String? {
        switch self {
        case .notConfigured: return "API client not configured"
        case .connectionFailed(let msg): return "Connection failed: \(msg)"
        case .authenticationFailed: return "Authentication failed"
        case .unauthorized: return "Unauthorized - check credentials"
        case .notFound(let resource): return "Not found: \(resource)"
        case .serverError(let code, let msg): return "Server error (\(code)): \(msg)"
        case .invalidResponse: return "Invalid response from server"
        case .decodingError(let msg): return "Failed to decode response: \(msg)"
        case .networkError(let msg): return "Network error: \(msg)"
        case .timeout: return "Request timed out"
        case .cancelled: return "Request cancelled"
        case .rateLimited: return "Rate limited - try again later"
        case .invalidURL: return "Invalid URL"
        }
    }
}

// MARK: - Authentication Configuration

/// API authentication configuration
struct APIAuthConfig: Sendable {
    let serverURL: URL
    let authMethod: AuthMethod
    
    enum AuthMethod: Sendable {
        case apiKey(String)
        case basicAuth(username: String, password: String)
        case mtls(certificatePath: String, keyPath: String)
    }
}

// MARK: - VelociraptorAPIClient

/// Main Velociraptor API Client
/// Actor-isolated for thread safety with Swift 6 strict concurrency
@MainActor
final class VelociraptorAPIClient: ObservableObject {
    
    // MARK: - Singleton
    
    static let shared = VelociraptorAPIClient()
    
    // MARK: - Published Properties
    
    /// Current connection state
    @Published private(set) var connectionState: ConnectionState = .disconnected
    
    /// Server information (populated after connection)
    @Published private(set) var serverInfo: ServerInfo?
    
    /// Last error
    @Published private(set) var lastError: APIError?
    
    /// Whether currently loading
    @Published private(set) var isLoading: Bool = false
    
    // MARK: - Private Properties
    
    private var authConfig: APIAuthConfig?
    private var session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private var requestCounter: Int = 0
    
    // Retry configuration
    private let maxRetryAttempts = 3
    private let retryDelayBase: TimeInterval = 1.0
    
    // MARK: - Initialization
    
    private init() {
        // Configure URL session
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        // Configure JSON decoder
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            
            // Try Unix timestamp (nanoseconds)
            if let timestamp = try? container.decode(Double.self) {
                // Velociraptor uses nanoseconds
                if timestamp > 1e12 {
                    return Date(timeIntervalSince1970: timestamp / 1_000_000_000)
                }
                return Date(timeIntervalSince1970: timestamp)
            }
            
            // Try ISO8601 string
            if let string = try? container.decode(String.self) {
                let formatter = ISO8601DateFormatter()
                formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                if let date = formatter.date(from: string) {
                    return date
                }
                
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                if let date = formatter.date(from: string) {
                    return date
                }
            }
            
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date")
        }
        
        // Configure JSON encoder
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .secondsSince1970
    }
    
    // MARK: - Configuration
    
    /// Configure the API client with server URL and authentication
    /// - Parameters:
    ///   - serverURL: The Velociraptor server URL
    ///   - apiKey: API key for authentication
    func configure(serverURL: URL, apiKey: String) {
        self.authConfig = APIAuthConfig(
            serverURL: serverURL,
            authMethod: .apiKey(apiKey)
        )
        Logger.shared.info("API client configured for: \(serverURL)", component: "API")
    }
    
    /// Configure with basic auth
    func configure(serverURL: URL, username: String, password: String) {
        self.authConfig = APIAuthConfig(
            serverURL: serverURL,
            authMethod: .basicAuth(username: username, password: password)
        )
        Logger.shared.info("API client configured with basic auth for: \(serverURL)", component: "API")
    }
    
    /// Configure with mTLS
    func configure(serverURL: URL, certificatePath: String, keyPath: String) {
        self.authConfig = APIAuthConfig(
            serverURL: serverURL,
            authMethod: .mtls(certificatePath: certificatePath, keyPath: keyPath)
        )
        Logger.shared.info("API client configured with mTLS for: \(serverURL)", component: "API")
    }
    
    /// Test connection to the server
    func testConnection() async throws -> Bool {
        connectionState = .connecting
        
        do {
            let info = try await getServerInfo()
            serverInfo = info
            connectionState = .connected
            Logger.shared.success("Connected to server: \(info.version ?? "unknown")", component: "API")
            return true
        } catch {
            let apiError = mapError(error)
            connectionState = .error(apiError.localizedDescription)
            lastError = apiError
            Logger.shared.error("Connection failed: \(apiError)", component: "API")
            throw apiError
        }
    }
    
    /// Disconnect from server
    func disconnect() {
        connectionState = .disconnected
        serverInfo = nil
        Logger.shared.info("Disconnected from server", component: "API")
    }
    
    // MARK: - Health & Info Endpoints
    
    /// Get server information
    func getServerInfo() async throws -> ServerInfo {
        return try await performRequest(endpoint: .serverInfo)
    }
    
    /// Get server health status
    func getHealth() async throws -> HealthResponse {
        return try await performRequest(endpoint: .health)
    }
    
    // MARK: - Client Endpoints
    
    /// List clients with pagination and search
    func listClients(limit: Int = 50, offset: Int = 0, query: String? = nil) async throws -> [VelociraptorClient] {
        struct ClientSearchResult: Codable {
            let items: [VelociraptorClient]?
        }
        
        let result: ClientSearchResult = try await performRequest(
            endpoint: .listClients(limit: limit, offset: offset, query: query),
            queryParams: [
                "limit": String(limit),
                "offset": String(offset),
                "query": query ?? "*"
            ]
        )
        
        return result.items ?? []
    }
    
    /// Get a specific client by ID
    func getClient(id: String) async throws -> VelociraptorClient {
        return try await performRequest(endpoint: .getClient(id: id))
    }
    
    /// Interrogate a client (collect basic info)
    func interrogateClient(id: String) async throws -> Flow {
        let body: [String: Any] = [
            "client_id": id,
            "artifacts": ["Generic.Client.Info"]
        ]
        
        return try await performRequest(
            endpoint: .interrogateClient(id: id),
            body: body
        )
    }
    
    /// Collect artifacts from a client
    func collectArtifacts(clientId: String, artifacts: [String], parameters: [String: [String: String]]? = nil) async throws -> Flow {
        var body: [String: Any] = [
            "client_id": clientId,
            "artifacts": artifacts
        ]
        
        if let params = parameters {
            var specs: [[String: Any]] = []
            for (artifact, artifactParams) in params {
                specs.append([
                    "artifact": artifact,
                    "parameters": ["env": artifactParams]
                ])
            }
            body["specs"] = specs
        }
        
        return try await performRequest(
            endpoint: .collectArtifacts(clientId: clientId),
            body: body
        )
    }
    
    /// Delete a client
    func deleteClient(id: String) async throws {
        let _: EmptyResponse = try await performRequest(endpoint: .deleteClient(id: id))
    }
    
    /// Get flows for a client
    func getClientFlows(clientId: String) async throws -> [Flow] {
        struct FlowsResponse: Codable {
            let items: [Flow]?
        }
        
        let result: FlowsResponse = try await performRequest(
            endpoint: .getClientFlows(clientId: clientId)
        )
        
        return result.items ?? []
    }
    
    // MARK: - Hunt Endpoints
    
    /// List hunts
    func listHunts(state: HuntState? = nil) async throws -> [Hunt] {
        struct HuntsResponse: Codable {
            let items: [Hunt]?
        }
        
        var queryParams: [String: String] = [:]
        if let state = state {
            queryParams["state"] = state.rawValue
        }
        
        let result: HuntsResponse = try await performRequest(
            endpoint: .listHunts(state: state),
            queryParams: queryParams.isEmpty ? nil : queryParams
        )
        
        return result.items ?? []
    }
    
    /// Get a specific hunt
    func getHunt(id: String) async throws -> Hunt {
        return try await performRequest(endpoint: .getHunt(id: id))
    }
    
    /// Create a new hunt
    func createHunt(description: String, artifacts: [String], specs: [ArtifactSpec]? = nil, expires: Date? = nil) async throws -> Hunt {
        var body: [String: Any] = [
            "hunt_description": description,
            "artifacts": artifacts,
            "start_request": ["artifacts": artifacts]
        ]
        
        if let expires = expires {
            body["expires"] = Int(expires.timeIntervalSince1970)
        }
        
        return try await performRequest(endpoint: .createHunt, body: body)
    }
    
    /// Start a hunt
    func startHunt(id: String) async throws -> Hunt {
        let body: [String: Any] = ["state": "RUNNING"]
        return try await performRequest(endpoint: .startHunt(id: id), body: body)
    }
    
    /// Stop a hunt
    func stopHunt(id: String) async throws -> Hunt {
        let body: [String: Any] = ["state": "STOPPED"]
        return try await performRequest(endpoint: .stopHunt(id: id), body: body)
    }
    
    /// Archive a hunt
    func archiveHunt(id: String) async throws -> Hunt {
        let body: [String: Any] = ["state": "ARCHIVED"]
        return try await performRequest(endpoint: .archiveHunt(id: id), body: body)
    }
    
    /// Delete a hunt
    func deleteHunt(id: String) async throws {
        let _: EmptyResponse = try await performRequest(endpoint: .deleteHunt(id: id))
    }
    
    /// Get hunt results
    func getHuntResults(huntId: String, artifact: String? = nil) async throws -> VQLResult {
        var queryParams: [String: String] = [:]
        if let artifact = artifact {
            queryParams["artifact"] = artifact
        }
        
        return try await performRequest(
            endpoint: .getHuntResults(huntId: huntId, artifact: artifact),
            queryParams: queryParams.isEmpty ? nil : queryParams
        )
    }
    
    // MARK: - VQL Endpoints
    
    /// Execute a VQL query
    func executeQuery(vql: String, env: [String: String]? = nil, timeout: Int? = nil) async throws -> VQLResult {
        var body: [String: Any] = ["query": vql]
        
        if let env = env {
            body["env"] = env.map { ["key": $0.key, "value": $0.value] }
        }
        
        if let timeout = timeout {
            body["timeout"] = timeout
        }
        
        return try await performRequest(endpoint: .executeQuery, body: body)
    }
    
    /// Execute VQL and stream results
    func executeQueryStreaming(vql: String) -> AsyncThrowingStream<VQLResult, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    // For now, just return single result
                    // TODO: Implement true streaming with chunked responses
                    let result = try await executeQuery(vql: vql)
                    continuation.yield(result)
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }
    
    // MARK: - VFS Endpoints
    
    /// List VFS directory contents
    func listVFSDirectory(clientId: String, path: String) async throws -> [VFSEntry] {
        struct VFSResponse: Codable {
            let Response: String?
        }
        
        let result: VFSResponse = try await performRequest(
            endpoint: .listVFSDirectory(clientId: clientId, path: path),
            queryParams: ["vfs_path": path]
        )
        
        // VFS returns entries as JSON string in Response field
        guard let responseString = result.Response,
              let data = responseString.data(using: .utf8) else {
            return []
        }
        
        return try decoder.decode([VFSEntry].self, from: data)
    }
    
    /// Download a file from VFS
    func downloadVFSFile(clientId: String, path: String) async throws -> Data {
        return try await performRequestRaw(
            endpoint: .downloadVFSFile(clientId: clientId, path: path),
            queryParams: ["vfs_path": path]
        )
    }
    
    /// Refresh VFS directory (trigger collection)
    func refreshVFSDirectory(clientId: String, path: String) async throws -> Flow {
        let body: [String: Any] = [
            "client_id": clientId,
            "vfs_path": path
        ]
        
        return try await performRequest(
            endpoint: .refreshVFSDirectory(clientId: clientId, path: path),
            body: body
        )
    }
    
    // MARK: - Artifact Endpoints
    
    /// List all artifacts
    func listArtifacts() async throws -> [Artifact] {
        struct ArtifactsResponse: Codable {
            let items: [Artifact]?
        }
        
        let result: ArtifactsResponse = try await performRequest(endpoint: .listArtifacts)
        return result.items ?? []
    }
    
    /// Get a specific artifact
    func getArtifact(name: String) async throws -> Artifact {
        return try await performRequest(endpoint: .getArtifact(name: name))
    }
    
    /// Upload an artifact (YAML definition)
    func uploadArtifact(yaml: String) async throws {
        let body: [String: Any] = ["artifact": yaml]
        let _: EmptyResponse = try await performRequest(endpoint: .uploadArtifact, body: body)
    }
    
    // MARK: - User Endpoints
    
    /// List all users
    func listUsers() async throws -> [VelociraptorUser] {
        struct UsersResponse: Codable {
            let items: [VelociraptorUser]?
        }
        
        let result: UsersResponse = try await performRequest(endpoint: .listUsers)
        return result.items ?? []
    }
    
    /// Create a new user
    func createUser(username: String, password: String, roles: [String]) async throws {
        let body: [String: Any] = [
            "name": username,
            "password": password,
            "roles": roles
        ]
        
        let _: EmptyResponse = try await performRequest(endpoint: .createUser, body: body)
    }
    
    /// Delete a user
    func deleteUser(username: String) async throws {
        let _: EmptyResponse = try await performRequest(endpoint: .deleteUser(username: username))
    }
    
    // MARK: - Label Endpoints
    
    /// List all client labels
    func listLabels() async throws -> [ClientLabel] {
        struct LabelsResponse: Codable {
            let items: [ClientLabel]?
        }
        
        let result: LabelsResponse = try await performRequest(endpoint: .listLabels)
        return result.items ?? []
    }
    
    /// Add label to client
    func addLabel(clientId: String, label: String) async throws {
        let body: [String: Any] = [
            "client_ids": [clientId],
            "labels": [label],
            "operation": "set"
        ]
        
        let _: EmptyResponse = try await performRequest(
            endpoint: .addLabel(clientId: clientId),
            body: body
        )
    }
    
    /// Remove label from client
    func removeLabel(clientId: String, label: String) async throws {
        let body: [String: Any] = [
            "client_ids": [clientId],
            "labels": [label],
            "operation": "remove"
        ]
        
        let _: EmptyResponse = try await performRequest(
            endpoint: .removeLabel(clientId: clientId),
            body: body
        )
    }
    
    // MARK: - Flow Endpoints
    
    /// Get flow details
    func getFlow(clientId: String, flowId: String) async throws -> Flow {
        return try await performRequest(endpoint: .getFlow(clientId: clientId, flowId: flowId))
    }
    
    /// Cancel a flow
    func cancelFlow(clientId: String, flowId: String) async throws {
        let _: EmptyResponse = try await performRequest(
            endpoint: .cancelFlow(clientId: clientId, flowId: flowId)
        )
    }
    
    /// Get flow results
    func getFlowResults(clientId: String, flowId: String, artifact: String) async throws -> VQLResult {
        return try await performRequest(
            endpoint: .getFlowResults(clientId: clientId, flowId: flowId, artifact: artifact)
        )
    }
    
    // MARK: - Private Request Methods
    
    /// Perform a typed API request
    private func performRequest<T: Decodable>(
        endpoint: APIEndpoint,
        queryParams: [String: String]? = nil,
        body: [String: Any]? = nil,
        retryCount: Int = 0
    ) async throws -> T {
        guard let config = authConfig else {
            throw APIError.notConfigured
        }
        
        let request = try buildRequest(
            config: config,
            endpoint: endpoint,
            queryParams: queryParams,
            body: body
        )
        
        requestCounter += 1
        let requestId = requestCounter
        
        Logger.shared.debug("[\(requestId)] \(endpoint.method) \(endpoint.path)", component: "API")
        
        do {
            isLoading = true
            defer { isLoading = false }
            
            let (data, response) = try await session.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw APIError.invalidResponse
            }
            
            Logger.shared.debug("[\(requestId)] Response: \(httpResponse.statusCode)", component: "API")
            
            try validateResponse(httpResponse, data: data)
            
            do {
                let result = try decoder.decode(T.self, from: data)
                return result
            } catch {
                Logger.shared.error("Decoding error: \(error)", component: "API")
                throw APIError.decodingError(String(describing: error))
            }
            
        } catch {
            let apiError = mapError(error)
            
            // Retry on transient errors
            if shouldRetry(error: apiError) && retryCount < maxRetryAttempts {
                let delay = retryDelayBase * pow(2, Double(retryCount))
                Logger.shared.warning("Retrying in \(delay)s (attempt \(retryCount + 1))", component: "API")
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await performRequest(
                    endpoint: endpoint,
                    queryParams: queryParams,
                    body: body,
                    retryCount: retryCount + 1
                )
            }
            
            throw apiError
        }
    }
    
    /// Perform raw data request (for file downloads)
    private func performRequestRaw(
        endpoint: APIEndpoint,
        queryParams: [String: String]? = nil
    ) async throws -> Data {
        guard let config = authConfig else {
            throw APIError.notConfigured
        }
        
        let request = try buildRequest(
            config: config,
            endpoint: endpoint,
            queryParams: queryParams,
            body: nil
        )
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }
        
        try validateResponse(httpResponse, data: data)
        
        return data
    }
    
    /// Build URLRequest from endpoint
    private func buildRequest(
        config: APIAuthConfig,
        endpoint: APIEndpoint,
        queryParams: [String: String]?,
        body: [String: Any]?
    ) throws -> URLRequest {
        var urlComponents = URLComponents(url: config.serverURL, resolvingAgainstBaseURL: true)!
        urlComponents.path = endpoint.path
        
        if let params = queryParams {
            urlComponents.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
        }
        
        guard let url = urlComponents.url else {
            throw APIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        // Add authentication
        switch config.authMethod {
        case .apiKey(let key):
            request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
            
        case .basicAuth(let username, let password):
            let credentials = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
            request.setValue("Basic \(credentials)", forHTTPHeaderField: "Authorization")
            
        case .mtls:
            // mTLS is handled at session level
            break
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        return request
    }
    
    /// Validate HTTP response
    private func validateResponse(_ response: HTTPURLResponse, data: Data) throws {
        switch response.statusCode {
        case 200...299:
            return
            
        case 401:
            throw APIError.unauthorized
            
        case 403:
            throw APIError.authenticationFailed
            
        case 404:
            throw APIError.notFound("Resource")
            
        case 429:
            throw APIError.rateLimited
            
        case 500...599:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(response.statusCode, message)
            
        default:
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(response.statusCode, message)
        }
    }
    
    /// Map Swift errors to APIError
    private func mapError(_ error: Error) -> APIError {
        if let apiError = error as? APIError {
            return apiError
        }
        
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .cancelled:
                return .cancelled
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkError("No internet connection")
            default:
                return .networkError(urlError.localizedDescription)
            }
        }
        
        return .networkError(error.localizedDescription)
    }
    
    /// Determine if error should trigger retry
    private func shouldRetry(error: APIError) -> Bool {
        switch error {
        case .timeout, .networkError, .serverError(500...599, _):
            return true
        default:
            return false
        }
    }
}

// MARK: - Helper Types

/// Empty response for DELETE endpoints
private struct EmptyResponse: Codable {}

// MARK: - Accessibility Identifiers

extension VelociraptorAPIClient {
    /// Accessibility identifiers for API-related UI elements
    enum AccessibilityID {
        static let connectionIndicator = "api.connection.indicator"
        static let retryButton = "api.retry.button"
        static let disconnectButton = "api.disconnect.button"
    }
}
