import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';

Future<void> softDeleteSubmissionFile(
  LocalDatabase localDatabase,
  String fileId, {
  Transaction? txn,
}) async {
  try {
    final db = await localDatabase.database;
    final executor = txn ?? db;
    await executor.delete(
      DbTables.submissionFiles,
      where: '${CommonCols.id} = ?',
      whereArgs: [fileId],
    );
  } catch (e) {
    throw CacheException('Failed to delete submission file: $e');
  }
}
