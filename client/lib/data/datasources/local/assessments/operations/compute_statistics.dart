import 'package:likha/core/database/local_database.dart';
import 'package:likha/core/logging/stats_logger.dart';
import 'package:likha/data/datasources/local/assessments/operations/statistics_computer.dart';
import 'package:likha/data/datasources/local/assessments/operations/statistics_data_fetcher.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';

/// Thin orchestrator that fetches raw data and delegates computation.
///
/// Returns `null` when local data is incomplete (e.g., submissions exist
/// but answer rows are missing), signaling the repository to fall back
/// to the server.
Future<AssessmentStatisticsModel?> computeStatistics(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  try {
    final fetcher = StatisticsDataFetcher(localDatabase);
    final data = await fetcher.fetchAll(assessmentId);

    if (data.submissions.isEmpty) {
      return AssessmentStatisticsModel(
        assessmentId: assessmentId,
        title: data.title,
        totalPoints: data.totalPoints,
        submissionCount: 0,
        classStatistics: const ClassStatisticsModel(
          mean: 0,
          median: 0,
          stdDev: 0,
          highest: 0,
          lowest: 0,
          passRate: 0,
          failRate: 0,
          scoreDistribution: [],
        ),
        questionStatistics: const [],
        itemAnalysis: const [],
      );
    }

    if (!data.isComplete) {
      final subsWithAnswers = data.answers.map((a) => a.submissionId).toSet().length;
      final threshold = data.submissions.length < 10 ? data.submissions.length : (data.submissions.length * 0.8).ceil();
      StatsLogger.instance.warn(
        'computeStatistics: local data INCOMPLETE — '
        'submissions=${data.submissions.length} '
        'submissionsWithAnswers=$subsWithAnswers '
        'threshold=$threshold → falling back to remote',
      );
      return null;
    }

    return StatisticsComputer.compute(data);
  } catch (_) {
    return null;
  }
}
