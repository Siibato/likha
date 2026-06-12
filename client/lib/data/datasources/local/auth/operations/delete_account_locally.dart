import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> deleteAccountLocally(
  LocalDatabase localDatabase,
  String userId,
) async {
  try {
    final db = await localDatabase.database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  } catch (e) {
    throw CacheException('Failed to delete account locally: $e');
  }
}
