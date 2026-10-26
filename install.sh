#!/bin/sh
# Installs the latest oGet into /Applications.
set -e
tmp=$(mktemp -d)
curl -fsSL https://github.com/owenferg/oGet/releases/latest/download/oGet.zip -o "$tmp/oGet.zip"
rm -rf /Applications/oGet.app
ditto -x -k "$tmp/oGet.zip" /Applications
rm -rf "$tmp"
open /Applications/oGet.app
