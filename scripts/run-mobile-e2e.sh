#!/usr/bin/env bash
# Mobile Auth E2E Test Runner
#
# Starts the seeded test server, waits for it to be healthy, runs Flutter
# integration tests, then shuts the server down. Called by `make test-e2e-mobile`.
# Environment variables (HOST, PORT, DATABASE_URL, JWT_SECRET, etc.) are
# inherited from the Makefile.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/server"
MOBILE_DIR="$PROJECT_ROOT/mobile"

TEST_PORT="${TEST_PORT:-18080}"
TEST_DEVICE_HOST="${TEST_DEVICE_HOST:-10.0.2.2}"

SERVER_PID=""

cleanup() {
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

cd "$SERVER_DIR"
./target/release/server &
SERVER_PID=$!

for i in {1..30}; do
  if curl -sf "http://localhost:${TEST_PORT}/api/v1/health" >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "Server failed to start within 30s" >&2
    exit 1
  fi
  sleep 1
done

cd "$MOBILE_DIR"
flutter test integration_test/auth_e2e_test.dart \
  --dart-define=TEST_SERVER_URL="http://${TEST_DEVICE_HOST}:${TEST_PORT}"

echo "All tests passed."
