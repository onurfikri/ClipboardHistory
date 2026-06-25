#!/bin/bash
set -e

SDK=$(xcrun --sdk macosx --show-sdk-path)
APP="ClipboardHistory.app"

echo "🔨 Building ClipboardHistory..."

# Create bundle structure
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

# Resolve Info.plist variables
sed 's/\$(EXECUTABLE_NAME)/ClipboardHistory/g; s/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.clipboardhistory.app/g' \
    ClipboardHistory/Info.plist > "$APP/Contents/Info.plist"

# Compile
swiftc \
    -target arm64-apple-macos13.0 \
    -sdk "$SDK" \
    -O \
    -framework SwiftUI \
    -framework AppKit \
    -framework Carbon \
    -parse-as-library \
    ClipboardHistory/ClipboardHistoryApp.swift \
    ClipboardHistory/AppDelegate.swift \
    ClipboardHistory/ClipItem.swift \
    ClipboardHistory/HistoryStore.swift \
    ClipboardHistory/ClipboardMonitor.swift \
    ClipboardHistory/EventMonitor.swift \
    ClipboardHistory/Views/HistoryPanelView.swift \
    ClipboardHistory/Views/ClipItemView.swift \
    -o "$APP/Contents/MacOS/ClipboardHistory"

# Sign
xattr -cr "$APP"
codesign --sign - --force --deep "$APP"

echo "✅ Build complete: $APP"
echo ""
echo "To run: open $APP"
echo "Note: Grant Accessibility permission for auto-paste to work:"
echo "  System Settings → Privacy & Security → Accessibility"
