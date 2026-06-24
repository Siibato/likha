import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> removeStudentLocally(
  LocalDatabase localDatabase,
  String classId,
  String studentId, {
  Transaction? txn,
}) async {
  try {
    final now = DateTime.now();

    Future<void> performRemove(Transaction t) async {
      // Soft delete: set removed_at instead of hard delete
      await t.update(
        DbTables.classParticipants,
        {
          ClassParticipantsCols.removedAt: now.toIso8601String(),
          CommonCols.syncStatus: 'pending',
          CommonCols.updatedAt: now.toIso8601String(),
        },
        where: '${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.userId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
        whereArgs: [classId, studentId],
      );

      await t.rawUpdate(
        'UPDATE ${DbTables.classes} SET student_count = (SELECT COUNT(*) FROM ${DbTables.classParticipants} WHERE class_id = ? AND removed_at IS NULL), updated_at = ?, ${CommonCols.syncStatus} = ? WHERE id = ?',
        [classId, now.toIso8601String(), 'pending', classId],
      );
    }

    if (txn != null) {
      await performRemove(txn);
    } else {
      final db = await localDatabase.database;
      await db.transaction((t) async {
        await performRemove(t);
      });
    }
  } catch (e) {
    throw CacheException('Failed to remove student locally: $e');
  }
}
