import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> softDeleteFile(
  LocalDatabase localDatabase,
  String fileId, {
  Transaction? txn,
}) async {
  final executor = txn ?? await localDatabase.database;
  await executor.update(
    DbTables.materialFiles,
    {
      CommonCols.deletedAt: DateTime.now().toIso8601String(),
    },
    where: '${CommonCols.id} = ?',
    whereArgs: [fileId],
  );
}
