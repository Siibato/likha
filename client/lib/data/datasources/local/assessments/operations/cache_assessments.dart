import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheAssessments(
  LocalDatabase localDatabase,
  List<AssessmentModel> assessments, {
  bool isServerConfirmed = true,
  Transaction? txn,
}) async {
  try {
    Future<void> doUpsert(Transaction t) async {
      for (final assessment in assessments) {
        final map = assessment.toMap();
        map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
        if (isServerConfirmed) {
          map[CommonCols.syncStatus] = 'synced';
        }
        final assessmentId = map[CommonCols.id] as String;
        final updated = await t.update(DbTables.assessments, map, where: '${CommonCols.id} = ?', whereArgs: [assessmentId]);
        if (updated == 0) {
          await t.insert(DbTables.assessments, map);
        }
      }
    }

    if (txn != null) {
      await doUpsert(txn);
    } else {
      final db = await localDatabase.database;
      await db.transaction((innerTxn) async {
        await doUpsert(innerTxn);
      });
    }
  } catch (e) {
    throw CacheException('Failed to cache assessments: $e');
  }
}
