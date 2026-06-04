# Likha Project Command Center
#
# Orchestrates development, building, testing, and database operations for the
# Rust server and Flutter mobile/web/desktop application.

SERVER_DIR := server
MOBILE_DIR := mobile

TEST_PORT        ?= 18080
TEST_DEVICE_HOST ?= 10.0.2.2
TEST_DB          := $(SERVER_DIR)/data/lms_e2e_test.db

export DATABASE_URL        := sqlite://$(TEST_DB)?mode=rwc
export HOST                := 0.0.0.0
export PORT                := $(TEST_PORT)
export JWT_SECRET          := dev-secret-key-please-change-min-32-chars-for-production-use
export DB_ENCRYPTION_KEY   := change-me-to-a-strong-random-key-min-32-chars
export FILE_ENCRYPTION_KEY := 0000000000000000000000000000000000000000000000000000000000000000
export SCHOOL_CODE         := E2ETST
export ALLOWED_ORIGINS     :=
export MAX_BODY_SIZE_MB    := 55
export RUST_LOG            := info

.SHELLFLAGS := -euo pipefail -c

.PHONY: help setup dev dev-server dev-mobile dev-web dev-desktop db-reset db-seed db-delete build build-apk build-macos build-windows test-server test-mobile test-e2e-mobile test-e2e-desktop format lint docker-up docker-down clean

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

setup:
	@if [ ! -f .env ]; then cp .env.example .env; fi
	@awk '/# --- SERVER ---/{p=1;next} p{print > "$(SERVER_DIR)/.env"} !p{print > "$(MOBILE_DIR)/.env"}' .env
	@cd $(MOBILE_DIR) && flutter pub get
	@mkdir -p $(SERVER_DIR)/data $(SERVER_DIR)/storage/materials $(SERVER_DIR)/storage/submissions $(SERVER_DIR)/storage/exports

dev:
	@cd $(SERVER_DIR) && cargo run &
	@trap "pkill -f 'cargo run' || true" EXIT
	@cd $(MOBILE_DIR) && flutter run

dev-server:
	@cd $(SERVER_DIR) && cargo run

dev-mobile:
	@cd $(MOBILE_DIR) && flutter run

dev-web:
	@cd $(MOBILE_DIR) && flutter run -d chrome

dev-desktop:
	@if [ "$(shell uname)" = "Darwin" ]; then cd $(MOBILE_DIR) && flutter run -d macos; else cd $(MOBILE_DIR) && flutter run -d windows; fi

db-reset:
	@cd $(SERVER_DIR) && cargo run -- reset-db

db-seed:
	@cd $(SERVER_DIR) && cargo run -- reset-db && cargo run -- seed-e2e

db-delete:
	@cd $(SERVER_DIR) && cargo run -- delete-db

build:
	@cd $(SERVER_DIR) && cargo build --release

build-apk:
	@cd $(MOBILE_DIR) && flutter build apk --release

build-macos:
	@cd $(MOBILE_DIR) && flutter build macos

build-windows:
	@cd $(MOBILE_DIR) && flutter build windows

test-server:
	@cd $(SERVER_DIR) && cargo test

test-mobile:
	@cd $(MOBILE_DIR) && flutter test

test-e2e-mobile: build db-seed
	@./scripts/run-mobile-e2e.sh

test-e2e-desktop:
	@echo "E2E desktop tests not yet implemented — run 'make test-e2e-mobile' instead"

format:
	@cd $(SERVER_DIR) && cargo fmt
	@cd $(MOBILE_DIR) && dart format .

lint:
	@cd $(SERVER_DIR) && cargo clippy
	@cd $(MOBILE_DIR) && flutter analyze

docker-up:
	@docker-compose up -d

docker-down:
	@docker-compose down

clean:
	@rm -rf $(SERVER_DIR)/target $(MOBILE_DIR)/build $(SERVER_DIR)/data/*.db
