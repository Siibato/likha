# Multi-stage build — works on x86_64 and ARM64 (Raspberry Pi 4/5)
# Stage 1: compile the release binary
FROM rust:1.82-alpine AS builder

RUN apk add --no-cache musl-dev

WORKDIR /build

# Copy the full workspace needed by the server crate
COPY Cargo.toml Cargo.lock ./
COPY src/ ./src/
COPY entity/ ./entity/
COPY migrations/ ./migrations/
COPY vendor/ ./vendor/

# Configure cargo to use the vendored sources
ENV CARGO_NET_OFFLINE=true

RUN cargo build --release --offline

# Stage 2: minimal runtime image
FROM alpine:3.20 AS runtime

# curl is used only for the health check
RUN apk add --no-cache curl

WORKDIR /app

COPY --from=builder /build/target/release/server ./server
COPY --from=builder /build/migrations ./migrations

# Data and storage directories are expected to be mounted as Docker volumes
RUN mkdir -p /app/data /app/storage

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD curl -f http://localhost:8080/api/v1/health || exit 1

CMD ["./server"]
