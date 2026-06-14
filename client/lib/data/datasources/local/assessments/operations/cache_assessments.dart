import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';

Future<void> cacheAssessments(
  LocalDatabase localDatabase,
  List<AssessmentModel> assessments,
) async {
  try {
    final db = await localDatabase.database;
    await db.transaction((txn) async {
      for (final assessment in assessments) {
        final map = assessment.toMap();
        map[CommonCols.cachedAt] = DateTime.now().toIso8601String();
        map[CommonCols.syncStatus] = 'synced';
        final assessmentId = map[CommonCols.id] as String;
        final updated = await txn.update(DbTables.assessments, map, where: '${CommonCols.id} = ?', whereArgs: [assessmentId]);
        if (updated == 0) {
          await txn.insert(DbTables.assessments, map);
        }
      }
    });
  } catch (e) {
    throw CacheException('Failed to cache assessments: $e');
  }
}
