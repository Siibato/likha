// Desktop/mobile native SQLite initialization using FFI
import 'package:flutter/foundation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeSqflite() {
  if (defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS) {
    return;
  }
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
