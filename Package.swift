// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "FormLogger",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "FormLogger",
            targets: ["FormLogger"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/markbattistella/SimpleLogger", from: "1.0.0"),
        .package(url: "https://github.com/markbattistella/PlatformChecker", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "FormLogger",
            dependencies: [
                "SimpleLogger",
                "PlatformChecker"
            ],
            exclude: [],
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)
