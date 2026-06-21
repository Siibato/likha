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
      // Look up teacher info from users table
      String teacherUsername = '';
      String teacherFullName = '';
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
          teacherFullName = '$firstName $lastName'.trim();
        }
      }

      final classMap = ClassModel(
        id: classDetail.id,
        title: classDetail.title,
        description: classDetail.description,
        teacherId: classDetail.teacherId,
        teacherUsername: teacherUsername,
        teacherFullName: teacherFullName,
        isArchived: classDetail.isArchived,
        isAdvisory: classDetail.isAdvisory,
        studentCount: classDetail.students.length,
        createdAt: classDetail.createdAt,
        updatedAt: classDetail.updatedAt,
      ).toMap();
      classMap[CommonCols.cachedAt] = DateTime.now().toIso8601String();
      classMap[CommonCols.syncStatus] = 'synced';
      await txn.insert(DbTables.classes, classMap, conflictAlgorithm: ConflictAlgorithm.replace);

      // Cache students as class_participants (v18 - no user detail columns)
      for (final participant in classDetail.students) {
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
