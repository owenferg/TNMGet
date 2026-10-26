#!/bin/sh
# Installs the latest TNMGet into /Applications.
set -e
tmp=$(mktemp -d)
curl -fsSL https://github.com/owenferg/TNMGet/releases/latest/download/TNMGet.zip -o "$tmp/TNMGet.zip"
rm -rf /Applications/TNMGet.app
ditto -x -k "$tmp/TNMGet.zip" /Applications
rm -rf "$tmp"
open /Applications/TNMGet.app
