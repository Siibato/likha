import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> softDeleteMaterial(
  LocalDatabase localDatabase,
  String materialId, {
  Transaction? txn,
}) async {
  final executor = txn ?? await localDatabase.database;
  final now = DateTime.now().toIso8601String();
  await executor.update(
    DbTables.learningMaterials,
    {
      CommonCols.deletedAt: now,
      CommonCols.updatedAt: now,
      CommonCols.syncStatus: 'pending',
      CommonCols.cachedAt: now,
    },
    where: '${CommonCols.id} = ?',
    whereArgs: [materialId],
  );
}
