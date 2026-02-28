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
        final classMap = ClassModel(
          id: classDetail.id,
          title: classDetail.title,
          description: classDetail.description,
          teacherId: classDetail.teacherId,
          teacherUsername: '',
          teacherFullName: '',
          isArchived: classDetail.isArchived,
          studentCount: classDetail.students.length,
          createdAt: classDetail.createdAt,
          updatedAt: classDetail.updatedAt,
        ).toMap();
        classMap['cached_at'] = DateTime.now().toIso8601String();
        classMap['sync_status'] = 'synced';
        classMap['is_offline_mutation'] = 0;
        await txn.insert('classes', classMap, conflictAlgorithm: ConflictAlgorithm.replace);

        for (final enrollment in classDetail.students) {
          await txn.insert(
            'class_enrollments',
            {
              'id': enrollment.id,
              'class_id': classDetail.id,
              'student_id': enrollment.student.id,
              'username': enrollment.student.username,
              'full_name': enrollment.student.fullName,
              'role': enrollment.student.role,
              'account_status': enrollment.student.accountStatus,
              'is_active': enrollment.student.isActive ? 1 : 0,
              'enrolled_at': enrollment.enrolledAt.toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              'cached_at': DateTime.now().toIso8601String(),
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
      await db.delete('class_enrollments');
      await db.delete('classes');
    } catch (e) {
      throw CacheException('Failed to clear class cache: $e');
    }
  }
}