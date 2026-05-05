#!/bin/bash
set -e

APP_NAME="ArcVirt"
BUNDLE_ID="com.arcvirt.app"
VERSION="1.0"
MIN_MACOS="14.0"

echo "🔨 Building release binary..."
swift build -c release

echo "📦 Creating .app bundle..."
rm -rf "${APP_NAME}.app"
mkdir -p "${APP_NAME}.app/Contents/MacOS"
mkdir -p "${APP_NAME}.app/Contents/Resources"

# Copy the compiled binary
cp ".build/release/${APP_NAME}" "${APP_NAME}.app/Contents/MacOS/"

# Write Info.plist
cat > "${APP_NAME}.app/Contents/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>ArcVirt</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>${MIN_MACOS}</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticTermination</key>
    <true/>
    <key>NSRequiresAquaSystemAppearance</key>
    <false/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

echo "✍️  Code signing (ad-hoc)..."
codesign --force --deep --sign - "${APP_NAME}.app"

# Clear quarantine so macOS doesn't block it on first launch
xattr -d com.apple.quarantine "${APP_NAME}.app" 2>/dev/null || true

echo ""
echo "✅ Done! ArcVirt.app is ready at:"
echo "   $(pwd)/${APP_NAME}.app"
echo ""
echo "To install: drag ArcVirt.app to your /Applications folder"
echo "To open now: open '$(pwd)/${APP_NAME}.app'"
