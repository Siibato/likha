import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import 'package:sqflite/sqflite.dart';
import '../class_local_datasource_base.dart';

mixin ClassCacheMixin on ClassLocalDataSourceBase {
  @override
  Future<void> cacheClasses(List<ClassModel> classes) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        for (final classModel in classes) {
          final map = classModel.toMap();
          map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
          map[CommonCols.needsSync] = 0;
          await txn.insert(DbTables.classes, map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache classes: $e');
    }
  }

  @override
  Future<void> cacheStudentParticipation({
    required String classId,
    required String userId,
    required DateTime joinedAt,
  }) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now();
      final syntheticId = 'local_${classId}_$userId';
      await db.insert(
        DbTables.classParticipants,
        {
          CommonCols.id: syntheticId,
          ClassParticipantsCols.classId: classId,
          ClassParticipantsCols.userId: userId,
          ClassParticipantsCols.joinedAt: joinedAt.toIso8601String(),
          CommonCols.updatedAt: now.toIso8601String(),
          ClassParticipantsCols.removedAt: null,
          CommonCols.cachedAt: now.toIso8601String(),
          CommonCols.needsSync: 0,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      throw CacheException('Failed to cache student participation: $e');
    }
  }

  @override
  Future<void> cacheClassDetail(ClassDetailModel classDetail) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        // Look up teacher info from users table
        String teacherUsername = '';
        String teacherFullName = '';
        if (classDetail.teacherId.isNotEmpty) {
          final teacherRows = await txn.query(
            'users',
            columns: ['username', 'full_name'],
            where: 'id = ?',
            whereArgs: [classDetail.teacherId],
            limit: 1,
          );
          if (teacherRows.isNotEmpty) {
            teacherUsername = teacherRows.first['username'] as String? ?? '';
            teacherFullName = teacherRows.first['full_name'] as String? ?? '';
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
        classMap[CommonCols.needsSync] = 0;
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
              CommonCols.needsSync: 0,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache class detail: $e');
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      final db = await localDatabase.database;
      await db.delete(DbTables.classParticipants);
      await db.delete(DbTables.classes);
    } catch (e) {
      throw CacheException('Failed to clear class cache: $e');
    }
  }
}
