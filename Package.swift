// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ArcVirt",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "ArcVirt",
            path: "Sources/ArcVirt"
        )
    ]
)
