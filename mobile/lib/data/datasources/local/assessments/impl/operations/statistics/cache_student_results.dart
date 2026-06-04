import 'dart:convert';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:sqflite/sqflite.dart';

Future<void> cacheStudentResultsOp(
  LocalDatabase localDatabase,
  StudentResultModel result,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      DbTables.studentResultsCache,
      {
        StudentResultsCacheCols.submissionId: result.submissionId,
        StudentResultsCacheCols.resultsJson: jsonEncode(result.toJson()),
        CommonCols.cachedAt: now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    CacheLogger.instance.warn('Failed to cache student results', e);
  }
}
