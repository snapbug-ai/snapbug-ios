import Foundation

#if canImport(UIKit)
import UIKit
#endif

#if canImport(SnapbugSDK)
@_exported import SnapbugSDK

// MARK: - SnapbugSDKHelper (Recommended API)

/// Simplified static API for initializing the full Snapbug SDK + debug overlay in one call.
///
/// Usage:
/// ```swift
/// import Snapbug
///
/// // One-liner (installs all plugins + starts overlay)
/// Snapbug.start()
///
/// // With config
/// Snapbug.start(config: .init(
///     appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
/// ))
///
/// // With server host for physical device testing
/// Snapbug.start(config: .init(
///     serverHost: "192.168.1.42",
///     screenNameProvider: { MyRouter.currentScreen }
/// ))
/// ```
public enum Snapbug {

    /// Configuration for the Snapbug SDK and debug feedback overlay.
    public struct Config {
        /// Host of the Snapbug Desktop app. Use your Mac's LAN IP for physical devices,
        /// or `nil` / `"localhost"` for simulators.
        public var serverHost: String?
        public var enabled: Bool
        public var screenNameProvider: (() -> String?)?
        public var collectTimeline: Bool
        public var timelineMaxEvents: Int
        public var timelineMaxAgeSeconds: Int
        public var appVersion: String?
        /// Whether to install the crash reporter with `catchFatalErrors = true`.
        public var catchFatalErrors: Bool
        /// Register a Home Screen quick action ("Snapbug") that opens the debug menu
        /// on long-press of the app icon. Appended to any existing shortcut items.
        public var registerHomeScreenShortcut: Bool

        public init(
            serverHost: String? = nil,
            enabled: Bool = true,
            screenNameProvider: (() -> String?)? = nil,
            collectTimeline: Bool = true,
            timelineMaxEvents: Int = 200,
            timelineMaxAgeSeconds: Int = 60,
            appVersion: String? = nil,
            catchFatalErrors: Bool = true,
            registerHomeScreenShortcut: Bool = true
        ) {
            self.serverHost = serverHost
            self.enabled = enabled
            self.screenNameProvider = screenNameProvider
            self.collectTimeline = collectTimeline
            self.timelineMaxEvents = timelineMaxEvents
            self.timelineMaxAgeSeconds = timelineMaxAgeSeconds
            self.appVersion = appVersion
            self.catchFatalErrors = catchFatalErrors
            self.registerHomeScreenShortcut = registerHomeScreenShortcut
        }
    }

    /// Initialize the Snapbug SDK with all plugins and start the debug feedback overlay.
    ///
    /// Call this once in `init()` of your `App` struct or in `application(_:didFinishLaunchingWithOptions:)`.
    /// This performs two steps:
    /// 1. Calls `SnapbugConfigurationKt.startSnapbug(...)` installing DebugFeedback, Analytics,
    ///    CrashReporter, Device, Network, and Logs plugins.
    /// 2. Calls `SnapbugDebugFeedbackIos.shared.start(config:)` to attach the overlay.
    @MainActor
    public static func start(config: Config = Config()) {
        // Step 1: Initialize the core SDK with all plugins
        SnapbugConfigurationKt.startSnapbug(
            context: SnapbugContext(),
            block: { sdkConfig in
                if let host = config.serverHost {
                    sdkConfig.serverHost = host
                }

                sdkConfig.install(factory: SnapbugDebugFeedback.shared, configure: { _ in })
                sdkConfig.install(factory: SnapbugAnalytics.shared, configure: { _ in })
                sdkConfig.install(factory: SnapbugCrashReporter.shared, configure: { c in
                    let crashConfig = c as! SnapbugCrashReporterConfig
                    crashConfig.catchFatalErrors = config.catchFatalErrors
                })
                sdkConfig.install(factory: SnapbugDevice.shared, configure: { _ in })
                sdkConfig.install(factory: SnapbugNetwork.shared, configure: { _ in })
                sdkConfig.install(factory: SnapbugLogs.shared, configure: { _ in })
                sdkConfig.install(factory: SnapbugPerformance.shared, configure: { _ in })
                sdkConfig.install(factory: SnapbugFiles.shared, configure: { _ in })
                sdkConfig.install(factory: SnapbugPreferences.shared, configure: { _ in })
                sdkConfig.install(factory: SnapbugDashboard.shared, configure: { _ in })
            }
        )

        // Step 2: Start the debug feedback overlay
        let overlayConfig = DebugFeedbackConfig(
            enabled: config.enabled,
            screenNameProvider: config.screenNameProvider,
            collectTimeline: config.collectTimeline,
            timelineMaxEvents: Int32(config.timelineMaxEvents),
            timelineMaxAgeSeconds: Int32(config.timelineMaxAgeSeconds),
            appVersion: config.appVersion
        )
        SnapbugDebugFeedbackIos.shared.start(config: overlayConfig)

        // start() usually runs inside SwiftUI's App.init(), i.e. before the app finishes
        // launching. Assigning UIApplication.shared.shortcutItems that early is silently
        // dropped by UIKit, so the "Snapbug" quick action never appears. Defer the write to
        // the next main-runloop turn — by then didFinishLaunching has run and SpringBoard
        // picks the item up. Idempotent, so a later re-run is harmless.
        let shouldRegister = config.enabled && config.registerHomeScreenShortcut
        DispatchQueue.main.async {
            if shouldRegister {
                registerHomeScreenShortcut()
            } else {
                unregisterHomeScreenShortcut()
            }
        }
    }

