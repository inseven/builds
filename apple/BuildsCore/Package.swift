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
        .package(url: "https://github.com/inseven/diligence.git", from: "2.0.1"),
        .package(url: "https://github.com/inseven/interact.git", from: "3.10.7"),
        .package(url: "https://github.com/inseven/SelectableCollectionView.git", from: "2.0.5"),
    ],
    targets: [
        .target(
            name: "BuildsCore",
            dependencies: [
                .product(name: "Diligence", package: "diligence"),
                .product(name: "Interact", package: "interact"),
                .product(name: "SelectableCollectionView", package: "SelectableCollectionView"),
            ],
            resources: [
                .process("Resources")
            ]),
        .testTarget(
            name: "BuildsCoreTests",
            dependencies: ["BuildsCore"]),
    ]
)
