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

SCHOOL_CONFIG="${BUNDLE_DIR}/school-config.txt"
if grep -q '^MESH_GROUP_ID=$' "$SCHOOL_CONFIG" 2>/dev/null; then
  osascript -e 'display alert "School config missing" message "Please fill in MESH_GROUP_ID in school-config.txt before flashing."' >&2
  open "$SCHOOL_CONFIG"
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

# ---- Post-flash: copy school config to boot partition ----
BUTTON=$(osascript -e 'display dialog "Pi Imager is now open. Flash your SD card. When it shows Done, click OK here to copy your school configuration to the card." buttons {"Skip", "OK"} default button "OK"' 2>/dev/null || echo "button returned:Skip")
if [[ "$BUTTON" == *"OK"* ]]; then
  # Try to find the boot partition (volume with config.txt that isn't the system drive)
  BOOT_VOL=""
  for vol in /Volumes/*; do
    if [[ -f "$vol/config.txt" && "$vol" != "/Volumes/Macintosh HD" ]]; then
      BOOT_VOL="$vol"
      break
    fi
  done

  if [[ -n "$BOOT_VOL" ]]; then
    cp "$SCHOOL_CONFIG" "$BOOT_VOL/likha-config.txt"
    osascript -e "display notification \"School config copied to SD card\" with title \"Likha Classroom Server\""
  else
    osascript -e 'display alert "Boot partition not found" message "Please re-insert the SD card, then copy school-config.txt to the boot partition and rename it to likha-config.txt."' >&2
  fi
fi
