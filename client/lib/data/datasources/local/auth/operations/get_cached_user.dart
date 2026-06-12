import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> getCachedUser(
  LocalDatabase localDatabase,
  String userId,
) async {
  try {
    final db = await localDatabase.database;
    final result = await db.query(
      DbTables.users,
      where: '${CommonCols.id} = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isEmpty) throw CacheException('User not found in cache: $userId');
    return UserModel.fromMap(result.first);
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException('Failed to get cached user: $e');
  }
}
