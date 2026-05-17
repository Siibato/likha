import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import '../assessment_local_datasource_base.dart';
import 'operations/cache/cache_assessments.dart';
import 'operations/cache/cache_assessment_detail.dart';
import 'operations/cache/cache_questions.dart';
import 'operations/cache/release_results_locally.dart';
import 'operations/cache/delete_assessment_locally.dart';
import 'operations/cache/clear_all_cache.dart';

mixin AssessmentCacheMixin on AssessmentLocalDataSourceBase {
  @override
  Future<void> cacheAssessments(List<AssessmentModel> assessments) async {
    return cacheAssessmentsOp(localDatabase, assessments);
  }

  @override
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions) async {
    return cacheAssessmentDetailOp(localDatabase, enc, assessment, questions);
  }

  @override
  Future<void> cacheQuestions(
    String assessmentId,
    List<QuestionModel> questions, {
    bool isServerConfirmed = false,
  }) async {
    return cacheQuestionsOp(localDatabase, enc, assessmentId, questions, isServerConfirmed: isServerConfirmed);
  }

  @override
  Future<void> releaseResultsLocally({required String assessmentId}) async {
    return releaseResultsLocallyOp(localDatabase, syncQueue, assessmentId);
  }

  @override
  Future<void> deleteAssessmentLocally({required String assessmentId}) async {
    return deleteAssessmentLocallyOp(localDatabase, assessmentId);
  }

  @override
  Future<void> clearAllCache() async {
    return clearAllCacheOp(localDatabase);
  }
}
