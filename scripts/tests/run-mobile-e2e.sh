#!/usr/bin/env bash
# Mobile E2E Test Runner
#
# Starts the seeded test server, waits for it to be healthy, runs Flutter
# integration tests, then shuts the server down.
#
# Usage:
#   ./run-mobile-e2e.sh [test-path]
#
# Arguments:
#   test-path   Flutter test file or directory (default: integration_test/mobile/auth_e2e_test.dart)
#
# Environment variables inherited from the Makefile:
#   DATABASE_URL  - overrides the test database URL
#   TEST_DEVICE_HOST - device host for Flutter test URL
# Server reads all other config (PORT, JWT_SECRET, etc.) from server/.env.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SERVER_DIR="$PROJECT_ROOT/server"
MOBILE_DIR="$PROJECT_ROOT/mobile"

TEST_DEVICE_HOST="${TEST_DEVICE_HOST:-10.0.2.2}"
TEST_DB_URL="${TEST_DB_URL:-sqlite://./data/lms_e2e_test.db?mode=rwc}"

# Resolve test path argument; default to auth e2e test
TEST_PATH="${1:-integration_test/mobile/auth_e2e_test.dart}"

SERVER_PID=""

cleanup() {
  if [ -n "$SERVER_PID" ]; then
    kill "$SERVER_PID" 2>/dev/null || true
    wait "$SERVER_PID" 2>/dev/null || true
  fi
}
trap cleanup EXIT

# Read port from server/.env so health check matches the server
SERVER_PORT=$(grep '^PORT=' "$SERVER_DIR/.env" | cut -d= -f2 | tr -d ' ') || true
SERVER_PORT="${SERVER_PORT:-8080}"

cd "$SERVER_DIR"
DATABASE_URL="$TEST_DB_URL" ./target/release/server &
SERVER_PID=$!

for i in {1..30}; do
  if curl -sf "http://localhost:${SERVER_PORT}/api/v1/health" >/dev/null 2>&1; then
    break
  fi
  if [ "$i" -eq 30 ]; then
    echo "Server failed to start within 30s" >&2
    exit 1
  fi
  sleep 1
done

cd "$MOBILE_DIR"

DEVICE_COUNT=$(flutter devices --machine 2>/dev/null | grep '"id"' | wc -l | tr -d ' ')
if [ "$DEVICE_COUNT" -eq 0 ]; then
  echo "No connected device or emulator found." >&2
  echo "Connect a physical device (with USB debugging enabled) or start an emulator, then retry." >&2
  echo "Run 'flutter devices' to see available devices." >&2
  exit 1
fi

echo "Running E2E test: $TEST_PATH"
flutter test "$TEST_PATH" \
  --dart-define=TEST_SERVER_URL="http://${TEST_DEVICE_HOST}:${SERVER_PORT}"

echo "All tests passed."
