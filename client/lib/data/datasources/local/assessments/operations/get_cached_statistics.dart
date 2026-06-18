import 'package:likha/core/database/local_database.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';
import 'compute_statistics.dart';

Future<AssessmentStatisticsModel?> getCachedStatistics(
  LocalDatabase localDatabase,
  String assessmentId,
) async {
  return computeStatistics(localDatabase, assessmentId);
}
