import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel?> getStudentByIdOp(
  LocalDatabase localDatabase,
  String studentId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.users,
      where: '${CommonCols.id} = ?',
      whereArgs: [studentId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  } catch (e) {
    throw CacheException('Failed to get student by id: $e');
  }
}
