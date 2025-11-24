# Pylon Chat SDK for React Native

React Native wrapper for the Pylon Chat iOS and Android SDKs.

## Installation

```bash
npm install @pylon/react-native-chat
# or
yarn add @pylon/react-native-chat
```

## Requirements

- React Native >= 0.70.0
- iOS >= 13.0
- Android minSdkVersion >= 24

**Note:** This package uses native modules. For Expo projects, you'll need to use a [development build](https://docs.expo.dev/develop/development-builds/introduction/).

## Setup

### Environment Configuration (Recommended)

For better configuration management, in the demo apps/your own application:

1. Copy the example environment file:

   ```bash
   cp env.example .env
   ```

2. Edit `.env` with your Pylon app ID and settings:

   ```bash
   EXPO_PUBLIC_PYLON_APP_ID=your-app-id-here
   EXPO_PUBLIC_PYLON_USER_EMAIL=demo@example.com
   EXPO_PUBLIC_PYLON_USER_NAME=Demo User
   ```

3. Use environment variables in your app:
   ```tsx
   const config = {
     appId: process.env.EXPO_PUBLIC_PYLON_APP_ID,
     widgetBaseUrl:
       process.env.EXPO_PUBLIC_PYLON_WIDGET_BASE_URL ||
       "https://widget.usepylon.com",
     enableLogging: process.env.EXPO_PUBLIC_PYLON_ENABLE_LOGGING === "true",
     debugMode: process.env.EXPO_PUBLIC_PYLON_DEBUG_MODE === "true",
   };
   ```

### iOS

The native module will automatically link via CocoaPods:

```bash
cd ios && pod install
```

### Android

The native module will automatically link. No additional steps required.

### Expo (Development Build Required)

Since this package includes native code, managed Expo projects need to create a development build:

```bash
expo install expo-dev-client
expo prebuild
expo run:ios  # or expo run:android
```

## Usage

```tsx
import { PylonChatView, type PylonChatViewRef } from "@pylon/react-native-chat";
import { useRef } from "react";
import { StyleSheet, View } from "react-native";

export default function App() {
  const pylonRef = useRef<PylonChatViewRef>(null);

  const config = {
    appId: "YOUR_APP_ID",
    widgetBaseUrl: "https://widget.usepylon.com",
    enableLogging: true,
    debugMode: false,
  };

  const user = {
    email: "user@example.com",
    name: "User Name",
  };

  const listener = {
    onChatOpened: () => console.log("Chat opened"),
    onChatClosed: (wasOpen) => console.log("Chat closed"),
    onUnreadCountChanged: (count) => console.log("Unread:", count),
  };

  return (
    <View style={styles.container}>
      {/* Your app content */}

      {/* Pylon Chat Widget - renders as overlay */}
      <PylonChatView
        ref={pylonRef}
        config={config}
        user={user}
        listener={listener}
        style={styles.chat}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  chat: {
    position: "absolute",
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
  },
});
```

## Imperative API

```tsx
// Control chat programmatically
pylonRef.current?.openChat();
pylonRef.current?.closeChat();
pylonRef.current?.showChatBubble();
pylonRef.current?.hideChatBubble();
pylonRef.current?.showNewMessage("<p>Hello!</p>", true);
pylonRef.current?.setNewIssueCustomFields({ priority: "high" });
```

## Configuration

### PylonConfig

| Property        | Type    | Required | Description                                        |
| --------------- | ------- | -------- | -------------------------------------------------- |
| `appId`         | string  | Yes      | Your Pylon app ID                                  |
| `widgetBaseUrl` | string  | No       | Base URL for widget (default: widget.usepylon.com) |
| `enableLogging` | boolean | No       | Enable debug logs (default: false)                 |
| `debugMode`     | boolean | No       | Enable debug overlay (default: false)              |
| `primaryColor`  | string  | No       | Primary color for widget                           |

### PylonUser

| Property            | Type   | Required | Description                                     |
| ------------------- | ------ | -------- | ----------------------------------------------- |
| `email`             | string | Yes      | User's email                                    |
| `name`              | string | Yes      | User's name                                     |
| `avatarUrl`         | string | No       | User's avatar URL                               |
| `emailHash`         | string | No       | SHA-256 hash of email for identity verification |
| `accountId`         | string | No       | Account ID                                      |
| `accountExternalId` | string | No       | External account ID                             |

## Events

