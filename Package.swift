// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Quick",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "QuickCore",
            targets: ["QuickCore"]
        ),
        .executable(
            name: "Quick",
            targets: ["Quick"]
        )
    ],
    targets: [
        .target(
            name: "QuickCore"
        ),
        .executableTarget(
            name: "Quick",
            dependencies: ["QuickCore"]
        ),
        .testTarget(
            name: "QuickCoreTests",
            dependencies: ["QuickCore"]
        )
    ]
)
