// swift-tools-version: 5.9
import PackageDescription

// The binary is published by .github/workflows/publish_ios.yml in the Snapbug
// monorepo, which uploads SnapbugSDK.xcframework.zip to snapbug-ai/releases and
// prints its checksum in the release notes. Bump the url and the checksum
// together — a mismatch fails resolution for everyone with a confusing error.
let package = Package(
    name: "Snapbug",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Snapbug", targets: ["Snapbug"]),
    ],
    targets: [
        // Thin Swift layer. It re-exports SnapbugSDK, which is why consumers
        // write `import Snapbug` while the framework module is named SnapbugSDK.
        .target(
            name: "Snapbug",
            dependencies: [.target(name: "SnapbugSDK")],
            path: "Sources/Snapbug"
        ),
        .binaryTarget(
            name: "SnapbugSDK",
            url: "https://github.com/snapbug-ai/releases/releases/download/ios-0.1.1/SnapbugSDK.xcframework.zip",
            checksum: "9aaff07e3778d5374889951d38cd74035c8a103fb5418e9ac18cbcc6dd100745"
        ),
    ]
)
