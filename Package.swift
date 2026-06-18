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
        .executableTarget(
            name: "Quick",
            dependencies: [
                "QuickCore",
                .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager")
            ]
        ),
        .executableTarget(
            name: "QuickOCRInspect",
            dependencies: [
                "QuickCore",
                .product(name: "onnxruntime", package: "onnxruntime-swift-package-manager")
            ]
        ),
        .testTarget(
            name: "QuickCoreTests",
            dependencies: ["QuickCore"]
        )
    ]
)
