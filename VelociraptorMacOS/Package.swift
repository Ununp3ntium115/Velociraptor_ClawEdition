// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
