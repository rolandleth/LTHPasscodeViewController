// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "LTHPasscodeViewController",
    platforms: [
        .iOS(.v10)
    ],
    products: [
        .library(
            name: "LTHPasscodeViewController",
            targets: ["LTHPasscodeViewController"]
        ),
    ],
    targets: [
        .target(
            name: "LTHPasscodeViewController",
            path: ".",
            exclude: ["Demo", "CHANGELOG.md", "LICENSE.txt", "README.md"],
            sources: ["LTHPasscodeViewController/LTHKeychainUtils.h", "LTHPasscodeViewController/LTHKeychainUtils.m", "LTHPasscodeViewController/LTHPasscodeViewController.h", "LTHPasscodeViewController/LTHPasscodeViewController.m"],
            resources: [.copy("Localizations")],
            publicHeadersPath: "LTHPasscodeViewController"
        )
    ]
)
