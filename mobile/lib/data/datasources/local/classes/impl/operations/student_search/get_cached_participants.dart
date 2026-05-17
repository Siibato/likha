import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> getCachedParticipantsOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String classId,
) async {
  try {
    final db = await localDatabase.database;
    // v18: Join with users table to get student details
    final rows = await db.rawQuery('''
      SELECT cp.id, cp.class_id, cp.user_id, cp.joined_at,
             u.username, u.full_name, u.role, u.account_status, u.activated_at, u.created_at
      FROM ${DbTables.classParticipants} cp
      JOIN ${DbTables.users} u ON u.id = cp.user_id
      WHERE cp.class_id = ? AND cp.removed_at IS NULL
      ORDER BY u.full_name ASC
    ''', [classId]);

    return rows.map((row) {
      final decryptedRow = _decryptUserRow(enc, row);
      final accountStatus = decryptedRow['account_status'] as String?;
      final isActive = accountStatus != null &&
          accountStatus != 'locked' &&
          accountStatus != 'deactivated';

      return UserModel(
        id: decryptedRow['user_id'] as String,
        username: decryptedRow['username'] as String? ?? '',
        fullName: decryptedRow['full_name'] as String? ?? '',
        role: decryptedRow['role'] as String? ?? '',
        accountStatus: accountStatus ?? 'active',
        isActive: isActive,
        activatedAt: decryptedRow['activated_at'] != null
            ? DateTime.parse(decryptedRow['activated_at'] as String)
            : null,
        createdAt: decryptedRow['created_at'] != null
            ? DateTime.parse(decryptedRow['created_at'] as String)
            : DateTime.parse(decryptedRow['joined_at'] as String),
      );
    }).toList();
  } catch (e) {
    throw CacheException('Failed to get participants: $e');
  }
}

Map<String, dynamic> _decryptUserRow(EncryptionService enc, Map<String, dynamic> row) {
  final m = Map<String, dynamic>.from(row);
  m['username'] = enc.decryptField(row['username'] as String?);
  m['full_name'] = enc.decryptField(row['full_name'] as String?);
  return m;
}
