import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> clearAllCacheOp(
  LocalDatabase localDatabase,
) async {
  try {
    final db = await localDatabase.database;
    await db.delete('users');
    await db.delete('activity_logs');
    // Preserve device_id so it persists across user sessions.
    await db.delete('sync_metadata', where: 'key != ?', whereArgs: ['device_id']);
  } catch (e) {
    throw CacheException('Failed to clear auth cache: $e');
  }
}
