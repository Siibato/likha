#!/usr/bin/env bash
# Configures a freshly flashed Likha Pi image on first boot.
#
# Responsibilities:
#   * Read /boot/likha-config.txt for mesh + WiFi settings
#   * Generate runtime secrets and .env file
#   * Configure networking (router mode via eth0 or WiFi client mode)
#   * Launch the Docker stack and signal readiness via LED blink
#   * Disable itself after successful completion

set -euo pipefail

CONFIG_FILE="/boot/likha-config.txt"
ENV_FILE="/opt/likha/server/.env"
SECRETS_SCRIPT="/opt/likha/scripts/generate-secrets.sh"
COMPOSE_FILE="/opt/likha/compose/docker-compose.pi.yml"
DNSMASQ_CONF="/etc/dnsmasq.d/likha.conf"
DHCPCD_CONF="/etc/dhcpcd.conf"
WPA_SUPPLICANT="/etc/wpa_supplicant/wpa_supplicant.conf"
LED_PATH="/sys/class/leds/led0"
STATE_FILE="/opt/likha/.first-boot-complete"

log() {
  echo "[likha-first-boot] $*"
}

read_config() {
  local key="$1"
  [[ -f "$CONFIG_FILE" ]] || return 1
  sed -n "s/^${key}=//p" "$CONFIG_FILE" | tail -n1 | tr -d '\r'
}

eth0_has_link() {
  [[ -f /sys/class/net/eth0/carrier ]] && [[ "$(cat /sys/class/net/eth0/carrier)" == "1" ]]
}

ensure_directories() {
  mkdir -p /opt/likha/server /opt/likha/compose /opt/likha/scripts /opt/likha/images

  if [[ ! -f "$COMPOSE_FILE" ]]; then
    log "Missing compose file: $COMPOSE_FILE"
    exit 1
  fi
}

load_secrets() {
  [[ -x "$SECRETS_SCRIPT" ]] || { log "Missing $SECRETS_SCRIPT"; exit 1; }
  declare -gA SECRETS=()
  while IFS='=' read -r key value; do
    [[ -z "${key:-}" ]] && continue
    SECRETS["$key"]="$value"
  done < <("$SECRETS_SCRIPT")
}

configure_router_mode() {
  log "Configuring Classroom Router mode (eth0)"
  mkdir -p /etc/dnsmasq.d
  local conf_marker="# Likha Classroom static IP"
  if ! grep -q "$conf_marker" "$DHCPCD_CONF"; then
    cat >> "$DHCPCD_CONF" <<EOF

$conf_marker
interface eth0
static ip_address=192.168.1.1/24
nohook wpa_supplicant
EOF
  fi

  cat > "$DNSMASQ_CONF" <<'EOF'
interface=eth0
bind-interfaces
dhcp-range=192.168.1.50,192.168.1.200,12h
domain-needed
bogus-priv
server=1.1.1.1
log-queries
log-dhcp
dhcp-option=option:router,192.168.1.1
dhcp-option=option:dns-server,192.168.1.1
EOF

  systemctl enable dnsmasq >/dev/null 2>&1 || true
  systemctl restart dhcpcd || true
  systemctl restart dnsmasq || true

  NODE_IP="192.168.1.1"
}

configure_wifi_mode() {
  local ssid="$1"
  local psk="$2"
  local country="$3"

  log "Configuring WiFi client mode for SSID '$ssid'"

  rm -f "$DNSMASQ_CONF"
  systemctl disable dnsmasq >/dev/null 2>&1 || true
  systemctl stop dnsmasq >/dev/null 2>&1 || true

  cat > "$WPA_SUPPLICANT" <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=${country}

network={
    ssid="${ssid}"
    psk="${psk}"
    key_mgmt=WPA-PSK
}
EOF

  chmod 600 "$WPA_SUPPLICANT"

  rfkill unblock wifi || true
  systemctl restart wpa_supplicant || true
  systemctl restart dhcpcd || true

  # Allow DHCP to settle
  for _ in {1..10}; do
    NODE_IP=$(ip -4 addr show wlan0 | awk '/inet / {print $2}' | cut -d/ -f1)
    [[ -n "${NODE_IP}" ]] && break
    sleep 3
  done

  NODE_IP="${NODE_IP:-likha.local}"
}

