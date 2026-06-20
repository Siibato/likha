import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> getCachedCurrentUser(
  LocalDatabase localDatabase,
  String? userId,
) async {
  try {
    final db = await localDatabase.database;

    List<Map<String, dynamic>> result;
    if (userId != null) {
      // If userId provided, query for that specific user
      result = await db.query(
        DbTables.users,
        where: '${CommonCols.id} = ?',
        whereArgs: [userId],
        limit: 1,
      );
    } else {
      // Otherwise, return most recent user (backwards compatibility)
      result = await db.query(
        DbTables.users,
        where: '${CommonCols.id} != ""',
        limit: 1,
        orderBy: '${CommonCols.cachedAt} DESC',
      );
    }

    if (result.isEmpty) throw CacheException('No cached current user found');
    return UserModel.fromMap(result.first);
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
