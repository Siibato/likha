import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheClassDetail(
  LocalDatabase localDatabase,
  ClassDetailModel classDetail,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      // Preserve existing teacher info from the classes table as fallback
      String teacherUsername = '';
      String teacherFullName = '';
      final existingClassRows = await txn.query(
        DbTables.classes,
        columns: [ClassesCols.teacherUsername, ClassesCols.teacherFullName],
        where: '${CommonCols.id} = ?',
        whereArgs: [classDetail.id],
        limit: 1,
      );
      if (existingClassRows.isNotEmpty) {
        teacherUsername = existingClassRows.first[ClassesCols.teacherUsername] as String? ?? '';
        teacherFullName = existingClassRows.first[ClassesCols.teacherFullName] as String? ?? '';
      }

      // Look up teacher info from users table (overrides if found)
      if (classDetail.teacherId.isNotEmpty) {
        final teacherRows = await txn.query(
          'users',
          columns: ['username', 'first_name', 'last_name'],
          where: 'id = ?',
          whereArgs: [classDetail.teacherId],
          limit: 1,
        );
        if (teacherRows.isNotEmpty) {
          teacherUsername = teacherRows.first['username'] as String? ?? '';
          final firstName = teacherRows.first['first_name'] as String? ?? '';
          final lastName = teacherRows.first['last_name'] as String? ?? '';
          teacherFullName = '$lastName, $firstName'.trim();
        }
      }

      // Recalculate student_count from local participants rather than
      // trusting the remote classDetail.students.length, which may be stale.
      final countResult = await txn.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbTables.classParticipants} WHERE ${ClassParticipantsCols.classId} = ? AND ${ClassParticipantsCols.removedAt} IS NULL',
        [classDetail.id],
      );
      final localCount = (countResult.first['count'] as int?) ?? 0;

      final classMap = ClassModel(
        id: classDetail.id,
        title: classDetail.title,
        description: classDetail.description,
        teacherId: classDetail.teacherId,
        teacherUsername: teacherUsername,
        teacherFullName: teacherFullName,
        isArchived: classDetail.isArchived,
        isAdvisory: classDetail.isAdvisory,
        studentCount: localCount,
        createdAt: classDetail.createdAt,
        updatedAt: classDetail.updatedAt,
      ).toMap();
      classMap[CommonCols.cachedAt] = DateTime.now().toIso8601String();

      // If the class row has pending mutations, preserve that status
      // so downstream consumers know not to overwrite metadata, but
      // always update student_count from local participants.
      final pendingClassRow = await txn.query(
        DbTables.classes,
        columns: [CommonCols.syncStatus],
        where: '${CommonCols.id} = ? AND ${CommonCols.syncStatus} = ?',
        whereArgs: [classDetail.id, 'pending'],
        limit: 1,
      );
      if (pendingClassRow.isNotEmpty) {
        classMap[CommonCols.syncStatus] = 'pending';
      } else {
        classMap[CommonCols.syncStatus] = 'synced';
      }

      // Use UPDATE-or-INSERT instead of REPLACE to avoid triggering
      // ON DELETE CASCADE on class_participants.
      final existingClass = await txn.query(
        DbTables.classes,
        columns: [CommonCols.id],
        where: '${CommonCols.id} = ?',
        whereArgs: [classDetail.id],
        limit: 1,
      );
      if (existingClass.isNotEmpty) {
        await txn.update(DbTables.classes, classMap, where: '${CommonCols.id} = ?', whereArgs: [classDetail.id]);
      } else {
        await txn.insert(DbTables.classes, classMap);
      }

      // Cache students as class_participants (v18 - no user detail columns)
      // Skip rows that have pending local mutations to avoid clobbering them
      final pendingParticipantRows = await txn.query(
        DbTables.classParticipants,
        columns: [ClassParticipantsCols.userId],
        where: '${ClassParticipantsCols.classId} = ? AND ${CommonCols.syncStatus} = ?',
        whereArgs: [classDetail.id, 'pending'],
      );
      final pendingUserIds = pendingParticipantRows
          .map((r) => r[ClassParticipantsCols.userId] as String?)
          .whereType<String>()
          .toSet();

      for (final participant in classDetail.students) {
        if (pendingUserIds.contains(participant.student.id)) continue;
        await txn.insert(
          DbTables.classParticipants,
          {
            CommonCols.id: participant.id,
            ClassParticipantsCols.classId: classDetail.id,
            ClassParticipantsCols.userId: participant.student.id,
            ClassParticipantsCols.joinedAt: participant.joinedAt.toIso8601String(),
            CommonCols.updatedAt: DateTime.now().toIso8601String(),
            ClassParticipantsCols.removedAt: null,
            CommonCols.cachedAt: DateTime.now().toIso8601String(),
            CommonCols.syncStatus: 'synced',
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache class detail: $e');
  }
}
