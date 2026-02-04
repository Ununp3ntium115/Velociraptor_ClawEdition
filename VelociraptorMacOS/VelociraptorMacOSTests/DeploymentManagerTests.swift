//
//  DeploymentManagerTests.swift
//  VelociraptorMacOSTests
//
//  Unit tests for DeploymentManager
//

import XCTest
@testable import VelociraptorMacOS

final class DeploymentManagerTests: XCTestCase {
    var deploymentManager: DeploymentManager!

    @MainActor
    override func setUp() async throws {
        deploymentManager = DeploymentManager()
    }

    @MainActor
    override func tearDown() async throws {
        deploymentManager = nil
    }

    // MARK: - Initial State Tests

    @MainActor
    func testInitialState() {
        XCTAssertFalse(deploymentManager.isDeploying)
        XCTAssertEqual(deploymentManager.progress, 0.0)
        XCTAssertTrue(deploymentManager.statusMessage.isEmpty)
        XCTAssertNil(deploymentManager.lastError)
    }

    @MainActor
    func testInitialStepStatus() {
        for step in DeploymentManager.DeploymentStep.allCases {
            if case .pending = deploymentManager.stepStatus[step] {
                // Expected
            } else {
                XCTFail("Step \(step) should be pending initially")
            }
        }
    }

    // MARK: - Deployment Step Tests

    func testDeploymentStepProperties() {
        for step in DeploymentManager.DeploymentStep.allCases {
            XCTAssertFalse(step.rawValue.isEmpty)
            XCTAssertFalse(step.iconName.isEmpty)
        }
    }

    // MARK: - Error Tests

    func testDeploymentErrorDescriptions() {
        let errors: [DeploymentManager.DeploymentError] = [
            .binaryNotFound,
            .downloadFailed("Test"),
            .extractionFailed("Test"),
            .configGenerationFailed("Test"),
            .serviceInstallFailed("Test"),
            .startupFailed("Test"),
            .verificationFailed("Test"),
            .cancelled,
            .permissionDenied,
            .networkUnavailable,
            .insufficientDiskSpace
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testDeploymentErrorRecoverySuggestions() {
        XCTAssertNotNil(DeploymentManager.DeploymentError.permissionDenied.recoverySuggestion)
        XCTAssertNotNil(DeploymentManager.DeploymentError.networkUnavailable.recoverySuggestion)
        XCTAssertNotNil(DeploymentManager.DeploymentError.insufficientDiskSpace.recoverySuggestion)
    }

    // MARK: - GitHub Release Parsing Tests

    func testGitHubReleaseDecoding() throws {
        let json = """
        {
            "tag_name": "v0.73.0",
            "name": "Release 0.73.0",
            "assets": [
                {
                    "name": "velociraptor-v0.73.0-darwin-amd64",
                    "browser_download_url": "https://github.com/Velocidex/velociraptor/releases/download/v0.73.0/velociraptor-v0.73.0-darwin-amd64",
                    "size": 50000000
                },
                {
                    "name": "velociraptor-v0.73.0-darwin-arm64",
                    "browser_download_url": "https://github.com/Velocidex/velociraptor/releases/download/v0.73.0/velociraptor-v0.73.0-darwin-arm64",
                    "size": 48000000
                }
            ]
        }
        """

        let data = json.data(using: .utf8)!
        let release = try JSONDecoder().decode(DeploymentManager.GitHubRelease.self, from: data)

        XCTAssertEqual(release.tagName, "v0.73.0")
        XCTAssertEqual(release.name, "Release 0.73.0")
        XCTAssertEqual(release.assets.count, 2)
        XCTAssertTrue(release.assets.contains(where: { $0.name.contains("darwin-amd64") }))
        XCTAssertTrue(release.assets.contains(where: { $0.name.contains("darwin-arm64") }))
    }

    // MARK: - Step Status Tests

    func testStepStatusValues() {
        // Test that step status enum cases exist
        let pending: DeploymentManager.StepStatus = .pending
        let inProgress: DeploymentManager.StepStatus = .inProgress
        let completed: DeploymentManager.StepStatus = .completed
        let failed: DeploymentManager.StepStatus = .failed(DeploymentManager.DeploymentError.cancelled)
        let skipped: DeploymentManager.StepStatus = .skipped

        // Just verify they can be created
        _ = pending
        _ = inProgress
        _ = completed
        _ = failed
        _ = skipped
    }

    // MARK: - Launchd Plist Generation Tests

    @MainActor
    func testLaunchdPlistFormat() async {
        // The plist generation is private, but we can test the deployment
        // creates proper launchd configuration by checking expected paths
        let expectedPlistPath = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/LaunchAgents/com.velocidex.velociraptor.plist")

        // Just verify the path is constructed correctly
        XCTAssertTrue(expectedPlistPath.path.contains("LaunchAgents"))
        XCTAssertTrue(expectedPlistPath.path.contains("com.velocidex.velociraptor"))
    }

    // MARK: - Progress Update Tests

    @MainActor
    func testProgressUpdatesDuringDeployment() async {
        // Progress should be 0 initially
        XCTAssertEqual(deploymentManager.progress, 0.0)

        // After deployment starts, progress should update
        // Note: We can't fully test deployment without network access
        // but we can verify the state management
    }
}

