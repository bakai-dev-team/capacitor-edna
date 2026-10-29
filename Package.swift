// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BakaiCapacitorEdna",
    defaultLocalization: "en",
    platforms: [.iOS(.v15)],
    products: [
        .library(
            name: "BakaiCapacitorEdna",
            targets: ["BakaiEdnaPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/ionic-team/capacitor-swift-pm.git", from: "8.0.0")
    ],
    targets: [
        .binaryTarget(
            name: "ChatCenterUI",
            path: "ios/Frameworks/ChatCenterUI.xcframework"),
        .target(
            name: "BakaiEdnaPlugin",
            dependencies: [
                .product(name: "Capacitor", package: "capacitor-swift-pm"),
                .product(name: "Cordova", package: "capacitor-swift-pm"),
                "ChatCenterUI"
            ],
            path: "ios/Sources/BakaiEdnaPlugin",
            resources: [.process("Resources")]),
        .testTarget(
            name: "BakaiEdnaPluginTests",
            dependencies: ["BakaiEdnaPlugin"],
            path: "ios/Tests/BakaiEdnaPluginTests")
    ]
)
