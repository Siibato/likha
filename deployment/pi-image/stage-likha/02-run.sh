#!/bin/bash -e

on_chroot <<'EOF'
set -e
systemctl enable docker || true
systemctl enable likha-first-boot.service || true
systemctl enable likha-server.service || true
if command -v docker >/dev/null 2>&1; then
  docker pull redis:7-alpine || true
fi
EOF
