// VelociraptorMCPTests.swift
// Tests for VelociraptorMCP module
//
// Copyright (c) 2026 Velociraptor Claw Edition Project

import Testing
import Foundation
@testable import VelociraptorMCP
import MCP

@Suite("VelociraptorMCP Tests")
struct VelociraptorMCPTests {
    
    // MARK: - Tool Definition Tests
    
    @Test("All tools are defined correctly")
    func testToolDefinitions() {
        let tools = VelociraptorTools.allTools
        
        #expect(tools.count == 5, "Expected 5 tools to be defined")
        
        let toolNames = tools.map { $0.name }
        #expect(toolNames.contains("velociraptor_generate_vql"))
        #expect(toolNames.contains("velociraptor_suggest_artifacts"))
        #expect(toolNames.contains("velociraptor_plan_deployment"))
        #expect(toolNames.contains("velociraptor_analyze_timeline"))
        #expect(toolNames.contains("velociraptor_create_ir_package"))
    }
    
    @Test("Generate VQL tool has correct schema")
    func testGenerateVQLToolSchema() {
        let tool = VelociraptorTools.generateVQL
        
        #expect(tool.name == "velociraptor_generate_vql")
        #expect(tool.description?.contains("VQL") == true)
        #expect(tool.description?.contains("forensics") == true)
    }
    
    @Test("Suggest artifacts tool has correct schema")
    func testSuggestArtifactsToolSchema() {
        let tool = VelociraptorTools.suggestArtifacts
        
        #expect(tool.name == "velociraptor_suggest_artifacts")
        #expect(tool.description?.contains("artifacts") == true)
        #expect(tool.description?.contains("incident") == true)
    }
    
    // MARK: - Tool Handler Tests
    
    @Test("Tool handler generates VQL correctly")
    func testVQLGeneration() async throws {
        let handler = VelociraptorToolHandler()
        
        let result = try await handler.handleToolCall(
            name: "velociraptor_generate_vql",
            arguments: [
                "objective": .string("find all running processes"),
                "platform": .string("Windows")
            ]
        )
        
        #expect(result.isError == false)
        #expect(result.content.count > 0)
        
        // Check that the result contains VQL
        if case .text(let text) = result.content.first {
            #expect(text.contains("SELECT"))
            #expect(text.contains("FROM"))
        }
    }
    
    @Test("Tool handler suggests artifacts correctly")
    func testArtifactSuggestion() async throws {
        let handler = VelociraptorToolHandler()
        
        let result = try await handler.handleToolCall(
            name: "velociraptor_suggest_artifacts",
            arguments: [
                "incident_type": .string("ransomware"),
                "platform": .string("Windows"),
                "urgency": .string("critical")
            ]
        )
        
        #expect(result.isError == false)
        #expect(result.content.count > 0)
        
        // Check that the result contains artifact recommendations
        if case .text(let text) = result.content.first {
            #expect(text.contains("Artifact"))
            #expect(text.contains("ransomware") || text.contains("Ransomware"))
        }
    }
    
    @Test("Tool handler returns error for missing required arguments")
    func testMissingArguments() async throws {
        let handler = VelociraptorToolHandler()
        
        // Call without required 'objective' argument
        let result = try await handler.handleToolCall(
            name: "velociraptor_generate_vql",
            arguments: [:]
        )
        
        #expect(result.isError == true)
        
        if case .text(let text) = result.content.first {
            #expect(text.contains("Error") || text.contains("required"))
        }
    }
    
    @Test("Tool handler handles unknown tool gracefully")
    func testUnknownTool() async throws {
        let handler = VelociraptorToolHandler()
        
        let result = try await handler.handleToolCall(
            name: "nonexistent_tool",
            arguments: [:]
        )
        
        #expect(result.isError == true)
        
        if case .text(let text) = result.content.first {
            #expect(text.contains("Unknown"))
        }
    }
    
    // MARK: - Configuration Tests
    
    @Test("Default configuration is valid")
    func testDefaultConfiguration() {
        let config = VelociraptorMCPConfiguration.default
        
        #expect(config.serverName == "velociraptor-mcp")
        #expect(config.serverVersion == "1.0.0")
        #expect(config.verboseLogging == false)
    }
    
