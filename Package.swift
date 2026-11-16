// swift-tools-version: 5.9
// PureMount — 純淨 NTFS 讀寫與外接硬碟管家 (macOS 13.0+)

import PackageDescription

let package = Package(
    name: "PureMount",
    defaultLocalization: "zh-Hant",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "PureMount", targets: ["PureMount"])
    ],
    targets: [
        .executableTarget(
            name: "PureMount",
            path: "Sources/PureMount",
            linkerSettings: [
                .linkedFramework("DiskArbitration"),
                .linkedFramework("IOKit"),
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("StoreKit")
            ]
        )
    ]
)
