// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "nekonata_map",
    platforms: [
        .iOS("12.0")
    ],
    products: [
        .library(name: "nekonata-map", targets: ["nekonata_map"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "nekonata_map",
            dependencies: [],
            path: "Sources",
            resources: [
                .process("PrivacyInfo.xcprivacy"),
            ]
        )
    ]
)
