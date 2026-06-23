#!/usr/bin/env bash
# Prints a block of secure random values for Likha server deployments.
# Usage:
#   ./generate-secrets.sh > server/.env
#   eval "$(./generate-secrets.sh)"

set -euo pipefail

require() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required dependency: $1" >&2
    exit 1
  }
}

rand_hex() {
  local bytes="$1"
  openssl rand -hex "$bytes"
}

rand_base64() {
  local bytes="$1"
  openssl rand -base64 "$bytes" | tr -d '\n'
}

require openssl

gen_uuid() {
  if command -v uuidgen >/dev/null 2>&1; then
    uuidgen
  else
    # Fallback: generate a v4-like UUID from /dev/urandom
    local hex
    hex=$(openssl rand -hex 16)
    printf '%s-%s-4%s-%s%s-%s\n' \
      "${hex:0:8}" "${hex:8:4}" "${hex:13:3}" \
      "$((0x${hex:16:1} & 0x3 | 0x8))" "${hex:17:1}" "${hex:18:12}"
  fi
}

cat <<EOF
JWT_SECRET=$(rand_base64 48)
DB_ENCRYPTION_KEY=$(rand_base64 48)
FILE_ENCRYPTION_KEY=$(rand_hex 32)
REPLICATION_SECRET=$(rand_hex 32)
NODE_ID=$(gen_uuid)
EOF
