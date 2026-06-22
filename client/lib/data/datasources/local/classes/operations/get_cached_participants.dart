import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> getCachedParticipants(
  LocalDatabase localDatabase,
  String classId,
) async {
  try {
    final db = await localDatabase.database;
    // v18: Join with users table to get student details
    final rows = await db.rawQuery('''
      SELECT cp.id, cp.class_id, cp.user_id, cp.joined_at,
             u.username, u.first_name, u.last_name, u.role, u.account_status, u.activated_at, u.created_at
      FROM ${DbTables.classParticipants} cp
      JOIN ${DbTables.users} u ON u.id = cp.user_id
      WHERE cp.class_id = ? AND cp.removed_at IS NULL
      ORDER BY u.last_name ASC, u.first_name ASC
    ''', [classId]);

    return rows.map((row) {
      final accountStatus = row['account_status'] as String?;
      final isActive = accountStatus != null &&
          accountStatus != 'locked' &&
          accountStatus != 'deactivated';
      return UserModel(
        id: row['user_id'] as String,
        username: row['username'] as String? ?? '',
        firstName: row['first_name'] as String? ?? '',
        lastName: row['last_name'] as String? ?? '',
        role: row['role'] as String? ?? '',
        accountStatus: accountStatus ?? 'active',
        isActive: isActive,
        activatedAt: row['activated_at'] != null
            ? DateTime.parse(row['activated_at'] as String)
            : null,
        createdAt: row['created_at'] != null
            ? DateTime.parse(row['created_at'] as String)
            : DateTime.parse(row['joined_at'] as String),
      );
    }).toList();
  } catch (e) {
    throw CacheException('Failed to get participants: $e');
  }
}
