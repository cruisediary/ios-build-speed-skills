// Before: No Package.swift exists (monolithic .xcodeproj)
// All source files live in a single app target.
// This example shows what a minimal/empty Package.swift might look like
// if someone added one without modularization.

// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.iOS(.v16)],
    targets: [
        // Everything in one target — no module boundaries
        .target(
            name: "MyApp",
            path: "Sources"
            // 300+ Swift files all in one target
            // Any change rebuilds most of the project
        )
    ]
)
