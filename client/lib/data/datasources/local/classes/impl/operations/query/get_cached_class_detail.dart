import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:likha/data/models/classes/class_detail_model.dart';

Future<ClassDetailModel> getCachedClassDetailOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String classId,
) async {
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
      students: _mapParticipants(enc, participantResults),
      createdAt: DateTime.parse(classMap[CommonCols.createdAt] as String),
      updatedAt: DateTime.parse(classMap[CommonCols.updatedAt] as String),
    );
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}

List<ParticipantModel> _mapParticipants(EncryptionService enc, List<Map<String, Object?>> rows) {
  return rows.map((e) {
    final accountStatus = e['account_status'] as String?;
    final isActive = accountStatus != null &&
        accountStatus != 'locked' &&
        accountStatus != 'deactivated';

    final decryptedRow = _decryptUserRow(enc, e);
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

Map<String, dynamic> _decryptUserRow(EncryptionService enc, Map<String, dynamic> row) {
  final m = Map<String, dynamic>.from(row);
  m['username'] = enc.decryptField(row['username'] as String?);
  m['full_name'] = enc.decryptField(row['full_name'] as String?);
  return m;
}
