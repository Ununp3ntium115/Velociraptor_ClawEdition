// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Swift 5.9+ provides concurrency checking and modern Swift features.

import PackageDescription

let package = Package(
    name: "VelociraptorMacOS",
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
        // Model Context Protocol Swift SDK
        // Official SDK: https://github.com/modelcontextprotocol/swift-sdk
        // Enables AI/ML integration and communication with MCP servers
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0"),
        
        // Sparkle - macOS software update framework
        // Official: https://sparkle-project.org/
        // Enables automatic updates for the application
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0")
    ],
    targets: [
        .executableTarget(
            name: "VelociraptorMacOS",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk"),
                .product(name: "Sparkle", package: "Sparkle")
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
