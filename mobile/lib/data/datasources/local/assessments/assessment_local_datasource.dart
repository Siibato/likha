import 'package:likha/data/models/assessments/assessment_model.dart';
import 'package:likha/data/models/assessments/question_model.dart';
import 'package:likha/data/models/assessments/submission_model.dart';
import 'package:likha/data/models/assessments/statistics_model.dart';

abstract class AssessmentLocalDataSource {
  Future<List<AssessmentModel>> getCachedAssessments(String classId);
  Future<(AssessmentModel, List<QuestionModel>)> getCachedAssessmentDetail(String assessmentId);
  Future<void> cacheAssessments(List<AssessmentModel> assessments);
  Future<void> cacheAssessmentDetail(AssessmentModel assessment, List<QuestionModel> questions);
  Future<void> cacheQuestions(String assessmentId, List<QuestionModel> questions);
  Future<void> updateQuestionLocally({
    required String questionId,
    required Map<String, dynamic> updates,
  });
  Future<void> deleteQuestionLocally({required String questionId});
  Future<void> updateQuestionId({
    required String localId,
    required String serverId,
  });
  Future<void> updateChoiceIds({
    required String questionId,
    required Map<String, String> idMapping,
  });
  Future<void> updateCorrectAnswerIds({
    required String questionId,
    required Map<String, String> idMapping,
  });
  Future<void> saveAnswersLocally({
    required String submissionId,
    required String answersJson,
  });
  Future<void> cacheStartSubmissionResult({
    required String submissionId,
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
    required DateTime startedAt,
  });
  Future<String> startAssessmentLocally({
    required String assessmentId,
    required String studentId,
    required String studentName,
    required String studentUsername,
  });
  Future<StartSubmissionResultModel?> getCachedStartResult(String submissionId);
  Future<void> submitAssessmentLocally({
    required String submissionId,
    required String assessmentId,
  });
  Future<SubmissionDetailModel?> getCachedSubmissionDetail(String submissionId);
  Future<void> cacheSubmissionDetail(SubmissionDetailModel submission);
  Future<String> createAssessmentLocally({
    required String classId,
    required String title,
    String? description,
    required int timeLimitMinutes,
    required String openAt,
    required String closeAt,
    bool? showResultsImmediately,
  });
  Future<List<SubmissionSummaryModel>> getCachedSubmissions(String assessmentId);
  Future<void> cacheSubmissions(String assessmentId, List<SubmissionSummaryModel> submissions);
  Future<AssessmentStatisticsModel?> getCachedStatistics(String assessmentId);
  Future<void> cacheStatistics(AssessmentStatisticsModel statistics);
  Future<StudentResultModel?> getCachedStudentResults(String submissionId);
  Future<void> cacheStudentResults(StudentResultModel result);
  Future<void> releaseResultsLocally({required String assessmentId});
  Future<void> overrideAnswerLocally({
    required String answerId,
    required bool isCorrect,
  });
  Future<void> clearAllCache();
}