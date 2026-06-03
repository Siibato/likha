import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<UserModel> getCachedUserOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String userId,
) async {
  try {
    final db = await localDatabase.database;
    final result = await db.query(
      DbTables.users,
      where: '${CommonCols.id} = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (result.isEmpty) throw CacheException('User not found in cache: $userId');
    return UserModel.fromMap(_decryptUserRow(enc, result.first));
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException('Failed to get cached user: $e');
  }
}

Map<String, dynamic> _decryptUserRow(EncryptionService enc, Map<String, dynamic> row) {
  final m = Map<String, dynamic>.from(row);
  m['full_name'] = enc.decryptField(row['full_name'] as String?);
  m['username'] = enc.decryptField(row['username'] as String?);
  return m;
}
