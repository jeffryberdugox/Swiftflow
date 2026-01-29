// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftFlow",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "SwiftFlow",
            targets: ["SwiftFlow"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "SwiftFlow",
            dependencies: [],
            resources: [
                .copy("SwiftFlow.docc")
            ]
        ),
        .testTarget(
            name: "SwiftFlowTests",
            dependencies: ["SwiftFlow"]
        ),
    ]
)
