import 'package:likha/data/models/assessments/statistics_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import '../assessment_local_datasource_base.dart';
import 'operations/statistics/get_cached_statistics.dart';
import 'operations/statistics/cache_statistics.dart';
import 'operations/statistics/get_cached_student_results.dart';
import 'operations/statistics/cache_student_results.dart';

mixin StatisticsDataSourceMixin on AssessmentLocalDataSourceBase {
  @override
  Future<AssessmentStatisticsModel?> getCachedStatistics(String assessmentId) async {
    return getCachedStatisticsOp(localDatabase, assessmentId);
  }

  @override
  Future<void> cacheStatistics(AssessmentStatisticsModel statistics) async {
    return cacheStatisticsOp(localDatabase, statistics);
  }

  @override
  Future<StudentResultModel?> getCachedStudentResults(String submissionId) async {
    return getCachedStudentResultsOp(localDatabase, submissionId);
  }

  @override
  Future<void> cacheStudentResults(StudentResultModel result) async {
    return cacheStudentResultsOp(localDatabase, result);
  }
}