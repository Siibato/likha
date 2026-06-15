import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/classes/class_model.dart';

Future<List<ClassModel>> getCachedClassesForUserOp(
  LocalDatabase localDatabase,
  String userId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.rawQuery('''
      SELECT DISTINCT c.*
      FROM ${DbTables.classes} c
      WHERE c.teacher_id = ? AND c.deleted_at IS NULL
      UNION
      SELECT DISTINCT c.*
      FROM ${DbTables.classes} c
      JOIN ${DbTables.classParticipants} cp ON c.id = cp.class_id
      WHERE cp.user_id = ? AND cp.removed_at IS NULL AND c.deleted_at IS NULL
      ORDER BY title ASC
    ''', [userId, userId]); // userId bound twice: once per UNION leg

    if (results.isEmpty) {
      return [];
    }
    return results.map((r) => ClassModel.fromMap(r)).toList();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
