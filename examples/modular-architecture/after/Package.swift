// After: Modular Package.swift with feature modules and a shared Core
// Touching a file in FeatureHome only rebuilds FeatureHome + App

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.iOS(.v16)],
    products: [
        .library(name: "FeatureHome",    targets: ["FeatureHome"]),
        .library(name: "FeatureProfile", targets: ["FeatureProfile"]),
        .library(name: "Core",           targets: ["Core"]),
    ],
    targets: [
        // Feature modules — only depend on Core, not on each other
        .target(
            name: "FeatureHome",
            dependencies: ["Core"],
            path: "Sources/FeatureHome"
        ),
        .target(
            name: "FeatureProfile",
            dependencies: ["Core"],
            path: "Sources/FeatureProfile"
        ),
        // Shared infrastructure — networking, storage, shared UI components
        .target(
            name: "Core",
            path: "Sources/Core"
        ),
        // Test targets
        .testTarget(name: "FeatureHomeTests",    dependencies: ["FeatureHome"]),
        .testTarget(name: "FeatureProfileTests", dependencies: ["FeatureProfile"]),
        .testTarget(name: "CoreTests",           dependencies: ["Core"]),
    ]
)
