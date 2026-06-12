import 'dart:convert';
import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';

Future<AssessmentStatisticsModel?> getCachedStatistics(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final db = await localDatabase.database;
    final results = await db.query(
      DbTables.assessmentStatisticsCache,
      where: '${AssessmentStatisticsCacheCols.assessmentId} = ?',
      whereArgs: [assessmentId],
    );
    if (results.isEmpty) return null;
    final json = jsonDecode(results.first[AssessmentStatisticsCacheCols.statisticsJson] as String) as Map<String, dynamic>;
    return AssessmentStatisticsModel.fromJson(json);
  } catch (e) {
    return null;
  }
}
