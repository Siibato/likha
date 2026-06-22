#!/usr/bin/env bash
# Syncs canonical deployment assets into the pi-gen stage directory.
# Run this before invoking pi-gen so stage-likha/files mirrors the latest compose,
# scripts, and systemd units.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
STAGE_FILES="${SCRIPT_DIR}/stage-likha/files"

rsync_tree() {
  local src="$1"
  local dest="$2"
  if [ ! -d "$src" ]; then
    echo "Source directory missing: $src" >&2
    exit 1
  fi
  mkdir -p "$dest"
  rsync -a --delete "$src/" "$dest/"
}

rsync_tree "${DEPLOY_DIR}/compose" "${STAGE_FILES}/opt/likha/compose"
rsync_tree "${DEPLOY_DIR}/scripts" "${STAGE_FILES}/opt/likha/scripts"
rsync_tree "${DEPLOY_DIR}/systemd" "${STAGE_FILES}/systemd"

# Ensure scripts remain executable after rsync.
find "${STAGE_FILES}/opt/likha/scripts" -type f -name '*.sh' -exec chmod 755 {} +

echo "Stage assets synced to ${STAGE_FILES}"
