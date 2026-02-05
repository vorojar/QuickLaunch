// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "QuickLaunch",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "QuickLaunch",
            dependencies: [],
            path: "Sources/QuickLaunch",
            resources: [
                .copy("../../Resources/Info.plist")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("Carbon")
            ]
        )
    ]
)
