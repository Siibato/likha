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
              where: 'teacher_id = ? AND deleted_at IS NULL',
              whereArgs: [teacherId],
              orderBy: 'title ASC',
            )
          : await db.query(
              'classes',
              where: 'deleted_at IS NULL',
              orderBy: 'title ASC',
            );

      if (results.isEmpty) {
        throw CacheException('No cached classes found');
      }

      final models = results.map(ClassModel.fromMap).toList();
      return models;
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

      final participantResults = await db.query(
        'class_participants',
        where: 'class_id = ? AND role = ? AND removed_at IS NULL',
        whereArgs: [classId, 'student'],
        orderBy: 'username ASC',
      );

      final classMap = classResult.first;
      return ClassDetailModel(
        id: classMap['id'] as String,
        title: classMap['title'] as String,
        description: classMap['description'] as String?,
        teacherId: classMap['teacher_id'] as String,
        isArchived: (classMap['is_archived'] as int?) == 1,
        students: _mapEnrollments(participantResults),
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

      final participantResults = await db.query(
        'class_participants',
        where: 'class_id = ? AND role = ? AND removed_at IS NULL',
        whereArgs: [classId, 'student'],
        orderBy: 'username ASC',
      );

      final classMap = classResults.first;
      return ClassDetailModel(
        id: classMap['id'] as String,
        title: classMap['title'] as String,
        description: classMap['description'] as String?,
        teacherId: classMap['teacher_id'] as String,
        isArchived: (classMap['is_archived'] as int?) == 1,
        students: _mapEnrollments(participantResults),
        createdAt: DateTime.parse(classMap['created_at'] as String),
        updatedAt: DateTime.parse(classMap['updated_at'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  List<EnrollmentModel> _mapEnrollments(List<Map<String, Object?>> rows) {
    return rows.map((e) {
      final accountStatus = e['account_status'] as String?;
      final isActive = accountStatus != null &&
          accountStatus != 'locked' &&
          accountStatus != 'deactivated';

      return EnrollmentModel(
        id: e['id'] as String,
        student: UserModel(
          id: e['user_id'] as String,
          username: e['username'] as String,
          fullName: e['full_name'] as String,
          role: e['role'] as String,
          accountStatus: accountStatus ?? 'active',
          isActive: isActive,
          createdAt: DateTime.parse(e['joined_at'] as String),
        ),
        joinedAt: DateTime.parse(e['joined_at'] as String),
      );
    }).toList();
  }
}