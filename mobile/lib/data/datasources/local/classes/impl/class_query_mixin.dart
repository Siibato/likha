import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';
import 'package:likha/data/models/classes/class_model.dart';
import '../class_local_datasource_base.dart';

mixin ClassQueryMixin on ClassLocalDataSourceBase {
  Map<String, dynamic> _decryptClassRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    m['teacher_full_name'] = enc.decryptField(row['teacher_full_name'] as String?);
    m['teacher_username'] = enc.decryptField(row['teacher_username'] as String?);
    return m;
  }

  Map<String, dynamic> _decryptUserRow(Map<String, dynamic> row) {
    final m = Map<String, dynamic>.from(row);
    m['username'] = enc.decryptField(row['username'] as String?);
    m['full_name'] = enc.decryptField(row['full_name'] as String?);
    return m;
  }
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
        DbTables.classes,
        where: '${CommonCols.deletedAt} IS NULL',
        orderBy: '${ClassesCols.title} ASC',
      );

      if (results.isEmpty) {
        return [];
      }

      final models = results.map((r) => ClassModel.fromMap(_decryptClassRow(r))).toList();
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
        FROM ${DbTables.classes} c
        WHERE c.teacher_id = ? AND c.deleted_at IS NULL
        UNION
        SELECT DISTINCT c.*
        FROM ${DbTables.classes} c
        JOIN ${DbTables.classParticipants} cp ON c.id = cp.class_id
        WHERE cp.user_id = ? AND cp.removed_at IS NULL AND c.deleted_at IS NULL
        ORDER BY title ASC
      ''', [userId, userId]); // userId bound twice: once per UNION leg

      if (results.isEmpty) {
        return [];
      }
      return results.map((r) => ClassModel.fromMap(_decryptClassRow(r))).toList();
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<ClassDetailModel> getCachedClassDetail(String classId) async {
    try {
      final db = await localDatabase.database;
      final classResult = await db.query(DbTables.classes, where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL', whereArgs: [classId]);
      if (classResult.isEmpty) throw CacheException('Class $classId not cached');

      // v18: Join to get student details from users table
      final participantResults = await db.rawQuery('''
        SELECT cp.id, cp.class_id, cp.user_id, cp.joined_at,
               u.username, u.full_name, u.role, u.account_status, u.created_at
        FROM ${DbTables.classParticipants} cp
        JOIN ${DbTables.users} u ON u.id = cp.user_id
        WHERE cp.class_id = ? AND cp.removed_at IS NULL
        ORDER BY u.full_name ASC
      ''', [classId]);

      final classMap = classResult.first;
      return ClassDetailModel(
        id: classMap[CommonCols.id] as String,
        title: classMap[ClassesCols.title] as String,
        description: classMap[ClassesCols.description] as String?,
        teacherId: classMap[ClassesCols.teacherId] as String? ?? '',
        isArchived: (classMap[ClassesCols.isArchived] as int?) == 1,
        isAdvisory: (classMap[ClassesCols.isAdvisory] as int?) == 1,
        students: _mapParticipants(participantResults),
        createdAt: DateTime.parse(classMap[CommonCols.createdAt] as String),
        updatedAt: DateTime.parse(classMap[CommonCols.updatedAt] as String),
      );
    } catch (e) {
      if (e is CacheException) rethrow;
      throw CacheException(e.toString());
    }
  }

  @override
  Future<ClassDetailModel?> buildClassDetailFromParticipants(String classId) async {
    try {
      final db = await localDatabase.database;
      final classResults = await db.query(
        DbTables.classes,
        where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL',
        whereArgs: [classId],
        limit: 1,
      );
      if (classResults.isEmpty) return null;

      // v18: Join to get student details from users table
      final participantResults = await db.rawQuery('''
        SELECT cp.id, cp.class_id, cp.user_id, cp.joined_at,
               u.username, u.full_name, u.role, u.account_status, u.created_at
        FROM ${DbTables.classParticipants} cp
        JOIN ${DbTables.users} u ON u.id = cp.user_id
        WHERE cp.class_id = ? AND cp.removed_at IS NULL
        ORDER BY u.full_name ASC
      ''', [classId]);

      final classMap = classResults.first;
      return ClassDetailModel(
        id: classMap[CommonCols.id] as String,
        title: classMap[ClassesCols.title] as String,
        description: classMap[ClassesCols.description] as String?,
        teacherId: classMap[ClassesCols.teacherId] as String? ?? '',
        isArchived: (classMap[ClassesCols.isArchived] as int?) == 1,
        isAdvisory: (classMap[ClassesCols.isAdvisory] as int?) == 1,
        students: _mapParticipants(participantResults),
        createdAt: DateTime.parse(classMap[CommonCols.createdAt] as String),
        updatedAt: DateTime.parse(classMap[CommonCols.updatedAt] as String),
      );
    } catch (_) {
      return null;
    }
  }

  List<ParticipantModel> _mapParticipants(List<Map<String, Object?>> rows) {
    return rows.map((e) {
      final accountStatus = e['account_status'] as String?;
      final isActive = accountStatus != null &&
          accountStatus != 'locked' &&
          accountStatus != 'deactivated';

      final decryptedRow = _decryptUserRow(e);
      return ParticipantModel(
        id: decryptedRow['id'] as String,
        student: UserModel(
          id: decryptedRow['user_id'] as String,
          username: decryptedRow['username'] as String? ?? '',
          fullName: decryptedRow['full_name'] as String? ?? '',
          role: decryptedRow['role'] as String? ?? '',
          accountStatus: accountStatus ?? 'active',
          isActive: isActive,
          createdAt: decryptedRow['created_at'] != null
              ? DateTime.parse(decryptedRow['created_at'] as String)
              : DateTime.parse(decryptedRow['joined_at'] as String),
        ),
        joinedAt: DateTime.parse(decryptedRow['joined_at'] as String),
      );
    }).toList();
  }
}
