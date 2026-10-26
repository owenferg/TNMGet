#!/bin/sh
# Builds oGet.zip and a drag-to-Applications oGet.dmg from oGet.app.
set -e
cd "$(dirname "$0")"
rm -rf build/dmg oGet.zip oGet.dmg
ditto -c -k --keepParent oGet.app oGet.zip
mkdir -p build/dmg
cp -R oGet.app build/dmg/
ln -s /Applications build/dmg/Applications
hdiutil create -quiet -volname oGet -srcfolder build/dmg -fs HFS+ -format UDZO oGet.dmg
