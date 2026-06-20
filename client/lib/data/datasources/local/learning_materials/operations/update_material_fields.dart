import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';

Future<void> updateMaterialFields(
  LocalDatabase localDatabase,
  String materialId,
  Map<String, dynamic> data, {
  Transaction? txn,
}) async {
  final executor = txn ?? await localDatabase.database;
  await executor.update(
    DbTables.learningMaterials,
    {
      ...data,
      CommonCols.updatedAt: DateTime.now().toIso8601String(),
      CommonCols.syncStatus: 'pending',
      CommonCols.cachedAt: DateTime.now().toIso8601String(),
    },
    where: '${CommonCols.id} = ?',
    whereArgs: [materialId],
  );
}
