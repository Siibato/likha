import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:uuid/uuid.dart';

Future<String> addStudentLocally(
  LocalDatabase localDatabase,
  String classId,
  UserModel student,
) async {
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
