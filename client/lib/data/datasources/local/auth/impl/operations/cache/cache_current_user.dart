import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/security/encryption_service.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:sqflite/sqflite.dart';

Future<void> cacheCurrentUserOp(
  LocalDatabase localDatabase,
  EncryptionService enc,
  UserModel user,
) async {
  try {
    final db = await localDatabase.database;
    final map = user.toMap();
    map['cached_at'] = DateTime.now().toIso8601String();
    map['needs_sync'] = 0;
    map['full_name'] = enc.encryptField(map['full_name'] as String?);
    map['username'] = enc.encryptField(map['username'] as String?);
    await db.insert('users', map, conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e) {
    throw CacheException('Failed to cache user: $e');
  }
}
