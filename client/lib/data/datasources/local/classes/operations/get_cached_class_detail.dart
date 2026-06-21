import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';

Future<ClassDetailModel> getCachedClassDetail(
  LocalDatabase localDatabase,
  String classId,
) async {
  try {
    final db = await localDatabase.database;
    final classResult = await db.query(DbTables.classes, where: '${CommonCols.id} = ? AND ${CommonCols.deletedAt} IS NULL', whereArgs: [classId]);
    if (classResult.isEmpty) throw CacheException('Class $classId not cached');

    // v18: Join to get student details from users table
    final participantResults = await db.rawQuery('''
      SELECT cp.id, cp.class_id, cp.user_id, cp.joined_at,
             u.username, u.first_name, u.last_name, u.role, u.account_status, u.created_at
      FROM ${DbTables.classParticipants} cp
      JOIN ${DbTables.users} u ON u.id = cp.user_id
      WHERE cp.class_id = ? AND cp.removed_at IS NULL
      ORDER BY u.first_name ASC
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

List<ParticipantModel> _mapParticipants(List<Map<String, Object?>> rows) {
  return rows.map((e) {
    final accountStatus = e['account_status'] as String?;
    final isActive = accountStatus != null &&
        accountStatus != 'locked' &&
        accountStatus != 'deactivated';
    return ParticipantModel(
      id: e['id'] as String,
      student: UserModel(
        id: e['user_id'] as String,
        username: e['username'] as String? ?? '',
        firstName: e['first_name'] as String? ?? '',
        lastName: e['last_name'] as String? ?? '',
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
