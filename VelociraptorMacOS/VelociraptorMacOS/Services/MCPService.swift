//
//  MCPService.swift
//  VelociraptorMacOS
//
//  MCP (Model Context Protocol) integration for AI-powered features.
//  Uses the official Swift MCP SDK: https://github.com/modelcontextprotocol/swift-sdk
//
//  BUILD NOTE: Run `swift package resolve` to download the MCP SDK before building.
//  If MCP is not available, the service will compile with stub implementations.
//

import Foundation
import SwiftUI

#if canImport(MCP)
import MCP
private let mcpAvailable = true
#else
private let mcpAvailable = false
#endif

// MARK: - MCP Service

/// Service for Model Context Protocol integration
/// Provides AI-powered capabilities for configuration assistance and analysis
@MainActor
public final class MCPService: ObservableObject {
    
    // MARK: - Singleton
    
    /// Shared instance
    public static let shared = MCPService()
    
    // MARK: - Published Properties
    
    /// Whether MCP is currently connected
    @Published public private(set) var isConnected: Bool = false
    
    /// Current connection status message
    @Published public private(set) var statusMessage: String = "Not connected"
    
    /// Available tools from the MCP server
    @Published public private(set) var availableTools: [String] = []
    
    /// Available prompts from the MCP server
    @Published public private(set) var availablePrompts: [String] = []
    
    // MARK: - Private Properties
    
    #if canImport(MCP)
    private var client: Client?
    private var transport: (any Transport)?
    #endif
    
    // MARK: - Initialization
    
    private init() {
        print("[MCPService] Initialized")
    }
    
    // MARK: - Connection Management
    
    /// Connect to an MCP server via HTTP
    /// - Parameters:
    ///   - endpoint: Server endpoint URL
    ///   - streaming: Enable Server-Sent Events for real-time updates
    public func connect(endpoint: URL, streaming: Bool = true) async throws {
        print("[MCPService] Connecting to \(endpoint.absoluteString)")
        
        #if canImport(MCP)
        // Create client
        let client = Client(name: "VelociraptorMacOS", version: "5.0.5")
        
        // Create HTTP transport
        let transport = HTTPClientTransport(endpoint: endpoint, streaming: streaming)
        
        // Connect
        let result = try await client.connect(transport: transport)
        
        self.client = client
        self.transport = transport
        self.isConnected = true
        self.statusMessage = "Connected to \(endpoint.host ?? "server")"
        
        // Fetch available tools if supported
        if result.capabilities.tools != nil {
            let (tools, _) = try await client.listTools()
            self.availableTools = tools.map { $0.name }
            print("[MCPService] Available tools: \(availableTools)")
        }
        
        // Fetch available prompts if supported
        if result.capabilities.prompts != nil {
            let (prompts, _) = try await client.listPrompts()
            self.availablePrompts = prompts.map { $0.name }
            print("[MCPService] Available prompts: \(availablePrompts)")
        }
        
        print("[MCPService] Connected successfully")
        #else
        // MCP SDK not available - stub implementation
        print("[MCPService] MCP SDK not available - run 'swift package resolve' to enable")
        self.statusMessage = "MCP SDK not available"
        throw MCPServiceError.connectionFailed("MCP SDK not imported. Run 'swift package resolve' first.")
        #endif
    }
    
    /// Connect to an MCP server via stdio (for local subprocess)
    public func connectStdio() async throws {
        print("[MCPService] Connecting via stdio")
        
        #if canImport(MCP)
        let client = Client(name: "VelociraptorMacOS", version: "5.0.5")
        let transport = StdioTransport()
        
        let result = try await client.connect(transport: transport)
        
        self.client = client
        self.transport = transport
        self.isConnected = true
        self.statusMessage = "Connected via stdio"
        
        if result.capabilities.tools != nil {
            let (tools, _) = try await client.listTools()
            self.availableTools = tools.map { $0.name }
        }
        
        print("[MCPService] Connected via stdio successfully")
        #else
        throw MCPServiceError.connectionFailed("MCP SDK not available")
        #endif
    }
    
    /// Disconnect from the MCP server
    public func disconnect() async {
        print("[MCPService] Disconnecting")
        
        #if canImport(MCP)
        if let transport = transport {
            await transport.disconnect()
        }
        
        client = nil
        transport = nil
        #endif
        
        isConnected = false
        statusMessage = "Disconnected"
        availableTools = []
        availablePrompts = []
    }
    
    // MARK: - Tool Operations
    
