// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SFML",
    products: [
        .library(
            name: "SFML",
            targets: ["SFML"]),
    ],
    dependencies: [
    ],
    targets: [
        .binaryTarget(
            name: "SFML",
            path: "Sources/SFML/SFML.xcframework"
        )
    ]
)
