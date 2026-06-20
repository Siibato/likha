import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';

Future<void> deleteMaterialFileLocally(
  LocalDatabase localDatabase,
  String fileId, {
  Transaction? txn,
}) async {
  try {
    final executor = txn ?? await localDatabase.database;
    await executor.update(
      DbTables.materialFiles,
      {CommonCols.deletedAt: DateTime.now().toIso8601String()},
      where: '${CommonCols.id} = ?',
      whereArgs: [fileId],
    );
  } catch (e) {
    throw CacheException('Failed to delete material file locally: $e');
  }
}
