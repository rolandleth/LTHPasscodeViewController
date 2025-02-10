// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "LTHPasscodeViewController",
    defaultLocalization: "en",
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
            exclude: ["Demo", "CHANGELOG.md", "README.md", "Package.swift"],
            resources: [
                .process("Localizations/LTHPasscodeViewController.bundle"),
                .process("LICENSE.txt")
            ],
            publicHeadersPath: "LTHPasscodeViewController"
        )
    ]
)
