import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> clearActivityLogsForUserOp(
  LocalDatabase localDatabase,
  String userId,
) async {
  try {
    final db = await localDatabase.database;
    await db.delete('activity_logs', where: 'user_id = ?', whereArgs: [userId]);
  } catch (e) {
    throw CacheException('Failed to clear activity logs: $e');
  }
}
