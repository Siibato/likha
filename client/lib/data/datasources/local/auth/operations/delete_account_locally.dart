import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> deleteAccountLocally(
  LocalDatabase localDatabase,
  String userId, {
  Transaction? txn,
}) async {
  try {
    if (txn != null) {
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    } else {
      final db = await localDatabase.database;
      await db.delete('users', where: 'id = ?', whereArgs: [userId]);
    }
  } catch (e) {
    throw CacheException('Failed to delete account locally: $e');
  }
}
