import 'dart:convert';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> cacheStatisticsOp(
  LocalDatabase localDatabase,
  AssessmentStatisticsModel statistics,
) async {
  try {
    final db = await localDatabase.database;
    final now = DateTime.now().toIso8601String();
    await db.insert(
      DbTables.assessmentStatisticsCache,
      {
        AssessmentStatisticsCacheCols.assessmentId: statistics.assessmentId,
        AssessmentStatisticsCacheCols.statisticsJson: jsonEncode(statistics.toJson()),
        CommonCols.cachedAt: now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  } catch (e) {
    CacheLogger.instance.warn('Failed to cache assessment statistics', e);
  }
}
