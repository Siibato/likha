import 'dart:convert';

import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/logging/cache_logger.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';

Future<AssessmentStatisticsModel?> getCachedStatistics(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final db = await localDatabase.database;
    final rows = await db.query(
      DbTables.assessmentStatisticsCache,
      where: '${AssessmentStatisticsCacheCols.assessmentId} = ?',
      whereArgs: [assessmentId],
      limit: 1,
    );

    if (rows.isEmpty) return null;

    final jsonStr = rows.first[AssessmentStatisticsCacheCols.statisticsJson] as String?;
    if (jsonStr == null || jsonStr.isEmpty) return null;

    final json = jsonDecode(jsonStr) as Map<String, dynamic>;
    return AssessmentStatisticsModel.fromJson(json);
  } catch (e) {
    CacheLogger.instance.warn('Failed to read cached statistics', e);
    return null;
  }
}
