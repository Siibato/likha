import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:uuid/uuid.dart';

Future<String> addStudentLocally(
  LocalDatabase localDatabase,
  String classId,
  UserModel student, {
  Transaction? txn,
}) async {
  try {
    final participantId = const Uuid().v4();
    final now = DateTime.now();

    Future<void> performInsert(Transaction t) async {
      await t.insert(
        DbTables.classParticipants,
        {
          CommonCols.id: participantId,
          ClassParticipantsCols.classId: classId,
          ClassParticipantsCols.userId: student.id,
          ClassParticipantsCols.joinedAt: now.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          ClassParticipantsCols.removedAt: null,
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.syncStatus: 'pending',
        },
      );

      await t.rawUpdate(
        'UPDATE ${DbTables.classes} SET student_count = (SELECT COUNT(*) FROM ${DbTables.classParticipants} WHERE class_id = ? AND removed_at IS NULL), updated_at = ? WHERE id = ?',
        [classId, now.toIso8601String(), classId],
      );
    }

    if (txn != null) {
      await performInsert(txn);
    } else {
      final db = await localDatabase.database;
      await db.transaction((t) async {
        await performInsert(t);
      });
    }

    return participantId;
  } catch (e) {
    throw CacheException('Failed to add student locally: $e');
  }
}
