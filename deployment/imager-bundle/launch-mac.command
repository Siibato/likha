#!/bin/bash
# Likha Classroom Server — Pi Imager Launcher (macOS)
# This script launches Raspberry Pi Imager pre-loaded with the Likha OS manifest.

set -e

BUNDLE_DIR="$(cd "$(dirname "$0")" && pwd)"
IMAGE_NAME="likha-server.img.xz"
MANIFEST="${BUNDLE_DIR}/os_list.json"
TEMPLATE="${BUNDLE_DIR}/os_list_template.json"
IMAGE_PATH="${BUNDLE_DIR}/${IMAGE_NAME}"

# ---- Sanity checks ----
if [[ ! -f "$IMAGE_PATH" ]]; then
  osascript -e 'display alert "Missing image file" message "likha-server.img.xz was not found in this folder."' >&2
  exit 1
fi

# Find Raspberry Pi Imager
IMAGER_APP="/Applications/Raspberry Pi Imager.app"
if [[ ! -d "$IMAGER_APP" ]]; then
  osascript -e 'display alert "Raspberry Pi Imager not found" message "Please download and install Raspberry Pi Imager from https://www.raspberrypi.com/software/"' >&2
  open "https://www.raspberrypi.com/software/"
  exit 1
fi

# ---- Prepare manifest ----
# Copy template and replace placeholder with absolute path
cp "$TEMPLATE" "$MANIFEST"
sed -i '' "s|BUNDLE_DIR_PLACEHOLDER|${BUNDLE_DIR}|g" "$MANIFEST"

# ---- Launch ----
open -a "Raspberry Pi Imager" --args --repo "$MANIFEST"
