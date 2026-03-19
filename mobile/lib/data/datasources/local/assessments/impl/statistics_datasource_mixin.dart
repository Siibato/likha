import 'dart:convert';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/core/database/db_schema.dart';
import 'package:sqflite/sqflite.dart';
import '../assessment_local_datasource_base.dart';

mixin StatisticsDataSourceMixin on AssessmentLocalDataSourceBase {
  @override
  Future<AssessmentStatisticsModel?> getCachedStatistics(String assessmentId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        'assessment_statistics_cache',
        where: 'assessment_id = ?',
        whereArgs: [assessmentId],
      );
      if (results.isEmpty) return null;
      final json = jsonDecode(results.first['statistics_json'] as String) as Map<String, dynamic>;
      return AssessmentStatisticsModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheStatistics(AssessmentStatisticsModel statistics) async {
    try {
      final db = await localDatabase.database;
      final now = DateTime.now().toIso8601String();
      // GHOST TABLE: assessment_statistics_cache does not exist in schema
      await db.insert(
        'assessment_statistics_cache',
        {
          'assessment_id': statistics.assessmentId,
          'statistics_json': jsonEncode(statistics.toJson()),
          'cached_at': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      // Non-fatal: statistics cache is optional
    }
  }

  @override
  Future<StudentResultModel?> getCachedStudentResults(String submissionId) async {
    try {
      final db = await localDatabase.database;
      final results = await db.query(
        DbTables.studentResultsCache,
        where: '${StudentResultsCacheCols.submissionId} = ?',
        whereArgs: [submissionId],
      );
      if (results.isEmpty) return null;
      final json = jsonDecode(results.first['results_json'] as String) as Map<String, dynamic>;
      return StudentResultModel.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> cacheStudentResults(StudentResultModel result) async {
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
      // Non-fatal: results cache is optional
    }
  }
}