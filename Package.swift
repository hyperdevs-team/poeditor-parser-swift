// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PoEditorParser",
    products: [
        .executable(
            name: "poe",
            targets: ["PoEditorParserCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/kylef/Commander", .upToNextMajor(from: "0.9.1")),
        .package(url: "https://github.com/onevcat/Rainbow", .upToNextMajor(from: "3.1.5")),
    ],
    targets: [
        .target(
            name: "PoEditorParser",
            dependencies: ["Commander", "Rainbow"]
        ),
        .executableTarget(
            name: "PoEditorParserCLI",
            dependencies: [
                "Commander",
                "Rainbow",
                .target(name: "PoEditorParser"),
            ]
        ),
        .testTarget(
            name: "PoEditorParserTests",
            dependencies: [
                .target(name: "PoEditorParser"),
            ]
        )
    ]
)
