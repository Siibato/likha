import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> softDeleteFile(
  LocalDatabase localDatabase,
  String fileId, {
  Transaction? txn,
}) async {
  final executor = txn ?? await localDatabase.database;
  await executor.delete(
    DbTables.materialFiles,
    where: '${CommonCols.id} = ?',
    whereArgs: [fileId],
  );
}
