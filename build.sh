#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

echo "Compiling default-browser…"
swiftc -O -o default-browser default-browser.swift

WORKFLOW="default-browser.alfredworkflow"
rm -f "$WORKFLOW"
zip -q "$WORKFLOW" info.plist default-browser
echo "Built $WORKFLOW — double-click to install in Alfred."
