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

      // v18: teacher_id column removed from classes table
      // If teacherId is provided, delegate to getCachedClassesForUser instead
      if (teacherId != null) {
        return getCachedClassesForUser(teacherId);
      }

      final results = await db.query(
        'classes',
        where: 'deleted_at IS NULL',
        orderBy: 'title ASC',
      );

      if (results.isEmpty) {
        return [];
      }

      final models = results.map(ClassModel.fromMap).toList();
      return models;
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<List<ClassModel>> getCachedClassesForUser(String userId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.rawQuery('''
        SELECT DISTINCT c.*
        FROM classes c
        WHERE c.teacher_id = ? AND c.deleted_at IS NULL
        UNION
        SELECT DISTINCT c.*
        FROM classes c
        JOIN class_participants cp ON c.id = cp.class_id
        WHERE cp.user_id = ? AND cp.removed_at IS NULL AND c.deleted_at IS NULL
        ORDER BY title ASC
      ''', [userId, userId]); // userId bound twice: once per UNION leg

      if (results.isEmpty) {
        return [];
      }
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
      final classResult = await db.query('classes', where: 'id = ? AND deleted_at IS NULL', whereArgs: [classId]);
      if (classResult.isEmpty) throw CacheException('Class $classId not cached');

      // v18: Join to get student details from users table
      final participantResults = await db.rawQuery('''
        SELECT cp.id, cp.class_id, cp.user_id, cp.joined_at,
               u.username, u.full_name, u.role, u.account_status, u.created_at
        FROM class_participants cp
        JOIN users u ON u.id = cp.user_id
        WHERE cp.class_id = ? AND cp.removed_at IS NULL
        ORDER BY u.full_name ASC
      ''', [classId]);

      final classMap = classResult.first;
      return ClassDetailModel(
        id: classMap['id'] as String,
        title: classMap['title'] as String,
        description: classMap['description'] as String?,
        teacherId: classMap['teacher_id'] as String? ?? '',
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
        where: 'id = ? AND deleted_at IS NULL',
        whereArgs: [classId],
        limit: 1,
      );
      if (classResults.isEmpty) return null;

      // v18: Join to get student details from users table
      final participantResults = await db.rawQuery('''
        SELECT cp.id, cp.class_id, cp.user_id, cp.joined_at,
               u.username, u.full_name, u.role, u.account_status, u.created_at
        FROM class_participants cp
        JOIN users u ON u.id = cp.user_id
        WHERE cp.class_id = ? AND cp.removed_at IS NULL
        ORDER BY u.full_name ASC
      ''', [classId]);

      final classMap = classResults.first;
      return ClassDetailModel(
        id: classMap['id'] as String,
        title: classMap['title'] as String,
        description: classMap['description'] as String?,
        teacherId: classMap['teacher_id'] as String? ?? '',
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
          username: e['username'] as String? ?? '',
          fullName: e['full_name'] as String? ?? '',
          role: e['role'] as String? ?? '',
          accountStatus: accountStatus ?? 'active',
          isActive: isActive,
          createdAt: e['created_at'] != null
              ? DateTime.parse(e['created_at'] as String)
              : DateTime.parse(e['joined_at'] as String),
        ),
        joinedAt: DateTime.parse(e['joined_at'] as String),
      );
    }).toList();
  }
}
