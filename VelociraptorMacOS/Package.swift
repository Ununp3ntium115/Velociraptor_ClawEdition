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
    dependencies: [],
    targets: [
        .executableTarget(
            name: "VelociraptorMacOS",
            path: "VelociraptorMacOS"
        ),
        .testTarget(
            name: "VelociraptorMacOSTests",
            dependencies: ["VelociraptorMacOS"],
            path: "VelociraptorMacOSTests"
        )
    ]
)
