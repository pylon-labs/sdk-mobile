# Pylon React Native Demo App

Demo application showcasing the Pylon Chat SDK for React Native. This is a complete Expo app with all SDK features integrated.

---

## Quick Start

### 1. Install Dependencies

```bash
cd demo-app
npm install
```

### 2. Configure Your App ID

Copy the example environment file:

```bash
cp env.example .env
```

Edit `.env` with your Pylon app ID:

```env
# Get your app ID from https://app.usepylon.com/settings
EXPO_PUBLIC_PYLON_APP_ID=your-app-id-here

# Default to production
EXPO_PUBLIC_PYLON_WIDGET_BASE_URL=https://widget.usepylon.com

# Test user
EXPO_PUBLIC_PYLON_USER_EMAIL=demo@yourcompany.com
EXPO_PUBLIC_PYLON_USER_NAME=Demo User

# Debug settings
EXPO_PUBLIC_PYLON_ENABLE_LOGGING=true
EXPO_PUBLIC_PYLON_DEBUG_MODE=true
```

**Why `EXPO_PUBLIC_` prefix?** Expo requires this prefix for environment variables to be accessible in your app code at build time.

### 3. Build and Run

**First time or after native changes:**

```bash
# Clean rebuild (runs prebuild, copies SDKs, etc.)
npm run rebuild

# Then start Expo
npm start

# Press 'i' for iOS or 'a' for Android
```

**Or run directly:**

```bash
npx expo run:ios      # iOS simulator
npx expo run:android  # Android emulator
```

**For code-only changes:**

```bash
# Start dev server
npm start

# Press 'i' for iOS or 'a' for Android
```

---

## How the SDK Was Integrated

This demo app shows a typical integration pattern. Here's how we did it:

### 1. Installation

The SDK is installed from the parent directory:

```json
// package.json
{
  "dependencies": {
    "@pylon/react-native-chat": "file:.."
  }
}
```

In your own app, you'd install from your local copy:

```bash
npm install /path/to/sdk-mobile/react-native
```

### 2. Configuration from Environment

```tsx
// App.tsx
const config = {
  appId: process.env.EXPO_PUBLIC_PYLON_APP_ID,
  widgetBaseUrl:
    process.env.EXPO_PUBLIC_PYLON_WIDGET_BASE_URL ||
    "https://widget.usepylon.com",
  enableLogging: process.env.EXPO_PUBLIC_PYLON_ENABLE_LOGGING === "true",
  debugMode: process.env.EXPO_PUBLIC_PYLON_DEBUG_MODE === "true",
};

const user = {
  email: process.env.EXPO_PUBLIC_PYLON_USER_EMAIL || "demo@example.com",
  name: process.env.EXPO_PUBLIC_PYLON_USER_NAME || "Demo User",
  avatarUrl: process.env.EXPO_PUBLIC_PYLON_USER_AVATAR_URL,
  emailHash: process.env.EXPO_PUBLIC_PYLON_USER_EMAIL_HASH,
  accountId: process.env.EXPO_PUBLIC_PYLON_USER_ACCOUNT_ID,
  accountExternalId: process.env.EXPO_PUBLIC_PYLON_USER_ACCOUNT_EXTERNAL_ID,
};
```

