import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> getCachedAccounts(
  LocalDatabase localDatabase,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.users,
      where: '${CommonCols.deletedAt} IS NULL',
      orderBy: '${UsersCols.username} ASC',
    );
    if (results.isEmpty) return [];
    return results.map((r) => UserModel.fromMap(r)).toList();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
