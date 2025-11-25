# Pylon iOS Demo App

Demo application showcasing the Pylon Chat SDK for iOS. This is a complete SwiftUI app with all SDK features integrated.

---

## Quick Start

### 1. Configure Your App ID

Create the configuration file:

```bash
cd ios
cp EnvConfig.swift.example DemoApp/EnvConfig.swift
```

Edit `DemoApp/EnvConfig.swift` with your settings:

```swift
enum EnvConfig {
    static let widgetAppId = "your-app-id-here"
    static let widgetBaseUrl = "https://widget.usepylon.com"
    static let userEmail = "demo@yourcompany.com"
    static let userName = "Demo User"
    static let userAvatarUrl: String? = nil
    static let userEmailHash: String? = nil
}
```

**Get your app ID:** Sign up at [usepylon.com](https://usepylon.com) → Settings → Chat Widget

### 2. Open in Xcode

```bash
open PylonChat.xcodeproj
```

### 3. Select DemoApp Scheme

In Xcode's top toolbar:

1. Click the scheme dropdown (middle, may say "PylonChat")
2. Select **DemoApp**
3. Select an iOS simulator (e.g., iPhone 15)

### 4. Run

Click Run (▶️) or press ⌘R.

**Note:** The app will show an error if `EnvConfig.swift` is not configured with your app ID.

---

## How the SDK Was Integrated

This demo shows a typical SwiftUI integration. Here's how we did it:

### 1. SDK Initialization

```swift
// DemoApp.swift
import SwiftUI
import PylonChat

@main
struct DemoApp: App {
    init() {
        // Initialize Pylon with config
        Pylon.shared.initialize(
            appId: EnvConfig.widgetAppId,
            widgetBaseUrl: EnvConfig.widgetBaseUrl
        )

        // Set user from config
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
```

### 2. Widget Integration

```swift
// ContentView.swift
import SwiftUI
import PylonChat

struct ContentView: View {
    @State private var pylonChatView: PylonChatView?
    @State private var unreadCount = 0

    var body: some View {
        ZStack {
            // App content
            ScrollView {
                VStack(spacing: 20) {
                    Text("Demo App")
                    // ... more content ...
                }
            }

            // Pylon widget as full-screen overlay
            PylonChatHostView(
                chatView: $pylonChatView,
                unreadCount: $unreadCount
            )
        }
    }
}
```

The `PylonChatHostView` is a SwiftUI wrapper that:

- Creates the native `PylonChatView`
- Bridges state (unreadCount) to SwiftUI
- Handles lifecycle automatically

### 3. Using Imperative Methods

```swift
struct ContentView: View {
    @State private var pylonChatView: PylonChatView?

    var body: some View {
        VStack {
            // Control buttons
            Button("Open Chat") {
                pylonChatView?.openChat()
            }

            Button("Send Message") {
                pylonChatView?.showNewMessage("Hello!", isHtml: false)
            }

            Button("Set Custom Fields") {
                pylonChatView?.setNewIssueCustomFields([
                    "source": "demo-app",
                    "platform": "ios"
                ])
            }

            // Widget
            PylonChatHostView(chatView: $pylonChatView, unreadCount: .constant(0))
        }
    }
}
```

### 4. Event Handling

For event listeners, you'd typically use a coordinator or custom view:

```swift
class ChatCoordinator: PylonChatListener {
    func onChatOpened() {
        print("Chat opened")
    }

    func onUnreadCountChanged(count: Int) {
        print("Unread: \(count)")
    }

    // ... other methods ...
}

// In your view:
.onAppear {
    let coordinator = ChatCoordinator()
    pylonChatView?.listener = coordinator
}
```

---

## Demo App Features

This demo includes:

- ✅ Environment-based configuration (`EnvConfig.swift`)
- ✅ Full-screen overlay integration
- ✅ SwiftUI patterns (`PylonChatHostView`)
- ✅ Imperative API examples
- ✅ Interactive test buttons
- ✅ Unread count display

---

## Quirks & Differences from Production

### 1. EnvConfig.swift Pattern

This demo uses a gitignored `EnvConfig.swift` file for configuration.

Example production pattern:

```swift
@main
struct MyApp: App {
    @StateObject private var authManager = AuthManager()

    init() {
        Pylon.shared.initialize(appId: Config.pylonAppId)
    }

    var body: some Scene {
        WindowGroup {
            if let user = authManager.currentUser {
                MainView(user: user)
            } else {
                LoginView()
            }
        }
        .onChange(of: authManager.currentUser) { user in
            if let user = user {
                Pylon.shared.setUser(
                    email: user.email,
                    name: user.name
                )
            } else {
                Pylon.shared.clearUser()
            }
        }
    }
}
```

### 2. Widget Base URL

This demo defaults to `https://widget.usepylon.com`. The config allows changing this endpoint, but you should basically always be using the default (omit the parameter).

### 3. Test User

The demo hardcodes a test user in `EnvConfig.swift`. **In production:**

- Use your authenticated user's actual email/name
- Set user after successful login
- Clear user on logout

### 4. Always-Visible Widget

This demo always shows the widget. **In production**, you might:

- Only show when user is logged in
- Hide on certain screens (login, onboarding)
- Conditionally render based on feature flags

```swift
struct ContentView: View {
    @State private var showChat = true
    @State private var pylonChatView: PylonChatView?

    var body: some View {
        ZStack {
            MyContent()

            if showChat {
                PylonChatHostView(chatView: $pylonChatView, unreadCount: .constant(0))
            }
        }
    }
}
```

---

## Project Structure

```
ios/
├── PylonChat/
│   └── PylonChat.swift         # SDK (single file)
├── DemoApp/
│   ├── DemoApp.swift           # App entry + SDK initialization
│   ├── ContentView.swift       # Main view with widget
│   ├── EnvConfig.swift         # Your config (gitignored)
│   └── Assets.xcassets/
├── EnvConfig.swift.example     # Config template
├── PylonChat.xcodeproj/
└── README.md                   # This file
```

---

## Configuration Files

### EnvConfig.swift (gitignored)

Your local configuration - create from `EnvConfig.swift.example`:

```swift
enum EnvConfig {
    static let widgetAppId = "your-app-id"
    static let widgetBaseUrl = "https://widget.usepylon.com"
    static let userEmail = "demo@example.com"
    static let userName = "Demo User"
    static let userAvatarUrl: String? = nil
    static let userEmailHash: String? = nil
}
```

### EnvConfig.swift.example (committed)

Template file showing the structure. Copy this to `DemoApp/EnvConfig.swift` and fill in your values.

---

## Troubleshooting

### "Configuration Required" Error

The app shows this error if `EnvConfig.swift` is missing or has invalid values:

```swift
// DemoApp checks for valid config:
if EnvConfig.widgetAppId == "your-app-id-here" {
    Text("⚠️ Configuration Required")
}
```

**Solution:** Copy and edit `EnvConfig.swift.example` to `DemoApp/EnvConfig.swift` with your real app ID.

### Build Errors: "Cannot find 'EnvConfig' in scope"

The file isn't in the right place or not added to the target.

**Solution:**

1. Make sure `EnvConfig.swift` is in `DemoApp/` directory
2. In Xcode, verify it's part of the DemoApp target (File Inspector → Target Membership)

### "No such module 'PylonChat'"

The SDK isn't properly linked.

**Solution:**

- Clean build folder: ⇧⌘K
- Rebuild the project: ⌘B
- Check scheme is set to "DemoApp"

### Widget Not Loading

1. Verify app ID in `EnvConfig.swift` is correct (from usepylon.com settings)
2. Check internet connectivity (simulator has network access)
3. Look for errors in Xcode console
4. Verify you're signed in at usepylon.com with that app ID

### Simulator vs Device

**Simulator:** Works great, full functionality

**Real Device:** May need code signing setup:

1. Select your team in Project Settings → Signing & Capabilities
2. Connect device via USB
3. Select device in scheme dropdown
4. Click Run

---

## Development Workflow

### Making Changes

1. Edit code in Xcode or your preferred editor
2. Xcode auto-reloads if you have "Automatically reload changes" enabled
3. Click Run (▶️) to rebuild and launch

### Testing Different Scenarios

**Different Users:**

Edit `EnvConfig.swift` and rerun:

```swift
static let userEmail = "different-user@example.com"
static let userName = "Different User"
```

**Local Development:**

If running the full Pylon backend locally, change:

```swift
static let widgetBaseUrl = "http://localhost:9002"
```

(See main README for taskrunner setup)

**Production Testing:**

Use default URL and a production app ID:

```swift
static let widgetBaseUrl = "https://widget.usepylon.com"
static let widgetAppId = "your-production-app-id"
```

---

## Next Steps

To integrate Pylon into your own app, see the [SDK README](../README.md) for installation and API reference.

This demo app source code provides a complete integration example you can reference or copy.
