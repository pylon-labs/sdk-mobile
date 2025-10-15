import SwiftUI
import PylonChat

@main
struct DemoApp: App {
    init() {
        // Initialize Pylon SDK
        Pylon.shared.initialize(
            appId: "d48c8c5b-f96c-45e0-bb0f-dfbcecd75c6b",
            enableLogging: true,
            debugMode: true,
            // widgetBaseUrl: "http://localhost:9001",
            // widgetScriptUrl: "http://localhost:9001/widget/d48c8c5b-f96c-45e0-bb0f-dfbcecd75c6b"
        )

        // Set user
        Pylon.shared.setUser(
            email: "ben@ben.com",
            name: "Ben Song"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
