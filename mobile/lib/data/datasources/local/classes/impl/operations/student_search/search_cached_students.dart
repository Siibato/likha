import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/user_model.dart';

Future<List<UserModel>> searchCachedStudentsOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  String query,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.users,
      where: '(${UsersCols.username} LIKE ? OR ${UsersCols.fullName} LIKE ?) AND ${UsersCols.role} = ?',
      whereArgs: ['%$query%', '%$query%', 'student'],
      orderBy: '${UsersCols.fullName} ASC',
    );
    return results.map((r) => UserModel.fromMap(_decryptUserRow(enc, r))).toList();
  } catch (e) {
    throw CacheException('Failed to search cached students: $e');
  }
}

Map<String, dynamic> _decryptUserRow(EncryptionService enc, Map<String, dynamic> row) {
  final m = Map<String, dynamic>.from(row);
  m['username'] = enc.decryptField(row['username'] as String?);
  m['full_name'] = enc.decryptField(row['full_name'] as String?);
  return m;
}
