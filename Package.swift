// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "POEditorParser",
    products: [
        .executable(name: "POEditorParser", targets: ["POEditorParser"]),
	.executable(name: "poe", targets: ["POEditorParser"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
	.package(url: "https://github.com/kylef/Commander", from: "0.8.0"),
	.package(url: "https://github.com/onevcat/Rainbow", from: "3.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "POEditorParser",
            dependencies: ["Commander", "Rainbow"])
    ]
)
