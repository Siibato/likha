import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> getCachedAccountsOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.users,
      where: '${CommonCols.deletedAt} IS NULL',
      orderBy: '${UsersCols.username} ASC',
    );
    if (results.isEmpty) return [];
    return results.map((r) => UserModel.fromMap(_decryptUserRow(enc, r))).toList();
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}

Map<String, dynamic> _decryptUserRow(EncryptionService enc, Map<String, dynamic> row) {
  final m = Map<String, dynamic>.from(row);
  m['full_name'] = enc.decryptField(row['full_name'] as String?);
  m['username'] = enc.decryptField(row['username'] as String?);
  return m;
}
