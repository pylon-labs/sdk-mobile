#!/bin/bash
# Unified rebuild script for React Native demo app
# Rebuilds BOTH iOS and Android native projects

set -e

echo "🧹 Cleaning all build artifacts..."
rm -rf android ios .expo node_modules/.cache

echo "📦 Copying latest native SDK files from parent directories..."
cd .. && npm run copy-sdks && cd demo-app

echo "📦 Installing dependencies..."
npm install

echo "🔨 Running Expo prebuild (generates iOS + Android native projects)..."
expo prebuild --clean

echo ""
echo "☕ Verifying Java 17 (required for Android)..."
if /usr/libexec/java_home -V 2>&1 | grep -q "17\."; then
    JAVA17_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null)
    echo "   ✅ Java 17 found: $JAVA17_HOME"
else
    echo "   ⚠️  Java 17 not found"
    echo "   Install with: brew install openjdk@17"
    echo "   Android builds will fail without Java 17"
fi

echo ""
echo "🍎 Verifying Xcode (required for iOS)..."
if command -v xcodebuild >/dev/null 2>&1; then
    XCODE_VERSION=$(xcodebuild -version | head -n 1)
    echo "   ✅ Xcode found: $XCODE_VERSION"
else
    echo "   ⚠️  Xcode not found"
    echo "   Install from Mac App Store"
    echo "   iOS builds will fail without Xcode"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Rebuild complete! Both iOS and Android are ready."
echo ""
echo "Next steps:"
echo "  1. npm run start           Start Expo dev server"
echo "  2. Press 'i' for iOS       Run in iOS simulator"
echo "     Press 'a' for Android   Run in Android emulator"
echo "     Press 'w' for web       Run in browser"
echo " Note that npm run ios is different than npm start -> ios"
echo " the distinction is important for compiling native code"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