    /// Call an MCP tool
    /// - Parameters:
    ///   - name: Tool name
    ///   - arguments: Tool arguments as key-value pairs
    /// - Returns: Tool result content
    public func callTool(name: String, arguments: [String: Any]) async throws -> [ToolContent] {
        guard isConnected else {
            throw MCPServiceError.notConnected
        }
        
        print("[MCPService] Calling tool: \(name)")
        
        #if canImport(MCP)
        guard let client = client else {
            throw MCPServiceError.notConnected
        }
        
        // Convert arguments to Value type
        var valueArgs: [String: Value] = [:]
        for (key, value) in arguments {
            valueArgs[key] = convertToValue(value)
        }
        
        let (content, isError) = try await client.callTool(name: name, arguments: valueArgs)
        
        if isError {
            print("[MCPService] Tool returned error")
        }
        
        return content.map { item -> ToolContent in
            switch item {
            case .text(let text):
                return .text(text)
            case .image(let data, let mimeType, _):
                return .image(data: data, mimeType: mimeType)
            case .audio(let data, let mimeType):
                return .audio(data: data, mimeType: mimeType)
            case .resource(let uri, let mimeType, let text):
                return .resource(uri: uri, mimeType: mimeType, text: text)
            }
        }
        #else
        throw MCPServiceError.connectionFailed("MCP SDK not available")
        #endif
    }
    
    // MARK: - Prompt Operations
    
    /// Get a prompt with arguments
    /// - Parameters:
    ///   - name: Prompt name
    ///   - arguments: Prompt arguments
    /// - Returns: Prompt description and messages
    public func getPrompt(name: String, arguments: [String: String]) async throws -> (description: String?, messages: [PromptMessage]) {
        guard isConnected else {
            throw MCPServiceError.notConnected
        }
        
        print("[MCPService] Getting prompt: \(name)")
        
        #if canImport(MCP)
        guard let client = client else {
            throw MCPServiceError.notConnected
        }
        
        var valueArgs: [String: Value] = [:]
        for (key, value) in arguments {
            valueArgs[key] = .string(value)
        }
        
        let (description, messages) = try await client.getPrompt(name: name, arguments: valueArgs)
        
        let promptMessages = messages.map { msg -> PromptMessage in
            var text = ""
            if case .text(let content) = msg.content {
                text = content
            }
            return PromptMessage(role: msg.role.rawValue, content: text)
        }
        
        return (description, promptMessages)
        #else
        throw MCPServiceError.connectionFailed("MCP SDK not available")
        #endif
    }
    
    // MARK: - Resource Operations
    
    /// List available resources
    /// - Returns: Array of resource URIs
    public func listResources() async throws -> [String] {
        guard isConnected else {
            throw MCPServiceError.notConnected
        }
        
        #if canImport(MCP)
        guard let client = client else {
            throw MCPServiceError.notConnected
        }
        
        let (resources, _) = try await client.listResources()
        return resources.map { $0.uri }
        #else
        throw MCPServiceError.connectionFailed("MCP SDK not available")
        #endif
    }
    
    /// Read a resource
    /// - Parameter uri: Resource URI
    /// - Returns: Resource content
    public func readResource(uri: String) async throws -> String {
        guard isConnected else {
            throw MCPServiceError.notConnected
        }
        
        #if canImport(MCP)
        guard let client = client else {
            throw MCPServiceError.notConnected
        }
        
        let contents = try await client.readResource(uri: uri)
        return contents.map { $0.description }.joined(separator: "\n")
        #else
        throw MCPServiceError.connectionFailed("MCP SDK not available")
        #endif
    }
    
    // MARK: - Helper Methods
    
    #if canImport(MCP)
    private func convertToValue(_ any: Any) -> Value {
        switch any {
        case let string as String:
            return .string(string)
        case let int as Int:
            return .int(int)
        case let double as Double:
            return .double(double)
        case let bool as Bool:
            return .bool(bool)
        case let array as [Any]:
            return .array(array.map { convertToValue($0) })
        case let dict as [String: Any]:
            return .object(dict.mapValues { convertToValue($0) })
        default:
            return .string(String(describing: any))
        }
    }
    #endif
}

// MARK: - Error Types

/// MCP service errors
public enum MCPServiceError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case toolNotFound(String)
    case invalidResponse
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to MCP server"
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .toolNotFound(let name):
            return "Tool not found: \(name)"
        case .invalidResponse:
            return "Invalid response from MCP server"
        }
    }
}

// MARK: - Supporting Types

/// Tool content returned from MCP
public enum ToolContent {
    case text(String)
    case image(data: Data, mimeType: String)
    case audio(data: Data, mimeType: String)
    case resource(uri: String, mimeType: String, text: String?)
}

/// Prompt message
public struct PromptMessage {
    public let role: String
    public let content: String
}

// MARK: - SwiftUI Environment

/// Environment key for MCP service
private struct MCPServiceKey: EnvironmentKey {
    static let defaultValue: MCPService = .shared
}

extension EnvironmentValues {
    /// Access to MCP service in SwiftUI views
    public var mcpService: MCPService {
        get { self[MCPServiceKey.self] }
        set { self[MCPServiceKey.self] = newValue }
    }
}
