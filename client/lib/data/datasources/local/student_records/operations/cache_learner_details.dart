import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/sync/sync_queue.dart';
import 'package:likha/data/models/student_records/learner_details_model.dart';

Future<void> cacheLearnerDetails(
  LocalDatabase localDatabase,
  LearnerDetailsModel model, {
  Transaction? txn,
}) async {
  try {
    final map = model.toJson();
    map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
    map[CommonCols.syncStatus] = 'synced';

    if (txn != null) {
      final updated = await txn.update(
        DbTables.learnerDetails,
        map,
        where: '${LearnerDetailsCols.userId} = ?',
        whereArgs: [map[LearnerDetailsCols.userId]],
      );
      if (updated == 0) {
        await txn.insert(DbTables.learnerDetails, map);
      }
    } else {
      final db = await localDatabase.database;
      final updated = await db.update(
        DbTables.learnerDetails,
        map,
        where: '${LearnerDetailsCols.userId} = ?',
        whereArgs: [map[LearnerDetailsCols.userId]],
      );
      if (updated == 0) {
        await db.insert(DbTables.learnerDetails, map);
      }
    }
  } catch (e) {
    throw CacheException('Failed to cache learner details: $e');
  }
}
