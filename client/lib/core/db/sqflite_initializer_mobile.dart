// Mobile (Android/iOS) SQLite initialization using standard platform channels
// This uses the native sqflite package, not FFI, which is the correct approach for mobile

void initializeSqflite() {
  // Standard sqflite package automatically uses the correct platform implementation
  // No initialization needed - just import from package:sqflite/sqflite.dart
}
