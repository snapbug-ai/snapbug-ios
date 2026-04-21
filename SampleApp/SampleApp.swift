import SwiftUI
import SnapbugDebugFeedback

final class SampleAppState {
    static let shared = SampleAppState()
    var currentScreen = "ProductList"

    private init() {}
}

@main
struct SampleApp: App {

    init() {
        #if DEBUG
        SnapbugConfigurationKt.startSnapbug(
            context: SnapbugContext(),
            block: { config in
                // Set to your Mac's LAN IP for physical device testing.
                // Use "localhost" (or leave nil) for simulators.
                config.serverHost = "192.168.100.4"

                config.install(factory: SnapbugDebugFeedback.shared, configure: { _ in })
                config.install(factory: SnapbugAnalytics.shared, configure: { _ in })
                config.install(factory: SnapbugCrashReporter.shared, configure: { c in
                    (c as! SnapbugCrashReporterConfig).catchFatalErrors = true
                })
                config.install(factory: SnapbugDevice.shared, configure: { _ in })
                config.install(factory: SnapbugNetwork.shared, configure: { _ in })
            }
        )
        #endif
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if DEBUG
                    SnapbugDebugFeedbackIos.shared.start(
                        config: DebugFeedbackConfig(
                            enabled: true,
                            screenNameProvider: { SampleAppState.shared.currentScreen },
                            collectTimeline: true,
                            timelineMaxEvents: 200,
                            timelineMaxAgeSeconds: 60,
                            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
                        )
                    )
                    #endif
                }
        }
    }
}
