// swift-tools-version:4.2
import PackageDescription
let package = Package(
    name: "LTHPasscodeViewController",
    products: [
        .library(name: "LTHPasscodeViewController", targets: ["LTHPasscodeViewController"])
    ],
    targets: [
        .target(
            name: "LTHPasscodeViewController",
            dependencies: [],
            path: ".",
            exclude: ["Demo"],
            sources: ["LTHPasscodeViewController", "Localizations"],
            publicHeadersPath: "LTHPasscodeViewController"
        )
    ]
)
