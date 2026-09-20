// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Lucid",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Lucid",
            path: "Sources/Lucid",
            resources: [
                .copy("Resources/WebEngine")
            ]
        )
    ]
)
