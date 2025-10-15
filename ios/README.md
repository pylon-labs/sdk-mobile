# Pylon Chat Widget - iOS SDK

Add Pylon's chat widget to your iOS application to enable in-app customer support.

## Requirements

- iOS 14.0 or higher
- Swift 5.5+
- Xcode 13.0+

## Installation

### 1. Add the SDK to your project

Drag the `PylonChat` framework into your Xcode project, or add it as a local Swift Package.

### 2. Import the SDK

```swift
import PylonChat
```

## Usage

### Initialize the SDK

Initialize Pylon in your App's `init()` or AppDelegate:

```swift
import SwiftUI
import PylonChat

@main
struct YourApp: App {
    init() {
        // Initialize Pylon SDK
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

### Add the Chat Widget

#### SwiftUI

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

#### UIKit

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

## Configuration Options

```swift
Pylon.shared.initialize(
    appId: "YOUR_APP_ID",
    primaryColor: "#FF5733",                      // Custom brand color
    widgetBaseUrl: "https://widget.usepylon.com", // Custom widget URL
    widgetScriptUrl: "https://..."                // Custom script URL
)
```

## User Management

### Set User

```swift
Pylon.shared.setUser(
    email: "user@example.com",
    name: "John Doe",
    avatarUrl: "https://example.com/avatar.jpg",
    emailHash: "sha256_hash_for_verification",
    accountId: "account_123",
    accountExternalId: "external_id_456"
)
```

Or using the struct:

```swift
let user = PylonUser(
    email: "user@example.com",
    name: "John Doe",
    avatarUrl: "https://example.com/avatar.jpg"
)
Pylon.shared.setUser(user)
```

### Update User

```swift
pylonChatView?.updateUser(
    PylonUser(
        email: "newuser@example.com",
        name: "Jane Doe"
    )
)
```

### Clear User (e.g., on logout)

```swift
Pylon.shared.clearUser()
```

## Chat Controls

```swift
// Show/hide chat window
pylonChatView?.openChat()
pylonChatView?.closeChat()

// Show/hide chat bubble
pylonChatView?.showChatBubble()
pylonChatView?.hideChatBubble()
```

## Advanced Features

### Send Messages from Your App

```swift
pylonChatView?.showNewMessage("Hello from the app!", isHtml: false)
pylonChatView?.showNewMessage("<p>Hello <strong>HTML</strong>!</p>", isHtml: true)
```

### Set Custom Fields

```swift
pylonChatView?.setNewIssueCustomFields([
    "source": "ios-app",
    "priority": "high",
    "version": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "unknown"
])
```

### Show Specific Forms

```swift
// Show a ticket form
pylonChatView?.showTicketForm("support-request")

// Show a knowledge base article
pylonChatView?.showKnowledgeBaseArticle("article-id-123")
```

### Set Ticket Form Fields

```swift
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

## Event Listeners

```swift
import PylonChat

class MyViewController: UIViewController, PylonChatListener {
    override func viewDidLoad() {
        super.viewDidLoad()

        let pylonChatView = Pylon.shared.createChat()
        pylonChatView.listener = self
    }

    func onPylonLoaded() {
        // Widget has loaded
    }

    func onPylonInitialized() {
        // Widget is initialized with user data
    }

    func onPylonReady() {
        // Widget JavaScript is ready
    }

    func onChatOpened() {
        // User opened the chat
    }

    func onChatClosed() {
        // User closed the chat
    }

    func onUnreadCountChanged(count: Int) {
        // Unread message count changed
    }

    func onMessageReceived(message: String) {
        // New message received
    }

    func onPylonError(error: String) {
        // Error occurred
    }
}
```

### SwiftUI Listener

For SwiftUI, extend the `PylonChatHostView.Coordinator`:

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
    }
}
```

## Cleanup

The SDK automatically cleans up when the view is deallocated, but you can manually clean up:

```swift
pylonChatView?.destroy()
```

## Example

See the `DemoApp` target for a complete demo application with all features.

## Support

For issues or questions, visit [usepylon.com](https://usepylon.com) or contact support@usepylon.com