write_env_file() {
  local school_code="$1"
  local mesh_group_id="$2"
  local node_id="$3"
  local node_ip="$4"

  cat > "$ENV_FILE" <<EOF
HOST=0.0.0.0
PORT=8080
DATABASE_URL=sqlite:///app/data/lms.db?mode=rwc
JWT_SECRET=${SECRETS[JWT_SECRET]}
JWT_EXPIRATION=86400
JWT_ACCESS_TOKEN_EXPIRATION=86400
JWT_REFRESH_TOKEN_EXPIRATION=604800
DB_ENCRYPTION_KEY=${SECRETS[DB_ENCRYPTION_KEY]}
FILE_ENCRYPTION_KEY=${SECRETS[FILE_ENCRYPTION_KEY]}
MATERIALS_PATH=./storage/materials
SUBMISSIONS_PATH=./storage/submissions
EXPORTS_PATH=./storage/exports
SCHOOL_CODE=${school_code}
ALLOWED_ORIGINS=http://192.168.1.1,http://likha.local,http://${node_ip}
MAX_BODY_SIZE_MB=55
REDIS_URL=redis://redis:6379
CACHE_ENABLED=true
CACHE_TTL_LIST_SECONDS=300
CACHE_TTL_DETAIL_SECONDS=120
CACHE_TTL_STATIC_SECONDS=3600
DISABLE_RATE_LIMIT=false
RUST_LOG=info,server=info
PEER_URL=
MESH_GROUP_ID=${mesh_group_id}
NODE_ID=${node_id}
NODE_IP=${node_ip}
REPLICATION_SECRET=${SECRETS[REPLICATION_SECRET]}
REPLICATION_INTERVAL_SECONDS=30
DISCOVERY_MULTICAST_ADDR=239.255.42.99:9999
DISCOVERY_BEACON_INTERVAL_SECONDS=5
DISCOVERY_PEER_TTL_SECONDS=30
EOF

  chmod 600 "$ENV_FILE"
}

blink_led() {
  [[ -d "$LED_PATH" ]] || return
  echo timer > "$LED_PATH/trigger"
  echo 50 > "$LED_PATH/delay_on"
  echo 50 > "$LED_PATH/delay_off"
  sleep 30
  echo default-on > "$LED_PATH/trigger"
}

start_stack() {
  log "Starting Likha Docker stack"
  systemctl enable --now docker >/dev/null 2>&1 || true
  systemctl enable likha-server.service >/dev/null 2>&1 || true
  systemctl restart likha-server.service || true
}

main() {
  [[ $EUID -eq 0 ]] || { log "Must run as root"; exit 1; }

  if [[ -f "$STATE_FILE" ]]; then
    log "First boot already completed; skipping"
    exit 0
  fi

  ensure_directories

  local mesh_group_id="$(read_config MESH_GROUP_ID || echo)"
  local wifi_ssid="$(read_config WIFI_SSID || echo)"
  local wifi_password="$(read_config WIFI_PASSWORD || echo)"
  local wifi_country="$(read_config WIFI_COUNTRY || echo PH)"
  local school_code="$(read_config SCHOOL_CODE || echo LIKHA)"
  local config_node_id="$(read_config NODE_ID || echo)"

  load_secrets

  local node_id="${config_node_id:-${SECRETS[NODE_ID]:-}}"
  if [[ -z "$node_id" ]]; then
    node_id="$(uuidgen)"
  fi
  NODE_IP="$(hostname -I | awk '{print $1}')"

  if eth0_has_link; then
    configure_router_mode
  elif [[ -n "$wifi_ssid" && -n "$wifi_password" ]]; then
    configure_wifi_mode "$wifi_ssid" "$wifi_password" "$wifi_country"
  else
    log "No network configuration supplied; using existing DHCP defaults"
    NODE_IP="${NODE_IP:-127.0.0.1}"
  fi

  write_env_file "$school_code" "$mesh_group_id" "$node_id" "$NODE_IP"
  start_stack
  blink_led &

  systemctl disable likha-first-boot.service || true
  systemctl enable --now avahi-daemon || true

  touch "$STATE_FILE"
  log "First boot configuration complete"
}

main "$@"
