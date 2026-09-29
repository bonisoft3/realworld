// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "RealWorld",
    platforms: [
        .macOS(.v13),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "RealWorld",
            targets: ["RealWorld"]
        ),
        .executable(
            name: "RealWorldApp",
            targets: ["RealWorldApp"]
        ),
    ],
    dependencies: [
        .package(path: "Packages/omnishell")
    ],
    targets: [
        .target(
            name: "RealWorld",
            dependencies: [
                .product(name: "Omnishell", package: "omnishell")
            ],
            path: "Sources/RealWorld",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "RealWorldApp",
            dependencies: ["RealWorld"],
            path: "Sources/RealWorldApp"
        ),
        .testTarget(
            name: "RealWorldTests",
            dependencies: ["RealWorld"],
            path: "Tests/RealWorldTests"
        ),
    ]
)
