// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NanoReminder",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "NanoReminder", targets: ["NanoReminder"])
    ],
    targets: [
        .executableTarget(
            name: "NanoReminder",
            path: "Sources/NanoReminder",
            resources: [
                .process("Assets")
            ]
        )
    ]
)
