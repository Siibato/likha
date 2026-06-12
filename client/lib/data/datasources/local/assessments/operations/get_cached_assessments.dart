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

    final assessments = <AssessmentModel>[];

    for (final result in results) {
      final assessment = AssessmentModel.fromMap(result);
      final statsResult = await db.rawQuery(
        'SELECT COUNT(*) as count, SUM(points) as total_points FROM ${DbTables.assessmentQuestions} WHERE assessment_id = ? AND deleted_at IS NULL',
        [assessment.id],
      );
      final actualCount = statsResult.first['count'] as int? ?? 0;
      final computedTotalPoints = statsResult.first['total_points'] as int? ?? 0;

      final subCountResult = await db.rawQuery(
        'SELECT COUNT(*) as count FROM ${DbTables.assessmentSubmissions} WHERE assessment_id = ? AND deleted_at IS NULL',
        [assessment.id],
      );
      final liveSubCount = subCountResult.first['count'] as int? ?? 0;
      final effectiveSubCount = liveSubCount > 0 ? liveSubCount : assessment.submissionCount;

      final effectiveTotalPoints = computedTotalPoints > 0 ? computedTotalPoints : assessment.totalPoints;

      RepoLogger.instance.log('${assessment.title} | dbTotalPoints=${assessment.totalPoints} | computedFromQuestions=$computedTotalPoints | effectiveTotalPoints=$effectiveTotalPoints | gradingPeriod=${assessment.gradingPeriodNumber} | component=${assessment.component}');

      final updatedAssessment = AssessmentModel(
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
        needsSync: assessment.needsSync,
        deletedAt: assessment.deletedAt,
      );
      assessments.add(updatedAssessment);
    }

    return assessments;
  } catch (e) {
    if (e is CacheException) rethrow;
    throw CacheException(e.toString());
  }
}
