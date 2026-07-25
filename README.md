# Snapbug for iOS

Swift package for the [Snapbug](https://snapbug.ai) debugging and bug-reporting
SDK. It wraps the `SnapbugSDK` XCFramework built from the Kotlin Multiplatform
core, so the same plugins run on iOS as on Android.

## Install

In Xcode: **File → Add Package Dependencies…** and enter

```
https://github.com/snapbug-ai/snapbug-ios.git
```

Or in a `Package.swift`:

```swift
.package(url: "https://github.com/snapbug-ai/snapbug-ios.git", from: "0.1.1")
```

The package pulls a prebuilt XCFramework from the
[releases](https://github.com/snapbug-ai/releases/releases) repo — there is
nothing to compile and no Kotlin toolchain to install.

Requires iOS 15 or later. The XCFramework ships `arm64` slices for devices and
for the simulator; Intel Macs are not supported.

## Use

One line in your `App`:

```swift
import SwiftUI
import Snapbug

@main
struct MyApp: App {
    init() {
        Snapbug.start()
    }

    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
```

`import Snapbug` works because this package re-exports the `SnapbugSDK` module.

Every plugin — network, logs, analytics, files, preferences, crash reporting,
device info, debug feedback — is on by default. To adjust that, pass a config:

```swift
Snapbug.start(config: .init(
    serverHost: "192.168.1.10",   // your desktop inspector
    collectTimeline: true
))
```

To connect the app to the inspector, follow the pairing instructions at
[snapbug.ai/get](https://snapbug.ai/get).

## Sample app

`SampleApp.xcodeproj` in this repo is a SwiftUI app that exercises every
inspector tab, mirroring the Android sample:

- HTTP request via `URLSession`
- Analytics and table events
- `UserDefaults` writes
- Image list loaded from the network
- A dialog, to check the overlay stays on top
- A deliberate crash, for the crash reporter

## Documentation

Full docs: [snapbug.ai/docs/ios](https://snapbug.ai/docs/ios)
