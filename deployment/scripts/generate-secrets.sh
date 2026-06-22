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
require uuidgen

cat <<EOF
JWT_SECRET=$(rand_base64 48)
DB_ENCRYPTION_KEY=$(rand_base64 48)
FILE_ENCRYPTION_KEY=$(rand_hex 32)
REPLICATION_SECRET=$(rand_hex 32)
NODE_ID=$(uuidgen)
EOF
