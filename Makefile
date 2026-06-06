# Likha Project Command Center
#
# Orchestrates development, building, testing, and database operations for the
# Rust server and Flutter mobile/web/desktop application.

SERVER_DIR := server
MOBILE_DIR := mobile

TEST_DEVICE_HOST ?= 10.0.2.2
TEST_DB_URL      := sqlite://./data/lms_e2e_test.db?mode=rwc

.SHELLFLAGS := -euo pipefail -c

.PHONY: help setup dev dev-server dev-mobile dev-web dev-desktop db-reset db-seed db-seed-e2e db-delete build build-apk build-macos build-windows test-server test-mobile test-e2e-auth test-e2e-admin test-e2e-mobile test-e2e-desktop format lint docker-up docker-down clean

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

setup:
	@if [ ! -f .env ]; then cp .env.example .env; fi
	@awk '/# --- SERVER ---/{p=1;next} p{print > "$(SERVER_DIR)/.env"} !p{print > "$(MOBILE_DIR)/.env"}' .env
	@cd $(MOBILE_DIR) && flutter pub get
	@mkdir -p $(SERVER_DIR)/data $(SERVER_DIR)/storage/materials $(SERVER_DIR)/storage/submissions $(SERVER_DIR)/storage/exports

dev-server:
	@cd $(SERVER_DIR) && cargo run

dev-mobile:
	@emulator -avd Medium_Phone_API_36.1 > /dev/null 2>&1 &
	@sleep 5
	@cd $(MOBILE_DIR) && flutter run

dev-web:
	@cd $(MOBILE_DIR) && flutter run -d chrome

dev-desktop:
	@if [ "$(shell uname)" = "Darwin" ]; then cd $(MOBILE_DIR) && flutter run -d macos; else cd $(MOBILE_DIR) && flutter run -d windows; fi

db-reset:
	@cd $(SERVER_DIR) && cargo run -- reset-db

db-seed:
	@cd $(SERVER_DIR) && cargo run -- reset-db --with-seed

db-seed-e2e:
	@cd $(SERVER_DIR) && DATABASE_URL="$(TEST_DB_URL)" cargo run -- reset-db && DATABASE_URL="$(TEST_DB_URL)" cargo run -- seed-e2e

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

test-e2e-auth: build db-seed
	@DATABASE_URL="$(TEST_DB_URL)" TEST_DEVICE_HOST=$(TEST_DEVICE_HOST) ./scripts/tests/run-mobile-e2e.sh "integration_test/mobile/auth_e2e_test.dart"

test-e2e-admin: build db-seed
	@DATABASE_URL="$(TEST_DB_URL)" TEST_DEVICE_HOST=$(TEST_DEVICE_HOST) ./scripts/tests/run-mobile-e2e.sh "integration_test/mobile/admin_e2e_test.dart"

test-e2e-mobile: test-e2e-auth test-e2e-admin

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
