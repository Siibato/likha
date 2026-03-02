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

Start an emulator (replace `<avd_name>` with one from the list above):

```bash
emulator -avd <avd_name>
```

Example:

```bash
emulator -avd Medium_Phone_API_36.1
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

### 4. Building an APK

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
```
