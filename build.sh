#!/bin/sh
set -e
cd "$(dirname "$0")"
APP=TNMGet.app
rm -rf "$APP" build
mkdir build
mkdir -p "$APP/Contents/MacOS"
for arch in arm64 x86_64; do
  swiftc -O -swift-version 5 -parse-as-library -target $arch-apple-macos14 Sources/main.swift -o "build/TNMGet-$arch"
done
lipo -create build/TNMGet-arm64 build/TNMGet-x86_64 -output "$APP/Contents/MacOS/TNMGet"
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>TNMGet</string>
  <key>CFBundleIdentifier</key><string>com.owenferg.tnmget</string>
  <key>CFBundleExecutable</key><string>TNMGet</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>${VERSION:-1.0}</string>
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>CFBundleDocumentTypes</key>
  <array><dict>
    <key>CFBundleTypeRole</key><string>Viewer</string>
    <key>LSItemContentTypes</key><array><string>public.plain-text</string></array>
  </dict></array>
</dict>
</plist>
PLIST
codesign --force -s - "$APP"
echo "built $APP"
