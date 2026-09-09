// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cryptography_flutter_pro",
    platforms: [
        .macOS("10.15")
    ],
    products: [
        .library(name: "cryptography-flutter-pro", targets: ["cryptography_flutter_pro"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "cryptography_flutter_pro",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
