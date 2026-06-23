# Likha Project Command Center
#
# Orchestrates development, building, testing, and database operations for the
# Rust server and Flutter client application (mobile/web/desktop).

SERVER_DIR := server
CLIENT_DIR := client

TEST_DEVICE_HOST ?= 10.0.2.2
TEST_DB_URL      := sqlite://./data/lms_e2e_test.db?mode=rwc

# Pi image build paths
PI_IMAGE_DIR      := deployment/pi-image
PI_GEN_DIR        := /tmp/pi-gen
PI_GEN_REPO       := https://github.com/RPi-Distro/pi-gen.git
PI_GEN_REF        := 2026-06-18-raspios-bookworm-arm64
PI_DEPLOY_DIR     := $(PI_GEN_DIR)/deploy
BUILD_DIR         := builds

.SHELLFLAGS := -euo pipefail -c

.PHONY: help setup dev dev-server dev-client dev-web dev-desktop dev-macos db-reset db-seed db-seed-manifest db-seed-e2e db-seed-realistic db-seed-demo db-delete build-server run-server build-apk build-macos build-windows test-server test-client test-e2e-auth test-e2e-admin test-e2e-client test-e2e-desktop format lint docker-up docker-down clean clean-server clean-client sync-pi-assets build-pi-server-image build-pi-image clean-pi-image

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-22s\033[0m %s\n", $$1, $$2}'

setup:
	@if [ ! -f .env ]; then cp .env.example .env; fi
	@awk '/# --- SERVER ---/{p=1;next} p{print > "$(SERVER_DIR)/.env"} !p{print > "$(CLIENT_DIR)/.env"}' .env
	@cd $(CLIENT_DIR) && flutter pub get
	@mkdir -p $(SERVER_DIR)/data $(SERVER_DIR)/storage/materials $(SERVER_DIR)/storage/submissions $(SERVER_DIR)/storage/exports

dev-server:
	@cd $(SERVER_DIR) && cargo run

dev-client:
	@emulator -avd Medium_Phone_API_36.1 > /dev/null 2>&1 &
	@sleep 15
	@cd $(CLIENT_DIR) && flutter run

dev-web:
	@cd $(CLIENT_DIR) && flutter run -d chrome

dev-desktop:
	@cd $(CLIENT_DIR) && flutter run -d chrome

dev-macos:
	@cd $(CLIENT_DIR) && flutter run -d macos

db-reset:
	@cd $(SERVER_DIR) && cargo run -- reset-db

db-seed:
	@cd $(SERVER_DIR) && cargo run -- reset-db --with-seed

db-seed-manifest:
	@cd $(SERVER_DIR) && cargo run -- reset-db && cargo run -- seed-manual --export-manifest ../load-tests/seed-manifest.json

db-seed-e2e:
	@cd $(SERVER_DIR) && DATABASE_URL="$(TEST_DB_URL)" cargo run -- reset-db && DATABASE_URL="$(TEST_DB_URL)" cargo run -- seed-e2e

db-seed-realistic:
	@cd $(SERVER_DIR) && cargo run -- reset-db && cargo run -- seed-realistic

db-seed-demo:
	@cd $(SERVER_DIR) && cargo run -- reset-db && cargo run -- seed-demo

db-delete:
	@cd $(SERVER_DIR) && cargo run -- delete-db

build-server:
	@cd $(SERVER_DIR) && cargo build --release --no-default-features

run-server:
	@cd $(SERVER_DIR) && ./target/release/server

build-apk:
	@cd $(CLIENT_DIR) && flutter build apk --release

build-macos:
	@cd $(CLIENT_DIR) && flutter build macos

build-windows:
	@cd $(CLIENT_DIR) && flutter build windows

test-server:
	@cd $(SERVER_DIR) && cargo test --features seed

test-client:
	@cd $(CLIENT_DIR) && flutter test

test-e2e-auth: build-server db-seed
	@DATABASE_URL="$(TEST_DB_URL)" TEST_DEVICE_HOST=$(TEST_DEVICE_HOST) ./scripts/tests/run-client-e2e.sh "integration_test/mobile/auth_e2e_test.dart"

test-e2e-admin: build-server db-seed
	@DATABASE_URL="$(TEST_DB_URL)" TEST_DEVICE_HOST=$(TEST_DEVICE_HOST) ./scripts/tests/run-client-e2e.sh "integration_test/mobile/admin_e2e_test.dart"

test-e2e-client: test-e2e-auth test-e2e-admin

test-e2e-desktop:
	@echo "E2E desktop tests not yet implemented — run 'make test-e2e-client' instead"

format:
	@cd $(SERVER_DIR) && cargo fmt
	@cd $(CLIENT_DIR) && dart format .

lint:
	@cd $(SERVER_DIR) && cargo clippy
	@cd $(CLIENT_DIR) && flutter analyze

docker-up:
	@docker-compose up -d

docker-down:
	@docker-compose down

sync-pi-assets: ## Sync deployment assets (compose, scripts, systemd) into pi-gen stage
	@cd $(PI_IMAGE_DIR) && ./sync-assets.sh

build-pi-server-image: ## Build ARM64 Docker image and save as tar for pi-gen embedding
	@docker buildx build --platform linux/arm64 -t likha-server:latest -f $(SERVER_DIR)/Dockerfile $(SERVER_DIR)/
	@mkdir -p $(PI_IMAGE_DIR)/stage-likha
	@docker save likha-server:latest > $(PI_IMAGE_DIR)/stage-likha/likha-server-arm64.tar
	@echo "Saved likha-server-arm64.tar to $(PI_IMAGE_DIR)/stage-likha/"

build-pi-image: sync-pi-assets build-pi-server-image ## Build the full Raspberry Pi SD card image (.img.xz)
	@echo "Cloning pi-gen..."
	@rm -rf $(PI_GEN_DIR)
	@git clone --depth 1 --branch $(PI_GEN_REF) $(PI_GEN_REPO) $(PI_GEN_DIR)
	@echo "Copying Likha config and stage..."
	@cp $(PI_IMAGE_DIR)/config $(PI_GEN_DIR)/
	@cp -r $(PI_IMAGE_DIR)/stage-likha $(PI_GEN_DIR)/
	@echo "Building Pi image (this takes 30–60 min)..."
	@cd $(PI_GEN_DIR) && ./build-docker.sh
	@echo "Compressing image..."
	@for img in $(PI_DEPLOY_DIR)/*.img; do \
		if [ -f "$$img" ]; then \
			xz -T0 -v "$$img"; \
			echo "Output: $$img.xz"; \
		fi; \
	done
	@mkdir -p $(BUILD_DIR)
	@cp $(PI_DEPLOY_DIR)/*.img.xz $(BUILD_DIR)/ 2>/dev/null || true
	@echo "Done. Image(s) in $(BUILD_DIR)/"

clean-pi-image: ## Remove pi-gen clone and build artifacts
	@docker rm -f pigen_work 2>/dev/null || true
	@rm -rf $(PI_GEN_DIR)
	@rm -f $(PI_IMAGE_DIR)/stage-likha/likha-server-arm64.tar
	@echo "Pi image build artifacts cleaned"

clean:
	@rm -rf $(SERVER_DIR)/target $(CLIENT_DIR)/build $(SERVER_DIR)/data/*.db

clean-server:
	@rm -rf $(SERVER_DIR)/target $(SERVER_DIR)/data/*.db

clean-client:
	@rm -rf $(CLIENT_DIR)/build
