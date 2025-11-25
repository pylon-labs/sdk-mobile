# Pylon Android Demo App

Demo application showcasing the Pylon Chat SDK for Android. This is a complete Compose app with all SDK features integrated.

---

## Quick Start

### 1. Configure Your App ID

Copy the example environment file:

```bash
cd android
cp env.local.example .env.local
```

Edit `.env.local` with your settings:

```bash
# Get your app ID from https://app.usepylon.com/settings
WIDGET_APP_ID=your-app-id-here

# Widget endpoint (leave empty for production)
WIDGET_BASE_URL=

# Test user
USER_EMAIL=demo@yourcompany.com
USER_NAME=Demo User

# Optional
# USER_AVATAR_URL=https://yourcompany.com/avatars/demo.png
# USER_EMAIL_HASH=your-hashed-email-here
```

**Note:** The `.env.local` file is read by the demo app's Gradle configuration to generate `BuildConfig` fields.

### 2. Open in Android Studio

```bash
# Open the project
open -a "Android Studio" .
```

Or use File → Open in Android Studio and select the `android` directory.

### 3. Sync Gradle

Wait for Gradle sync to complete (first time takes 2-3 minutes).

### 4. Run

1. Create an Android Virtual Device (AVD) via Tools → Device Manager if needed
2. Click Run (▶️) or press ⌘R
3. Choose your emulator or connected device

---

## How the SDK Was Integrated

This demo shows a typical Compose integration. Here's how we did it:

### 1. Module Dependency

The demo app depends on the `pylon` SDK module:

```kotlin
// app/build.gradle.kts
dependencies {
    implementation(project(":pylon"))
    // ... other dependencies
}
```

In your own app, you'd include the `:pylon` module after copying it to your project.

### 2. Environment Variable Loading

The demo uses a Gradle plugin to load `.env.local` into `BuildConfig`:

```kotlin
// app/build.gradle.kts
android {
    defaultConfig {
        // Read from .env.local
        val envFile = rootProject.file(".env.local")
        if (envFile.exists()) {
            envFile.forEachLine { line ->
                val (key, value) = line.split("=", limit = 2)
                buildConfigField("String", key, "\"$value\"")
            }
        }
    }
}
```

**In production apps:** Use your own config management (Firebase Remote Config, gradle.properties, etc.) instead of `.env.local`.

### 3. Configuration Helpers

The demo app uses companion object functions to build config and user:

```kotlin
// MainActivity.kt
class MainActivity : ComponentActivity() {
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (Pylon.handleActivityResult(resultCode, data)) return
        super.onActivityResult(requestCode, resultCode, data)
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            ChatWidgetDemoTheme(darkTheme = true) {
                Scaffold(modifier = Modifier.fillMaxSize()) { innerPadding ->
                    MainContent(modifier = Modifier.padding(innerPadding).fillMaxSize())
                }
            }
        }
    }

    companion object {
        // Build config from .env.local
        fun buildConfig(): PylonConfig {
            return PylonConfig.build(BuildConfig.WIDGET_APP_ID) {
                enableLogging = true
                debugMode = true

                if (BuildConfig.WIDGET_BASE_URL.isNotEmpty()) {
                    widgetBaseUrl = BuildConfig.WIDGET_BASE_URL
                    widgetScriptUrl = "${BuildConfig.WIDGET_BASE_URL}/widget/${BuildConfig.WIDGET_APP_ID}"
                }
            }
        }

        // Build user from .env.local
        fun buildUser(): PylonUser {
            return PylonUser.build(
                email = BuildConfig.USER_EMAIL,
                name = BuildConfig.USER_NAME
            ) {
                if (BuildConfig.USER_AVATAR_URL.isNotEmpty()) {
                    avatarUrl = BuildConfig.USER_AVATAR_URL
                }
                if (BuildConfig.USER_EMAIL_HASH.isNotEmpty()) {
                    emailHash = BuildConfig.USER_EMAIL_HASH
                }
            }
        }
    }
}
```

### 4. Widget Integration

The demo creates a `PylonChatHost` composable that uses instance-based configuration:

