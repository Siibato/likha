#!/bin/bash -e

STAGE_DIR="$(dirname "$0")"
FILES_DIR="${STAGE_DIR}/files"

require_dir() {
  if [ ! -d "$1" ]; then
    echo "[stage-likha] Missing directory: $1" >&2
    exit 1
  fi
}

copy_tree() {
  local src="$1"
  local dest="$2"
  if [ -d "$src" ]; then
    install -m 755 -d "$dest"
    rsync -a "$src/" "$dest/"
  fi
}

require_dir "$FILES_DIR"

copy_tree "${FILES_DIR}/opt/likha" "${ROOTFS_DIR}/opt/likha"
copy_tree "${FILES_DIR}/systemd" "${ROOTFS_DIR}/etc/systemd/system"

find "${ROOTFS_DIR}/opt/likha/scripts" -type f -name '*.sh' -exec chmod 755 {} + || true

IMAGE_TAR="${STAGE_DIR}/likha-server-arm64.tar"
if [ -f "$IMAGE_TAR" ]; then
  install -m 755 -d "${ROOTFS_DIR}/opt/likha/images"
  install -m 644 "$IMAGE_TAR" "${ROOTFS_DIR}/opt/likha/images/likha-server-arm64.tar"
  on_chroot <<'EOF'
set -e
if [ -f /opt/likha/images/likha-server-arm64.tar ]; then
  docker load -i /opt/likha/images/likha-server-arm64.tar || true
fi
EOF
else
  echo "[stage-likha] WARNING: likha-server-arm64.tar not found; image will be pulled later" >&2
fi
