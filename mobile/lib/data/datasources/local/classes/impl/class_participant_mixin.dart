import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:uuid/uuid.dart';
import '../class_local_datasource_base.dart';

mixin ClassParticipantMixin on ClassLocalDataSourceBase {
  @override
  Future<String> addStudentLocally({
    required String classId,
    required UserModel student,
  }) async {
    try {
      final db = await localDatabase.database;
      final participantId = const Uuid().v4();
      final now = DateTime.now();
      await db.transaction((txn) async {
        await txn.insert(
          DbTables.classParticipants,
          {
            CommonCols.id: participantId,
            ClassParticipantsCols.classId: classId,
            ClassParticipantsCols.userId: student.id,
            ClassParticipantsCols.joinedAt: now.toIso8601String(),
            CommonCols.updatedAt: now.toIso8601String(),
            ClassParticipantsCols.removedAt: null,
            CommonCols.cachedAt: now.toIso8601String(),
            CommonCols.needsSync: 1,
          },
        );

        await txn.rawUpdate(
          'UPDATE ${DbTables.classes} SET student_count = (SELECT COUNT(*) FROM ${DbTables.classParticipants} WHERE class_id = ? AND removed_at IS NULL), updated_at = ? WHERE id = ?',
          [classId, now.toIso8601String(), classId],
        );
      });
      return participantId;
    } catch (e) {
      throw CacheException('Failed to add student locally: $e');
    }
  }

  @override
  Future<void> removeStudentLocally({
    required String classId,
    required String studentId,
  }) async {
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

  @override
  Future<Set<String>> getParticipantIds(String classId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        DbTables.classParticipants,
        columns: [ClassParticipantsCols.userId],
        where: '${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
        whereArgs: [classId],
      );
      return results.map((row) => row[ClassParticipantsCols.userId] as String).toSet();
    } catch (e) {
      throw CacheException('Failed to get participant IDs: $e');
    }
  }
}
