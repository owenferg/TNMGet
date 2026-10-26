#!/bin/sh
# Builds TNMGet.zip and a drag-to-Applications TNMGet.dmg from TNMGet.app.
set -e
cd "$(dirname "$0")"
rm -rf build/dmg TNMGet.zip TNMGet.dmg
ditto -c -k --keepParent TNMGet.app TNMGet.zip
mkdir -p build/dmg
cp -R TNMGet.app build/dmg/
ln -s /Applications build/dmg/Applications
hdiutil create -quiet -volname TNMGet -srcfolder build/dmg -fs HFS+ -format UDZO TNMGet.dmg