| Event                  | Parameters         | Description                  |
| ---------------------- | ------------------ | ---------------------------- |
| `onPylonLoaded`        | -                  | Widget loaded                |
| `onPylonReady`         | -                  | Widget ready                 |
| `onChatOpened`         | -                  | Chat window opened           |
| `onChatClosed`         | `wasOpen: boolean` | Chat window closed           |
| `onUnreadCountChanged` | `count: number`    | Unread message count changed |
| `onMessageReceived`    | `message: string`  | New message received         |
| `onPylonError`         | `error: string`    | Error occurred               |

## Architecture

### How It Works

This package wraps the native iOS and Android Pylon Chat SDKs using React Native's native module system, providing a unified API across platforms while leveraging native performance and capabilities.

```
┌─────────────────────────────────────────────────────────────┐
│ React Native App (JavaScript/TypeScript)                    │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ <PylonChatWidget />                                     │ │
│ │ - Props: config, user, listener                         │ │
│ │ - Ref: imperative methods (openChat, closeChat, etc.)  │ │
│ └───────────────────────┬─────────────────────────────────┘ │
│                         │ Native Bridge                     │
│ ┌───────────────────────▼─────────────────────────────────┐ │
│ │ Platform-Specific Native Module                         │ │
│ │ iOS: RNPylonChatView.swift                             │ │
│ │ Android: RNPylonChatView.kt                            │ │
│ │ - Wraps native PylonChatView                           │ │
│ │ - Handles props → native config conversion             │ │
│ │ - Forwards events to JS via RCTEventEmitter            │ │
│ └───────────────────────┬─────────────────────────────────┘ │
│                         │                                   │
│ ┌───────────────────────▼─────────────────────────────────┐ │
│ │ Native SDK (PylonChatView)                              │ │
│ │ iOS: PylonChat.swift                                    │ │
│ │ Android: PylonChat.kt                                   │ │
│ │ ┌─────────────────────────────────────────────────────┐ │ │
│ │ │ WebView (Pylon Chat Widget)                         │ │ │
│ │ │ - Loads widget from widget.usepylon.com             │ │ │
│ │ │ - JavaScript ↔ Native bridge                        │ │ │
│ │ │ - Touch event handling                              │ │ │
│ │ │ - Real-time messaging (Pusher)                      │ │ │
│ │ └─────────────────────────────────────────────────────┘ │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Build Process

The React Native package is structured as a native module with TypeScript bindings:

**1. TypeScript Compilation (`npm run build`)**

```bash
tsc  # Compiles src/*.ts → lib/*.js + type definitions
```

**2. Native SDK Sync (`npm run copy-sdks`)**

```bash
scripts/copy-native-sdks.sh
# Copies latest native SDK code from parent directories:
# - ios/PylonChat/ → react-native/ios/PylonChat/
# - android/pylon/src/ → react-native/android/src/
```

**3. Package Preparation (`npm run prepare`)**

- Runs automatically before `npm publish`
- Ensures TypeScript is compiled and native SDKs are synced
- Called by: `npm install`, `npm pack`, `npm publish`

### Expo Prebuild

For Expo projects, the native code needs to be generated before building:

```bash
expo prebuild
```

This command:

1. Reads your `app.json` and dependencies
2. Generates `ios/` and `android/` directories
3. Configures native projects with required modules
4. Links our native module automatically via autolinking

**After prebuild**, you have a standard React Native project that can be built with:

- `expo run:ios` or `npx react-native run-ios`
- `expo run:android` or `npx react-native run-android`

## Troubleshooting

### Android: Java Version Issues

**Error:** `Unsupported class file major version 69` or Java 25 incompatibility

**Solution:** The Android build requires Java 17. Install it via Homebrew:

```bash
brew install openjdk@17
```

The demo app's `npm run android` script automatically uses Java 17, but for custom projects, you may need to set `JAVA_HOME`:

```bash
export JAVA_HOME=$(/usr/libexec/java_home -v 17)
```

To verify Java 17 is installed:

```bash
/usr/libexec/java_home -v 17
```

### iOS: CocoaPods Encoding Issues

**Error:** `Unicode Normalization not appropriate for ASCII-8BIT`

**Solution:** Set UTF-8 encoding before running pod install:

```bash
export LANG=en_US.UTF-8
cd ios && pod install
```

You can add this to your `~/.zshrc` or `~/.bash_profile` to make it permanent.

### Module Not Found / Invariant Violation

**Error:** `Invariant Violation: View config not found for component RNPylonChatView`

**Solution:** This means the native module wasn't compiled or linked. For Expo projects:

```bash
# Clean and rebuild
rm -rf ios android .expo
npx expo prebuild --clean
npx expo run:ios  # or expo run:android
```

For bare React Native:

```bash
# iOS
cd ios && pod install && cd ..
npx react-native run-ios

