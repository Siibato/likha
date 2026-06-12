import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> removeStudentLocally(
  LocalDatabase localDatabase,
  String classId,
  String studentId,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now();
    await db.transaction((txn) async {
      // Soft delete: set removed_at instead of hard delete
      await txn.update(
        DbTables.classParticipants,
        {
          ClassParticipantsCols.removedAt: now.toIso8601String(),
          CommonCols.needsSync: 1,
          CommonCols.updatedAt: now.toIso8601String(),
        },
        where: '${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.userId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
        whereArgs: [classId, studentId],
      );

      await txn.rawUpdate(
        'UPDATE ${DbTables.classes} SET student_count = (SELECT COUNT(*) FROM ${DbTables.classParticipants} WHERE class_id = ? AND removed_at IS NULL), updated_at = ? WHERE id = ?',
        [classId, now.toIso8601String(), classId],
      );
    });
  } catch (e) {
    throw CacheException('Failed to remove student locally: $e');
  }
}
