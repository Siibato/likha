import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import '../class_local_datasource_base.dart';

mixin ClassQueryMixin on ClassLocalDataSourceBase {
  @override
  Future<List<ClassModel>> getCachedClasses({String? teacherId}) async {
    try {
      final db = await localDatabase.database;
      final results = teacherId != null
          ? await db.query(
              'classes',
              where: 'teacher_id = ? OR teacher_id = ?',
              whereArgs: [teacherId, ''],
              orderBy: 'title ASC',
            )
          : await db.query('classes', orderBy: 'title ASC');
      if (results.isEmpty) throw CacheException('No cached classes found');
      return results.map(ClassModel.fromMap).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<ClassDetailModel> getCachedClassDetail(String classId) async {
    try {
      final db = await localDatabase.database;
      final classResult = await db.query('classes', where: 'id = ?', whereArgs: [classId]);
      if (classResult.isEmpty) throw CacheException('Class $classId not cached');

      final enrollmentResults = await db.query(
        'class_enrollments',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'username ASC',
      );

      final classMap = classResult.first;
      return ClassDetailModel(
        id: classMap['id'] as String,
        title: classMap['title'] as String,
        description: classMap['description'] as String?,
        teacherId: classMap['teacher_id'] as String,
        isArchived: (classMap['is_archived'] as int?) == 1,
        students: _mapEnrollments(enrollmentResults),
        createdAt: DateTime.parse(classMap['created_at'] as String),
        updatedAt: DateTime.parse(classMap['updated_at'] as String),
      );
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<ClassDetailModel?> buildClassDetailFromEnrollments(String classId) async {
    try {
      final db = await localDatabase.database;
      final classResults = await db.query(
        'classes',
        where: 'id = ?',
        whereArgs: [classId],
        limit: 1,
      );
      if (classResults.isEmpty) return null;

      final enrollmentResults = await db.query(
        'class_enrollments',
        where: 'class_id = ?',
        whereArgs: [classId],
        orderBy: 'username ASC',
      );

      final classMap = classResults.first;
      return ClassDetailModel(
        id: classMap['id'] as String,
        title: classMap['title'] as String,
        description: classMap['description'] as String?,
        teacherId: classMap['teacher_id'] as String,
        isArchived: (classMap['is_archived'] as int?) == 1,
        students: _mapEnrollments(enrollmentResults),
        createdAt: DateTime.parse(classMap['created_at'] as String),
        updatedAt: DateTime.parse(classMap['updated_at'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  List<EnrollmentModel> _mapEnrollments(List<Map<String, Object?>> rows) {
    return rows.map((e) => EnrollmentModel(
      id: e['id'] as String,
      student: UserModel(
        id: e['student_id'] as String,
        username: e['username'] as String,
        fullName: e['full_name'] as String,
        role: e['role'] as String,
        accountStatus: e['account_status'] as String,
        isActive: (e['is_active'] as int?) == 1,
        createdAt: DateTime.parse(e['enrolled_at'] as String),
      ),
      enrolledAt: DateTime.parse(e['enrolled_at'] as String),
    )).toList();
  }
}