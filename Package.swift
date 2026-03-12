// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Sasayaku",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/exPHAT/SwiftWhisper.git", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "Sasayaku",
            dependencies: ["SwiftWhisper"],
            path: "Sources/Sasayaku",
            exclude: ["Info.plist"],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ApplicationServices"),
            ]
        ),
    ]
)
