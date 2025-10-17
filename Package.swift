// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PylonChat",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "PylonChat",
            targets: ["PylonChat"]
        )
    ],
    targets: [
        .target(
            name: "PylonChat",
            path: "ios/PylonChat"
        )
    ],
    swiftLanguageVersions: [.v5]
)
