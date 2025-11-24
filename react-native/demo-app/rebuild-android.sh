#!/bin/bash

# Clean and rebuild Android project for React Native demo app

set -e

echo "🧹 Cleaning Android build artifacts..."
rm -rf android ios .expo

echo "📦 Copying native SDK files..."
cd .. && npm run copy-sdks && cd demo-app

echo "📦 Running expo prebuild..."
npx expo prebuild --clean

echo "☕ Checking Java version..."
# Check if Java 17 exists in the list of installed versions
if /usr/libexec/java_home -V 2>&1 | grep -q "17\."; then
    JAVA17_HOME=$(/usr/libexec/java_home -v 17 2>/dev/null)
    echo "✅ Found Java 17 at: $JAVA17_HOME"
    echo "   (npm run android will use this automatically)"
else
    echo "❌ Java 17 not found!"
    echo ""
    echo "React Native requires Java 17. You currently have:"
    /usr/libexec/java_home -V 2>&1 | head -3
    echo ""
    echo "To install Java 17:"
    echo "  brew install openjdk@17"
    echo ""
    echo "After installation, link it:"
    echo "  sudo ln -sfn /opt/homebrew/opt/openjdk@17/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-17.jdk"
    echo ""
    exit 1
fi

echo "✅ Android rebuild complete!"
echo ""
echo "Run 'npm run android' to build and launch the app"

