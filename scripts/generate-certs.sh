#!/usr/bin/env bash
# Generates a local CA and a server TLS certificate for the school Raspberry Pi.
# Run this once on the Pi before starting the Docker stack.
#
# Usage:
#   SERVER_IP=192.168.1.1 bash scripts/generate-certs.sh
#
# Output:
#   nginx/certs/ca.key        — CA private key (keep secret, used to sign certs)
#   nginx/certs/ca.crt        — CA certificate (install on every school device once)
#   nginx/certs/server.key    — Server private key
#   nginx/certs/server.crt    — Server certificate (presented to browsers/apps)

set -euo pipefail

CERTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/nginx/certs"
SERVER_IP="${SERVER_IP:-192.168.1.1}"
DAYS_VALID=3650   # 10 years — school-internal, no rotation needed

mkdir -p "$CERTS_DIR"

echo "Generating certificates in: $CERTS_DIR"
echo "Server IP SAN: $SERVER_IP"
echo ""

# --- CA key and certificate ---
openssl genrsa -out "$CERTS_DIR/ca.key" 4096

openssl req -new -x509 \
  -key "$CERTS_DIR/ca.key" \
  -out "$CERTS_DIR/ca.crt" \
  -days $DAYS_VALID \
  -subj "/CN=Likha School CA/O=Likha LMS/C=PH"

# --- Server key and CSR ---
openssl genrsa -out "$CERTS_DIR/server.key" 2048

openssl req -new \
  -key "$CERTS_DIR/server.key" \
  -out "$CERTS_DIR/server.csr" \
  -subj "/CN=likha.local/O=Likha LMS/C=PH"

# --- SAN extension file ---
cat > "$CERTS_DIR/server.ext" <<EOF
[v3_req]
subjectAltName = IP:${SERVER_IP},DNS:likha.local,DNS:localhost
basicConstraints = CA:FALSE
keyUsage = digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
EOF

# --- Sign server cert with CA ---
openssl x509 -req \
  -in "$CERTS_DIR/server.csr" \
  -CA "$CERTS_DIR/ca.crt" \
  -CAkey "$CERTS_DIR/ca.key" \
  -CAcreateserial \
  -out "$CERTS_DIR/server.crt" \
  -days $DAYS_VALID \
  -extensions v3_req \
  -extfile "$CERTS_DIR/server.ext"

# Clean up intermediates
rm "$CERTS_DIR/server.csr" "$CERTS_DIR/server.ext"

echo ""
echo "Certificates generated successfully."
echo ""
echo "=== INSTALL ca.crt ON ALL SCHOOL DEVICES ==="
echo ""
echo "Android:"
echo "  1. Copy nginx/certs/ca.crt to the device"
echo "  2. Settings > Security > Install a certificate > CA certificate"
echo ""
echo "iOS:"
echo "  1. AirDrop or email ca.crt to the device"
echo "  2. Settings > General > VPN & Device Management > Install profile"
echo "  3. Settings > General > About > Certificate Trust Settings > Enable"
echo ""
echo "Windows:"
echo "  1. Double-click ca.crt > Install Certificate"
echo "  2. Store: Local Machine > Trusted Root Certification Authorities"
echo ""
echo "macOS:"
echo "  1. Double-click ca.crt to add to Keychain"
echo "  2. Right-click > Get Info > Trust > Always Trust"
echo ""
