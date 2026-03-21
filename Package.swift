// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FormLogger",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17),
        .macCatalyst(.v17),
        .macOS(.v14),
        .tvOS(.v17),
        .watchOS(.v10),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "FormLogger", targets: ["FormLogger"])
    ],
    dependencies: [
        .package(url: "https://github.com/markbattistella/SimpleLogger", from: "26.0.0"),
        .package(url: "https://github.com/markbattistella/PlatformChecker", from: "26.0.0")
    ],
    targets: [
        .target(
            name: "FormLogger",
            dependencies: ["SimpleLogger", "PlatformChecker"],
            resources: [.process("Resources")],
            swiftSettings: [
                .swiftLanguageMode(.v6)
            ]
        )
    ]
)
