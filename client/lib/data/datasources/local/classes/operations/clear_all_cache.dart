import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> clearAllCache(
  LocalDatabase localDatabase,
) async {
  try {
    final db = await localDatabase.database;
    await db.delete(DbTables.classParticipants);
    await db.delete(DbTables.classes);
  } catch (e) {
    throw CacheException('Failed to clear class cache: $e');
  }
}
