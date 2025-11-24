#!/bin/bash
# Copies the native iOS and Android SDK files into the React Native package

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RN_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "📦 Copying native SDK files..."

# Copy iOS SDK
echo "  → Copying iOS SDK..."
mkdir -p "$RN_DIR/ios/PylonChat"
cp -f "$RN_DIR/../ios/PylonChat/PylonChat.swift" "$RN_DIR/ios/PylonChat/"

# Copy Android SDK
echo "  → Copying Android SDK..."
ANDROID_SDK_DIR="$RN_DIR/../android/pylon/src/main/java/com/pylon/chatwidget"
mkdir -p "$RN_DIR/android/src/main/java/com/pylon/chatwidget"
cp -f "$ANDROID_SDK_DIR"/*.kt "$RN_DIR/android/src/main/java/com/pylon/chatwidget/"

echo "✅ Native SDK files copied successfully"

