// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "cryptography_flutter_pro",
    platforms: [
        .iOS("13.0"),
        .macOS("10.15")
    ],
    products: [
        .library(name: "cryptography-flutter-pro", targets: ["cryptography_flutter_pro"])
    ],
    dependencies: [.package(name: "FlutterFramework", path: "../FlutterFramework")],
    targets: [
        .target(
            name: "cryptography_flutter_pro",
            dependencies: [.product(name: "FlutterFramework", package: "FlutterFramework")],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
