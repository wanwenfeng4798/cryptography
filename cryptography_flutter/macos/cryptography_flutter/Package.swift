// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cryptography_flutter",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "cryptography-flutter", targets: ["cryptography_flutter"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "cryptography_flutter",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
