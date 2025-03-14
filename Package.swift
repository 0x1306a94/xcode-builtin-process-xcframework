// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "xcode-builtin-process-xcframework",
    platforms: [
        .macOS(.v12),
    ],
//    products: [
//        .executable(name: "xcode-builtin-process-xcframework", targets: [
//            "xcode-builtin-process-xcframework",
//        ]),
//    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.5.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .executableTarget(
            name: "xcode-builtin-process-xcframework",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
