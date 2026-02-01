// VelociraptorMCP.swift
// Main module file for VelociraptorMCP library
//
// This module provides Model Context Protocol (MCP) integration for Velociraptor
// DFIR (Digital Forensics and Incident Response) tools. It exposes Velociraptor
// capabilities to AI assistants like Claude and Cursor.
//
// Copyright (c) 2026 Velociraptor Claw Edition Project
// Licensed under Apache 2.0

import Foundation
import MCP
import Logging

// MARK: - Module Exports

// Re-export key types for convenience
public typealias MCPValue = Value
public typealias MCPTool = Tool

// MARK: - VelociraptorMCP Configuration

/// Configuration for the Velociraptor MCP integration
public struct VelociraptorMCPConfiguration: Sendable {
    /// Server name to advertise via MCP
    public let serverName: String
    
    /// Server version
    public let serverVersion: String
    
    /// Whether to enable verbose logging
    public let verboseLogging: Bool
    
    /// Default configuration
    public static let `default` = VelociraptorMCPConfiguration(
        serverName: "velociraptor-mcp",
        serverVersion: "1.0.0",
        verboseLogging: false
    )
    
    public init(serverName: String, serverVersion: String, verboseLogging: Bool) {
        self.serverName = serverName
        self.serverVersion = serverVersion
        self.verboseLogging = verboseLogging
    }
}

// MARK: - VelociraptorMCPClient

/// Client for connecting to Velociraptor services via MCP
public actor VelociraptorMCPClient {
    private let logger: Logger
    private var client: Client?
    
    public init(logger: Logger = Logger(label: "com.velociraptor.mcp.client")) {
        self.logger = logger
    }
    
    /// Connect to an MCP server
    public func connect(transport: any Transport) async throws {
        let mcpClient = Client(name: "VelociraptorClient", version: "1.0.0")
        self.client = mcpClient
        
        let result = try await mcpClient.connect(transport: transport)
        
        logger.info("Connected to MCP server", metadata: [
            "serverName": "\(result.serverInfo.name)",
            "serverVersion": "\(result.serverInfo.version)"
        ])
    }
    
    /// List available tools from the connected server
    public func listTools() async throws -> [Tool] {
        guard let client = client else {
            throw VelociraptorMCPError.notConnected
        }
        
        let (tools, _) = try await client.listTools()
        return tools
    }
    
    /// Call a tool on the connected server
    public func callTool(name: String, arguments: [String: Value]) async throws -> (content: [Tool.Content], isError: Bool?) {
        guard let client = client else {
            throw VelociraptorMCPError.notConnected
        }
        
        return try await client.callTool(name: name, arguments: arguments)
    }
}

// MARK: - Errors

/// Errors specific to VelociraptorMCP operations
public enum VelociraptorMCPError: Error, LocalizedError {
    case notConnected
    case invalidArguments(String)
    case toolExecutionFailed(String)
    case resourceNotFound(String)
    
    public var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to an MCP server"
        case .invalidArguments(let message):
            return "Invalid arguments: \(message)"
        case .toolExecutionFailed(let message):
            return "Tool execution failed: \(message)"
        case .resourceNotFound(let uri):
            return "Resource not found: \(uri)"
        }
    }
}

// MARK: - Convenience Extensions

extension Tool {
    /// Create a Velociraptor tool with common defaults
    public static func velociraptorTool(
        name: String,
        description: String,
        parameters: [String: Value]
    ) -> Tool {
        Tool(
            name: "velociraptor_\(name)",
            description: description,
            inputSchema: .object(parameters)
        )
    }
}

// MARK: - Version Info

/// Version information for the VelociraptorMCP module
public enum VelociraptorMCPVersion {
    public static let major = 1
    public static let minor = 0
    public static let patch = 0
    public static let string = "\(major).\(minor).\(patch)"
    
    /// MCP protocol version supported
    public static let mcpVersion = "2025-03-26"
}
