// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BuildsCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "BuildsCore",
            targets: ["BuildsCore"]),
    ],
    dependencies: [
        .package(path: "../interact"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
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