```kotlin
// MainActivity.kt
@Composable
fun PylonChatHost(
    onControllerChanged: (PylonChatController?) -> Unit,
    modifier: Modifier = Modifier
) {
    val config = remember { MainActivity.buildConfig() }
    val user = remember { MainActivity.buildUser() }

    AndroidView(
        factory = { context ->
            Pylon.createChat(context, config, user).also { controller ->
                onControllerChanged(controller)
            }.view
        },
        modifier = modifier,
        onRelease = { view ->
            if (view is PylonChat) {
                view.destroy()
            }
            onControllerChanged(null)
        }
    )
}
```

Then in `MainContent`:

```kotlin
@Composable
fun MainContent(modifier: Modifier = Modifier) {
    var pylonChat by remember { mutableStateOf<PylonChatController?>(null) }

    Box(modifier = modifier) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Control toolbar for testing
            ControlToolbar(/* ... */)

            // App content
            Box(modifier = Modifier.weight(1f)) { }
        }

        // Pylon widget as full-screen overlay
        PylonChatHost(
            onControllerChanged = { pylonChat = it },
            modifier = Modifier.fillMaxSize()
        )
    }
}
```

The widget renders as an absolute-positioned overlay. When collapsed, touch events pass through to underlying content.

### 5. Event Handling

```kotlin
val listener = object : PylonChatListener {
    override fun onPylonLoaded() {
        Log.d("Pylon", "Widget loaded")
    }

    override fun onChatOpened() {
        Log.d("Pylon", "Chat opened")
    }

    override fun onUnreadCountChanged(count: Int) {
        Log.d("Pylon", "Unread: $count")
    }

    override fun onPylonError(error: String) {
        Log.e("Pylon", "Error: $error")
    }

    // ... other methods ...
}

pylonChat?.setListener(listener)
```

### 6. Using Imperative API

```kotlin
@Composable
fun DemoAppContent() {
    var pylonChat by remember { mutableStateOf<PylonChatController?>(null) }

    Column {
        // Control buttons
        Button(onClick = { pylonChat?.openChat() }) {
            Text("Open Chat")
        }

        Button(onClick = {
            pylonChat?.showNewMessage("Hello!", isHtml = false)
        }) {
            Text("Send Message")
        }

        Button(onClick = {
            pylonChat?.setNewIssueCustomFields(
                mapOf(
                    "source" to "demo-app",
                    "platform" to "android"
                )
            )
        }) {
            Text("Set Custom Fields")
        }
    }

    // Widget (using instance-based pattern)
    PylonChatHost(
        onControllerChanged = { pylonChat = it },
        modifier = Modifier.fillMaxSize()
    )
}
```

---

## Demo App Features

This demo includes:

- ✅ Environment-based configuration (`.env.local`)
- ✅ Full-screen overlay integration
- ✅ Jetpack Compose patterns
- ✅ Imperative API examples
- ✅ Interactive test buttons
- ✅ Event listener logging

---

## Quirks & Differences from Production

### 1. Instance-Based Pattern (No Global State)

This demo uses `Pylon.createChat(context, config, user)` which creates an independent chat instance without global state. **In production**, you might prefer the global state pattern:

```kotlin
// Initialize once in Application class
class MyApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Pylon.initialize(this, appId = BuildConfig.PYLON_APP_ID)
    }
}

// Set user after authentication
fun onUserLogin(user: User) {
    Pylon.setUser(
        email = user.email,
        name = user.name
    )
}

// Then create chat views without passing config/user each time
@Composable
fun ChatWidget() {
    AndroidView(
        factory = { context -> Pylon.createChat(context).view }
    )
}
```

**Why the demo uses instance-based:** It's more self-contained and doesn't require an `Application` class, making it easier to understand in isolation.

### 2. `.env.local` Pattern

This demo uses `.env.local` loaded into `BuildConfig`. **In production:**

- Use `gradle.properties` for sensitive values
- Use Firebase Remote Config for dynamic config
- Use your own user management system
- Don't commit credentials to git

Example:

```kotlin
// Read from gradle.properties
android {
    defaultConfig {
        buildConfigField("String", "PYLON_APP_ID",
            "\"${project.findProperty("pylon.appId") ?: ""}\"")
    }
}
```

### 2. Test User Hardcoding

The demo hardcodes a test user from `.env.local`. **In production:**

- Use your authenticated user's actual email/name
- Set user dynamically after login
- Clear user on logout

### 3. Always-Visible Widget

This demo always shows the widget. **In production**, you might:

- Only show when user is logged in
- Hide on certain screens (login, checkout)
- Conditionally render based on feature flags

