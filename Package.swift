// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AutoPDFRenamer",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AutoPDFRenamer", targets: ["AutoPDFRenamer"])
    ],
    targets: [
        .executableTarget(
            name: "AutoPDFRenamer",
            path: "Sources/AutoPDFRenamer",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("PDFKit"),
                .linkedFramework("Vision"),
                .linkedFramework("CoreServices")
            ]
        ),
        .testTarget(
            name: "AutoPDFRenamerTests",
            dependencies: ["AutoPDFRenamer"],
            path: "Tests/AutoPDFRenamerTests"
        )
    ]
)
