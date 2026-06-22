# Likha Pi Image Deployment

Builds a Raspberry Pi OS Lite SD card image with the Likha server pre-embedded as a Docker container, ready for classroom deployments.

## Pipeline Overview

```
Build ARM64 Docker image
        |
        v
  Bake into pi-gen stage
        |
        v
  Produce .img.xz release
        |
        v
  Publish to GitHub Releases + os_list.json
```

## Directory Layout

| Path | Purpose |
|------|---------|
| `compose/docker-compose.pi.yml` | Runtime stack: Likha server + Redis |
| `scripts/first-boot.sh` | First-boot configuration (network, secrets, env file) |
| `scripts/generate-secrets.sh` | Secure random secret generator |
| `systemd/*.service` | systemd units for first-boot and server stack |
| `pi-image/config` | pi-gen build configuration |
| `pi-image/stage-likha/` | Custom pi-gen stage scripts |
| `imager-manifest/os_list.json` | Pi Imager custom OS manifest |

## How to Build Locally

Requires Docker, `docker buildx`, and `make`.

```bash
# 1. Sync deployment assets into the pi-gen stage
make sync-pi-assets

# 2. Build the ARM64 server image and save as tar
make build-pi-server-image

# 3. Build the full Pi SD card image (takes 30–60 min)
make build-pi-image

# Output: /tmp/pi-gen/deploy/likha-server-*.img.xz
```

To build manually without Make:

```bash
# Build server image
docker buildx build --platform linux/arm64 -t likha-server:latest -f server/Dockerfile server/
docker save likha-server:latest > deployment/pi-image/stage-likha/likha-server-arm64.tar

# Sync assets
cd deployment/pi-image && ./sync-assets.sh

# Clone pi-gen and build
rm -rf /tmp/pi-gen
git clone --depth 1 https://github.com/RPi-Distro/pi-gen.git /tmp/pi-gen
cp deployment/pi-image/config /tmp/pi-gen/config
cp -r deployment/pi-image/stage-likha /tmp/pi-gen/
cd /tmp/pi-gen && ./build-docker.sh

# Compress
xz -T0 -v /tmp/pi-gen/deploy/*.img
```

## How to Flash an SD Card

### Using Raspberry Pi Imager
1. Open Pi Imager → Choose OS → Use custom URL.
2. Enter: `https://likha.app/imager/os_list.json`
3. Select **Likha Classroom Server**.
4. In **Advanced Options**, fill in:
   - **School Code / Mesh Group ID** (required for mesh discovery)
   - **WiFi SSID / Password** (optional; Ethernet router mode is default)
5. Flash and boot.

### Using Command Line (macOS / Linux)

```bash
# Identify your SD card device (e.g., /dev/disk4 on macOS, /dev/sdb on Linux)
diskutil list  # macOS
# or
lsblk          # Linux

# Flash (replace /dev/rdisk4 with your device)
pv likha-server-v1.0.0.img.xz | xz -d | sudo dd of=/dev/rdisk4 bs=4m status=progress

# Eject
diskutil eject /dev/disk4  # macOS
# or
sudo eject /dev/sdb         # Linux
```

## First Boot Behavior

1. The `likha-first-boot.service` runs `first-boot.sh`.
2. Reads `/boot/likha-config.txt` for mesh group ID and WiFi credentials.
3. Generates runtime secrets (JWT, DB encryption, replication secret, node UUID).
4. Configures networking:
   - **Ethernet (`eth0`)**: Sets static IP `192.168.1.1`, enables dnsmasq DHCP (50–200).
   - **WiFi**: Writes `wpa_supplicant.conf`, client mode via DHCP, mDNS `likha.local`.
5. Writes `/opt/likha/server/.env` and starts the Docker stack.
6. Blinks the green LED rapidly for 30 seconds to signal readiness.
7. Disables itself so subsequent boots go straight to the server stack.

## Troubleshooting

### Check first-boot logs
```bash
# On the Pi (or via SSH after WiFi is up)
sudo journalctl -u likha-first-boot.service -b
```

### Check server stack status
```bash
sudo docker ps
sudo docker logs likha-server
sudo journalctl -u likha-server.service -f
```

### LED Signals
- **Rapid blink (50 ms on/off) for 30 s**: First boot completed successfully; server is running.
- **Solid green**: Normal operation (after first boot).
- **No LED activity**: Check power supply; Pi may not be booting at all.

### Re-run first boot
If you need to reconfigure:
```bash
sudo rm /opt/likha/.first-boot-complete
sudo systemctl enable likha-first-boot.service
sudo reboot
```

## Updating the Imager Manifest

The `os_list.json` is updated automatically by the GitHub Actions workflow on each release. The URL and sizes are computed from the built `.img.xz` artifact.

To update manually:
1. Edit `deployment/imager-manifest/os_list.json`.
2. Update `url`, `extract_size`, `image_download_size`, and `release_date`.
3. Commit and push; if hosting on `gh-pages`, cherry-pick to that branch.

## CI/CD

The `.github/workflows/build-pi-image.yml` pipeline triggers on version tags (`v*`) or manually via `workflow_dispatch`. It:

1. Checks out `pi-gen` at a pinned tag.
2. Builds the ARM64 server image with `docker buildx`.
3. Embeds the image into the pi-gen stage.
4. Runs pi-gen inside Docker (`build-docker.sh`).
5. Compresses the output `.img` to `.img.xz`.
6. Uploads to GitHub Releases.
7. Updates `os_list.json` with computed metadata.