**In production apps:** Use your own config management instead of environment variables (could just be your own environment variables as well, but it's easy enough to hardcode).

### 3. Full-Screen Overlay Pattern

```tsx
// App.tsx
<View style={styles.container}>
  {/* App content */}
  <ScrollView style={styles.content}>
    <Text>My App Content</Text>
  </ScrollView>

  {/* Pylon widget as full-screen overlay */}
  <PylonChatView
    ref={pylonRef}
    config={config}
    user={user}
    listener={eventHandlers}
    style={styles.chatWidget}
  />
</View>
```

```tsx
// Styles
const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  content: {
    flex: 1,
  },
  chatWidget: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
});
```

The widget renders as an absolute-positioned overlay. When collapsed, touch events pass through to underlying content.

### 4. Event Handling

```tsx
const [unreadCount, setUnreadCount] = useState(0);
const [chatStatus, setChatStatus] = useState("closed");

const listener = {
  onPylonLoaded: () => console.log("Widget loaded"),
  onPylonReady: () => console.log("Widget ready"),
  onChatOpened: () => setChatStatus("open"),
  onChatClosed: (wasOpen) => setChatStatus("closed"),
  onUnreadCountChanged: (count) => setUnreadCount(count),
  onMessageReceived: (message) => {
    console.log("New message:", message);
    // Show notification, etc.
  },
  onPylonError: (error) => console.error("Error:", error),
};
```

### 5. Imperative API Usage

```tsx
const pylonRef = useRef<PylonChatViewRef>(null);

// Control chat
<Button onPress={() => pylonRef.current?.openChat()} />
<Button onPress={() => pylonRef.current?.closeChat()} />

// Send messages
<Button onPress={() => {
  pylonRef.current?.showNewMessage("Hello from app!", false);
}} />

// Set custom fields
<Button onPress={() => {
  pylonRef.current?.setNewIssueCustomFields({
    source: "demo-app",
    platform: Platform.OS,
  });
}} />
```

### 6. Safe Area Handling

```tsx
import { useSafeAreaInsets } from "react-native-safe-area-context";

const insets = useSafeAreaInsets();

<PylonChatView
  style={{
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    paddingTop: insets.top, // Respects status bar
    paddingBottom: insets.bottom, // Respects home indicator
  }}
/>;
```

---

## Demo App Features

This demo includes:

- ✅ Environment-based configuration
- ✅ Full-screen overlay integration
- ✅ Safe area inset handling
- ✅ Event listener examples
- ✅ Imperative API demos (all methods)
- ✅ Interactive test buttons
- ✅ Unread count badge
- ✅ Chat status indicator

---

## Quirks & Differences from Production

### 1. Environment Variables

This demo uses Expo environment variables for easy configuration. **In production:** it's likely you can hardcode many of these values, or grab them from your own data store.

### 2. Test/Debug Features

This demo enables debug features:

```tsx
enableLogging: true,  // Verbose console logs
debugMode: true,      // Shows debug overlay
```

**In production:** Set both to `false`.

### 3. SDK Installation Path

The demo installs from parent directory:

```json
"@pylon/react-native-chat": "file:.."
```

**In your app:** Install from your local copy or git repository.

### 4. Test User Hardcoding

The demo hardcodes a test user from `.env`. **In production:**

- Use your authenticated user's actual email/name
- Set user dynamically based on login state
- Conditionally render the widget (only when logged in)

### 5. Rebuild Scripts

This demo includes helper scripts for development:

```json
{
  "scripts": {
    "rebuild:android": "...", // Cleans and rebuilds Android
    "rebuild:ios": "..." // Cleans and rebuilds iOS
  }
}
```

These are **for demo development only**. Your app uses standard build commands.

---

## Project Structure

```
demo-app/
├── App.tsx                 # Main app with SDK integration
├── app.json               # Expo configuration
├── package.json           # Dependencies
├── .env                   # Your config (gitignored)
├── env.example            # Config template
├── android/               # Generated by expo prebuild
├── ios/                   # Generated by expo prebuild
└── assets/                # App icons and splash
```

---

## Troubleshooting

### "Invariant Violation: View config not found"

The native module wasn't compiled. Run:

```bash
npm run rebuild
npm start
# Then press 'i' for iOS or 'a' for Android
```

### Java Version Errors on Android

```bash
# Install Java 17
brew install openjdk@17

# Verify installation
/usr/libexec/java_home -v 17

# Rebuild with correct Java version
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
npm run rebuild
```

### CocoaPods Encoding Error (iOS)

```bash
export LANG=en_US.UTF-8
cd ios && pod install && cd ..
```

### Changes Not Appearing

- **Code changes**: Reload app (shake device → Reload, or press 'r' in Metro)
- **Native changes**: Run `npm run rebuild` then restart
- **Config changes**: Restart Metro (`npm start` then reload)

### Widget Not Loading

1. Check your `.env` file has correct `EXPO_PUBLIC_PYLON_APP_ID`
2. Check you're logged in at usepylon.com and app ID is valid
3. Look for errors in console (`enableLogging: true`)
4. Verify network connectivity

---

## Development Workflow

### Making Code Changes

1. Edit `App.tsx` or other files
2. Save (Metro auto-reloads)
3. See changes immediately

### Testing Native SDK Updates

When the parent SDK is updated:

```bash
# Full rebuild (updates native code + rebuilds)
npm run rebuild
```

### Testing on Real Devices

```bash
# iOS (device must be registered with Apple Developer)
npx expo run:ios --device

# Android (device must be connected via USB with debugging enabled)
npx expo run:android --device
```

---

## Next Steps

To integrate Pylon into your own app, see the [SDK README](../README.md) for installation and API reference.

This demo app source code (`App.tsx`) provides a complete integration example you can reference or copy.
