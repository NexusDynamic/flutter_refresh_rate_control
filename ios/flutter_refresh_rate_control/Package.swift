// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    // TODO: Update your plugin name.
    name: "flutter_refresh_rate_control",
    platforms: [
        .iOS("13.0"),
    ],
    products: [
        .library(name: "flutter-refresh-rate-control", targets: ["flutter_refresh_rate_control"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "flutter_refresh_rate_control",
            dependencies: [],
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
