import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:likha/core/database/local_database.dart';

/// Creates a fresh in-memory SQLite database with the full app schema applied.
/// Overrides the LocalDatabase singleton so all datasources use it.
/// Call [closeTestDatabase] in tearDown to reset state.
Future<Database> openFreshTestDatabase() async {
  dotenv.testLoad(fileInput: 'SYNC_LOGGING_ENABLED=false\nVALIDATION_LOGGING_ENABLED=false');
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final db = await databaseFactory.openDatabase(
    inMemoryDatabasePath,
    options: OpenDatabaseOptions(
      version: 1,
      onCreate: (db, _) => LocalDatabase.createSchemaForTesting(db),
    ),
  );
  LocalDatabase.overrideForTesting(db);
  return db;
}

/// Closes the test database and resets the LocalDatabase singleton.
Future<void> closeTestDatabase() async {
  await LocalDatabase().close();
}
