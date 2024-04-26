// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuildsCore",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "BuildsCore",
            targets: ["BuildsCore"]),
    ],
    dependencies: [
        .package(path: "../interact"),
    ],
    targets: [
        .target(
            name: "BuildsCore",
            dependencies: [
                .product(name: "Interact", package: "interact"),
            ],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "BuildsCoreTests",
            dependencies: ["BuildsCore"]),
    ]
)