```kotlin
@Composable
fun MyApp() {
    val currentUser by viewModel.currentUser.collectAsState()
    var pylonChat by remember { mutableStateOf<PylonChatController?>(null) }

    Box(modifier = Modifier.fillMaxSize()) {
        MyContent()

        if (currentUser != null) {
            AndroidView(
                factory = { context ->
                    Pylon.createChat(context).also { pylonChat = it }.view
                },
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}
```

### 4. Debug Logging

The demo logs all events to Logcat. **In production:**

- Remove or reduce logging
- Use proper logging framework (Timber, etc.)
- Don't log sensitive user data

---

## Project Structure

```
android/
├── pylon/                      # SDK module
│   └── src/main/java/com/pylon/chatwidget/
│       ├── Pylon.kt           # SDK initialization
│       ├── PylonChat.kt       # Main view
│       ├── PylonChatController.kt
│       ├── PylonUser.kt
│       └── ...
├── app/                        # Demo app module
│   ├── src/main/java/com/example/chatwidgetdemo/
│   │   └── MainActivity.kt    # Demo app code
│   └── build.gradle.kts       # App build config
├── .env.local                  # Your config (gitignored)
├── env.local.example           # Config template
├── build.gradle.kts            # Root build config
├── settings.gradle.kts         # Module includes
└── README.md                   # This file
```

---

## Configuration Files

### `.env.local` (gitignored)

Your local configuration - create from `env.local.example`:

```bash
WIDGET_APP_ID=your-app-id-here
WIDGET_BASE_URL=
USER_EMAIL=demo@yourcompany.com
USER_NAME=Demo User
```

### `env.local.example` (committed)

Template file showing the structure. Copy this to `.env.local` and fill in your values.

---

## Troubleshooting

### "Please configure .env.local" Error

The app shows this if `.env.local` is missing or has invalid values.

**Solution:** Copy and edit the example file:

```bash
cp env.local.example .env.local
# Edit .env.local with your app ID
```

Then sync Gradle (File → Sync Project with Gradle Files).

### Build Errors: "Unresolved reference: WIDGET_APP_ID"

The `.env.local` file wasn't read during Gradle sync.

**Solution:**

1. Verify `.env.local` exists in `android/` directory
2. Sync Gradle (File → Sync Project with Gradle Files)
3. Clean and rebuild (Build → Clean Project, then Build → Rebuild Project)

### "No Android device or emulator connected"

No emulator is running.

**Solution:**

- Tools → Device Manager
- Create an AVD or start an existing one

### Gradle Sync Failures

**Solution:**

- File → Sync Project with Gradle Files
- File → Invalidate Caches / Restart
- Check Java version: `java -version` (should be 11+)

### Widget Not Loading

1. Verify app ID in `.env.local` is correct (from usepylon.com settings)
2. Check internet connectivity
3. Look for errors in Logcat (filter by "pylon")
4. Verify you're signed in at usepylon.com with that app ID

### Changes Not Appearing

- **Code changes**: Click ⚡ "Apply Changes" (⌃⌘R) for fast iteration
- **Build config changes**: Full rebuild (Run ▶️)
- **SDK changes**: Sync Gradle and rebuild

---

## Development Workflow

### Making Code Changes

1. Edit code in Android Studio or your preferred editor
2. Android Studio auto-reloads if "Synchronize files" is enabled (Settings → System Settings)
3. Click ⚡ "Apply Changes" (⌃⌘R) for fast iteration (~5-10 seconds)
4. Full rebuild with Run (▶️) when needed

### Testing Different Users

Edit `.env.local` and sync Gradle:

```bash
USER_EMAIL=different-user@example.com
USER_NAME=Different User
```

Then: File → Sync Project with Gradle Files → Run

### Production Testing

Use default URL and a production app ID:

```bash
WIDGET_BASE_URL=
WIDGET_APP_ID=your-production-app-id
```

---

## Viewing Logs

In Android Studio:

1. Open Logcat panel (View → Tool Windows → Logcat)
2. Filter by "pylon" or "chatwidget"
3. See all SDK events and errors

---

## Next Steps

To integrate Pylon into your own app, see the [SDK README](../README.md) for installation and API reference.

This demo app source code (`MainActivity.kt`) provides a complete integration example you can reference or copy.
