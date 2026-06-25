#!/bin/bash
set -e

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Kullanım: ./release.sh 1.1"
    exit 1
fi

SDK=$(xcrun --sdk macosx --show-sdk-path)
APP="ClipboardHistory.app"
DMG="ClipboardHistory-$VERSION.dmg"

echo "🔨 v$VERSION build ediliyor..."

# Info.plist versiyonunu güncelle
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" ClipboardHistory/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $VERSION" ClipboardHistory/Info.plist

# Universal binary
SOURCES=(
    ClipboardHistory/ClipboardHistoryApp.swift
    ClipboardHistory/AppDelegate.swift
    ClipboardHistory/ClipItem.swift
    ClipboardHistory/HistoryStore.swift
    ClipboardHistory/ClipboardMonitor.swift
    ClipboardHistory/EventMonitor.swift
    ClipboardHistory/UpdateChecker.swift
    ClipboardHistory/Views/HistoryPanelView.swift
    ClipboardHistory/Views/ClipItemView.swift
)

swiftc -target arm64-apple-macos13.0 -sdk "$SDK" -O \
    -framework SwiftUI -framework AppKit -framework Carbon \
    -parse-as-library "${SOURCES[@]}" -o /tmp/ch_arm64

swiftc -target x86_64-apple-macos13.0 -sdk "$SDK" -O \
    -framework SwiftUI -framework AppKit -framework Carbon \
    -parse-as-library "${SOURCES[@]}" -o /tmp/ch_x86

lipo -create -output /tmp/ch_universal /tmp/ch_arm64 /tmp/ch_x86

# App bundle
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp /tmp/ch_universal "$APP/Contents/MacOS/ClipboardHistory"

sed "s/\$(EXECUTABLE_NAME)/ClipboardHistory/g; s/\$(PRODUCT_BUNDLE_IDENTIFIER)/com.clipboardhistory.app/g" \
    ClipboardHistory/Info.plist > /tmp/info_fixed.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleIconFile ClipboardHistory" /tmp/info_fixed.plist 2>/dev/null || \
/usr/libexec/PlistBuddy -c "Add :CFBundleIconFile string ClipboardHistory" /tmp/info_fixed.plist
cp /tmp/info_fixed.plist "$APP/Contents/Info.plist"

ICNS="/tmp/ClipboardHistory.icns"
if [ -f "$ICNS" ]; then
    cp "$ICNS" "$APP/Contents/Resources/ClipboardHistory.icns"
fi

xattr -cr "$APP"
codesign --sign - --force --deep "$APP" 2>/dev/null

# DMG
pkgbuild --component "$APP" --install-location /Applications \
    --identifier com.clipboardhistory.app --version "$VERSION" \
    /tmp/ClipboardHistory.pkg 2>/dev/null

rm -rf /tmp/dmg-stage && mkdir /tmp/dmg-stage
cp /tmp/ClipboardHistory.pkg /tmp/dmg-stage/
rm -f "$DMG"
hdiutil create -volname "ClipboardHistory" -srcfolder /tmp/dmg-stage \
    -ov -format UDZO "$DMG" 2>/dev/null

echo "✅ Build tamamlandı: $DMG"

# Git commit + tag
git add ClipboardHistory/Info.plist
git commit -m "v$VERSION"
git tag "v$VERSION"
git push origin main
git push origin "v$VERSION"

# GitHub Release
echo "🚀 GitHub Release oluşturuluyor..."
gh release create "v$VERSION" "$DMG" \
    --title "v$VERSION" \
    --notes "## v$VERSION

### Değişiklikler
- Güncelleme notlarını buraya yaz

**Kurulum:** DMG içindeki .pkg dosyasını çalıştırın."

echo ""
echo "✅ Bitti! Release: https://github.com/onurfikri/ClipboardHistory/releases/tag/v$VERSION"
