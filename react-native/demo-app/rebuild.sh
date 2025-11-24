#!/bin/bash
set -e

echo "🧹 Cleaning..."
cd ios
rm -rf Pods Podfile.lock

echo "📦 Installing pods..."
export LANG=en_US.UTF-8
pod install

echo "✅ Done! Now run: npm run ios"

