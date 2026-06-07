import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:sqflite/sqflite.dart';

Future<void> cacheAccountsOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  List<UserModel> accounts,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final account in accounts) {
        final map = account.toMap();
        map['cached_at'] = DateTime.now().toIso8601String();
        map['needs_sync'] = 0;
        map['full_name'] = enc.encryptField(map['full_name'] as String?);
        map['username'] = enc.encryptField(map['username'] as String?);
        await txn.insert('users', map, conflictAlgorithm: ConflictAlgorithm.replace);
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache accounts: $e');
  }
}