# Android
npx react-native run-android
```

### Expo: Development Build Required

**Error:** `No development build installed`

**Solution:** This package uses native modules and cannot run in Expo Go. You must create a development build:

```bash
npx expo install expo-dev-client
npx expo prebuild
npx expo run:ios  # or expo run:android
```

### Android Build Cache Issues

If you encounter persistent Android build errors, clean the build cache:

```bash
cd android
./gradlew clean
cd ..
rm -rf android/.gradle android/app/build
npx expo run:android
```

### iOS Build Cache Issues

If you encounter persistent iOS build errors:

```bash
cd ios
rm -rf Pods Podfile.lock
pod cache clean --all
pod install
cd ..
npx expo run:ios
```

### Touch Events Not Working

If touches aren't passing through to views behind the chat bubble when it's collapsed:

1. Make sure you're using `position: "absolute"` and covering the full screen
2. The native SDK handles touch pass-through automatically
3. Ensure you're not wrapping `PylonChatView` in additional `View` components that intercept touches

Example correct layout:

```tsx
<View style={{ flex: 1 }}>
  <ScrollView>{/* Your content */}</ScrollView>

  <PylonChatView
    style={{
      position: "absolute",
      top: 0,
      left: 0,
      right: 0,
      bottom: 0,
    }}
    // ... props
  />
</View>
```

## Demo App

The `demo-app/` directory contains a complete Expo application demonstrating SDK integration and all available features.

### Quick Start

```bash
cd demo-app
npm install

# Configure your app ID
cp env.example .env
# Edit .env with your Pylon app ID

# First time setup or after native changes
npm run rebuild:android  # Clean rebuild for Android
# or
expo prebuild --clean     # For iOS/Android

# Run the app
npm run ios      # or npm run android
```

### Demo App Architecture

The demo app showcases:

1. **Environment Configuration**: Loads config from `.env` using `process.env.EXPO_PUBLIC_*`
2. **Widget Integration**: Full-screen overlay pattern with touch pass-through
3. **Imperative API**: All SDK methods exposed via ref
4. **Event Handling**: Real-time updates (message counts, open/close events)
5. **Interactive Testing**: Buttons to test all SDK features

```tsx
// demo-app/App.tsx (simplified)
export default function App() {
  const pylonRef = useRef<PylonChatViewRef>(null);
  const insets = useSafeAreaInsets();

  return (
    <View style={{ flex: 1 }}>
      <ScrollView>{/* Your app UI */}</ScrollView>

      {/* Pylon widget as full-screen overlay */}
      <PylonChatWidget
        ref={pylonRef}
        config={config}
        user={user}
        listener={eventHandlers}
        topInset={-insets.top} // Adjust for safe area
      />
    </View>
  );
}
```

### Build Scripts

The demo app includes helper scripts in `package.json`:

**`npm run rebuild:android`**

- Cleans all Android build artifacts
- Copies latest native SDK files
- Runs `expo prebuild --clean`
- Verifies Java 17 installation
- Use after: changing native code, updating dependencies

**`npm run android`**

- Sets `JAVA_HOME` to Java 17 automatically
- Builds and launches on Android emulator/device
- Faster than full rebuild for code-only changes

**`npm run ios`**

- Builds and launches on iOS simulator
- No special Java requirements

**`npm run start`**

- Starts Metro bundler
- Shows QR code for development builds
- Use with: Expo Go (limited) or development builds

### Environment Variables

The demo app uses environment variables for configuration:

```bash
# .env file (gitignored)
EXPO_PUBLIC_PYLON_APP_ID=your-app-id
EXPO_PUBLIC_PYLON_WIDGET_BASE_URL=https://widget.usepylon.com
EXPO_PUBLIC_PYLON_USER_EMAIL=user@example.com
EXPO_PUBLIC_PYLON_USER_NAME=User Name
EXPO_PUBLIC_PYLON_ENABLE_LOGGING=true
EXPO_PUBLIC_PYLON_DEBUG_MODE=true
```

**Why `EXPO_PUBLIC_`?**
Expo requires this prefix for environment variables to be accessible in your app code at build time. Without it, `process.env` values will be `undefined`.

### Testing the Demo

1. **Start the app**: The widget should load with a chat bubble
2. **Test touch pass-through**: Tap outside the bubble - underlying UI should respond
3. **Open chat**: Tap the bubble - chat window opens
4. **Send messages**: Type and send test messages
5. **Test API**: Use the control buttons to test imperative methods

The demo app is set up to work with production (`widget.usepylon.com`) by default. For local development, see the parent `chatwidget-mobile-sdk/README.md` for taskrunner commands.
