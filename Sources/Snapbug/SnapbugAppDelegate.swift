#if canImport(SnapbugSDK) && canImport(UIKit)
import UIKit

/// Drop-in app delegate that wires the Snapbug Home Screen quick action for SwiftUI
/// apps that don't have their own delegate:
///
/// ```swift
/// @main
/// struct MyApp: App {
///     @UIApplicationDelegateAdaptor(SnapbugAppDelegate.self) var snapbugDelegate
///     init() { Snapbug.start() }
///     var body: some Scene { WindowGroup { ContentView() } }
/// }
/// ```
///
/// Apps that already have their own scene delegate should instead call
/// `Snapbug.handleShortcut(_:)` from their own quick-action handlers.
public final class SnapbugAppDelegate: NSObject, UIApplicationDelegate {
    public func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        let configuration = UISceneConfiguration(
            name: nil,
            sessionRole: connectingSceneSession.role
        )
        configuration.delegateClass = SnapbugSceneDelegate.self
        return configuration
    }
}

/// Scene delegate that opens the Snapbug menu when the app is launched or resumed
/// via the Home Screen quick action.
// IMPORTANT: this scene delegate must NOT create or assign a UIWindow. SwiftUI's
// WindowGroup renders only because this delegate leaves window creation to SwiftUI.
// Assigning `self.window` here would black-screen the host app.
public final class SnapbugSceneDelegate: NSObject, UIWindowSceneDelegate {

    /// Cold start: the app was launched by tapping the quick action.
    public func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let item = connectionOptions.shortcutItem else { return }
        // The window scene is still activating and the overlay window isn't attached
        // yet; defer to the next runloop so findWindowScene()/showMenu() can succeed.
        DispatchQueue.main.async {
            _ = Snapbug.handleShortcut(item)
        }
    }

    /// Warm start: the app was already running in the background.
    public func windowScene(
        _ windowScene: UIWindowScene,
        performActionFor shortcutItem: UIApplicationShortcutItem,
        completionHandler: @escaping (Bool) -> Void
    ) {
        completionHandler(Snapbug.handleShortcut(shortcutItem))
    }
}
#endif
