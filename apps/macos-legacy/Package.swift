// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Swift 6 ensures strict concurrency checking and modern Swift features.

import PackageDescription

let package = Package(
    name: "VelociraptorMacOS",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "VelociraptorMacOS",
            targets: ["VelociraptorMacOS"]
        ),
        .executable(
            name: "VelociraptorMCPServer",
            targets: ["VelociraptorMCPServer"]
        ),
        .library(
            name: "VelociraptorMCP",
            targets: ["VelociraptorMCP"]
        )
    ],
    dependencies: [
        // MCP Swift SDK - Official Model Context Protocol implementation
        // https://github.com/modelcontextprotocol/swift-sdk
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),
        
        // Swift Service Lifecycle for graceful server management
        .package(url: "https://github.com/swift-server/swift-service-lifecycle.git", from: "2.3.0"),
        
        // Swift Logging for consistent logging across the application
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        
        // Swift Argument Parser for CLI tools
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        // Main macOS GUI application
        .executableTarget(
            name: "VelociraptorMacOS",
            dependencies: [
                "VelociraptorMCP",
                .product(name: "Logging", package: "swift-log")
            ],
            path: "VelociraptorMacOS"
        ),
        
        // MCP Server executable - runs as a standalone MCP server
        .executableTarget(
            name: "VelociraptorMCPServer",
            dependencies: [
                "VelociraptorMCP",
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "ServiceLifecycle", package: "swift-service-lifecycle"),
                .product(name: "Logging", package: "swift-log"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/VelociraptorMCPServer"
        ),
        
        // Shared MCP library with Velociraptor DFIR tools
        .target(
            name: "VelociraptorMCP",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "Sources/VelociraptorMCP"
        ),
        
        // Tests
        .testTarget(
            name: "VelociraptorMacOSTests",
            dependencies: ["VelociraptorMacOS"],
            path: "VelociraptorMacOSTests"
        ),
        .testTarget(
            name: "VelociraptorMCPTests",
            dependencies: [
                "VelociraptorMCP",
                .product(name: "MCP", package: "swift-sdk")
            ],
            path: "Tests/VelociraptorMCPTests"
        )
    ]
)
