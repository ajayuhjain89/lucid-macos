// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Lucid",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .executableTarget(
            name: "Lucid",
            dependencies: [
                .product(name: "Sparkle", package: "Sparkle")
            ],
            path: "Sources/Lucid",
            resources: [
                .copy("Resources/WebEngine")
            ]
        ),
        // Swift Testing unit tests (`swift test`). Lives under tests/ with the
        // Node suites; a top-level Tests/ would clash on case-insensitive disks.
        .testTarget(
            name: "LucidTests",
            dependencies: ["Lucid"],
            path: "tests/LucidTests"
        )
    ]
)
