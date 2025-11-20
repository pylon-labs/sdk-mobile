import SwiftUI
import PylonChat

@main
struct DemoApp: App {
    init() {
        // Configuration is loaded from EnvConfig.swift
        // To customize: cp ../EnvConfig.swift.example DemoApp/EnvConfig.swift
        // Then edit EnvConfig.swift with your app ID from https://app.usepylon.com/settings
        
        // Validate configuration
        guard EnvConfig.widgetAppId != "YOUR_APP_ID_HERE" && !EnvConfig.widgetAppId.isEmpty else {
            fatalError("""
                ⚠️ Configuration Required
                
                Please configure EnvConfig.swift with your Pylon app ID:
                1. Copy: cp EnvConfig.swift.example DemoApp/EnvConfig.swift
                2. Edit DemoApp/EnvConfig.swift with your app ID from https://app.usepylon.com/settings
                3. Rebuild and run
                """)
        }
        
        let widgetScriptUrl = "\(EnvConfig.widgetBaseUrl)/widget/\(EnvConfig.widgetAppId)"
        
        // Initialize Pylon SDK
        Pylon.shared.initialize(
            appId: EnvConfig.widgetAppId,
            enableLogging: true,
            debugMode: true,
            widgetBaseUrl: EnvConfig.widgetBaseUrl,
            widgetScriptUrl: widgetScriptUrl
        )

        // Set user from environment
        Pylon.shared.setUser(
            email: EnvConfig.userEmail,
            name: EnvConfig.userName,
            avatarUrl: EnvConfig.userAvatarUrl,
            emailHash: EnvConfig.userEmailHash
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
