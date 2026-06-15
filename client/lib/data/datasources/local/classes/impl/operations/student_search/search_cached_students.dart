import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> searchCachedStudentsOp(
  LocalDatabase localDatabase,
  String query,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.users,
      where: '(${UsersCols.username} LIKE ? OR ${UsersCols.fullName} LIKE ?) AND ${UsersCols.role} = ?',
      whereArgs: ['%$query%', '%$query%', 'student'],
      orderBy: '${UsersCols.fullName} ASC',
    );
    return results.map((r) => UserModel.fromMap(r)).toList();
  } catch (e) {
    throw CacheException('Failed to search cached students: $e');
  }
}
