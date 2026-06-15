import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/auth/user_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheCurrentUserOp(
  LocalDatabase localDatabase,
  UserModel user,
) async {
  try {
    final db = await localDatabase.database;
    final map = user.toMap();
    map['cached_at'] = DateTime.now().toIso8601String();
    map['needs_sync'] = 0;
    await db.insert('users', map, conflictAlgorithm: ConflictAlgorithm.replace);
  } catch (e) {
    throw CacheException('Failed to cache user: $e');
  }
}
