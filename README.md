# Likha - Offline Learning Management System

## Prerequisites

- Rust (for server)
- Flutter SDK (for mobile)
- Android Studio (for Android development)
  - Android SDK
  - Android Emulator or physical Android device

## Getting Started

### 1. Set up environment variables

```bash
cp server/.env.example server/.env
```

Edit `server/.env` as needed.

### 2. Run the server

```bash
cd server
cargo run
```

The server will:
- Automatically create the SQLite database (`server/data/lms.db`) on first run
- Run database migrations
- Start listening on `http://localhost:8080`

### 3. Run the mobile app

#### Step 1: Start an Android emulator

List available emulators:

```bash
emulator -list-avds
```

**Set up low-resource device emulators (for testing on constrained devices like school networks):**

```bash
# Install Android 7 (2016)
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "system-images;android-24;google_apis;arm64-v8a"

# Install Android 5 (2014)
$ANDROID_HOME/cmdline-tools/latest/bin/sdkmanager "system-images;android-21;google_apis;arm64-v8a"

# Create Android 7 emulator (512MB RAM)
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  -n lowres_device \
  -k "system-images;android-24;google_apis;arm64-v8a" \
  -d "Nexus 5"

# Create Android 5 extreme low-resource emulator (256MB RAM)
$ANDROID_HOME/cmdline-tools/latest/bin/avdmanager create avd \
  -n lowres_device_256 \
  -k "system-images;android-21;google_apis;arm64-v8a" \
  -d "Nexus 5"

# Configure lowres_device (API 24): edit ~/.android/avd/lowres_device.avd/config.ini
# Change: hw.ramSize=512, vm.heapSize=128, hw.gpu.enabled=no, runtime.network.speed=slow

# Configure lowres_device_256 (API 21): edit ~/.android/avd/lowres_device_256.avd/config.ini
# Change: hw.ramSize=256, vm.heapSize=64, hw.gpu.enabled=no, runtime.network.speed=slow
```

**Start an emulator:**

Choose one of the three options below:

**1. Modern phone (default - recommended for development):**
```bash
emulator -avd Medium_Phone_API_36.1
```

**2. Low-resource device (Android 7.0, 512MB RAM):**
```bash
emulator -avd lowres_device
```

**3. Extreme low-resource device (Android 5.0, 256MB RAM - for testing extreme constraints):**
```bash
emulator -avd lowres_device_256 -memory 256
```

> **Note:** If the `emulator` command is not found, add the Android SDK to your PATH:
> ```bash
> # macOS/Linux - add to ~/.zshrc or ~/.bashrc
> export ANDROID_HOME=$HOME/Library/Android/sdk
> export PATH=$PATH:$ANDROID_HOME/emulator
> export PATH=$PATH:$ANDROID_HOME/platform-tools
> ```

#### Step 2: Run the Flutter app

```bash
cd mobile
flutter pub get
```

Verify the emulator is detected:

```bash
flutter devices
```

Run the app:

```bash
flutter run
```

Or specify a device if multiple are connected:

```bash
flutter run -d <device_id>
```

#### Using a physical device instead

1. Enable Developer Options on your Android device:
   - Go to `Settings > About phone`
   - Tap `Build number` 7 times
2. Enable USB debugging in `Settings > Developer options`
3. Connect your device via USB and accept the debugging prompt
4. **Forward the server port** (so the app can reach localhost:8080):
   ```bash
   adb reverse tcp:8080 tcp:8080
   ```
5. Update `mobile/.env` to use localhost:
   ```env
   API_BASE_URL=http://localhost:8080
   ```
6. Run `flutter devices` to verify it's detected, then `flutter run`

#### Troubleshooting

- Run `flutter doctor` to check your environment setup
- If `emulator` command not found, ensure `$ANDROID_HOME/emulator` is in your PATH
- For physical devices, ensure USB debugging is enabled and the device is authorized

### 4. Run the web app (Chrome)

The web version shows the desktop UI (side navigation rail) and uses IndexedDB for local storage in the browser.

#### First-time setup

Run this once to copy the required SQLite web worker files:

```bash
cd mobile
dart run sqflite_common_ffi_web:setup
```

#### Configure the API URL

In `mobile/.env`, make sure the API URL points to localhost:

```env
API_BASE_URL=http://localhost:8080
```

#### Run

```bash
cd mobile
flutter run -d chrome
```

### 5. Run the desktop app (macOS / Windows)

Both macOS and Windows desktop targets are already configured in the project.

```bash
cd mobile

# macOS
flutter run -d macos

# Windows
flutter run -d windows
```

To build a release binary:

```bash
flutter build macos   # on macOS
flutter build windows # on Windows
```

> **Note:** You can only build for the platform you're currently on. Full Xcode is required for macOS builds.

#### Clearing desktop local data (SQLite)

The desktop app stores its local database as a SQLite file:

- **macOS:** `~/Library/Application Support/com.example.likha/likha.db` (or similar)
- **Windows:** `C:\Users\<you>\AppData\Roaming\com.example.likha\likha.db`

Delete the `.db` file to reset local app data.

---

### 7. Building an APK

To build an APK for distribution or testing:

```bash
cd mobile
flutter build apk --release
```

The APK will be available at `build/app/outputs/apk/release/app-release.apk`

For debug builds (for testing only):

```bash
flutter build apk --debug
```

For split APKs by architecture (smaller file sizes):

```bash
flutter build apk --release --split-per-abi
```

## Database

This project uses **SQLite** for simplicity and true offline capability:
- No external database server required
- Database file is created automatically at `server/data/lms.db`
- Easy backup - just copy the `.db` file
- Migrations run automatically on server start

### Database Commands

Run these from the `server/` directory:

```bash
# Create the database and run migrations (without starting the server)
cargo run -- create-db

# Delete the database file
cargo run -- delete-db

# Delete and recreate the database (fresh start)
cargo run -- reset-db

# Clear all failed login attempts
cargo run -- clear-invalid-attempts
```
