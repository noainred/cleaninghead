// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "ScreenSnap",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "ScreenSnap",
            path: "Sources/ScreenSnap"
        )
    ]
)
