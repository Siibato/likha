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
          map['sync_status'] = 'synced';
          map['is_offline_mutation'] = 0;
          await txn.insert('classes', map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });
    } catch (e) {
      throw CacheException('Failed to cache classes: $e');
    }
  }

  @override
  Future<void> cacheClassDetail(ClassDetailModel classDetail) async {
    try {
      final db = await localDatabase.database;
      await db.transaction((txn) async {
        final existing = await txn.query(
          'classes',
          columns: ['teacher_username', 'teacher_full_name'],
          where: 'id = ?',
          whereArgs: [classDetail.id],
          limit: 1,
        );
        final teacherUsername = existing.isNotEmpty
            ? (existing.first['teacher_username'] as String? ?? '')
            : '';
        final teacherFullName = existing.isNotEmpty
            ? (existing.first['teacher_full_name'] as String? ?? '')
            : '';

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
        classMap['sync_status'] = 'synced';
        classMap['is_offline_mutation'] = 0;
        await txn.insert('classes', classMap, conflictAlgorithm: ConflictAlgorithm.replace);

        // Cache students as class_participants with role='student'
        for (final enrollment in classDetail.students) {
          await txn.insert(
            'class_participants',
            {
              'id': enrollment.id,
              'local_id': enrollment.id,
              'class_id': classDetail.id,
              'user_id': enrollment.student.id,
              'username': enrollment.student.username,
              'full_name': enrollment.student.fullName,
              'role': 'student',
              'account_status': enrollment.student.accountStatus,
              'joined_at': enrollment.joinedAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'removed_at': null,
              'cached_at': DateTime.now().toIso8601String(),
              'sync_status': 'synced',
              'is_offline_mutation': 0,
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