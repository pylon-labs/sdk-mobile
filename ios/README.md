# Pylon Chat SDK for iOS

Add Pylon's chat widget to your iOS application to enable in-app customer support.

## Requirements

- iOS 14.0+
- Swift 5.5+
- Xcode 13.0+

---

## Installation

### Option 1: Copy Single File (Recommended)

This SDK is distributed as source code. Clone or download the repository:

```bash
git clone https://github.com/pylon-labs/sdk-mobile.git
```

Copy the SDK file directly into your Xcode project:

1. Locate `ios/PylonChat/PylonChat.swift` in the cloned repository
2. Drag it into your Xcode project
3. Make sure "Copy items if needed" is checked
4. Add to your app target

The SDK is a single Swift file with no external dependencies (except WebKit, which is part of iOS).

### Option 2: Local Swift Package Manager

**Note:** A published package for Swift Package Manager support will likely be added in the future.

Add as a local package in Xcode:

1. File → Add Package Dependencies
2. Click "Add Local..."
3. Select the `sdk-mobile` folder
4. Click "Add Package"

The `Package.swift` at the root defines the `PylonChat` library.

### Get Your Pylon App ID

1. Login to [app.usepylon.com](https://app.usepylon.com)
2. Go to Settings → Chat Widget
3. Copy your App ID

---

## Quick Start

### 1. Initialize the SDK

In your App's `init()` or AppDelegate:

```swift
import SwiftUI
import PylonChat

@main
struct YourApp: App {
    init() {
        // Initialize Pylon
        Pylon.shared.initialize(appId: "YOUR_APP_ID")

        // Set user information
        Pylon.shared.setUser(
            email: "user@example.com",
            name: "John Doe"
        )
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### 2. Add the Chat Widget

**SwiftUI:**

```swift
import SwiftUI
import PylonChat

struct ContentView: View {
    @State private var pylonChatView: PylonChatView?
    @State private var unreadCount = 0

    var body: some View {
        ZStack {
            // Your app content
            VStack {
                Text("Your App Content")
                Spacer()
            }

            // Pylon Chat Widget
            PylonChatHostView(
                chatView: $pylonChatView,
                unreadCount: $unreadCount
            )
        }
    }
}
```

**UIKit:**

```swift
import UIKit
import PylonChat

class ViewController: UIViewController {
    private var pylonChatView: PylonChatView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Create chat view
        pylonChatView = Pylon.shared.createChat()
        pylonChatView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pylonChatView)

        NSLayoutConstraint.activate([
            pylonChatView.topAnchor.constraint(equalTo: view.topAnchor),
            pylonChatView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            pylonChatView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            pylonChatView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    deinit {
        pylonChatView?.destroy()
    }
}
```

---

## API Reference

### Initialization

```swift
// Basic initialization
Pylon.shared.initialize(appId: "YOUR_APP_ID")

// With optional configuration
Pylon.shared.initialize(
    appId: "YOUR_APP_ID",
    enableLogging: true,   // Enable debug logs (default: true)
    debugMode: false       // Show debug overlay (default: false)
    // widgetBaseUrl: "http://localhost:0001"  // likely do not need this
)
```

### User Management

**Set User:**

```swift
// Basic user
Pylon.shared.setUser(
    email: "user@example.com",
    name: "John Doe"
)

// With optional fields
Pylon.shared.setUser(
    email: "user@example.com",
    name: "John Doe",
    avatarUrl: "https://example.com/avatar.jpg",
    emailHash: "sha256_hash_for_verification",
    accountId: "account_123",
    accountExternalId: "external_id_456"
)

// Or using struct
let user = PylonUser(
    email: "user@example.com",
    name: "John Doe",
    avatarUrl: "https://example.com/avatar.jpg"
)
Pylon.shared.setUser(user)
```

**Update User:**

```swift
pylonChatView?.updateUser(
    PylonUser(
        email: "newemail@example.com",
        name: "Jane Doe"
    )
)
```

**Clear User (on logout):**

```swift
Pylon.shared.clearUser()
```

### Creating Chat Views

```swift
// Create a chat view
let chatView = Pylon.shared.createChat()

// For SwiftUI, use PylonChatHostView wrapper
PylonChatHostView(
    chatView: $pylonChatView,
    unreadCount: $unreadCount
)
```

### Chat Controls

```swift
// Show/hide chat window
pylonChatView?.openChat()
pylonChatView?.closeChat()

// Show/hide chat bubble
pylonChatView?.showChatBubble()
pylonChatView?.hideChatBubble()
```

### Sending Messages

```swift
// Plain text message
pylonChatView?.showNewMessage("Hello from the app!", isHtml: false)

// HTML message
pylonChatView?.showNewMessage("<p>Hello <strong>HTML</strong>!</p>", isHtml: true)
```

### Custom Fields

```swift
pylonChatView?.setNewIssueCustomFields([
    "source": "ios-app",
    "priority": "high",
    "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
])
```

### Form Navigation

```swift
// Show a ticket form
pylonChatView?.showTicketForm("support-request")

// Show a knowledge base article
pylonChatView?.showKnowledgeBaseArticle("article-id-123")

// Pre-fill ticket form fields
pylonChatView?.setTicketFormFields([
    "subject": "Issue from iOS app",
    "description": "User reported an issue"
])
```

### Identity Verification

```swift
// Set email hash for verified users
pylonChatView?.updateEmailHash("sha256_hashed_email")
```

### Event Listeners

Implement the `PylonChatListener` protocol:

```swift
class MyViewController: UIViewController, PylonChatListener {
    override func viewDidLoad() {
        super.viewDidLoad()

        let pylonChatView = Pylon.shared.createChat()
        pylonChatView.listener = self
    }

    func onPylonLoaded() {
        print("Widget has loaded")
    }

    func onPylonInitialized() {
        print("Widget is initialized with user data")
    }

    func onPylonReady() {
        print("Widget JavaScript is ready")
    }

    func onChatOpened() {
        print("User opened the chat")
    }

    func onChatClosed(wasOpen: Bool) {
        print("User closed the chat, was open: \(wasOpen)")
    }

    func onUnreadCountChanged(count: Int) {
        print("Unread messages: \(count)")
    }

    func onMessageReceived(message: String) {
        print("New message: \(message)")
    }

    func onPylonError(error: String) {
        print("Error: \(error)")
    }
}
```

**SwiftUI Event Handling:**

```swift
struct ContentView: View {
    @State private var pylonChatView: PylonChatView?
    @State private var unreadCount = 0

    var body: some View {
        ZStack {
            // Your content

            PylonChatHostView(
                chatView: $pylonChatView,
                unreadCount: $unreadCount
            )
        }
        .onChange(of: unreadCount) { newCount in
            print("Unread count: \(newCount)")
        }
        .onAppear {
            // Access the view once created
            if let chatView = pylonChatView {
                // Set listener, call methods, etc.
            }
        }
    }
}
```

### Cleanup

The SDK automatically cleans up when the view is deallocated. For manual cleanup:

```swift
pylonChatView?.destroy()
```

---

## Usage Patterns

### Conditional Rendering (User Login)

```swift
struct ContentView: View {
    @State private var currentUser: User?
    @State private var pylonChatView: PylonChatView?
    @State private var unreadCount = 0

    var body: some View {
        ZStack {
            MyAppContent()

            if let user = currentUser {
                PylonChatHostView(
                    chatView: $pylonChatView,
                    unreadCount: $unreadCount
                )
                .onAppear {
                    Pylon.shared.setUser(
                        email: user.email,
                        name: user.name
                    )
                }
            }
        }
    }
}
```

### Setting Metadata

```swift
class ChatViewController: UIViewController {
    private var pylonChatView: PylonChatView!

    override func viewDidLoad() {
        super.viewDidLoad()

        pylonChatView = Pylon.shared.createChat()
        // ... add to view ...

        // Set custom fields for all new issues
        pylonChatView.setNewIssueCustomFields([
            "app_version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown",
            "platform": "ios",
            "device": UIDevice.current.model,
            "ios_version": UIDevice.current.systemVersion
        ])
    }
}
```

---

## Architecture

The iOS SDK is a single Swift file (`PylonChat.swift`) with no external dependencies (except WebKit, which is part of iOS).

**How it works:**

```
PylonChatView
  └── WKWebView
      ├── Loads widget from widget.usepylon.com/widget/{appId}
      ├── JavaScript ↔ Swift bridge (evaluateJavaScript)
      ├── Touch event interception (hitTest)
      └── Dynamic bounds tracking for interactive elements
```

**Key features:**

- WebView-based (same widget as web SDK)
- Native touch handling with smart pass-through
- JavaScript bridge for API calls and events
- String escaping for XSS prevention
- URL encoding for parameters

---

## Demo App

See [`DemoApp/README.md`](./DemoApp/README.md) for a complete example application demonstrating all SDK features.

---

## Support

For issues or questions:, please reach out to the Pylon team.
