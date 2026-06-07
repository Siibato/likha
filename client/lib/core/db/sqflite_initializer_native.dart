// Desktop/mobile native SQLite initialization using FFI
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void initializeSqflite() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
}
