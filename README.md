# Snapbug iOS Sample App

Pure Swift/SwiftUI sample app demonstrating the Snapbug Debug Feedback SDK.

## Setup

1. Build the KMP XCFramework:
   ```bash
   cd ../SnapbugAndroid
   ./gradlew :snapbug:assembleXCFramework
   ./gradlew :debug-feedback:assembleXCFramework
   ```

2. Copy the XCFramework to the Swift Package:
   ```bash
   cp -r SnapbugAndroid/snapbug/build/XCFrameworks/release/SnapbugSDK.xcframework \
         SnapbugDebugFeedbackSwift/
   ```

3. Open `SampleApp.xcodeproj` in Xcode

4. Add the local Swift Package dependency:
   - File → Add Package Dependencies
   - Click "Add Local..."
   - Select `SnapbugDebugFeedbackSwift/` directory

5. Build and run on iOS Simulator or device

## Features

Mirrors the Android `sample-android-only` app:
- HTTP test request (URLSession)
- Show dialog (FAB should appear above it)
- Send analytics event (simulated)
- Send table event (simulated)
- Write UserDefaults
- Insert dog in DB (simulated)
- Crash button
- Image list from picsum.photos