    @Test("Custom configuration is valid")
    func testCustomConfiguration() {
        let config = VelociraptorMCPConfiguration(
            serverName: "custom-server",
            serverVersion: "2.0.0",
            verboseLogging: true
        )
        
        #expect(config.serverName == "custom-server")
        #expect(config.serverVersion == "2.0.0")
        #expect(config.verboseLogging == true)
    }
    
    // MARK: - Version Tests
    
    @Test("Version information is correct")
    func testVersionInfo() {
        #expect(VelociraptorMCPVersion.major == 1)
        #expect(VelociraptorMCPVersion.minor == 0)
        #expect(VelociraptorMCPVersion.patch == 0)
        #expect(VelociraptorMCPVersion.string == "1.0.0")
        #expect(VelociraptorMCPVersion.mcpVersion == "2025-03-26")
    }
    
    // MARK: - Value Extension Tests
    
    @Test("Value stringValue works correctly")
    func testValueStringExtension() {
        let stringValue: Value = .string("test")
        let intValue: Value = .int(42)
        
        #expect(stringValue.stringValue == "test")
        #expect(intValue.stringValue == nil)
    }
    
    @Test("Value boolValue works correctly")
    func testValueBoolExtension() {
        let boolValue: Value = .bool(true)
        let stringValue: Value = .string("true")
        
        #expect(boolValue.boolValue == true)
        #expect(stringValue.boolValue == nil)
    }
    
    @Test("Value intValue works correctly")
    func testValueIntExtension() {
        let intValue: Value = .int(42)
        let stringValue: Value = .string("42")
        
        #expect(intValue.intValue == 42)
        #expect(stringValue.intValue == nil)
    }
    
    // MARK: - Error Tests
    
    @Test("Error descriptions are meaningful")
    func testErrorDescriptions() {
        let notConnected = VelociraptorMCPError.notConnected
        let invalidArgs = VelociraptorMCPError.invalidArguments("test")
        let toolFailed = VelociraptorMCPError.toolExecutionFailed("reason")
        let notFound = VelociraptorMCPError.resourceNotFound("uri://test")
        
        #expect(notConnected.errorDescription?.contains("Not connected") == true)
        #expect(invalidArgs.errorDescription?.contains("Invalid arguments") == true)
        #expect(toolFailed.errorDescription?.contains("Tool execution failed") == true)
        #expect(notFound.errorDescription?.contains("Resource not found") == true)
    }
}

// MARK: - Integration Tests

@Suite("VelociraptorMCP Integration Tests")
struct VelociraptorMCPIntegrationTests {
    
    @Test("VQL generation covers different platforms")
    func testVQLPlatformCoverage() async throws {
        let handler = VelociraptorToolHandler()
        let platforms = ["Windows", "Linux", "macOS"]
        
        for platform in platforms {
            let result = try await handler.handleToolCall(
                name: "velociraptor_generate_vql",
                arguments: [
                    "objective": .string("list running processes"),
                    "platform": .string(platform)
                ]
            )
            
            #expect(result.isError == false, "Failed for platform: \(platform)")
        }
    }
    
    @Test("Artifact suggestions cover all incident types")
    func testIncidentTypeCoverage() async throws {
        let handler = VelociraptorToolHandler()
        let incidentTypes = [
            "ransomware",
            "apt",
            "malware",
            "insider_threat",
            "data_exfiltration",
            "credential_theft",
            "general_triage"
        ]
        
        for incidentType in incidentTypes {
            let result = try await handler.handleToolCall(
                name: "velociraptor_suggest_artifacts",
                arguments: [
                    "incident_type": .string(incidentType)
                ]
            )
            
            #expect(result.isError == false, "Failed for incident type: \(incidentType)")
        }
    }
    
    @Test("Deployment planning covers all deployment types")
    func testDeploymentTypeCoverage() async throws {
        let handler = VelociraptorToolHandler()
        let deploymentTypes = [
            "standalone",
            "server_client",
            "kubernetes",
            "docker"
        ]
        
        for deploymentType in deploymentTypes {
            let result = try await handler.handleToolCall(
                name: "velociraptor_plan_deployment",
                arguments: [
                    "deployment_type": .string(deploymentType)
                ]
            )
            
            #expect(result.isError == false, "Failed for deployment type: \(deploymentType)")
        }
    }
}
