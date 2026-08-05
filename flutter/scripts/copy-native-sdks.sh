#!/bin/bash
# Copies the native iOS and Android SDK sources into the Flutter plugin package.
#
# The Flutter plugin vendors the native SDKs rather than depending on them, so the
# package is self-contained when consumed from a path or git dependency. Re-run this
# after changing anything under ../ios/PylonChat or ../android/pylon.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FLUTTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📦 Copying native SDK files..."

# Copy iOS SDK
echo "  → Copying iOS SDK..."
mkdir -p "$FLUTTER_DIR/ios/Classes/PylonChat"
cp -f "$FLUTTER_DIR/../ios/PylonChat/PylonChat.swift" "$FLUTTER_DIR/ios/Classes/PylonChat/"

# Copy Android SDK
echo "  → Copying Android SDK..."
ANDROID_SDK_DIR="$FLUTTER_DIR/../android/pylon/src/main/java/com/pylon/chatwidget"
mkdir -p "$FLUTTER_DIR/android/src/main/kotlin/com/pylon/chatwidget"
cp -f "$ANDROID_SDK_DIR"/*.kt "$FLUTTER_DIR/android/src/main/kotlin/com/pylon/chatwidget/"

echo "✅ Native SDK files copied successfully"
