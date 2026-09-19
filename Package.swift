// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Lucid",
    targets: [
        .executableTarget(
            name: "Lucid",
            path: "Sources/Lucid",
            resources: [
                .copy("Resources/WebEngine")
            ]
        )
    ],
    swiftLanguageModes: [.v6]
)
