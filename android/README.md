# Pylon Chat SDK for Android

Add Pylon's chat widget to your Android application to enable in-app customer support.

## Requirements

- Android SDK 24 (Android 7.0)+
- Kotlin 1.9+
- Java 11+

---

## Installation

This SDK is distributed as source code. Clone or download the repository:

```bash
git clone https://github.com/pylon-labs/sdk-mobile.git
cd sdk-mobile/android
```

### 1. Copy the SDK Module

Copy the `pylon/` directory into your Android project:

```bash
# From your Android project root
cp -r /path/to/sdk-mobile/android/pylon ./
```

### 2. Include the Module

Add to your `settings.gradle.kts`:

```kotlin
include(":pylon")
```

### 3. Add Dependency

Add to your app's `build.gradle.kts`:

```kotlin
dependencies {
    implementation(project(":pylon"))
    // ... your other dependencies
}
```

### 4. Get Your Pylon App ID

1. Login to [app.usepylon.com](https://app.usepylon.com)
2. Go to Settings → Chat Widget
3. Copy your App ID

---

## Quick Start

### 1. Initialize the SDK

In your Application class or Activity's `onCreate()`:

```kotlin
import com.pylon.chatwidget.Pylon

class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Initialize Pylon SDK
        Pylon.initialize(
            applicationContext,
            appId = "YOUR_APP_ID"
        )

        // Set user information
        Pylon.setUser(
            email = "user@example.com",
            name = "John Doe"
        )
    }
}
```

### 2. Add the Chat Widget

**Jetpack Compose:**

```kotlin
import com.pylon.chatwidget.Pylon
import com.pylon.chatwidget.PylonChat
import com.pylon.chatwidget.PylonChatController
import androidx.compose.ui.viewinterop.AndroidView

@Composable
fun MyScreen() {
    var pylonChat by remember { mutableStateOf<PylonChatController?>(null) }

    Box(modifier = Modifier.fillMaxSize()) {
        // Your app content
        MyAppContent()

        // Pylon Chat Widget
        AndroidView(
            factory = { context ->
                Pylon.createChat(context).also { controller ->
                    pylonChat = controller
                }.view
            },
            modifier = Modifier.fillMaxSize(),
            onRelease = { view ->
                if (view is PylonChat) {
                    view.destroy()
                }
            }
        )
    }
}
```

**XML Layout:**

```xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <!-- Your app content -->
    <LinearLayout
        android:layout_width="match_parent"
        android:layout_height="match_parent">
        <!-- ... -->
    </LinearLayout>

    <!-- Pylon Chat Widget -->
    <com.pylon.chatwidget.PylonChat
        android:id="@+id/pylonChat"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</FrameLayout>
```

```kotlin
class MainActivity : AppCompatActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        val pylonChat = findViewById<PylonChat>(R.id.pylonChat)
    }
}
```

---

## API Reference

### Initialization

```kotlin
// Basic initialization
Pylon.initialize(
    context,
    appId = "YOUR_APP_ID"
)

// With optional configuration
Pylon.initialize(
    context,
    appId = "YOUR_APP_ID"
) {
    enableLogging = true   // Enable debug logs (default: true)
    debugMode = false      // Show debug overlay (default: false)

    // widgetBaseUrl = "http://10.0.2.2:9002" // likely do not need this
}
```

### User Management

**Set User:**

```kotlin
// Basic user
Pylon.setUser(
    email = "user@example.com",
    name = "John Doe"
)

// With optional fields
Pylon.setUser(
    email = "user@example.com",
    name = "John Doe"
) {
    avatarUrl = "https://example.com/avatar.jpg"
    emailHash = "sha256_hash_for_verification"
    accountId = "account_123"
    accountExternalId = "external_id_456"
}

// Or using object
val user = PylonUser(
    email = "user@example.com",
    name = "John Doe"
)
Pylon.setUser(user)
```

**Update User:**

```kotlin
chatController.updateUser(
    PylonUser(
        email = "newuser@example.com",
        name = "Jane Doe"
    )
)
```

**Clear User (on logout):**

```kotlin
Pylon.clearUser()
```

### Creating Chat Views

```kotlin
// Create a chat controller
val chatController = Pylon.createChat(context)

// Access the view
val chatView = chatController.view
```

### Chat Controls

```kotlin
// Show/hide chat window
chatController.openChat()
chatController.closeChat()

// Show/hide chat bubble
chatController.showChatBubble()
chatController.hideChatBubble()
```

### Sending Messages

```kotlin
// Plain text message
chatController.showNewMessage("Hello from the app!", isHtml = false)

// HTML message
chatController.showNewMessage("<p>Hello <strong>HTML</strong>!</p>", isHtml = true)
```

### Custom Fields

```kotlin
chatController.setNewIssueCustomFields(
    mapOf(
        "source" to "android-app",
        "priority" to "high",
        "version" to BuildConfig.VERSION_NAME
    )
)
```

### Form Navigation

```kotlin
// Show a ticket form
chatController.showTicketForm("support-request")

// Show a knowledge base article
chatController.showKnowledgeBaseArticle("article-id-123")

// Pre-fill ticket form fields
chatController.setTicketFormFields(
    mapOf(
        "subject" to "Issue from Android app",
        "description" to "User reported an issue"
    )
)
```

### Identity Verification

```kotlin
// Set email hash for verified users
chatController.setEmailHash("sha256_hashed_email")
```

### Event Listeners

```kotlin
import com.pylon.chatwidget.PylonChatListener

val listener = object : PylonChatListener {
    override fun onPylonLoaded() {
        // Widget has loaded
    }

    override fun onPylonInitialized() {
        // Widget is initialized with user data
    }

    override fun onPylonReady() {
        // Widget JavaScript is ready
    }

    override fun onChatOpened() {
        // User opened the chat
    }

    override fun onChatClosed() {
        // User closed the chat
    }

    override fun onUnreadCountChanged(count: Int) {
        // Unread message count changed
    }

    override fun onMessageReceived(message: String) {
        // New message received
    }

    override fun onPylonError(error: String) {
        // Error occurred
    }
}

chatController.setListener(listener)
```

### Cleanup

```kotlin
override fun onDestroy() {
    super.onDestroy()
    chatController.destroy()
}
```

---

## Usage Patterns

### Application-Wide Initialization

```kotlin
class MyApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize once for the entire app
        Pylon.initialize(this, appId = "YOUR_APP_ID")
    }
}
```

Don't forget to register in `AndroidManifest.xml`:

```xml
<application
    android:name=".MyApplication"
    ...>
```

### Conditional Rendering (User Login)

```kotlin
@Composable
fun MyApp() {
    val currentUser by viewModel.currentUser.collectAsState()
    var pylonChat by remember { mutableStateOf<PylonChatController?>(null) }

    Box(modifier = Modifier.fillMaxSize()) {
        MyContent()

        // Only show chat when logged in
        if (currentUser != null) {
            AndroidView(
                factory = { context ->
                    Pylon.setUser(
                        email = currentUser!!.email,
                        name = currentUser!!.name
                    )
                    Pylon.createChat(context).also { pylonChat = it }.view
                },
                modifier = Modifier.fillMaxSize()
            )
        }
    }

    // Clear user on logout
    LaunchedEffect(currentUser) {
        if (currentUser == null) {
            Pylon.clearUser()
        }
    }
}
```

### Setting Metadata

```kotlin
class MainActivity : AppCompatActivity() {
    private lateinit var chatController: PylonChatController

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        chatController = Pylon.createChat(this)

        // Set custom fields for all new issues
        chatController.setNewIssueCustomFields(
            mapOf(
                "app_version" to BuildConfig.VERSION_NAME,
                "platform" to "android",
                "device" to Build.MODEL,
                "android_version" to Build.VERSION.RELEASE
            )
        )
    }
}
```

---

## Architecture

The Android SDK consists of several Kotlin files in the `com.pylon.chatwidget` package:

**Core Files:**

- `Pylon.kt` - Singleton for SDK initialization and configuration
- `PylonChat.kt` - Main view that embeds the widget
- `PylonChatController.kt` - Controller for imperative API
- `PylonUser.kt` - User data model
- `PylonConfig.kt` - Configuration model
- `PylonChatListener.kt` - Event listener interface

**How it works:**

```
PylonChat (View)
  └── WebView
      ├── Loads widget from widget.usepylon.com/widget/{appId}
      ├── JavaScript ↔ Kotlin bridge (evaluateJavascript)
      ├── Touch event interception (dispatchTouchEvent)
      └── Dynamic bounds tracking for interactive elements
```

**Key features:**

- WebView-based (same widget as web SDK)
- Native touch handling with smart pass-through
- JavaScript bridge for API calls and events
- String escaping for XSS prevention
- URL encoding for parameters
- No external dependencies (except Android WebView)

---

## Demo App

See [`app/README.md`](./app/README.md) for a complete example application demonstrating all SDK features.

---

## Support

For issues or questions, pleaes reach out to the Pylon team.
