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
        .library(
            name: "QuickOCR",
            targets: ["QuickOCR"]
        ),
        .executable(
            name: "Quick",
            targets: ["Quick"]
        ),
        .executable(
            name: "QuickOCRInspect",
            targets: ["QuickOCRInspect"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/microsoft/onnxruntime-swift-package-manager", exact: "1.20.0")
    ],
    targets: [
        .target(
            name: "QuickCore"
        ),
        .target(
            name: "QuickOCR",
            dependencies: [
                "QuickCore",
                .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager")
            ]
        ),
        .executableTarget(
            name: "Quick",
            dependencies: [
                "QuickCore",
                "QuickOCR"
            ]
        ),
        .executableTarget(
            name: "QuickOCRInspect",
            dependencies: [
                "QuickCore",
                "QuickOCR",
                .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager")
            ]
        ),
        .testTarget(
            name: "QuickCoreTests",
            dependencies: ["QuickCore"]
        )
    ]
)
