// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "Sasayaku",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/argmaxinc/WhisperKit.git", from: "0.9.0"),
    ],
    targets: [
        .executableTarget(
            name: "Sasayaku",
            dependencies: ["WhisperKit"],
            path: "Sources/Sasayaku",
            exclude: ["Info.plist", "AppIcon.icns"],
            linkerSettings: [
                .linkedFramework("AVFoundation"),
                .linkedFramework("CoreGraphics"),
                .linkedFramework("ApplicationServices"),
            ]
        ),
    ]
)
