// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Swift 5.9+ provides concurrency checking and modern Swift features.

import PackageDescription

let package = Package(
    name: "VelociraptorMacOS",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "VelociraptorMacOS",
            targets: ["VelociraptorMacOS"]
        )
    ],
    dependencies: [
        // Optional dependencies - uncomment when Swift 6.0+ is available in CI:
        // .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),
        // .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
        
        // Note: MCPService.swift and UpdateService.swift use conditional compilation
        // (#if canImport(MCP) and #if canImport(Sparkle)) to gracefully handle
        // the absence of these dependencies during build.
    ],
    targets: [
        .executableTarget(
            name: "VelociraptorMacOS",
            dependencies: [
                // Add when Swift 6.0+ is available:
                // .product(name: "MCP", package: "swift-sdk"),
                // .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "VelociraptorMacOS"
        ),
        .testTarget(
            name: "VelociraptorMacOSTests",
            dependencies: ["VelociraptorMacOS"],
            path: "VelociraptorMacOSTests"
        )
    ]
)
