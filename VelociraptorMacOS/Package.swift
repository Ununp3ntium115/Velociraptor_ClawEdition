// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.
// Swift 6 ensures strict concurrency checking and modern Swift features.

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
        .package(url: "https://github.com/modelcontextprotocol/swift-sdk.git", from: "0.10.0")
    ],
    targets: [
        .executableTarget(
            name: "VelociraptorMacOS",
            dependencies: [
                .product(name: "MCP", package: "swift-sdk")
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
