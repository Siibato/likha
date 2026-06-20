import 'package:likha/core/database/db_schema.dart';
import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/errors/exceptions.dart';
import 'package:likha/core/logging/repo_logger.dart';
import 'package:likha/data/models/assessments/assessment_model.dart';

Future<List<AssessmentModel>> getCachedAssessments(
  LocalDatabase localDatabase,
  String classId, {
  bool publishedOnly = false,
}) async {
  try {
    final db = await localDatabase.database;
    final where = publishedOnly
        ? '${AssessmentsCols.classId} = ? AND ${AssessmentsCols.isPublished} = 1 AND ${CommonCols.deletedAt} IS NULL'
        : '${AssessmentsCols.classId} = ? AND ${CommonCols.deletedAt} IS NULL';
    final results = await db.query(
      DbTables.assessments,
      where: where,
      whereArgs: [classId],
      orderBy: '${AssessmentsCols.orderIndex} ASC',
    );
    if (results.isEmpty) return [];

    final assessmentIds = results.map((r) => r['id'] as String).toList();
    final inClause = assessmentIds.map((_) => '?').join(',');

    // Batch fetch question stats for all assessments in one query
    final questionStatsResult = await db.rawQuery(
      'SELECT assessment_id, COUNT(*) as count, COALESCE(SUM(points), 0) as total_points FROM ${DbTables.assessmentQuestions} WHERE assessment_id IN ($inClause) AND deleted_at IS NULL GROUP BY assessment_id',
      assessmentIds,
    );
    final questionCounts = <String, int>{};
    final questionTotalPoints = <String, int>{};
    for (final row in questionStatsResult) {
      final id = row['assessment_id'] as String;
      questionCounts[id] = (row['count'] as int?) ?? 0;
      questionTotalPoints[id] = (row['total_points'] as int?) ?? 0;
    }

    // Batch fetch submission counts for all assessments in one query
    final submissionCountsResult = await db.rawQuery(
      'SELECT assessment_id, COUNT(*) as count FROM ${DbTables.assessmentSubmissions} WHERE assessment_id IN ($inClause) AND deleted_at IS NULL GROUP BY assessment_id',
      assessmentIds,
    );
    final submissionCounts = <String, int>{};
    for (final row in submissionCountsResult) {
      final id = row['assessment_id'] as String;
      submissionCounts[id] = (row['count'] as int?) ?? 0;
    }

    final assessments = <AssessmentModel>[];
    for (final result in results) {
      final assessment = AssessmentModel.fromMap(result);
      final actualCount = questionCounts[assessment.id] ?? 0;
      final computedTotalPoints = questionTotalPoints[assessment.id] ?? 0;
      final liveSubCount = submissionCounts[assessment.id] ?? 0;
      final effectiveSubCount = liveSubCount > 0 ? liveSubCount : assessment.submissionCount;
      final effectiveTotalPoints = computedTotalPoints > 0 ? computedTotalPoints : assessment.totalPoints;

      RepoLogger.instance.log('${assessment.title} | dbTotalPoints=${assessment.totalPoints} | computedFromQuestions=$computedTotalPoints | effectiveTotalPoints=$effectiveTotalPoints | gradingPeriod=${assessment.gradingPeriodNumber} | component=${assessment.component}');

      assessments.add(AssessmentModel(
        id: assessment.id,
        classId: assessment.classId,
        title: assessment.title,
        description: assessment.description,
        timeLimitMinutes: assessment.timeLimitMinutes,
        openAt: assessment.openAt,
        closeAt: assessment.closeAt,
        showResultsImmediately: assessment.showResultsImmediately,
        resultsReleased: assessment.resultsReleased,
        isPublished: assessment.isPublished,
        orderIndex: assessment.orderIndex,
        totalPoints: effectiveTotalPoints,
        questionCount: actualCount > 0 ? actualCount : assessment.questionCount,
        submissionCount: effectiveSubCount,
        tosId: assessment.tosId,
        gradingPeriodNumber: assessment.gradingPeriodNumber,
        component: assessment.component,
        isSubmitted: assessment.isSubmitted,
        createdAt: assessment.createdAt,
        updatedAt: assessment.updatedAt,
        cachedAt: assessment.cachedAt,
        syncStatus: assessment.syncStatus,
        deletedAt: assessment.deletedAt,
      ));
    }

    return assessments;
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
