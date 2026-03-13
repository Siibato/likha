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
          map['cached_at'] = DateTime.now().toIso8601String();
          map['needs_sync'] = 0;
          await txn.insert('classes', map, conflictAlgorithm: ConflictAlgorithm.replace);
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
        'class_participants',
        {
          'id': syntheticId,
          'class_id': classId,
          'user_id': userId,
          'joined_at': joinedAt.toIso8601String(),
          'updated_at': now.toIso8601String(),
          'removed_at': null,
          'cached_at': now.toIso8601String(),
          'needs_sync': 0, 
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
          studentCount: classDetail.students.length,
          createdAt: classDetail.createdAt,
          updatedAt: classDetail.updatedAt,
        ).toMap();
        classMap['cached_at'] = DateTime.now().toIso8601String();
        classMap['needs_sync'] = 0;
        await txn.insert('classes', classMap, conflictAlgorithm: ConflictAlgorithm.replace);

        // Cache students as class_participants (v18 - no user detail columns)
        for (final enrollment in classDetail.students) {
          await txn.insert(
            'class_participants',
            {
              'id': enrollment.id,
              'class_id': classDetail.id,
              'user_id': enrollment.student.id,
              'joined_at': enrollment.joinedAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'removed_at': null,
              'cached_at': DateTime.now().toIso8601String(),
              'needs_sync': 0,
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
      await db.delete('class_participants');
      await db.delete('classes');
    } catch (e) {
      throw CacheException('Failed to clear class cache: $e');
    }
  }
}
