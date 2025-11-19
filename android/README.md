# Pylon Chat Widget - Android SDK

Add Pylon's chat widget to your Android application to enable in-app customer support.

## Requirements

- Android SDK 24 (Android 7.0) or higher
- Kotlin 1.9+
- Java 11+

## Installation

### 1. Add the SDK to your project

Add the Pylon Chat SDK to your app's `build.gradle.kts`:

```kotlin
dependencies {
    implementation(project(":pylon"))
}
```

### 2. Update settings.gradle.kts

Make sure the SDK module is included in your `settings.gradle.kts`:

```kotlin
include(":app")
include(":pylon")
```

## Demo App

### 1. Set environment variables for demo app

The demo app uses `.env.local` for easy configuration. Copy the example file and add your credentials:

```bash
cp env.local.example .env.local
```

Edit `.env.local` with your Pylon account details:

```bash
# Get your app ID from https://app.usepylon.com/settings/chat-widget
WIDGET_APP_ID=your-app-id-from-pylon

# Test user for the demo app
USER_EMAIL=john@yourcompany.com
USER_NAME=John Doe
```

### 2. Run the Demo App

Open the project in Android Studio and run the `app` module. The demo app will automatically use your configuration from `.env.local`.

**Note:** The demo app's configuration is in `app/src/main/java/com/example/chatwidgetdemo/MainActivity.kt` - this is for testing only. In your own app, you'll initialize the SDK directly in your code.

---

## Integration Guide

### Initialize the SDK

In your own app, initialize Pylon in your Application class or Activity's `onCreate()`:

```kotlin
import com.pylon.chatwidget.Pylon
import com.pylon.chatwidget.PylonUser

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

### Add the Chat Widget

#### Jetpack Compose

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

#### XML Layout

```xml
<FrameLayout xmlns:android="http://schemas.android.com/apk/res/android"
    android:layout_width="match_parent"
    android:layout_height="match_parent">

    <!-- Your app content -->

    <!-- Pylon Chat Widget -->
    <com.pylon.chatwidget.PylonChat
        android:id="@+id/pylonChat"
        android:layout_width="match_parent"
        android:layout_height="match_parent" />
</FrameLayout>
```

```kotlin
val pylonChat = findViewById<PylonChat>(R.id.pylonChat)
```

## Configuration Options

```kotlin
Pylon.initialize(
    context,
    appId = "YOUR_APP_ID"
) {
    primaryColor = "#FF5733"                      // Custom brand color
    widgetBaseUrl = "https://widget.usepylon.com" // Custom widget URL
    widgetScriptUrl = "https://..."               // Custom script URL
}
```

## User Management

### Set User

```kotlin
Pylon.setUser(
    email = "user@example.com",
    name = "John Doe"
) {
    avatarUrl = "https://example.com/avatar.jpg"
    emailHash = "sha256_hash_for_verification"
    accountId = "account_123"
    accountExternalId = "external_id_456"
}
```

### Update User

```kotlin
pylonChat.updateUser(
    PylonUser(
        email = "newuser@example.com",
        name = "Jane Doe"
    )
)
```

### Clear User (e.g., on logout)

```kotlin
Pylon.clearUser()
```

## Chat Controls

```kotlin
val chatController = Pylon.createChat(context)

// Show/hide chat window
chatController.openChat()
chatController.closeChat()

// Show/hide chat bubble
chatController.showChatBubble()
chatController.hideChatBubble()
```

## Advanced Features

### Send Messages from Your App

```kotlin
chatController.showNewMessage("Hello from the app!", isHtml = false)
chatController.showNewMessage("<p>Hello <strong>HTML</strong>!</p>", isHtml = true)
```

### Set Custom Fields

```kotlin
chatController.setNewIssueCustomFields(
    mapOf(
        "source" to "android-app",
        "priority" to "high",
        "version" to BuildConfig.VERSION_NAME
    )
)
```

### Show Specific Forms

```kotlin
// Show a ticket form
chatController.showTicketForm("support-request")

// Show a knowledge base article
chatController.showKnowledgeBaseArticle("article-id-123")
```

### Set Ticket Form Fields

```kotlin
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

## Event Listeners

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

## File Upload Support

Handle file picker results in your Activity:

```kotlin
class MainActivity : AppCompatActivity() {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (Pylon.handleActivityResult(resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }
}
```

## Cleanup

```kotlin
override fun onDestroy() {
    super.onDestroy()
    chatController.destroy()
}
```

## Example

See the `app` module for a complete demo application with all features.

## Support

For issues or questions, visit [usepylon.com](https://usepylon.com) or contact support@usepylon.com
