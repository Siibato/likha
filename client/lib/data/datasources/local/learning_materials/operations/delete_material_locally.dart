import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:uuid/uuid.dart';

Future<void> deleteMaterialLocally(
  LocalDatabase localDatabase,
  SyncQueue syncQueue,
  String materialId, {
  Transaction? txn,
}) async {
  try {
    final executor = txn ?? await localDatabase.database;
    final now = DateTime.now();
    await executor.update(
      DbTables.learningMaterials,
      {
        CommonCols.deletedAt: now.toIso8601String(),
        CommonCols.syncStatus: 'pending',
        CommonCols.updatedAt: now.toIso8601String(),
      },
      where: '${CommonCols.id} = ?',
      whereArgs: [materialId],
    );
  } catch (e) {
    throw CacheException('Failed to delete material locally: $e');
  }
}