    /// Stop and remove the debug feedback overlay.
    @MainActor
    public static func stop() {
        SnapbugDebugFeedbackIos.shared.stop()
    }

    /// Home Screen quick action type that opens the Snapbug debug menu.
    public static let openMenuShortcutType = "ai.snapbug.open_menu"

    /// Opens the Snapbug debug menu programmatically — same as tapping the overlay bubble.
    @MainActor
    public static func openMenu() {
        SnapbugDebugFeedbackIos.shared.openMenu()
    }

    /// Handle a Home Screen quick action. Returns `true` if it was the Snapbug shortcut
    /// (and the menu was opened), `false` otherwise — pass other shortcuts to your own handlers.
    @MainActor
    @discardableResult
    public static func handleShortcut(_ item: UIApplicationShortcutItem) -> Bool {
        guard item.type == openMenuShortcutType else { return false }
        openMenu()
        return true
    }

    @MainActor
    private static func registerHomeScreenShortcut() {
        let item = UIApplicationShortcutItem(
            type: openMenuShortcutType,
            localizedTitle: "Snapbug",
            localizedSubtitle: "Open debug menu",
            icon: UIApplicationShortcutIcon(systemImageName: "ladybug"),
            userInfo: nil
        )
        var items = UIApplication.shared.shortcutItems ?? []
        // Idempotent: drop any prior Snapbug item, then append — keeps other apps'
        // shortcuts intact and avoids duplicates on repeated start().
        items.removeAll { $0.type == openMenuShortcutType }
        items.append(item)
        UIApplication.shared.shortcutItems = items
    }

    @MainActor
    private static func unregisterHomeScreenShortcut() {
        var items = UIApplication.shared.shortcutItems ?? []
        items.removeAll { $0.type == openMenuShortcutType }
        UIApplication.shared.shortcutItems = items
    }
}

// MARK: - SnapbugDebugFeedbackOverlay (Legacy)

// Legacy API — kept for backward compatibility.
// Prefer `Snapbug.start(config:)` which initializes the full SDK + overlay in one call.
@MainActor
public final class SnapbugDebugFeedbackOverlay {
    public static let shared = SnapbugDebugFeedbackOverlay()

    private init() {}

    /// Configuration for the debug feedback overlay.
    public struct Config {
        public var enabled: Bool
        public var screenNameProvider: (() -> String?)?
        public var collectTimeline: Bool
        public var timelineMaxEvents: Int
        public var timelineMaxAgeSeconds: Int
        public var appVersion: String?

        public init(
            enabled: Bool = true,
            screenNameProvider: (() -> String?)? = nil,
            collectTimeline: Bool = true,
            timelineMaxEvents: Int = 200,
            timelineMaxAgeSeconds: Int = 60,
            appVersion: String? = nil
        ) {
            self.enabled = enabled
            self.screenNameProvider = screenNameProvider
            self.collectTimeline = collectTimeline
            self.timelineMaxEvents = timelineMaxEvents
            self.timelineMaxAgeSeconds = timelineMaxAgeSeconds
            self.appVersion = appVersion
        }
    }

    /// Start the debug feedback overlay with the given configuration.
    public func start(config: Config = Config()) {
        let kotlinConfig = DebugFeedbackConfig(
            enabled: config.enabled,
            screenNameProvider: config.screenNameProvider,
            collectTimeline: config.collectTimeline,
            timelineMaxEvents: Int32(config.timelineMaxEvents),
            timelineMaxAgeSeconds: Int32(config.timelineMaxAgeSeconds),
            appVersion: config.appVersion
        )
        SnapbugDebugFeedbackIos.shared.start(config: kotlinConfig)
    }

    /// Update the configuration at runtime.
    public func updateConfig(_ config: Config) {
        let kotlinConfig = DebugFeedbackConfig(
            enabled: config.enabled,
            screenNameProvider: config.screenNameProvider,
            collectTimeline: config.collectTimeline,
            timelineMaxEvents: Int32(config.timelineMaxEvents),
            timelineMaxAgeSeconds: Int32(config.timelineMaxAgeSeconds),
            appVersion: config.appVersion
        )
        SnapbugDebugFeedbackIos.shared.updateConfig(config: kotlinConfig)
    }

    /// Stop and remove the debug feedback overlay.
    public func stop() {
        SnapbugDebugFeedbackIos.shared.stop()
    }
}
#else
@available(*, unavailable, message: "SnapbugSDK.xcframework is only available when building the package for iOS.")
public enum Snapbug {}

@available(*, unavailable, message: "SnapbugSDK.xcframework is only available when building the package for iOS.")
@MainActor
public final class SnapbugDebugFeedbackOverlay {
    public static let shared = SnapbugDebugFeedbackOverlay()

    private init() {}
}
#endif
