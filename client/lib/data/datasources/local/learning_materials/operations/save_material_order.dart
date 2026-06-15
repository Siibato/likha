import 'package:sqflite_sqlcipher/sqflite.dart';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> saveMaterialOrder(
  LocalDatabase localDatabase,
  String classId,
  List<String> materialIds, {
  Transaction? txn,
}) async {
  final executor = txn ?? await localDatabase.database;
  final now = DateTime.now().toIso8601String();
  final batch = executor.batch();
  for (int i = 0; i < materialIds.length; i++) {
    batch.update(
      DbTables.learningMaterials,
      {
        LearningMaterialsCols.orderIndex: i,
        CommonCols.updatedAt: now,
        CommonCols.syncStatus: SyncStatus.pending.dbValue,
        CommonCols.cachedAt: now,
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [materialIds[i]],
    );
  }
  await batch.commit(noResult: true);
}
