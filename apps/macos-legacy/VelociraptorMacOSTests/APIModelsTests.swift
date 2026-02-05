//
//  APIModelsTests.swift
//  VelociraptorMacOSTests
//
//  Test suite for API Models (Codable)
//  Gap: 0x01 - API Client Foundation
//
//  CDIF Pattern: JSON encoding/decoding validation
//  Swift 6 Concurrency: Thread-safe model testing
//

import XCTest
@testable import Velociraptor

final class APIModelsTests: XCTestCase {
    
    var decoder: JSONDecoder!
    var encoder: JSONEncoder!
    
    override func setUp() {
        super.setUp()
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        
        // Configure decoder for Velociraptor date format
        decoder.dateDecodingStrategy = .secondsSince1970
        encoder.dateEncodingStrategy = .secondsSince1970
    }
    
    // MARK: - ServerInfo Tests
    
    func testServerInfoDecoding() throws {
        // Given
        let json = """
        {
            "version": "v0.75.3",
            "name": "VelociraptorServer",
            "build_time": "2024-01-15T10:30:00Z",
            "install_time": "2024-01-20T14:00:00Z",
            "server_uptime": 3600.0,
            "frontend_uptime": 3500.0
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let serverInfo = try decoder.decode(ServerInfo.self, from: data)
        
        // Then
        XCTAssertEqual(serverInfo.version, "v0.75.3")
        XCTAssertEqual(serverInfo.name, "VelociraptorServer")
        XCTAssertNotNil(serverInfo.serverUptime)
    }
    
    // MARK: - VelociraptorClient Tests
    
    func testVelociraptorClientDecoding() throws {
        // Given
        let json = """
        {
            "client_id": "C.1234567890abcdef",
            "agent_information": {
                "version": "v0.75.3",
                "name": "VelociraptorAgent"
            },
            "os_info": {
                "system": "darwin",
                "hostname": "test-mac",
                "release": "14.0",
                "machine": "x86_64"
            },
            "first_seen_at": 1705327200,
            "last_seen_at": 1705410800,
            "last_ip": "192.168.1.100",
            "labels": ["workstation", "production"]
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let client = try decoder.decode(VelociraptorClient.self, from: data)
        
        // Then
        XCTAssertEqual(client.clientId, "C.1234567890abcdef")
        XCTAssertEqual(client.id, "C.1234567890abcdef")
        XCTAssertEqual(client.agentInformation?.version, "v0.75.3")
        XCTAssertEqual(client.osInfo?.system, "darwin")
        XCTAssertEqual(client.osInfo?.hostname, "test-mac")
        XCTAssertEqual(client.labels?.count, 2)
    }
    
    func testVelociraptorClientHelperProperties() throws {
        // Given
        let json = """
        {
            "client_id": "C.1234567890abcdef",
            "last_seen_at": \(Date().timeIntervalSince1970 - 30)
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let client = try decoder.decode(VelociraptorClient.self, from: data)
        
        // Then - 30 seconds ago should be "Just now" (< 60 seconds)
        XCTAssertEqual(client.lastSeenFormatted, "Just now")
        XCTAssertTrue(client.isOnline)
    }
    
    // MARK: - Hunt Tests
    
    func testHuntDecoding() throws {
        // Given
        let json = """
        {
            "hunt_id": "H.1234567890",
            "hunt_description": "Test Hunt",
            "state": "RUNNING",
            "start_request": {
                "artifacts": ["Generic.Client.Info"]
            },
            "stats": {
                "total_clients_scheduled": 100,
                "total_clients_with_results": 50,
                "total_clients_with_errors": 5
            },
            "create_time": 1705327200,
            "creator": "admin"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let hunt = try decoder.decode(Hunt.self, from: data)
        
        // Then
        XCTAssertEqual(hunt.huntId, "H.1234567890")
        XCTAssertEqual(hunt.id, "H.1234567890")
        XCTAssertEqual(hunt.huntDescription, "Test Hunt")
        XCTAssertEqual(hunt.state, .running)
        XCTAssertEqual(hunt.stateDescription, "Running")
        XCTAssertEqual(hunt.stats?.totalClientsScheduled, 100)
        XCTAssertEqual(hunt.progressPercentage, 50.0)
    }
    
    func testHuntStateEnum() {
        XCTAssertEqual(HuntState.running.rawValue, "RUNNING")
        XCTAssertEqual(HuntState.stopped.rawValue, "STOPPED")
        XCTAssertEqual(HuntState.paused.rawValue, "PAUSED")
        XCTAssertEqual(HuntState.archived.rawValue, "ARCHIVED")
    }
    
    // MARK: - Flow Tests
    
    func testFlowDecoding() throws {
        // Given
        let json = """
        {
            "session_id": "F.C.1234567890abcdef",
            "client_id": "C.1234567890abcdef",
            "flow_id": "F.1234567890",
            "artifacts": ["Generic.Client.Info"],
            "state": "RUNNING",
            "create_time": 1705327200,
            "total_uploaded_files": 10,
            "total_uploaded_bytes": 1024,
            "total_expected_uploaded_bytes": 2048
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let flow = try decoder.decode(Flow.self, from: data)
        
        // Then
        XCTAssertEqual(flow.sessionId, "F.C.1234567890abcdef")
        XCTAssertEqual(flow.id, "F.C.1234567890abcdef")
        XCTAssertEqual(flow.clientId, "C.1234567890abcdef")
        XCTAssertEqual(flow.state, .running)
        XCTAssertEqual(flow.stateDescription, "Running")
        XCTAssertEqual(flow.uploadProgress, 50.0)
    }
    
    // MARK: - Artifact Tests
    
    func testArtifactDecoding() throws {
        // Given
        let json = """
        {
            "name": "Generic.Client.Info",
            "description": "Collect basic client information",
            "type": "CLIENT",
            "author": "Velociraptor Team",
            "parameters": [
                {
                    "name": "Timeout",
                    "description": "Query timeout",
                    "type": "int",
                    "default": "60"
                }
            ]
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let artifact = try decoder.decode(Artifact.self, from: data)
        
        // Then
        XCTAssertEqual(artifact.name, "Generic.Client.Info")
        XCTAssertEqual(artifact.id, "Generic.Client.Info")
        XCTAssertEqual(artifact.description, "Collect basic client information")
        XCTAssertEqual(artifact.type, "CLIENT")
        XCTAssertEqual(artifact.parameters?.count, 1)
        XCTAssertEqual(artifact.parameters?.first?.name, "Timeout")
    }
    
    // MARK: - VFS Tests
    
    func testVFSEntryDecoding() throws {
        // Given
        let json = """
        {
            "Name": "test.txt",
            "Size": 1024,
            "Mode": "0644",
            "mtime": 1705327200,
            "IsDir": false
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let entry = try decoder.decode(VFSEntry.self, from: data)
        
        // Then
        XCTAssertEqual(entry.name, "test.txt")
        XCTAssertEqual(entry.id, "test.txt")
        XCTAssertEqual(entry.size, 1024)
        XCTAssertEqual(entry.mode, "0644")
        XCTAssertEqual(entry.isDir, false)
    }
    
    // MARK: - User Tests
    
    func testVelociraptorUserDecoding() throws {
        // Given
        let json = """
        {
            "name": "admin",
            "roles": ["administrator", "reader"],
            "locked": false
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let user = try decoder.decode(VelociraptorUser.self, from: data)
        
        // Then
        XCTAssertEqual(user.name, "admin")
        XCTAssertEqual(user.id, "admin")
        XCTAssertEqual(user.roles?.count, 2)
        XCTAssertEqual(user.locked, false)
    }
    
    // MARK: - Request Model Tests
    
    func testCollectionRequestEncoding() throws {
        // Given
        let request = CollectionRequest(
            clientId: "C.1234567890abcdef",
            artifacts: ["Generic.Client.Info", "Windows.System.TaskScheduler"],
            specs: nil,
            urgent: true,
            allowCustomOverrides: false
        )
        
        // When
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(json.contains("C.1234567890abcdef"))
        XCTAssertTrue(json.contains("Generic.Client.Info"))
    }
    
    func testHuntCreateRequestEncoding() throws {
        // Given
        let request = HuntCreateRequest(
            huntDescription: "Test Hunt",
            artifacts: ["Generic.Client.Info"],
            specs: nil,
            expires: Int(Date().timeIntervalSince1970 + 3600),
            includeLabels: ["production"],
            excludeLabels: ["test"],
            condition: nil
        )
        
        // When
        let data = try encoder.encode(request)
        let json = String(data: data, encoding: .utf8)!
        
        // Then
        XCTAssertTrue(json.contains("Test Hunt"))
        XCTAssertTrue(json.contains("production"))
    }
    
    // MARK: - Error Model Tests
    
    func testAPIErrorResponseDecoding() throws {
        // Given
        let json = """
        {
            "error": "NotFound",
            "message": "Client not found",
            "code": 404
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let errorResponse = try decoder.decode(APIErrorResponse.self, from: data)
        
        // Then
        XCTAssertEqual(errorResponse.error, "NotFound")
        XCTAssertEqual(errorResponse.message, "Client not found")
        XCTAssertEqual(errorResponse.code, 404)
    }
    
    // MARK: - Sendable Compliance Tests
    
    func testModelsAreSendable() {
        // These tests verify that models can be safely passed between concurrency domains
        
        let serverInfo = ServerInfo(
            version: "v0.75.3",
            name: "Test",
            buildTime: nil,
            installTime: nil,
            serverUptime: nil,
            frontendUptime: nil,
            clientCount: nil
        )
        
        Task {
            // Should compile without warnings - models are Sendable
            let _ = serverInfo
        }
    }
    
    // MARK: - VQLValue Tests
    
    func testVQLValueStringValueString() {
        let value = VQLValue.string("hello world")
        XCTAssertEqual(value.stringValue, "hello world")
    }
    
    func testVQLValueStringValueNumber() {
        let intValue = VQLValue.number(42.0)
        XCTAssertEqual(intValue.stringValue, "42")
        
        let floatValue = VQLValue.number(3.14159)
        XCTAssertTrue(floatValue.stringValue.contains("3.14"))
    }
    
    func testVQLValueStringValueBool() {
        let trueValue = VQLValue.bool(true)
        XCTAssertEqual(trueValue.stringValue, "true")
        
        let falseValue = VQLValue.bool(false)
        XCTAssertEqual(falseValue.stringValue, "false")
    }
    
    func testVQLValueStringValueNull() {
        let nullValue = VQLValue.null
        XCTAssertEqual(nullValue.stringValue, "null")
    }
    
    func testVQLValueStringValueArray() {
        let arrayValue = VQLValue.array([1, 2, 3])
        let result = arrayValue.stringValue
        XCTAssertTrue(result.contains("1"))
        XCTAssertTrue(result.contains("2"))
        XCTAssertTrue(result.contains("3"))
    }
    
    func testVQLValueStringValueObject() {
        let objectValue = VQLValue.object(["key": "value"])
        let result = objectValue.stringValue
        XCTAssertTrue(result.contains("key"))
        XCTAssertTrue(result.contains("value"))
    }
    
    // MARK: - HealthResponse Tests
    
    func testHealthResponseDecoding() throws {
        // Given
        let json = """
        {
            "status": "ok",
            "version": "v0.75.3",
            "uptime": 3600.0,
            "cpu_percent": 25.5,
            "memory_percent": 45.2
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let health = try decoder.decode(HealthResponse.self, from: data)
        
        // Then
        XCTAssertEqual(health.status, "ok")
        XCTAssertEqual(health.version, "v0.75.3")
        XCTAssertEqual(health.cpuPercent, 25.5)
        XCTAssertEqual(health.memoryPercent, 45.2)
        XCTAssertTrue(health.isHealthy)
    }
    
    func testHealthResponseIsHealthyWithDifferentStatuses() throws {
        // Test "ok" status
        let okJson = """
        {"status": "ok", "version": null, "uptime": null}
        """
        let okHealth = try decoder.decode(HealthResponse.self, from: okJson.data(using: .utf8)!)
        XCTAssertTrue(okHealth.isHealthy)
        
        // Test "healthy" status
        let healthyJson = """
        {"status": "healthy", "version": null, "uptime": null}
        """
        let healthyHealth = try decoder.decode(HealthResponse.self, from: healthyJson.data(using: .utf8)!)
        XCTAssertTrue(healthyHealth.isHealthy)
        
        // Test "error" status
        let errorJson = """
        {"status": "error", "version": null, "uptime": null}
        """
        let errorHealth = try decoder.decode(HealthResponse.self, from: errorJson.data(using: .utf8)!)
        XCTAssertFalse(errorHealth.isHealthy)
    }
    
    // MARK: - ServerInfo with clientCount Tests
    
    func testServerInfoWithClientCount() throws {
        // Given
        let json = """
        {
            "version": "v0.75.3",
            "name": "VelociraptorServer",
            "client_count": 150
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let serverInfo = try decoder.decode(ServerInfo.self, from: data)
        
        // Then
        XCTAssertEqual(serverInfo.clientCount, 150)
    }
    
    // MARK: - ArtifactSource with description Tests
    
    func testArtifactSourceWithDescription() throws {
        // Given
        let json = """
        {
            "name": "TestSource",
            "description": "This is a test source",
            "query": "SELECT * FROM info()",
            "precondition": "SELECT OS From info() WHERE OS =~ 'windows'"
        }
        """
        
        // When
        let data = json.data(using: .utf8)!
        let source = try decoder.decode(ArtifactSource.self, from: data)
        
        // Then
        XCTAssertEqual(source.name, "TestSource")
        XCTAssertEqual(source.description, "This is a test source")
        XCTAssertEqual(source.query, "SELECT * FROM info()")
        XCTAssertEqual(source.precondition, "SELECT OS From info() WHERE OS =~ 'windows'")
    }
}
